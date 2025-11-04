# Turbopack Tree-Shaking Issues

## Summary

Turbopack has two related tree-shaking issues that prevent complete elimination of dead code:

1. **Transitive imports not eliminated**: Imports from tree-shaken components remain in the bundle
2. **Function definitions not tree-shaken**: Utility functions stay in the bundle even when all references are removed

Both issues are demonstrated in this repository with automated proof scripts.

---

## Issue 1: Transitive Imports Not Eliminated

### Problem

When a component is tree-shaken, its imports should also be removed. Turbopack removes the component but keeps the import statements.

### Impact

- ❌ Unused utility functions remain in bundle
- ❌ Increased bundle size
- ❌ Breaks tree-shaking verification methods

### Minimal Reproduction

**Import chain:**
```
app/issue-repro/page.tsx
  ↓ imports
components/SecretComponent.tsx
  ↓ imports
lib/assertPrune.ts
```

**Source code:**

```typescript
// app/issue-repro/page.tsx
"use client";
import { SecretComponent } from "@/components/SecretComponent";

export default function IssueReproPage() {
  if (process.env.NEXT_PUBLIC_INCLUDE_SECRET_STUFF) {
    return <SecretComponent />;
  }
  return <div>Public page</div>;
}
```

```typescript
// components/SecretComponent.tsx
import { assertPrune } from "@/lib/assertPrune";

export function SecretComponent() {
  assertPrune();
  return <div>Secret Content</div>;
}
```

```typescript
// lib/assertPrune.ts
export function assertPrune() {
  console.assert('__ant_only__');
  if (!process.env.NEXT_PUBLIC_INCLUDE_SECRET_STUFF) {
    throw new Error('Environment variable is not set');
  }
}
```

**Configuration:**
```typescript
// next.config.ts
export default {
  env: {
    // Setting to "" enables constant folding
    NEXT_PUBLIC_INCLUDE_SECRET_STUFF:
      process.env.NEXT_PUBLIC_INCLUDE_SECRET_STUFF || "",
  },
};
```

### Expected Behavior (Webpack)

When building **without** the env var:
1. ✅ Route-level check eliminates `<SecretComponent />` (dead code)
2. ✅ `SecretComponent` never referenced → tree-shaken
3. ✅ `assertPrune()` never referenced → tree-shaken
4. ✅ Both removed from bundle

### Actual Behavior (Turbopack)

When building **without** the env var:
1. ✅ Route-level check eliminates `<SecretComponent />` (dead code)
2. ✅ `SecretComponent` never referenced → tree-shaken
3. ❌ `assertPrune()` never referenced → **NOT tree-shaken**
4. ❌ `assertPrune()` remains in bundle

### Bundle Evidence

**Turbopack output:**
```javascript
// .next/static/chunks/8efbbf25e6067adf.js

// The page component (returns "Public page" only)
function r(){return(0,e.jsx)("div",{children:"Public page"})}

// But it imports module 12704 (assertPrune)!
t.i(12704)  // ← This import should not be here

// Module 12704 definition:
function e(){
  throw console.assert("__ant_only__"),
  Error("Environment variable is not set")
}
t.s(["assertPrune",()=>e])
```

The import `t.i(12704)` should not exist because:
- `SecretComponent` (which imports assertPrune) was tree-shaken
- Nothing in the page references `assertPrune`

**Webpack output:**
```bash
$ grep -r "assertPrune" .next/static/
# No results - correctly tree-shaken ✅
```

---

## Issue 2: Function Definitions Not Eliminated

### Problem

Even when all call sites are removed, shared utility functions remain in the bundle. This is related to Issue 1 but worth noting separately.

### Observation

The `assertPrune` function:
- Is called only by `SecretComponent`
- `SecretComponent` is tree-shaken
- But `assertPrune` definition still exists in the bundle

This suggests that even if Issue 1 were fixed (import statements removed), the function definition itself might still be present as dead code that needs a second pass of elimination.

### Connection to Issue 1

If the import statement (`t.i(12704)`) were eliminated, a subsequent tree-shaking pass should recognize that module 12704 (assertPrune) is never imported anywhere and remove it entirely. The fact that the import remains prevents this second-level elimination.

