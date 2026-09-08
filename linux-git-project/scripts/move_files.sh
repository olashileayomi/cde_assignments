#!/bin/bash

# -----------------------------------------------------------------------------
# move_files.sh
# -----------------------------------------------------------------------------
# CoreDataEngineers|Linux-git-Assignment - File Organization Script
#
# Purpose:
#   Move all CSV and JSON files from files_to_move/ into json_and_CSV/.
#
# The script:
#   1. Determines the project directory.
#   2. Defines the source and destination directories.
#   3. Creates the destination directory if necessary.
#   4. Finds CSV and JSON files.
#   5. Moves each matching file.
#   6. Reports what was moved.
# -----------------------------------------------------------------------------

set -euo pipefail # exit on error, undefined var use, and failed pipes

# -----------------------------------------------------------------------------
# 1. CONFIGURATION
# -----------------------------------------------------------------------------

# Directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Project root = parent directory of scripts/
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Source and destination directories
SOURCE_DIR="${BASE_DIR}/files_to_move"
DEST_DIR="${BASE_DIR}/json_and_CSV"


# -----------------------------------------------------------------------------
# 2. DISPLAY CONFIGURATION
# -----------------------------------------------------------------------------

echo "=============================================="
echo "Starting file organization"
echo "=============================================="

echo "Source directory      : $SOURCE_DIR"
echo "Destination directory : $DEST_DIR"


# -----------------------------------------------------------------------------
# 3. VALIDATE SOURCE DIRECTORY
# -----------------------------------------------------------------------------

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "ERROR: Source directory does not exist: $SOURCE_DIR"
    exit 1
fi


# -----------------------------------------------------------------------------
# 4. CREATE DESTINATION DIRECTORY
# -----------------------------------------------------------------------------

mkdir -p "$DEST_DIR"  # if exists do nothing, if not create it

echo "Destination directory is ready."


# -----------------------------------------------------------------------------
# 5. FIND AND MOVE CSV/JSON FILES
# -----------------------------------------------------------------------------

file_count=0

while IFS= read -r -d '' file; do

    filename="$(basename "$file")"

    echo "Moving: $filename"

    mv "$file" "$DEST_DIR/"

    ((file_count+=1))

done < <(
    find "$SOURCE_DIR" -maxdepth 1 -type f \
        \( -iname "*.csv" -o -iname "*.json" \) \
        -print0
)


# -----------------------------------------------------------------------------
# 6. REPORT RESULT
# -----------------------------------------------------------------------------

if [[ "$file_count" -eq 0 ]]; then
    echo "No CSV or JSON files were found."
else
    echo "Successfully moved $file_count CSV/JSON file(s)."
fi

echo "=============================================="
echo "File organization completed."
echo "=============================================="