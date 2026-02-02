#!/bin/bash

# ==============================================================================
# Script: migrate_data.sh
# Description: A sample script that processes command-line arguments and options.
#              This version supports flags for checksum, source, destination,
#              and report folders, and adds a timestamp to the report filename.
# ==============================================================================

# --- Get a timestamp for the script start time ---
# This will be used to create a unique report filename.
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# --- Function to display the help message ---
usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "This script migrates data from a source folder to a destination folder."
  echo "It can optionally generate a report and perform a checksum."
  echo ""
  echo "Options:"
  echo "  -s, --source <folder>     Specify the source folder to migrate (required)."
  echo "  -d, --dest <folder>       Specify the destination folder (required)."
  echo "  -r, --report <folder>     Specify a folder to save the migration report (default: ~/Reports)."
  echo "  --dry-run                 Perform a test run of the sync without making any changes."
  echo "  --checksum                Include checksum verification during the migration process."
  echo "  --version                 Display the script version and exit."
  echo "  -h, --help                Display this help information and exit."
  echo ""
  echo "Example:"
  echo "  $0 -s /home/user/data -d /mnt/backup/data"
  echo "  $0 --dry-run -s /home/user/data -d /mnt/backup/data -r /tmp/reports"
}

# --- Initialize default values for options ---
CHECKSUM_SOURCE=false
DRY_RUN=false
CHECKSUM=false
SOURCE_FOLDER=""
DESTINATION_FOLDER=""
REPORT_FOLDER="~/Reports"

# --- Check if any arguments are provided ---
if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

# --- Parse command-line options ---
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --checksum-source)
      CHECKSUM_SOURCE=true
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --checksum)
      CHECKSUM=true
      ;;
    --version)
      echo "Version: v1.5_2025-12-05"
      echo "This script is part of the UCL Research Data under Management project."
      echo "Research Data Stewardship Group - UCL Advanced Research Computing"
      echo ""
      exit 0
      ;;
    -s|--source)
      if [[ -n "$2" && "$2" != -* ]]; then
        SOURCE_FOLDER="$2"
        shift # Move past the option value
      else
        echo "Error: Option '$1' requires an argument." >&2
        usage
        exit 1
      fi
      ;;
    -d|--dest)
      if [[ -n "$2" && "$2" != -* ]]; then
        DESTINATION_FOLDER="$2"
        shift # Move past the option value
      else
        echo "Error: Option '$1' requires an argument." >&2
        usage
        exit 1
      fi
      ;;
    -r|--report)
      if [[ -n "$2" && "$2" != -* ]]; then
        REPORT_FOLDER="$2"
        shift # Move past the option value
      else
        echo "Error: Option '$1' requires an argument." >&2
        usage
        exit 1
      fi
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: Unrecognized option '$1'." >&2
      usage
      exit 1
      ;;
    *)
      # Handle any positional arguments that are not options
      echo "Error: Unrecognized argument '$1'." >&2
      usage
      exit 1
      ;;
  esac
  shift # Move to the next argument
done

# --- Validate required arguments ---
if [ -z "$SOURCE_FOLDER" ]; then
  echo "Error: A source folder must be specified with -s or --source." >&2
  usage
  exit 1
fi

if [ -z "$DESTINATION_FOLDER" ]; then
  echo "Error: A destination folder must be specified with -d or --dest." >&2
  usage
  exit 1
fi

# --- Main script logic starts here ---
echo "--- Starting Data Migration ---"
echo "Source folder: $SOURCE_FOLDER"
echo "Destination folder: $DESTINATION_FOLDER"
echo "Report folder: $REPORT_FOLDER"

# Create the report folder if it doesn't exist
mkdir -p "$REPORT_FOLDER"

# Extract the last part of the source folder path to use in the filename.
# This uses parameter expansion to first remove any trailing slashes,
# then extract the base name, which handles paths like /a/b/cde/ correctly.
REPORT_FILENAME_BASE="${SOURCE_FOLDER%/}"
REPORT_FILENAME_BASE="${REPORT_FILENAME_BASE##*/}"

if [ "$CHECKSUM_SOURCE" = true ]; then
  echo "Checksumming source folder with SHA256..."
  REPORT_FILE_CHECKSUM="$REPORT_FOLDER/${REPORT_FILENAME_BASE}_${TIMESTAMP}_checksum.sha256"

  # Use find with xargs to safely generate SHA256 checksums for all files
  find "$SOURCE_FOLDER" -type f -print0 | xargs -0 sha256sum > "$REPORT_FILE_CHECKSUM"
  echo "SHA256 checksum report saved to $REPORT_FILE_CHECKSUM"
  exit 1
fi

# Rclone migration logic
echo "Starting data sync from source to destination using rclone..."
REPORT_FILE_SYNC="$REPORT_FOLDER${REPORT_FILENAME_BASE}_${TIMESTAMP}_sync_report.md"
REPORT_LOG_SYNC="$REPORT_FOLDER${REPORT_FILENAME_BASE}_${TIMESTAMP}_sync.log"

# Build the rclone command
RCLONE_CMD="rclone copy --transfers 8  --stats 5m --inplace --update "
RCLONE_CMD+=" --log-level DEBUG --log-file $REPORT_LOG_SYNC"

# Add --dry-run if the flag is set
if [ "$DRY_RUN" = true ]; then
    echo "Performing a dry run (no files will be changed)..."
    RCLONE_CMD+=" --dry-run"
fi

# Add --checksum if the flag is set
if [ "$CHECKSUM" = true ]; then
    echo "Including checksum verification..."
    RCLONE_CMD+=" --checksum"
fi


# Execute the command and redirect output
echo "Executing command: $RCLONE_CMD $SOURCE_FOLDER $DESTINATION_FOLDER "
$RCLONE_CMD "$SOURCE_FOLDER" "$DESTINATION_FOLDER"  2> "$REPORT_FILE_SYNC"

echo "Data sync report saved to $REPORT_LOG_SYNC"
echo "--- Data migration complete. ---"
