#!/bin/bash

# Usage: ./source_precheck.sh -s /path/to/source_directory [-r /path/to/report_folder]
# This script performs a pre-check on a source directory:
# - Counts total files
# - Calculates total size
# - Works out the file density (files per TB)
# - Warns if density is too high
# - Outputs a Markdown report

# exit on error, unset variables, or pipeline failure
set -euo pipefail

# --- Function to display the help message ---
usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "This script performs a pre-check on a source directory."
  echo "It counts files, calculates total size, determines file density,"
  echo "and outputs a Markdown report."
  echo ""
  echo "Options:"
  echo "  -s, --source <folder>    Specify the source folder to pre-check (required)."
  echo "  -r, --report <folder>    Specify a folder to save the pre-check report (default: ~/Reports)."
  echo "  -h, --help               Display this help information and exit."
  echo "  -v, --version            Display the script version and exit."
  echo ""
  echo "Example:"
  echo "  $0 -s /mnt/DBIO_Evans_data1 -r /home/almalinux/Reports"
  echo "  $0 --source /mnt/DBIO_Evans_data1 --report /home/almalinux/Reports"
}

# --- Initialize default values for options ---
SOURCE_DIR=""
REPORT_FOLDER="/home/almalinux/Reports"

# --- Check if any arguments are provided ---
if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

# --- Parse command-line options ---
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -s|--source)
      if [[ -n "$2" && "$2" != -* ]]; then
        SOURCE_DIR="$2"
        shift # Move past the option value
      else
        echo "❌ Error: Option '$1' requires an argument." >&2
        usage
        exit 1
      fi
      ;;
    -r|--report)
      if [[ -n "$2" && "$2" != -* ]]; then
        REPORT_FOLDER="$2"
        shift # Move past the option value
      else
        echo "❌ Error: Option '$1' requires an argument." >&2
        usage
        exit 1
      fi
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -v|--version)
      echo "Version: v1.1_2026-01-21"
      echo "This script is part of the UCL Research Data under Management project."
      echo "Research Data Stewardship Group - UCL Advanced Research Computing"
      echo ""
      exit 0
      ;;
    -*)
      echo "❌ Error: Unrecognized option '$1'." >&2
      usage
      exit 1
      ;;
    *)
      # Handle any positional arguments that are not options
      echo "❌ Error: Unrecognized argument '$1'." >&2
      usage
      exit 1
      ;;
  esac
  shift # Move to the next argument
done

# Check if SOURCE_DIR is missing after parsing
if [[ -z "$SOURCE_DIR" ]]; then
  echo "❌ Error: No source directory provided. Use -s or --source."
  usage
  exit 1
fi

# Check if the source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "❌ Error: Source directory '$SOURCE_DIR' does not exist."
  exit 1
fi

# Ensure the report directory exists
mkdir -p "$REPORT_FOLDER" || { echo "❌ Error: Could not create report directory '$REPORT_FOLDER'."; exit 1; }

# Create a timestamped report that also contains name of source directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SOURCE_NAME=$(basename "$SOURCE_DIR")
REPORT="/home/almalinux/Reports/precheck_${SOURCE_NAME}_${TIMESTAMP}.md"

# Display header and output where report will be saved
echo " Running pre-check for: $SOURCE_DIR"
echo "Generating report: $REPORT"
echo ""

# Step 1: Count total number of files
echo "Counting files in $SOURCE_DIR..."
FILE_COUNT=$(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -n 1 -P 8 sh -c 'find "$0" -type f | wc -l' | awk '{s+=$1} END {print s}')

# Step 2: Get total size in bytes and convert to a readable format
echo "Calculating total size of files in $SOURCE_DIR..."
#TOTAL_SIZE_BYTES=$(du -sb "$SOURCE_DIR" | cut -f1)
TOTAL_SIZE_READABLE=$(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -n 1 -P 8 du -s | awk '{sum+=$1} END {print sum/1024/1024 "G"}')

# Step 3: Estimate the total size in TB for file density calculation
echo "Estimating total size in TB"
SIZE_TB=$(awk -v GB="$TOTAL_SIZE_READABLE" 'BEGIN { print GB / (1024) }')

# Step 4: Calculate files per TB (avoid divide-by-zero)
echo "Calculating files per TB..."
FILES_PER_TB=$(awk -v files="$FILE_COUNT" -v tb="$SIZE_TB" 'BEGIN { if (tb > 0) print files / tb; else print 0 }')

# # Step 5: Write output to a Markdown report
{
  echo "#Source Directory Pre-Check before migration"
  echo ""
  echo "**Location:** \`$SOURCE_DIR\`"
  echo ""
  echo "- File count: **$FILE_COUNT**"
  echo "- Total size: **$TOTAL_SIZE_READABLE**"
  echo "- Estimated size (TB): **$(printf "%.3f" "$SIZE_TB")**"
  echo "- Files per TB: **$(printf "%.0f" "$FILES_PER_TB")**"
  echo ""


  if (( $(echo "$FILES_PER_TB > 200000" | bc -l) )); then
    echo "⚠️ **Warning:** High file density detected — more than 200,000 files per TB."
    echo ""
    echo "Theres a limit of 200,000 files per TB when projects are created on the RDSS."
  else
    echo "✅ File density is below 200,000 files per TB."
  fi
 } > "$REPORT"

echo "✅ Pre-check complete. Summary saved to: $REPORT"
