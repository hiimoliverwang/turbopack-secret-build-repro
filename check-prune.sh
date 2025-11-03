#!/bin/bash

# Search in .next/static directory (like claude-ai does)
if [ ! -d ".next/static" ]; then
  echo "ERROR: .next/static directory not found"
  exit 1
fi

# Check for __ant_only__ string (exclude source maps)
ant_only_found="false"
if find .next/static -type f -not -name '*.map' -exec grep -l "__ant_only__" {} \; 2>/dev/null | grep -q .; then
  ant_only_found="true"
fi

# Output parsable result
echo "ANT_ONLY_FOUND=$ant_only_found"

exit 0
