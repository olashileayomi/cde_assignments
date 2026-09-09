# Linux and Git Project

## CoreDataEngineers Bootcamp Assignment

This project demonstrates the use of **Linux, Bash scripting, file-system management, ETL concepts, cron job scheduling, environment variables, and Git version control** to build and automate a simple data engineering workflow.

The project consists of two main Bash scripts:

1. `etl.sh` — performs an Extract, Transform, Load (ETL) process.
2. `move_files.sh` — organizes CSV and JSON files between directories.

The ETL process is scheduled to run automatically every day at **12:00 AM using cron**.

---

# 1. Project Objectives

The objectives of this project are to demonstrate the ability to:

- Work with the Linux command line.
- Navigate and manage directories and files.
- Write Bash scripts.
- Use environment variables in Bash.
- Download data from an external source.
- Perform basic data transformation using Bash/Linux utilities.
- Organize files programmatically.
- Schedule automated jobs with cron.
- Implement logging for automated processes.
- Use Git for version control.
- Maintain a structured data pipeline using Raw, Transformed, and Gold layers.

---

# 2. Project Structure

```text
linux-git-project/
│
├── Gold/
│   └── 2023_year_finance.csv
│
├── Transformed/
│   └── 2023_year_finance.csv
│
├── cron/
│   └── etl_env.sh
│
├── files_to_move/
│   └── note.txt
│
├── json_and_CSV/
│   ├── customers.csv
│   ├── products.json
│   └── sales.csv
│
├── logs/
|   ├── cron.log
│   └── etl_YYYY-MM-DD.log
│
├── raw/
│   └── annual-enterprise-survey-2023-financial-year-provisional.csv
│   
├── scripts/
│   ├── etl.sh
│   └── move_files.sh
│
├── .env
├── .gitignore
└── README.md
```

> **Note:** `.env` and runtime log files are intentionally excluded from Git using `.gitignore`.

---

# 3. ETL Pipeline

The primary component of this project is the Bash-based ETL pipeline.

The pipeline follows the standard three-stage architecture:

```text
                EXTRACT
                   │
                   ▼
              External CSV
                   │
                   ▼
                raw/
                   │
                   │
              TRANSFORM
                   │
                   ▼
             Transformed/
                   │
                   │
                 LOAD
                   │
                   ▼
                Gold/
```

The three stages are:

### Extract

Download the Annual Enterprise Survey CSV file from Statistics New Zealand and save it into the `raw` directory.

### Transform

Modify the source data by:

- Renaming `Variable_code` to `variable_code`.
- Selecting only:
  - `year`
  - `Value`
  - `Units`
  - `variable_code`

The transformed dataset is saved as:

```text
Transformed/2023_year_finance.csv
```

### Load

Copy the transformed dataset into the Gold layer:

```text
Gold/2023_year_finance.csv
```

The Gold layer represents the final dataset available for downstream consumption.

---

# 4. Environment Variable
we created an env file and supplied the `CSV_URL` into the env. Then call it in the `etl.sh` script as

```bash
ENV_FILE="${BASE_DIR}/.env" 
if [[ -f "$ENV_FILE" ]]; then 
    source "$ENV_FILE" 
    echo "Loaded environment variables from '$ENV_FILE'."
else 
    echo "ERROR: Environment file '$ENV_FILE' not found." 
    exit 1 
fi
```

The ETL script checks whether the variable exists before continuing:

```bash
if [[ -z "${CSV_URL:-}" ]]; then
    echo "ERROR: CSV_URL environment variable is not set."
    exit 1
fi
```
We also set default CSV_URL if not provided in .env 
```bash
export CSV_URL="${CSV_URL:-https://www.stats.govt.nz/assets/Uploads/Annual-enterprise-survey/Annual-enterprise-survey-2023-financial-year-provisional/Download-data/annual-enterprise-survey-2023-financial-year-provisional.csv}"
```

This provides an important separation between:

- **Configuration** — where the source URL is defined.
- **Application logic** — what the ETL script does with that URL.

