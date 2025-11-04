#!/bin/bash

set -e

echo "=========================================="
echo "Tree-Shaking Pattern Tests"
echo "=========================================="
echo ""

# Test 1: Current working pattern
echo "TEST 1: Route-level check (app/page.tsx)"
echo "Pattern: export default wraps component in if(env)"
echo "Expected: PASS (no __ant_only__ in bundle)"
echo "------------------------------------------"
npm run build > /dev/null 2>&1
result=$(./check-prune.sh)
echo "$result"
if echo "$result" | grep -q "ANT_ONLY_FOUND=false"; then
  echo "✅ PASSED - Tree-shaking worked!"
else
  echo "❌ FAILED - Tree-shaking did not work"
fi
echo ""

# Test 2: Create a failing pattern
echo "TEST 2: Creating inline-fail pattern..."
echo "Pattern: import component with inline assertPrune, no route-level check"
echo "Expected: FAIL (__ant_only__ found in bundle)"
echo "------------------------------------------"

# Create the failing page
mkdir -p app/inline-fail
cat > app/inline-fail/page.tsx << 'EOF'
'use client'
import styles from "../page.module.css";
import { InlineComponent } from "@/components/InlineComponent";

export default function InlineFailPage() {
  return (
    <div className={styles.page}>
      <main className={styles.main}>
        <h1>Inline Fail Pattern</h1>
        <p>This demonstrates when tree-shaking FAILS</p>
        {process.env.NEXT_PUBLIC_INCLUDE_SECRET_STUFF && <InlineComponent />}
      </main>
    </div>
  );
}
EOF

npm run build > /dev/null 2>&1
result=$(./check-prune.sh)
echo "$result"
if echo "$result" | grep -q "ANT_ONLY_FOUND=true"; then
  echo "✅ CONFIRMED - Tree-shaking failed as expected!"
else
  echo "❌ UNEXPECTED - Should have failed but didn't"
fi
echo ""

# Cleanup
echo "Cleaning up test files..."
rm -rf app/inline-fail
echo ""

echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Route-level check: ✅ Works (tree-shaking succeeds)"
echo "Inline import:     ❌ Fails (tree-shaking fails)"
echo ""
echo "The key difference:"
echo "  ✅ if (env) return <Component /> - Component module eliminated"
echo "  ❌ import { Component }; {env && <Component />} - Module already loaded"
