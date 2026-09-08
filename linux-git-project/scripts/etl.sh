#!/bin/bash

set -euo pipefail # exit on error, undefined var use, and failed pipes

# Determine the location of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine the project root
BASE_DIR="${BASE_DIR:-$(dirname "$SCRIPT_DIR")}"

# ------------------------------------------------------------------------------
# Load environment variables from .env file if it exists
ENV_FILE="${BASE_DIR}/.env" 
if [[ -f "$ENV_FILE" ]]; then 
    source "$ENV_FILE" 
    echo "Loaded environment variables from '$ENV_FILE'."
else 
    echo "ERROR: Environment file '$ENV_FILE' not found." 
    exit 1 
fi

# check if CSV_URL is set, if not exit with error
if [[ -z "${CSV_URL:-}" ]]; then
    echo "ERROR: CSV_URL environment variable is not set."
    exit 1
fi
# -----------------------------------------------------------------------------

# Set default CSV_URL if not provided in .env
export CSV_URL="${CSV_URL:-https://www.stats.govt.nz/assets/Uploads/Annual-enterprise-survey/Annual-enterprise-survey-2023-financial-year-provisional/Download-data/annual-enterprise-survey-2023-financial-year-provisional.csv}"

# Project directories
RAW_DIR="${BASE_DIR}/raw"
TRANSFORM_DIR="${BASE_DIR}/Transformed"
GOLD_DIR="${BASE_DIR}/Gold"
LOG_DIR="${BASE_DIR}/logs"

# Project files
RAW_FILE="${RAW_DIR}/annual-enterprise-survey-2023-financial-year-provisional.csv"
TRANSFORMED_FILE="${TRANSFORM_DIR}/2023_year_finance.csv"
GOLD_FILE="${GOLD_DIR}/2023_year_finance.csv"

# Create required directories
# if they exist do nothing if they do not exist create them

mkdir -p "$RAW_DIR" "$TRANSFORM_DIR" "$GOLD_DIR" "$LOG_DIR"

# -----------------------------------------------------------------------------
# Helper: timestamped logging function, printed to console AND appended
# to a daily log file so cron runs leave an audit trail.
# -----------------------------------------------------------------------------

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "${LOG_DIR}/etl_$(date '+%Y-%m-%d').log"
}

# -----------------------------------------------------------------------------
# 1. EXTRACT
# -----------------------------------------------------------------------------

log "STEP 1/3 - EXTRACT: Downloading source CSV..."

# -f  : fail silently on server errors (so curl's exit code reflects failure)
# -L  : follow redirects (Stats NZ URLs can redirect)
# -sS : silent, but still show errors
# -o  : output file

if curl -fLsS -o "$RAW_FILE" "$CSV_URL"; then
    log "Download completed successfully."
else
    log "ERROR: Failed to download the CSV file."
    exit 1
fi

# Confirm the file actually landed in raw/ and is non-empty.
if [[ -f "$RAW_FILE" && -s "$RAW_FILE" ]]; then
    RAW_SIZE=$(du -h "$RAW_FILE" | cut -f1)
    RAW_LINES=$(wc -l < "$RAW_FILE")

    log "CONFIRMED: File saved to '$RAW_FILE'"
    log "File size: $RAW_SIZE"
    log "Number of lines: $RAW_LINES"
else
    log "ERROR: Raw file was not created or is empty."
    exit 1
fi

# -----------------------------------------------------------------------------
# 2. TRANSFORM
# -----------------------------------------------------------------------------

log "STEP 2/3 - TRANSFORM: renaming Variable_code -> variable_code and"
log "           selecting columns [year, Value, Units, variable_code]..."

awk '
    function csv_split(line, arr,    n, i, c, field, inquotes, len) {
        n = 0
        field = ""
        inquotes = 0
        len = length(line)

        for (i = 1; i <= len; i++) {
            c = substr(line, i, 1)

            if (inquotes) {
                if (c == "\"") {
                    if (substr(line, i + 1, 1) == "\"") {
                        field = field "\""
                        i++
                    } else {
                        inquotes = 0
                    }
                } else {
                    field = field c
                }
            } else {
                if (c == "\"") {
                    inquotes = 1
                } else if (c == ",") {
                    n++
                    arr[n] = field
                    field = ""
                } else {
                    field = field c
                }
            }
        }

        n++
        arr[n] = field
        return n
    }

    NR == 1 {
        n = csv_split($0, header)

        for (i = 1; i <= n; i++) {
            if (tolower(header[i]) == "year") year_idx = i
            if (tolower(header[i]) == "value") value_idx = i
            if (tolower(header[i]) == "units") units_idx = i
            if (tolower(header[i]) == "variable_code") varcode_idx = i
        }

        if (!year_idx || !value_idx || !units_idx || !varcode_idx) {
            print "ERROR: Required column is missing." > "/dev/stderr"
            exit 1
        }

        print "year,Value,Units,variable_code"
        next
    }

    {
        m = csv_split($0, row)
        print row[year_idx] "," row[value_idx] "," row[units_idx] "," row[varcode_idx]
    }

' "$RAW_FILE" > "$TRANSFORMED_FILE"

# Confirm the file actually landed in Transformed/ and is non-empty.
if [[ -f "$TRANSFORMED_FILE" && -s "$TRANSFORMED_FILE" ]]; then
    TRANSFORMED_SIZE=$(du -h "$TRANSFORMED_FILE" | cut -f1)
    TRANSFORMED_LINES=$(wc -l < "$TRANSFORMED_FILE")

    log "CONFIRMED: File saved to '$TRANSFORMED_FILE'"
    log "File size: $TRANSFORMED_SIZE"
    log "Number of lines: $TRANSFORMED_LINES"
else
    log "ERROR: Transformed file was not created or is empty."
    exit 1
fi

# -----------------------------------------------------------------------------
# 3. LOAD
# -----------------------------------------------------------------------------

log "STEP 3/3 - LOAD: Copying transformed data into Gold..."

cp "$TRANSFORMED_FILE" "$GOLD_FILE"

if [[ -f "$GOLD_FILE" && -s "$GOLD_FILE" ]]; then
    GOLD_LINES=$(wc -l < "$GOLD_FILE")

    log "CONFIRMED: File loaded into Gold."
    log "Gold file: $GOLD_FILE"
    log "Number of lines: $GOLD_LINES"
else
    log "ERROR: Gold file was not created or is empty."
    exit 1
fi

log "===================================================================="
log "ETL run completed successfully."
log "===================================================================="