This also means that the URL can be changed without modifying the ETL logic itself.

---

# 5. `etl.sh`

The ETL script is located at:

```text
scripts/etl.sh
```

It performs the complete Extract → Transform → Load workflow.

## 5.1 Bash Interpreter

The script begins with:

```bash
#!/bin/bash
```

This tells Linux to execute the script using Bash.

---

## 5.2 Strict Bash Mode

The script uses:

```bash
set -euo pipefail
```

This enables safer Bash scripting.

### `-e`

Stops the script when a command fails.

### `-u`

Treats the use of an undefined variable as an error.

### `pipefail`

Causes a pipeline to fail if any command within the pipeline fails.

Together, these options make the script more reliable and prevent silent failures.

---

# 6. Determining the Project Directory

The script dynamically determines where it is located:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

Since `etl.sh` lives inside:

```text
scripts/
```

the project root can then be determined using:

```bash
BASE_DIR="$(dirname "$SCRIPT_DIR")"
```

This makes the script portable within the project.

Instead of depending on the directory from which the user happens to execute the script, it calculates the project location from the script itself.

---

# 7. Directory Configuration

The script defines the different pipeline layers:

```bash
RAW_DIR="${BASE_DIR}/raw"
TRANSFORM_DIR="${BASE_DIR}/Transformed"
GOLD_DIR="${BASE_DIR}/Gold"
LOG_DIR="${BASE_DIR}/logs"
```

This gives the project a simple data-layer architecture:

```text
raw/          → source data
Transformed/  → cleaned/transformed data
Gold/         → final consumption layer
logs/         → pipeline execution logs
```

---

# 8. Creating Required Directories

The script uses:

```bash
mkdir -p "$RAW_DIR" "$TRANSFORM_DIR" "$GOLD_DIR" "$LOG_DIR"
```

The `-p` option ensures that the directories are created if they don't already exist.

It also prevents an error when the directories already exist.

This makes the script **idempotent at the directory-creation level**.

---

# 9. Logging

The project implements a logging function:

```bash
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "${LOG_DIR}/etl_$(date '+%Y-%m-%d').log"
}
```

The function performs two actions:

1. Prints the message to the terminal.
2. Writes the message to a dated log file.

For example:

```text
logs/etl_2026-09-08.log
```

A log entry looks like:

```text
[2026-09-08 18:33:32] STEP 1/3 - EXTRACT: Downloading source CSV...
```

This provides an execution history that can be used for troubleshooting and monitoring.

---

# 10. Extract Stage

The extraction stage downloads the source dataset using `curl`.

Conceptually:

```bash
curl -fLsS -o "$RAW_FILE" "$CSV_URL"
```

The important options are:

- `-f` — fail when the HTTP request returns an error.
- `-L` — follow redirects.
- `-s` — operate quietly.
- `-S` — still display errors.
- `-o` — write the downloaded file to the specified location.

The source file is stored in:

```text
raw/annual-enterprise-survey-2023-financial-year-provisional.csv
```

---

# 11. Extract Validation

The script doesn't simply assume that the download worked.

It checks:

```bash
if [[ -f "$RAW_FILE" && -s "$RAW_FILE" ]]; then
```

Here:

- `-f` checks that the file exists.
- `-s` checks that the file is not empty.

It also records:

```bash
du -h "$RAW_FILE"
```

to determine file size and:

```bash
wc -l < "$RAW_FILE"
```

to determine the number of lines.

The successful extraction produced approximately:

```text
File size: 7.7M
Number of lines: 50986
```

---

# 12. Transform Stage

The transformation stage creates:

```text
Transformed/2023_year_finance.csv
```

The required output columns are:

```text
year,Value,Units,variable_code
```

The source column:

```text
Variable_code
```

is renamed conceptually to:

```text
variable_code
```

The transformation also removes all other columns from the source dataset.

---

# 13. CSV Parsing with AWK

The transformation uses `awk`.

A simple comma split is not always sufficient for CSV files because CSV fields can contain commas inside quotation marks.

