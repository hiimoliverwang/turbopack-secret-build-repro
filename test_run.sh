#!/bin/bash

set -e

echo "=========================================="
echo "Tree-Shaking Test (assertAntOnly pattern)"
echo "=========================================="
echo ""

# Test 1: Build WITH env var - __ant_only__ SHOULD be found
echo "TEST 1: Building WITH NEXT_PUBLIC_INCLUDE_SECRET_STUFF=true"
echo "Expected: __ant_only__ SHOULD be found (code is included)"
echo "------------------------------------------------------------"
rm -rf .next
NEXT_PUBLIC_INCLUDE_SECRET_STUFF=true npm run build:webpack

echo ""
echo "Checking webpack build..."
result1=$(./check-prune.sh)
echo "$result1"

echo ""
echo ""

# Test 2: Build WITHOUT env var - __ant_only__ should NOT be found
echo "TEST 2: Building WITHOUT NEXT_PUBLIC_INCLUDE_SECRET_STUFF"
echo "Expected: __ant_only__ should NOT be found (code should be tree-shaken)"
echo "Reality: If found, tree-shaking FAILED"
echo "------------------------------------------------------------------------"
rm -rf .next
npm run build:webpack

echo ""
echo "Checking webpack build..."
result2=$(./check-prune.sh)
echo "$result2"

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "WITH env var:    $result1"
echo "WITHOUT env var: $result2"
echo ""

if echo "$result2" | grep -q "ANT_ONLY_FOUND=true"; then
  echo "❌ TREE-SHAKING FAILED: __ant_only__ was found even without env var"
  echo "This means the component code was NOT tree-shaken from the bundle"
  exit 1
else
  echo "✅ TREE-SHAKING WORKED: __ant_only__ was not found without env var"
  exit 0
fi
