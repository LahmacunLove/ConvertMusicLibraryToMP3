#!/bin/bash

# Exit on any error, undefined variables, or pipe failures
set -euo pipefail

# Default configuration
DEFAULT_BITRATE="320k"
DEFAULT_JOBS="$(nproc)"
LOG_FILE=""
DRY_RUN=false
RESUME=false
VERBOSE=false
QUALITY_CHECK=false

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cleanup function for signal handling
cleanup() {
    echo -e "\n${YELLOW}Received interrupt signal. Cleaning up...${NC}" >&2
    # Kill any running background processes
    jobs -p | xargs -r kill 2>/dev/null || true
    exit 130
}

# Set up signal traps
trap cleanup SIGINT SIGTERM

# Usage function
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] <source_directory> <target_directory>

OPTIONS:
    -b, --bitrate RATE      Output bitrate (default: $DEFAULT_BITRATE)
    -j, --jobs NUM          Number of parallel jobs (default: $DEFAULT_JOBS)
    -l, --log FILE          Log file path
    -d, --dry-run          Show what would be converted without doing it
    -r, --resume           Resume interrupted conversion
    -v, --verbose          Verbose output
    -q, --quality-check    Validate output file quality
    -h, --help             Show this help message

EXAMPLE:
    $0 -b 256k -j 4 -l convert.log /path/to/flac /path/to/mp3

SUPPORTED FORMATS:
    Input: FLAC, WAV, APE, ALAC (m4a), OGG, WMA
    Output: MP3
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--bitrate)
            DEFAULT_BITRATE="$2"
            shift 2
            ;;
        -j|--jobs)
            DEFAULT_JOBS="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -r|--resume)
            RESUME=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quality-check)
            QUALITY_CHECK=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            show_usage >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Check remaining arguments
if [ "$#" -ne 2 ]; then
    echo "Error: Source and target directories are required" >&2
    show_usage >&2
    exit 1
fi

SOURCE_DIR="$1"
TARGET_DIR="$2"

# Logging function
log_message() {
    local message="$1"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] $message" >> "$LOG_FILE"
    fi
    
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[$timestamp]${NC} $message"
    fi
}

