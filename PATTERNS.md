# Tree-Shaking Patterns in Next.js

This guide explains which code patterns enable tree-shaking with environment variables in Next.js, and why they work or fail.

## Core Concept

Tree-shaking only works when the bundler can **statically determine** that code will never be executed. The key is how imports and conditionals interact.

---

## Pattern 1: ✅ WORKS - Route-Level Check

**File**: `app/page.tsx`

```typescript
import { FeatureContent } from "@/components/FeatureContent";

export default function Home() {
  if (process.env.NEXT_PUBLIC_INCLUDE_FEATURE) {
    return <FeatureContent />;
  }
  return <div>Public version</div>;
}
```

### What happens when env var is NOT set:

1. `next.config.ts` sets it to `""` (empty string)
2. The bundler sees: `if ("")` which is always false
3. The bundler eliminates the entire `if` block (dead code elimination)
4. `FeatureContent` is never used/referenced
5. Tree-shaking removes the entire `FeatureContent` module and all its dependencies

**Key insight**: The component is defined in a separate function/file, so when the reference is removed, the whole module can be tree-shaken.

---

## Pattern 2: ❌ FAILS - Unconditional Import with Inline Conditional

**File**: `app/inline-fail/page.tsx`

```typescript
import { InlineComponent } from "@/components/InlineComponent";

export default function InlineFailPage() {
  return (
    <div>
      {process.env.NEXT_PUBLIC_INCLUDE_FEATURE && <InlineComponent />}
    </div>
  );
}
```

**InlineComponent.tsx**:
```typescript
export function InlineComponent() {
  assertPrune();  // Calls immediately when component is defined
  return <div>Feature content</div>;
}
```

### What happens when env var is NOT set:

1. The `import { InlineComponent }` statement executes
2. This loads the entire `InlineComponent` module
3. Even though the JSX `{... && <InlineComponent />}` evaluates to false
4. The module is already loaded, so `assertPrune()` is in the bundle
5. Tree-shaking FAILS because the import happened unconditionally

**Key insight**: ES module imports are **hoisted** and execute before runtime conditionals. Once you import something, it's in the bundle.

---

## Pattern 3: ✅ WORKS - Route-Level Check with Inner Component

**File**: `app/feature/page.tsx`

```typescript
import { FeaturePage } from "./components/FeaturePage";

export default function TreeShakenFeaturePage() {
  if (process.env.NEXT_PUBLIC_INCLUDE_FEATURE) {
    return <FeaturePage />;
  }
  return <div>Not Found</div>;
}
```

**FeaturePage.tsx**:
```typescript
export function FeaturePage() {
  assertPrune();  // This DOES get tree-shaken!
  return <div>...</div>;
}
```

### What happens when env var is NOT set:

1. Route-level check eliminates the entire `<FeaturePage />` reference
2. The whole module is never used
3. Even though `assertPrune()` is called inline, the entire component is tree-shaken
4. Works because the route-level check prevents ANY reference to the component

---

## Pattern 4: ❌ FAILS - Same-File Component Definition

**Example** (this would fail):

```typescript
import { assertPrune } from "@/lib/assertPrune";

function SecretComponent() {
  assertPrune();  // Called inline
  return <div>Secret</div>;
}

export default function Page() {
  return (
    <div>
      {process.env.NEXT_PUBLIC_INCLUDE_FEATURE && <SecretComponent />}
    </div>
  );
}
```

### Why it fails:

1. `SecretComponent` is defined in the same file
2. The function definition is evaluated when the module loads
3. Even with conditional rendering, the function exists in the module
4. The import of `assertPrune` at the top brings in unwanted code
5. Tree-shaking can't eliminate the import because it's at module scope

---

## The Key Difference

### ✅ Works:
```typescript
// The conditional is at the DEFAULT EXPORT level
// The entire component module can be eliminated
export default function Page() {
  if (env_var) {
    return <ComponentInSeparateFile />;  // Whole file eliminated
  }
  return <Other />;
}
```

### ❌ Fails:
```typescript
// The component is imported/defined at module level
// Then conditionally used in JSX
import { Component } from "./Component";  // Already loaded!

export default function Page() {
  return (
    <div>
      {env_var && <Component />}  // Too late, already imported
    </div>
  );
}
```

---

## Visual Mental Model

**Working Pattern (Route-Level):**
```
env_var = false
    ↓
if (false) → ELIMINATED AT BUILD TIME
    ↓
return <Component />  → NEVER REFERENCED
    ↓
import Component  → TREE-SHAKEN
    ↓
Functions inside Component  → ELIMINATED
```

**Failing Pattern (Inline):**
```
import Component  → LOADED IMMEDIATELY
    ↓
env_var = false
    ↓
{false && <Component />}  → RUNTIME CHECK (too late!)
    ↓
Functions inside Component  → ALREADY IN BUNDLE
```

---

## Why next.config.ts Matters

```typescript
env: {
  NEXT_PUBLIC_VAR: process.env.NEXT_PUBLIC_VAR || "",
}
```

**Without the `|| ""`:**
- Undefined env var stays as `undefined`
- `if (undefined)` might not be optimized the same way
- Bundler can't guarantee it's always false

**With the `|| ""`:**
- Undefined becomes `""`
- `if ("")` is provably always false
- Bundler can safely eliminate the entire branch

---

## Turbopack Limitation

**Note:** Even with the correct pattern (route-level check), Turbopack has a bug where transitive imports are not eliminated:

```
Page → Component → UtilityFunction
```

- **Pattern 1 works**: Component is tree-shaken ✅
- **But**: UtilityFunction is NOT tree-shaken ❌ (Turbopack bug)

See [BUG_REPORT.md](./BUG_REPORT.md) for details.

---

## Summary

### ✅ What Works
1. Route-level env var checks that wrap entire page components
2. Explicitly setting env vars to `""` in `next.config.ts`
3. Separate component files (not same-file definitions)

### ❌ What Doesn't Work
1. Inline conditional rendering without route-level checks
2. Top-level imports of conditionally-rendered components
3. Leaving env vars as `undefined` instead of explicitly setting to `""`
4. Same-file component definitions with inline conditionals

### 🎯 Best Practice

**Always use route-level checks for conditional features:**

```typescript
export default function MyPage() {
  if (process.env.NEXT_PUBLIC_FEATURE_FLAG) {
    return <FeatureComponent />;
  }
  return <DefaultComponent />;
}
```

**And configure env vars explicitly:**
```typescript
// next.config.ts
env: {
  NEXT_PUBLIC_FEATURE_FLAG: process.env.NEXT_PUBLIC_FEATURE_FLAG || "",
}
```
