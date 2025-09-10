#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Check if the script is run as root or with appropriate permissions
if [[ $EUID -ne 0 ]]; then
    echo "This script should be run with elevated privileges (e.g., using sudo)." >&2
    exit 1
fi

# Default values
LOGFILE="${LOGFILE:-binary_verification.log}"
OUTPUT_FORMAT="text"
QUIET=false
DIRECTORIES=()

# Function: Print usage info
usage() {
    cat <<EOF
Usage: $0 [options] [directories...]

Options:
  -l, --log <file>       Set log file (default: binary_verification.log)
  -j, --json             Output in JSON format
  -q, --quiet            Suppress terminal output (log only)
  -h, --help             Show this help message

Arguments:
  directories            One or more directories to scan (default: /usr/local/bin)

Environment Variables:
  LOGFILE                Alternative way to set the log file

Examples:
  $0                     # Scan /usr/local/bin with default settings
  $0 -l scan.log /opt/bin /usr/bin
  $0 --json --quiet /usr/local/bin
EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--log)
            LOGFILE="$2"
            shift 2
            ;;
        -j|--json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage
            ;;
        *)
            DIRECTORIES+=("$1")
            shift
            ;;
    esac
done

# Default to /usr/local/bin if no directories provided
[[ ${#DIRECTORIES[@]} -eq 0 ]] && DIRECTORIES=(/usr/local/bin)

# Prepare log file
: > "$LOGFILE"
chmod 600 "$LOGFILE"

# Output function (respects --quiet)
log() {
    $QUIET || echo "$1"
    echo "$1" >> "$LOGFILE"
}

# Function: escape JSON strings
json_escape() {
    echo "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Function: verify binaries
verify_binaries() {
    local dir="$1"

    log "Scanning directory: $dir"
    log "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    log "----------------------------------------"

    local json_entries=()

    while IFS= read -r -d '' file; do
        local status checksum
        if codesign -vvv --deep --strict "$file" 2>&1 | grep -q "valid on disk"; then
            status="Signed"
        else
            status="Not signed or invalid"
        fi

        if checksum=$(shasum -a 256 "$file" 2>/dev/null | awk '{print $1}'); then
            :
        else
            checksum="Error calculating checksum"
        fi

        if [[ "$OUTPUT_FORMAT" == "json" ]]; then
            local json_entry
            json_entry=$(cat <<EOF
{
  "file": "$(json_escape "$file")",
  "status": "$status",
  "sha256": "$checksum"
}
EOF
)
            json_entries+=("$json_entry")
        else
            log "File: $file"
            log "Status: $status"
            log "SHA-256: $checksum"
            log "----------------------------------------"
        fi
    done < <(find "$dir" -type f -perm -111 -print0)

    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        log "["
        local count=${#json_entries[@]}
        for ((i=0; i<count; i++)); do
            [[ $i -gt 0 ]] && log ","
            log "${json_entries[$i]}"
        done
        log "]"
    fi
}

# Main execution
main() {
    log "Binary Verification Tool"
    log "Started at: $(date)"
    log ""

    for dir in "${DIRECTORIES[@]}"; do
        if [[ -d "$dir" ]]; then
            verify_binaries "$dir"
        else
            log "Warning: Directory '$dir' does not exist or is not accessible"
        fi
    done

    log ""
    log "Scan completed at: $(date)"
    log "Log file: $LOGFILE"
}

# Run main function
main "$@"