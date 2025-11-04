#!/bin/bash
set -e

echo "================================================"
echo "Tree-Shaking Verification Script"
echo "================================================"
echo ""

# Clean previous builds
echo "Cleaning previous build..."
rm -rf .next
echo ""

# Test 1: Build without env var (component should be tree-shaken)
echo "================================================"
echo "TEST 1: Build WITHOUT env var"
echo "Expected: SecretComponent should be tree-shaken"
echo "================================================"
echo ""

npm run build > /dev/null 2>&1

echo "Checking for component-specific content..."
if grep -r "Secret Content" .next/static/ > /dev/null 2>&1; then
  echo "❌ FAIL: 'Secret Content' found in bundle (should be tree-shaken)"
  RESULT_1="FAIL"
else
  echo "✅ PASS: 'Secret Content' NOT found in bundle (tree-shaken correctly)"
  RESULT_1="PASS"
fi
echo ""

echo "Checking for assertPrune function..."
if grep -r "__ant_only__" .next/static/ > /dev/null 2>&1; then
  echo "ℹ️  INFO: '__ant_only__' found in bundle (expected - it's in the function definition)"
else
  echo "⚠️  WARN: '__ant_only__' not found (unexpected)"
fi
echo ""

# Test 2: Build with env var (component should be included)
echo "================================================"
echo "TEST 2: Build WITH env var"
echo "Expected: SecretComponent should be included"
echo "================================================"
echo ""

rm -rf .next
NEXT_PUBLIC_INCLUDE_SECRET_STUFF=1 npm run build > /dev/null 2>&1

echo "Checking for component-specific content..."
if grep -r "Secret Content" .next/static/ > /dev/null 2>&1; then
  echo "✅ PASS: 'Secret Content' found in bundle (component included correctly)"
  RESULT_2="PASS"
else
  echo "❌ FAIL: 'Secret Content' NOT found in bundle (should be included)"
  RESULT_2="FAIL"
fi
echo ""

# Summary
echo "================================================"
echo "SUMMARY"
echo "================================================"
echo "Test 1 (WITHOUT env var): $RESULT_1"
echo "Test 2 (WITH env var):    $RESULT_2"
echo ""

if [ "$RESULT_1" = "PASS" ] && [ "$RESULT_2" = "PASS" ]; then
  echo "✅ All tests passed - tree-shaking is working correctly"
  exit 0
else
  echo "❌ Some tests failed"
  exit 1
fi