For example:

```text
"Agriculture, Forestry and Fishing"
```

contains a comma but represents a single field.

Therefore, the script uses a quote-aware CSV parsing function to prevent commas inside quoted fields from incorrectly shifting column positions.

The script first identifies the required columns from the header and then uses those positions when processing each row.

The output header is:

```text
year,Value,Units,variable_code
```

---

# 14. Transformation Validation

After transformation, the script checks whether the output exists and is non-empty.

It also counts the resulting lines.

The resulting file contained:

```text
50986 lines
```

including the header.

The transformed dataset was approximately:

```text
1.5 MB
```

This confirms that the transformation generated an output file containing the expected number of records.

---

# 15. Load Stage

The final ETL stage copies the transformed dataset into the Gold directory:

```bash
cp "$TRANSFORMED_FILE" "$GOLD_FILE"
```

The final location is:

```text
Gold/2023_year_finance.csv
```

The Gold layer therefore contains the final four-column dataset:

```text
year
Value
Units
variable_code
```

---

# 16. Load Validation

The script verifies that the Gold file:

- Exists.
- Is not empty.
- Contains the expected number of lines.

The final file contained:

```text
50986 lines
```

This gives us a simple validation mechanism across the pipeline.

---

# 17. File Movement Script

The second script is:

```text
scripts/move_files.sh
```

Its purpose is to move all CSV and JSON files from:

```text
files_to_move/
```

into:

```text
json_and_CSV/
```

The script is designed to work with **one or many CSV/JSON files**.

It does not depend on specific filenames.

---

# 18. Finding CSV and JSON Files

The script uses:

```bash
find "$SOURCE_DIR" -maxdepth 1 -type f \
    \( -iname "*.csv" -o -iname "*.json" \) \
    -print0
```

This searches the source directory for:

```text
*.csv
```

or:

```text
*.json
```

The use of:

```bash
-iname
```

makes the extension matching case-insensitive.

The script only searches the immediate directory because of:

```bash
-maxdepth 1
```

It does not recursively search subdirectories.

---

# 19. Moving Multiple Files

Each matching file is processed by a loop:

```bash
while IFS= read -r -d '' file; do
```

and moved using:

```bash
mv "$file" "$DEST_DIR/"
```

This means the script can handle:

```text
customers.csv
sales.csv
products.json
orders.json
inventory.json
```

without needing to modify the script.

---

# 20. Testing File Movement

The test directory initially contained:

```text
files_to_move/
├── customers.csv
├── note.txt
├── products.json
└── sales.csv
```

After running:

```bash
./scripts/move_files.sh
```

the result was:

```text
files_to_move/
└── note.txt
```

and:

```text
json_and_CSV/
├── customers.csv
├── products.json
└── sales.csv
```

This confirms that:

- CSV files were moved.
- JSON files were moved.
- Multiple files were supported.
- Non-CSV/JSON files were ignored.

---

# 21. Cron Scheduling

The ETL pipeline is scheduled using Linux `cron`.

The cron entry is:

```cron
0 0 * * * /bin/bash -c 'source /home/habeeb_olashile_ajao/cde_assignments/linux-git-project/cron/etl_env.sh && /home/habeeb_olashile_ajao/cde_assignments/linux-git-project/scripts/etl.sh' >> /home/habeeb_olashile_ajao/cde_assignments/linux-git-project/logs/cron.log 2>&1
```

---

# 22. Understanding the Cron Expression

The first five fields are:

```text
0 0 * * *
```

Cron uses:

```text
minute hour day-of-month month day-of-week
```

Therefore:

```text
0     → minute 0
0     → hour 0
*     → every day of the month
*     → every month
*     → every day of the week
```

So:

```text
0 0 * * *
```

means:

> Run the job every day at 12:00 AM.

---

# 23. Why `etl_env.sh` Is Used

Cron does not necessarily inherit the environment variables from an interactive terminal session.

The project therefore uses:

```text
cron/etl_env.sh
```

to load the environment configuration before running the ETL.