# Check available disk space
check_disk_space() {
    local target_dir="$1"
    local source_size
    local available_space
    
    source_size=$(du -sb "$SOURCE_DIR" 2>/dev/null | cut -f1 || echo "0")
    available_space=$(df -B1 "$target_dir" | awk 'NR==2 {print $4}')
    
    # Estimate MP3 size as ~10% of lossless (conservative estimate)
    local estimated_size=$((source_size / 10))
    
    if [ "$estimated_size" -gt "$available_space" ]; then
        echo -e "${RED}Warning: Estimated output size ($((estimated_size / 1024 / 1024))MB) may exceed available space ($((available_space / 1024 / 1024))MB)${NC}" >&2
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Validate directories
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist" >&2
    exit 1
fi

if [ ! -r "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' is not readable" >&2
    exit 1
fi

# Create target directory if it doesn't exist
if ! mkdir -p "$TARGET_DIR"; then
    echo "Error: Cannot create target directory '$TARGET_DIR'" >&2
    exit 1
fi

# Check for required dependencies
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}Error: ffmpeg is required but not installed${NC}" >&2
    exit 1
fi

if ! command -v parallel &> /dev/null; then
    echo -e "${RED}Error: GNU parallel is required but not installed${NC}" >&2
    exit 1
fi

# Optional dependencies
HAS_MEDIAINFO=false
if command -v mediainfo &> /dev/null; then
    HAS_MEDIAINFO=true
fi

# Check disk space
check_disk_space "$TARGET_DIR"

# Initialize log file
if [ -n "$LOG_FILE" ]; then
    echo "Conversion started at $(date)" > "$LOG_FILE"
    echo "Source: $SOURCE_DIR" >> "$LOG_FILE"
    echo "Target: $TARGET_DIR" >> "$LOG_FILE"
    echo "Bitrate: $DEFAULT_BITRATE" >> "$LOG_FILE"
    echo "Jobs: $DEFAULT_JOBS" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
fi

# Export variables for parallel
export SOURCE_DIR
export TARGET_DIR
export DEFAULT_BITRATE
export RESUME
export VERBOSE
export QUALITY_CHECK
export HAS_MEDIAINFO
export LOG_FILE
export RED GREEN YELLOW BLUE NC

# Quality validation function
validate_output() {
    local input_file="$1"
    local output_file="$2"
    
    if [ "$QUALITY_CHECK" != true ]; then
        return 0
    fi
    
    # Basic file size check (MP3 should be smaller but not too small)
    local input_size output_size
    input_size=$(stat -f%z "$input_file" 2>/dev/null || stat -c%s "$input_file" 2>/dev/null || echo "0")
    output_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")
    
    # MP3 should be 5-50% of original size (rough estimate)
    local min_size=$((input_size / 20))
    local max_size=$((input_size / 2))
    
    if [ "$output_size" -lt "$min_size" ] || [ "$output_size" -gt "$max_size" ]; then
        echo -e "${YELLOW}Warning: Output file size seems unusual for '$output_file'${NC}" >&2
        if [ -n "$LOG_FILE" ]; then
            echo "Quality warning: Unusual file size for $output_file (input: ${input_size}B, output: ${output_size}B)" >> "$LOG_FILE"
        fi
    fi
    
    # Duration check with mediainfo if available
    if [ "$HAS_MEDIAINFO" = true ]; then
        local input_duration output_duration
        input_duration=$(mediainfo --Inform="General;%Duration%" "$input_file" 2>/dev/null || echo "")
        output_duration=$(mediainfo --Inform="General;%Duration%" "$output_file" 2>/dev/null || echo "")
        
        if [ -n "$input_duration" ] && [ -n "$output_duration" ]; then
            local duration_diff=$((input_duration - output_duration))
            duration_diff=${duration_diff#-} # absolute value
            
            # Allow 1 second difference
            if [ "$duration_diff" -gt 1000 ]; then
                echo -e "${YELLOW}Warning: Duration mismatch for '$output_file'${NC}" >&2
                if [ -n "$LOG_FILE" ]; then
                    echo "Quality warning: Duration mismatch for $output_file" >> "$LOG_FILE"
                fi
            fi
        fi
    fi
    
    return 0
}

# Progress tracking variables
PROGRESS_FILE="/tmp/convert_progress_$$"
START_TIME=$(date +%s)

# Function to update progress
update_progress() {
    local current_count="$1"
    local total_count="$2"
    local current_time elapsed_time eta rate
    
    current_time=$(date +%s)
    elapsed_time=$((current_time - START_TIME))
    
    if [ "$current_count" -gt 0 ] && [ "$elapsed_time" -gt 0 ]; then
        # Use awk instead of bc for better compatibility
        rate=$(awk "BEGIN {printf \"%.2f\", $current_count / $elapsed_time}")
        remaining=$((total_count - current_count))
        
        if [ "$remaining" -gt 0 ] && [ "$(awk "BEGIN {print ($rate > 0)}")" = "1" ]; then
            eta_seconds=$(awk "BEGIN {printf \"%.0f\", $remaining / $rate}")
            eta=$(date -u -d @"$eta_seconds" +%H:%M:%S 2>/dev/null || echo "--:--:--")
        else
            eta="--:--:--"
        fi
        
        local percent=$((current_count * 100 / total_count))
        echo -e "${GREEN}Progress: $current_count/$total_count ($percent%) | Rate: ${rate}/s | ETA: $eta${NC}"
    fi
}

# Function to convert a single audio file to MP3
convert_audio_file() {
    local input_file="$1"
    local filename
    filename="$(basename "$input_file")"
    
    # Skip hidden files starting with "._"
    if [[ "$filename" == ._* ]]; then
        return 0
    fi
    
    # Generate output path
    local mp3_file="${input_file%.*}.mp3"
    mp3_file="${mp3_file/$SOURCE_DIR/$TARGET_DIR}"
    local mp3_dir
    mp3_dir="$(dirname "$mp3_file")"
    
    # Create output directory
    if ! mkdir -p "$mp3_dir"; then
        echo -e "${RED}Error: Cannot create directory '$mp3_dir'${NC}" >&2
        if [ -n "$LOG_FILE" ]; then
            echo "Error: Cannot create directory '$mp3_dir'" >> "$LOG_FILE"
        fi
        return 1
    fi
    
    # Check for resume functionality
    if [ "$RESUME" = true ] && [ -f "$mp3_file" ]; then
        # Check if file was completely converted (not corrupted)
        if ffmpeg -v error -i "$mp3_file" -f null - 2>/dev/null; then
            echo -e "${BLUE}Resuming: Skipping completed file $mp3_file${NC}"
            echo "1" >> "$PROGRESS_FILE"
            return 0
        else
            echo -e "${YELLOW}Resuming: Re-converting corrupted file $mp3_file${NC}"
            rm -f "$mp3_file"
        fi
    elif [ -f "$mp3_file" ] && [ "$RESUME" != true ]; then
        echo -e "${BLUE}Skipping (exists): $mp3_file${NC}"
        echo "1" >> "$PROGRESS_FILE"
        return 0
    fi
    
    # Dry run mode
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY RUN] Would convert: $input_file -> $mp3_file${NC}"
        echo "1" >> "$PROGRESS_FILE"
        return 0
    fi
    
    echo -e "${GREEN}Converting: $input_file -> $mp3_file${NC}"
    
    # Convert with optimized settings
    if ! ffmpeg -nostdin -threads 1 -i "$input_file" \
        -codec:a libmp3lame -b:a "$DEFAULT_BITRATE" \
        -map_metadata 0 -id3v2_version 3 \
        "$mp3_file" -y 2>/dev/null; then
        echo -e "${RED}Error: Failed to convert '$input_file'${NC}" >&2
        if [ -n "$LOG_FILE" ]; then
            echo "Error: Failed to convert '$input_file'" >> "$LOG_FILE"
        fi
        # Remove partial file if conversion failed
        [ -f "$mp3_file" ] && rm -f "$mp3_file"
        return 1
    fi
    
    # Validate output quality
    validate_output "$input_file" "$mp3_file"
    
    # Preserve file timestamps
    if command -v touch &> /dev/null; then
        touch -r "$input_file" "$mp3_file"
    fi
    
    echo -e "${GREEN}Completed: $mp3_file${NC}"
    if [ -n "$LOG_FILE" ]; then
        echo "Completed: $input_file -> $mp3_file" >> "$LOG_FILE"
    fi
    
    # Update progress counter
    echo "1" >> "$PROGRESS_FILE"
}

export -f convert_audio_file validate_output update_progress

# Count total files for progress tracking
echo -e "${BLUE}Scanning for audio files...${NC}"
TOTAL_FILES=$(find "$SOURCE_DIR" -type f \( \
    -iname "*.flac" -o -iname "*.wav" -o -iname "*.ape" -o \
    -iname "*.m4a" -o -iname "*.ogg" -o -iname "*.wma" \) \
    ! -name "._*" | wc -l)

if [ "$TOTAL_FILES" -eq 0 ]; then
    echo -e "${RED}No supported audio files found in '$SOURCE_DIR'${NC}"
    exit 1
fi

echo -e "${BLUE}Found $TOTAL_FILES audio files${NC}"
echo -e "${BLUE}Starting conversion from '$SOURCE_DIR' to '$TARGET_DIR'${NC}"
echo -e "${BLUE}Using $DEFAULT_JOBS parallel processes${NC}"
echo -e "${BLUE}Output bitrate: $DEFAULT_BITRATE${NC}"

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN MODE - No files will be converted${NC}"
fi

if [ "$RESUME" = true ]; then
    echo -e "${YELLOW}RESUME MODE - Will skip existing valid files${NC}"
fi

log_message "Starting conversion of $TOTAL_FILES files"

# Initialize progress file
echo "0" > "$PROGRESS_FILE"

# Progress monitoring in background
if [ "$VERBOSE" = true ]; then
    (
        while [ -f "$PROGRESS_FILE" ]; do
            if [ -f "$PROGRESS_FILE" ]; then
                current_count=$(wc -l < "$PROGRESS_FILE" 2>/dev/null || echo "0")
                update_progress "$current_count" "$TOTAL_FILES"
            fi
            sleep 5
        done
    ) &
    PROGRESS_PID=$!
fi

# Find and convert all audio files with expanded format support
if [ -t 1 ] && [ "$VERBOSE" = true ]; then
    # Interactive terminal with verbose mode - show progress bar
    find "$SOURCE_DIR" -type f \( \
        -iname "*.flac" -o -iname "*.wav" -o -iname "*.ape" -o \
        -iname "*.m4a" -o -iname "*.ogg" -o -iname "*.wma" \) \
        ! -name "._*" -print0 | \
        parallel -j"$DEFAULT_JOBS" -0 --bar convert_audio_file
else
    # Non-interactive or non-verbose mode - no progress bar
    find "$SOURCE_DIR" -type f \( \
        -iname "*.flac" -o -iname "*.wav" -o -iname "*.ape" -o \
        -iname "*.m4a" -o -iname "*.ogg" -o -iname "*.wma" \) \
        ! -name "._*" -print0 | \
        parallel -j"$DEFAULT_JOBS" -0 convert_audio_file
fi

# Clean up progress monitoring
if [ "$VERBOSE" = true ] && [ -n "${PROGRESS_PID:-}" ]; then
    kill "$PROGRESS_PID" 2>/dev/null || true
    wait "$PROGRESS_PID" 2>/dev/null || true
fi

# Final progress update
FINAL_COUNT=$(wc -l < "$PROGRESS_FILE" 2>/dev/null || echo "0")
rm -f "$PROGRESS_FILE"

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
TOTAL_TIME_FORMATTED=$(date -u -d @"$TOTAL_TIME" +%H:%M:%S 2>/dev/null || echo "${TOTAL_TIME}s")

echo
echo -e "${GREEN}Conversion completed!${NC}"
echo -e "${GREEN}Processed: $FINAL_COUNT/$TOTAL_FILES files${NC}"
echo -e "${GREEN}Total time: $TOTAL_TIME_FORMATTED${NC}"

if [ "$FINAL_COUNT" -lt "$TOTAL_FILES" ]; then
    FAILED_COUNT=$((TOTAL_FILES - FINAL_COUNT))
    echo -e "${YELLOW}Failed conversions: $FAILED_COUNT${NC}"
fi

log_message "Conversion completed. Processed: $FINAL_COUNT/$TOTAL_FILES files in $TOTAL_TIME_FORMATTED"

if [ -n "$LOG_FILE" ]; then
    echo -e "${BLUE}Log file saved to: $LOG_FILE${NC}"
fi
