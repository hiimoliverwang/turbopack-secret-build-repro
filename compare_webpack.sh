#!/bin/bash
set -e

echo "================================================"
echo "Comparing Turbopack vs Webpack Tree-Shaking"
echo "================================================"
echo ""

# Test Turbopack
echo "========== TURBOPACK =========="
echo "Building with Turbopack..."
rm -rf .next
npm run build > /dev/null 2>&1

echo "✓ Build complete"
echo ""

echo "Checking for SecretComponent content..."
if grep -r "Secret Content" .next/static/ > /dev/null 2>&1; then
  echo "  ❌ Found (not tree-shaken)"
  TURBO_COMPONENT="NOT_SHAKEN"
else
  echo "  ✅ Not found (tree-shaken)"
  TURBO_COMPONENT="SHAKEN"
fi

echo "Checking for assertPrune..."
if grep -r "assertPrune" .next/static/ > /dev/null 2>&1; then
  echo "  ❌ Found (not tree-shaken)"
  TURBO_ASSERT="NOT_SHAKEN"
else
  echo "  ✅ Not found (tree-shaken)"
  TURBO_ASSERT="SHAKEN"
fi

echo ""

# Test Webpack
echo "========== WEBPACK =========="
echo "Building with Webpack..."
rm -rf .next
npm run build:webpack > /dev/null 2>&1

echo "✓ Build complete"
echo ""

echo "Checking for SecretComponent content..."
if grep -r "Secret Content" .next/static/ > /dev/null 2>&1; then
  echo "  ❌ Found (not tree-shaken)"
  WEBPACK_COMPONENT="NOT_SHAKEN"
else
  echo "  ✅ Not found (tree-shaken)"
  WEBPACK_COMPONENT="SHAKEN"
fi

echo "Checking for assertPrune..."
if grep -r "assertPrune" .next/static/ > /dev/null 2>&1; then
  echo "  ❌ Found (not tree-shaken)"
  WEBPACK_ASSERT="NOT_SHAKEN"
else
  echo "  ✅ Not found (tree-shaken)"
  WEBPACK_ASSERT="SHAKEN"
fi

echo ""
echo "================================================"
echo "COMPARISON"
echo "================================================"
printf "%-20s %-15s %-15s\n" "" "Turbopack" "Webpack"
printf "%-20s %-15s %-15s\n" "--------------------" "---------------" "---------------"
printf "%-20s %-15s %-15s\n" "SecretComponent" "$TURBO_COMPONENT" "$WEBPACK_COMPONENT"
printf "%-20s %-15s %-15s\n" "assertPrune" "$TURBO_ASSERT" "$WEBPACK_ASSERT"
echo ""

if [ "$TURBO_ASSERT" = "NOT_SHAKEN" ] && [ "$WEBPACK_ASSERT" = "SHAKEN" ]; then
  echo "🐛 BUG CONFIRMED: Webpack tree-shakes assertPrune, Turbopack doesn't"
  exit 0
elif [ "$TURBO_ASSERT" = "$WEBPACK_ASSERT" ]; then
  echo "ℹ️  Both bundlers have the same behavior"
  exit 0
else
  echo "⚠️  Unexpected results"
  exit 1
fi