The scheduled command executes:

```bash
source /home/.../cron/etl_env.sh
```

and then:

```bash
/home/.../scripts/etl.sh
```

Conceptually:

```text
Cron
  │
  ▼
etl_env.sh
  │
  │ loads CSV_URL
  ▼
etl.sh
  │
  ├── Extract
  ├── Transform
  └── Load
```

This ensures the scheduled ETL has access to the required configuration.

---

# 24. Cron Logging

The cron command redirects output using:

```bash
>> /home/.../logs/cron.log 2>&1
```

The two important components are:

### `>>`

Appends standard output to:

```text
logs/cron.log
```

instead of overwriting the existing file.

### `2>&1`

Redirects standard error to the same location as standard output.

Therefore, both successful messages and errors can be captured in:

```text
logs/cron.log
```

---

# 25. Testing Cron Before Waiting Until Midnight

Rather than waiting until 12:00 AM to discover whether the command works, the exact command intended for cron was executed manually:

```bash
/bin/bash -c 'source /home/.../cron/etl_env.sh && /home/.../scripts/etl.sh' >> logs/cron.log 2>&1
```

The successful output confirmed that:

- The environment configuration was loaded.
- The source dataset downloaded successfully.
- The transformation completed.
- The Gold dataset was created.
- The ETL process completed successfully.

The cron configuration was then verified with:

```bash
crontab -l
```

which displayed:

```cron
0 0 * * * ...
```

---

# 26. Git Version Control

All project work is versioned using Git.

The project is part of the main:

```text
cde_assignments
```

Git repository.

The assignment was developed on:

```text
linuxbranch
```

and subsequently merged into:

```text
main
```

---

# 27. Git Workflow Used

The basic workflow was:

```text
Working directory
       │
       ▼
   git status
       │
       ▼
    git add
       │
       ▼
   Staging area
       │
       ▼
   git commit
       │
       ▼
 Local repository
       │
       ▼
    git push
       │
       ▼
 GitHub
```

---

# 28. `.gitignore`

The project uses `.gitignore` to prevent sensitive or runtime-generated files from being committed.

The configuration includes:

```gitignore
# Environment variables / local configuration
.env

# Runtime logs
logs/*.log

# Python cache
__pycache__/
*.pyc
```

The `.env` file is ignored because environment/configuration files may contain values that should remain local.

Runtime logs are also ignored because they are generated during execution and are not part of the source code.

---

# 29. Git Commit

The completed assignment was committed using:

```bash
git commit -m "Add Linux and Git ETL assignment"
```

The commit was then pushed to the remote repository.

The `linuxbranch` was subsequently merged into `main`.

The final repository state showed:

```text
main
└── linuxbranch work merged
```

and Git reported:

```text
nothing to commit, working tree clean
```

This confirms that the local repository was synchronized with the remote repository.

---

# 30. Data Flow Summary

The complete data engineering workflow can be represented as:

```text
                    SOURCE
                      │
                      │ CSV_URL
                      ▼
             Statistics New Zealand
                      │
                      │ curl
                      ▼
                   raw/
                      │
                      │ AWK transformation
                      ▼
                Transformed/
                      │
                      │ cp
                      ▼
                    Gold/
```

Separately, the file organization workflow is:

```text
             files_to_move/
                    │
                    │ find
                    ▼
          ┌─────────┴─────────┐
          │                   │
        *.csv               *.json
          │                   │
          └─────────┬─────────┘
                    │
                    ▼
              json_and_CSV/
```

And automation is provided by:

```text
                    cron
                     │
                     │ 00:00 daily
                     ▼
                etl_env.sh
                     │
                     ▼
                  etl.sh
                     │
             ┌───────┼───────┐
             ▼       ▼       ▼
          Extract Transform Load
```

---

# 31. How to Run the Project

## Run the ETL manually

Ensure the `CSV_URL` environment variable is available:

```bash
export CSV_URL="https://www.stats.govt.nz/assets/Uploads/Annual-enterprise-survey/Annual-enterprise-survey-2023-financial-year-provisional/Download-data/annual-enterprise-survey-2023-financial-year-provisional.csv"
```

