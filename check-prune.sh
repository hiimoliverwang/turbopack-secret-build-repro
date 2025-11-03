#!/bin/bash

# Search in .next directory
if [ ! -d ".next" ]; then
  echo "ERROR: .next directory not found"
  exit 1
fi

# Check for external function string (exclude cache and source maps)
external_found="false"
if grep -r --exclude-dir=cache --exclude="*.map" "DID NOT WORK" .next >/dev/null 2>&1; then
  external_found="true"
fi

# Check for inline string (exclude cache and source maps)
inline_found="false"
if grep -r --exclude-dir=cache --exclude="*.map" "INLINE_DID_NOT_WORK" .next >/dev/null 2>&1; then
  inline_found="true"
fi

# Output parsable result
echo "EXTERNAL_FOUND=$external_found"
echo "INLINE_FOUND=$inline_found"

exit 0
