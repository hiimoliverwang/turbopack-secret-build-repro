#!/bin/bash

set -e

echo "=========================================="
echo "Tree-Shaking Test (assertAntOnly pattern)"
echo "=========================================="
echo ""

# Test 1: Turbopack WITHOUT env var
echo "TEST 1: Turbopack WITHOUT NEXT_PUBLIC_INCLUDE_SECRET_STUFF"
echo "Expected: __ant_only__ should NOT be found (tree-shaken)"
echo "-----------------------------------------------------------"
rm -rf .next
npm run build

echo ""
turbo_without=$(./check-prune.sh)
echo "$turbo_without"

echo ""
echo ""

# Test 2: Turbopack WITH env var
echo "TEST 2: Turbopack WITH NEXT_PUBLIC_INCLUDE_SECRET_STUFF=true"
echo "Expected: __ant_only__ SHOULD be found (code included)"
echo "-----------------------------------------------------------"
rm -rf .next
NEXT_PUBLIC_INCLUDE_SECRET_STUFF=true npm run build

echo ""
turbo_with=$(./check-prune.sh)
echo "$turbo_with"

echo ""
echo ""

# Test 3: Webpack WITHOUT env var
echo "TEST 3: Webpack WITHOUT NEXT_PUBLIC_INCLUDE_SECRET_STUFF"
echo "Expected: __ant_only__ should NOT be found (tree-shaken)"
echo "----------------------------------------------------------"
rm -rf .next
npm run build:webpack

echo ""
webpack_without=$(./check-prune.sh)
echo "$webpack_without"

echo ""
echo ""

# Test 4: Webpack WITH env var
echo "TEST 4: Webpack WITH NEXT_PUBLIC_INCLUDE_SECRET_STUFF=true"
echo "Expected: __ant_only__ SHOULD be found (code included)"
echo "----------------------------------------------------------"
rm -rf .next
NEXT_PUBLIC_INCLUDE_SECRET_STUFF=true npm run build:webpack

echo ""
webpack_with=$(./check-prune.sh)
echo "$webpack_with"

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Turbopack WITHOUT env: $turbo_without"
echo "Turbopack WITH env:    $turbo_with"
echo "Webpack WITHOUT env:   $webpack_without"
echo "Webpack WITH env:      $webpack_with"
echo ""

turbo_fail=$(echo "$turbo_without" | grep -q "ANT_ONLY_FOUND=true" && echo "FAILED" || echo "PASSED")
webpack_fail=$(echo "$webpack_without" | grep -q "ANT_ONLY_FOUND=true" && echo "FAILED" || echo "PASSED")

echo "Turbopack tree-shaking: $turbo_fail"
echo "Webpack tree-shaking:   $webpack_fail"
echo ""

if [ "$turbo_fail" = "FAILED" ] || [ "$webpack_fail" = "FAILED" ]; then
  echo "❌ BUG CONFIRMED: Tree-shaking failed - __ant_only__ found in bundle without env var"
  exit 1
else
  echo "✅ Both bundlers properly tree-shook the code"
  exit 0
fi
