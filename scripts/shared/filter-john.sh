#!/bin/bash
# filter-john.sh
# Usage: filter-john.sh <run_dir>

set -euo pipefail

JOHN_RUN_DIR="$1"
if [ -z "$JOHN_RUN_DIR" ]; then
    echo "Usage: $0 <run_dir>"
    exit 1
fi

cd "$JOHN_RUN_DIR"

# Count before
BEFORE_COUNT=$(find . -type f | wc -l | tr -d ' ')
if [ "$BEFORE_COUNT" -eq 0 ]; then
    echo "Error: No files found in $JOHN_RUN_DIR - build may have failed"
    exit 1
fi
BEFORE_SIZE=$(du -sm . | cut -f1)

# Define what to keep
KEEP_FILES=("john" "zip2john" "pdf2john.py")
KEEP_PATTERNS=("*.conf" "*.chr")
KEEP_DIRS=("lib" "rules")

# Remove root directory files except essential ones
find . -maxdepth 1 -type f | while read -r file; do
    basename="$(basename "$file")"
    keep=false

    # Check exact matches
    for name in "${KEEP_FILES[@]}"; do
        if [[ "$basename" == "$name" ]]; then
            keep=true
            break
        fi
    done

    # Check patterns
    if [ "$keep" = false ]; then
        for pattern in "${KEEP_PATTERNS[@]}"; do
            if [[ "$basename" == $pattern ]]; then
                keep=true
                break
            fi
        done
    fi

    if [ "$keep" = false ]; then
        rm -f "$file"
    fi
done

# Remove directories not in keep list
find . -maxdepth 1 -type d ! -name '.' | while read -r dir; do
    dirname="$(basename "$dir")"
    keep=false

    for keepdir in "${KEEP_DIRS[@]}"; do
        if [[ "$dirname" == "$keepdir" ]]; then
            keep=true
            break
        fi
    done

    if [ "$keep" = false ]; then
        rm -rf "$dir"
    fi
done

# Count after
AFTER_COUNT=$(find . -type f | wc -l | tr -d ' ')
if [ "$AFTER_COUNT" -eq 0 ]; then
    echo "Error: All files were removed from $JOHN_RUN_DIR - file removal logic may be incorrect"
    exit 1
fi
AFTER_SIZE=$(du -sm . | cut -f1)
SAVED=$((BEFORE_COUNT - AFTER_COUNT))
SIZE_SAVED=$((BEFORE_SIZE - AFTER_SIZE))

echo "Removed $SAVED files (saved ${SIZE_SAVED}MB)"
echo "Kept $AFTER_COUNT essential files (${AFTER_SIZE}MB) in $JOHN_RUN_DIR"