---

## Proof

### Automated Verification

```bash
# Install dependencies
npm install

# Prove Issue 1: Transitive imports not eliminated
./prove_bug.sh

# Compare Turbopack vs Webpack
./compare_webpack.sh
```

### Expected Output

```
                     Turbopack       Webpack
SecretComponent      SHAKEN          SHAKEN
assertPrune          NOT_SHAKEN      SHAKEN

🐛 BUG CONFIRMED: Webpack tree-shakes assertPrune, Turbopack doesn't
```

### Manual Verification

```bash
# Build without env var
npm run build

# Check that component is tree-shaken
# Note: We check for JSX text content, not function names (which get minified)
grep -r "Secret Content" .next/static/
# No results ✅ (component was tree-shaken)

# Verify by building WITH env var:
NEXT_PUBLIC_INCLUDE_SECRET_STUFF=1 npm run build
grep -r "Secret Content" .next/static/
# Found: children:"Secret Content" ✅ (JSX text stays literal)

# Check that assertPrune is NOT tree-shaken (Issue 1)
npm run build  # Without env var again
grep -r "assertPrune" .next/static/
# Found in bundle ❌ (the bug)
```

---

## Root Cause Analysis

### Issue 1: Import Elimination

Turbopack's tree-shaking appears to work in these stages:
1. ✅ Constant folding: `if ("")` → always false
2. ✅ Dead code elimination: Remove unreachable branches
3. ✅ Component elimination: Remove unused component code
4. ❌ Import cleanup: **MISSING** - Import statements from eliminated code remain

Webpack includes this fourth stage. Turbopack does not.

### Issue 2: Function Definition Cleanup

This may be a consequence of Issue 1:
- Import statement keeps module reference alive
- Module definition cannot be eliminated while references exist
- Fixing Issue 1 might automatically fix Issue 2

---

## Environment

- **Next.js**: 15.5.6 (Turbopack)
- **Node.js**: 23.5.0
- **OS**: macOS (Darwin 24.6.0)

---

## Repository Structure

```
app/
  issue-repro/page.tsx      # Minimal reproduction
  page.tsx                  # Another example
components/
  SecretComponent.tsx       # Component to be tree-shaken
lib/
  assertPrune.ts           # Utility function
next.config.ts             # Critical env var config
prove_bug.sh              # Automated proof script
compare_webpack.sh        # Turbopack vs Webpack comparison
```

---

## Related Patterns

This bug affects any code pattern where:
1. Component A imports utility function B
2. Component A is conditionally rendered based on env var
3. Route-level check eliminates Component A as dead code
4. Function B should be eliminated but isn't

Common use cases:
- Feature flags that remove entire features
- Environment-specific debugging code
- Development vs production code paths
- Conditional third-party library imports

---

## SWC Configuration Limitations

We investigated whether SWC could be configured to inline functions (like Terser does), which would make the `assertPrune` function inline into components and get tree-shaken with them.

### What We Tried

**`.swcrc` configuration:**
```json
{
  "jsc": {
    "minify": {
      "compress": {
        "inline": 3
      }
    }
  }
}
```

**Result:** ❌ Next.js explicitly ignores `.swcrc` files

From Next.js docs:
> Next.js does not support custom .swcrc configuration files

### Why This Doesn't Help Anyway

Even if SWC could inline functions, it wouldn't fix the core issue:
- The problem is that **import statements** from tree-shaken components remain
- Inlining would just move the code, not eliminate the import
- The real issue is transitive import elimination, not function inlining

### Conclusion

SWC configuration is:
1. Not exposed by Next.js 15
2. Not the right solution anyway (issue is import elimination, not inlining)

The core problem is that Turbopack doesn't eliminate imports from dead code branches.

---

## Request

Can the Next.js/Turbopack team investigate:

1. **Primary issue**: Why import statements from tree-shaken components are not eliminated?
2. **Secondary**: Whether fixing #1 would automatically resolve #2 (function definitions)?

This works correctly in Webpack but fails in Turbopack, causing production bundles to include unnecessary code.
