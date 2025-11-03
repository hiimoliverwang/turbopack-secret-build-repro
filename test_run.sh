#!/bin/bash

set -e

echo "=========================================="
echo "Turbopack Pruning Test"
echo "=========================================="
echo ""

# Test 1: Build WITH the environment variable
echo "TEST 1: Building WITH NEXT_PUBLIC_INCLUDE_SECRET_STUFF=true"
echo "Expected: Both strings should be found (code is included)"
echo "----------------------------------------------------------"
NEXT_PUBLIC_INCLUDE_SECRET_STUFF=true npm run build

echo ""
echo "Checking build output..."
./check-prune.sh || true

echo ""
echo ""

# Test 2: Build WITHOUT the environment variable
echo "TEST 2: Building WITHOUT NEXT_PUBLIC_INCLUDE_SECRET_STUFF"
echo "Expected: Neither string should be found (code should be pruned)"
echo "Reality: Both strings will likely be found (pruning fails)"
echo "------------------------------------------------------------"
npm run build

echo ""
echo "Checking build output..."
./check-prune.sh || true

echo ""
echo "=========================================="
echo "Test Complete"
echo "=========================================="
