#!/bin/bash

# Search in .next directory
if [ ! -d ".next" ]; then
  echo "ERROR: .next directory not found"
  exit 1
fi

# Check for __ant_only__ string (exclude cache and source maps)
ant_only_found="false"
if grep -r --exclude-dir=cache --exclude="*.map" "__ant_only__" .next >/dev/null 2>&1; then
  ant_only_found="true"
fi

# Output parsable result
echo "ANT_ONLY_FOUND=$ant_only_found"

exit 0
