#!/bin/bash
set -e

echo "================================================"
echo "Proving Turbopack Transitive Import Bug"
echo "================================================"
echo ""

# Clean and build
echo "Building without env var..."
rm -rf .next
npm run build > /dev/null 2>&1
echo "✓ Build complete"
echo ""

# Test 1: SecretComponent is tree-shaken
echo "================================================"
echo "TEST 1: Is SecretComponent tree-shaken?"
echo "================================================"
echo ""

echo "Searching for 'Secret Content' in bundle..."
if grep -r "Secret Content" .next/static/ > /dev/null 2>&1; then
  echo "❌ FAIL: Found 'Secret Content' - component NOT tree-shaken"
  exit 1
else
  echo "✅ PASS: 'Secret Content' not found - component IS tree-shaken"
fi
echo ""

echo "Searching for 'SecretComponent' in bundle..."
if grep -r "SecretComponent" .next/static/ > /dev/null 2>&1; then
  echo "❌ FAIL: Found 'SecretComponent' name in bundle"
  exit 1
else
  echo "✅ PASS: 'SecretComponent' name not found"
fi
echo ""

# Test 2: assertPrune is NOT tree-shaken (the bug)
echo "================================================"
echo "TEST 2: Is assertPrune tree-shaken?"
echo "================================================"
echo ""

echo "Searching for 'assertPrune' in bundle..."
ASSERTPRUNE_RESULTS=$(grep -r "assertPrune" .next/static/chunks/ 2>/dev/null || true)

if [ -n "$ASSERTPRUNE_RESULTS" ]; then
  echo "❌ BUG CONFIRMED: 'assertPrune' found in bundle"
  echo ""
  echo "Found in these chunks:"
  grep -l "assertPrune" .next/static/chunks/*.js 2>/dev/null || true
  echo ""

  # Show the actual function definition
  echo "Function definition in bundle:"
  echo "---"
  grep -o 'function [a-z](){throw console.assert("__ant_only__").*}' .next/static/chunks/*.js 2>/dev/null | head -1 || true
  echo "---"
  echo ""

  # Show which module imports it
  echo "Checking issue-repro page chunk..."
  ISSUE_REPRO_CHUNK=$(grep -l "Public page" .next/static/chunks/*.js | head -1)
  if [ -n "$ISSUE_REPRO_CHUNK" ]; then
    echo "Found issue-repro chunk: $ISSUE_REPRO_CHUNK"
    echo ""
    echo "Content of issue-repro page:"
    echo "---"
    # Extract the relevant module
    grep -o 'function r(){return.*"Public page".*}' "$ISSUE_REPRO_CHUNK" || true
    echo ""
    # Check for import statement
    if grep "t\.i(12704)" "$ISSUE_REPRO_CHUNK" > /dev/null 2>&1; then
      echo ""
      echo "Import statement found: t.i(12704)"
      echo "(This imports the assertPrune module even though it's not used)"
    fi
    echo "---"
  fi

else
  echo "✅ UNEXPECTED: 'assertPrune' NOT found (bug would be fixed)"
  exit 1
fi

echo ""
echo "================================================"
echo "CONCLUSION"
echo "================================================"
echo "SecretComponent:  ✅ Tree-shaken correctly"
echo "assertPrune:      ❌ NOT tree-shaken (BUG)"
echo ""
echo "This proves Turbopack does not eliminate imports"
echo "from tree-shaken components."