Then execute:

```bash
./scripts/etl.sh
```

---

## Run the File Movement Script

Execute:

```bash
./scripts/move_files.sh
```

---

## Check ETL Output

```bash
ls -lh raw/
ls -lh Transformed/
ls -lh Gold/
```

---

## Check Logs

```bash
ls -lh logs/
```

View the current ETL log:

```bash
cat logs/etl_$(date '+%Y-%m-%d').log
```

View the cron log:

```bash
cat logs/cron.log
```

---

## Check Cron

```bash
crontab -l
```

The expected schedule is:

```cron
0 0 * * *
```

---

# 32. Key Linux Commands Used

| Command | Purpose |
|---|---|
| `mkdir` | Create directories |
| `cd` | Change directory |
| `ls` | List files |
| `ls -la` | List hidden files and detailed permissions |
| `tree` | Display directory structure |
| `head` | Display beginning of a file |
| `cat` | Display file contents |
| `wc` | Count lines/words/bytes |
| `du` | Check disk usage |
| `find` | Search for files |
| `mv` | Move files |
| `cp` | Copy files |
| `curl` | Download data |
| `awk` | Process and transform text data |
| `chmod` | Change file permissions |
| `export` | Create an environment variable |
| `source` | Load commands/configuration into the current shell |
| `crontab` | Manage scheduled cron jobs |
| `git status` | Check repository state |
| `git add` | Stage changes |
| `git commit` | Create a versioned snapshot |
| `git push` | Push changes to GitHub |

---

# 33. Engineering Concepts Demonstrated

This project demonstrates several foundational Data Engineering concepts:

### ETL

The project implements:

```text
Extract → Transform → Load
```

using Bash and standard Linux utilities.

### Data Layering

The project separates:

```text
Raw → Transformed → Gold
```

which provides a simple data pipeline architecture.

### Automation

Cron removes the need to manually execute the ETL every day.

### Configuration Management

The source URL is provided through an environment variable rather than being embedded directly into the ETL logic.

### Validation

The pipeline checks whether files exist, whether they are empty, and how many records they contain.

### Logging

Execution events are timestamped and stored in log files.

### File Management

The project demonstrates programmatic movement and organization of data files.

### Version Control

Git provides a history of changes and enables the work to be safely stored and collaborated on through GitHub.

---

# 34. Final Outcome

At the completion of the project, the following requirements were implemented:

- [x] Downloaded the Annual Enterprise Survey CSV.
- [x] Stored the raw data in `raw/`.
- [x] Used an environment variable for the source URL.
- [x] Renamed `Variable_code` to `variable_code`.
- [x] Selected `year`, `Value`, `Units`, and `variable_code`.
- [x] Stored transformed data in `Transformed/`.
- [x] Loaded the transformed dataset into `Gold/`.
- [x] Added validation and execution messages.
- [x] Implemented ETL logging.
- [x] Created a Bash script to move CSV and JSON files.
- [x] Demonstrated movement of multiple files.
- [x] Confirmed non-CSV/JSON files remain untouched.
- [x] Scheduled the ETL to run daily at 12:00 AM using cron.
- [x] Tested the scheduled command manually.
- [x] Added Git version control.
- [x] Used `.gitignore` for local configuration and runtime logs.
- [x] Pushed the completed work to GitHub.
- [x] Merged the assignment branch into `main`.

---

# 35. Conclusion

This project demonstrates how fundamental Linux capabilities can be combined to create a simple but practical Data Engineering workflow.

Although the pipeline is intentionally small, it introduces several concepts used in larger production systems:

```text
Configuration
     ↓
Extraction
     ↓
Validation
     ↓
Transformation
     ↓
Validation
     ↓
Loading
     ↓
Logging
     ↓
Automation
     ↓
Version Control
```

The project therefore provides a foundation for progressing from simple Bash-based ETL pipelines toward more sophisticated Data Engineering technologies.