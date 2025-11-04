# Turbopack Tree-Shaking Bug Reproduction

This repository demonstrates two related tree-shaking bugs in Turbopack that cause unused code to remain in production bundles.

## Quick Start

```bash
# Install dependencies
npm install

# Prove the bug exists
./prove_bug.sh

# Compare Turbopack vs Webpack
./compare_webpack.sh
```

## The Issues

### Issue 1: Transitive Imports Not Eliminated

When a component is tree-shaken, its imports should also be removed. Turbopack removes the component but keeps the import statements.

```
Page → SecretComponent → assertPrune()
```

**Webpack:** Both `SecretComponent` AND `assertPrune` removed ✅
**Turbopack:** Only `SecretComponent` removed, `assertPrune` stays ❌

### Issue 2: Function Definitions Not Tree-Shaken

Even when all call sites are removed, utility functions remain in the bundle. This is likely a consequence of Issue 1 (import statements keep module references alive).

## Documentation

- **[BUG_REPORT.md](./BUG_REPORT.md)** ⭐ **Start here** - Complete bug report for Next.js team
- **[PATTERNS.md](./PATTERNS.md)** - Educational guide on tree-shaking patterns

## Verification Scripts

### `prove_bug.sh` ⭐
Definitive proof showing:
1. `SecretComponent` is tree-shaken ✅ (checks for JSX text "Secret Content")
2. `assertPrune` (imported by SecretComponent) is NOT tree-shaken ❌

Note: We check for JSX text content ("Secret Content") rather than function names because function names get minified but JSX text stays literal in the bundle.

```bash
./prove_bug.sh
```

**Output:**
```
TEST 1: Is SecretComponent tree-shaken?
✅ PASS: 'Secret Content' not found - component IS tree-shaken

TEST 2: Is assertPrune tree-shaken?
❌ BUG CONFIRMED: 'assertPrune' found in bundle

CONCLUSION:
SecretComponent:  ✅ Tree-shaken correctly
assertPrune:      ❌ NOT tree-shaken (BUG)
```

### `compare_webpack.sh` ⭐
Side-by-side comparison showing Webpack eliminates both but Turbopack doesn't:

```bash
./compare_webpack.sh
```

**Output:**
```
                     Turbopack       Webpack
SecretComponent      SHAKEN          SHAKEN
assertPrune          NOT_SHAKEN      SHAKEN

🐛 BUG CONFIRMED: Webpack tree-shakes assertPrune, Turbopack doesn't
```

### `verify_tree_shaking.sh`
Comprehensive test building with/without env var:

```bash
./verify_tree_shaking.sh
```

## Test Files

- `app/issue-repro/page.tsx` - Minimal reproduction for Next.js team
- `app/page.tsx` - Additional example
- `components/SecretComponent.tsx` - Component that should be tree-shaken
- `lib/assertPrune.ts` - Utility function that should be eliminated

## Configuration

Critical configuration in `next.config.ts`:

```typescript
export default {
  env: {
    // Setting to "" (not undefined) enables constant folding
    NEXT_PUBLIC_INCLUDE_SECRET_STUFF:
      process.env.NEXT_PUBLIC_INCLUDE_SECRET_STUFF || "",
  },
};
```

Without the `|| ""`, the env var would be `undefined` when not set, preventing constant folding and dead code elimination.

## Pattern That Works

```typescript
// Route-level check (✅ Enables tree-shaking)
export default function Page() {
  if (process.env.NEXT_PUBLIC_FEATURE_FLAG) {
    return <FeatureComponent />;
  }
  return <PublicVersion />;
}
```

The conditional must be at the page export level, not inline in JSX.

## For the Next.js Team

See **[BUG_REPORT.md](./BUG_REPORT.md)** for:
- Detailed explanation of both issues
- Minimal reproduction case
- Bundle analysis showing the problem
- Root cause analysis

**TL;DR:** Turbopack tree-shakes components correctly but fails to eliminate their transitive imports, causing utility functions to remain in the bundle. Run `./compare_webpack.sh` to see the difference.

## Environment

- **Next.js**: 15.5.6 (Turbopack)
- **Node.js**: 23.5.0
- **OS**: macOS
