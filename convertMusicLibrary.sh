#!/bin/bash

# Exit on any error, undefined variables, or pipe failures
set -euo pipefail

# Check command line arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_directory> <target_directory>" >&2
    echo "Example: $0 /path/to/flac/music /path/to/mp3/output" >&2
    exit 1
fi

SOURCE_DIR="$1"
TARGET_DIR="$2"

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
    echo "Error: ffmpeg is required but not installed" >&2
    exit 1
fi

if ! command -v parallel &> /dev/null; then
    echo "Error: GNU parallel is required but not installed" >&2
    exit 1
fi

export SOURCE_DIR
export TARGET_DIR

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
        echo "Error: Cannot create directory '$mp3_dir'" >&2
        return 1
    fi
    
    # Skip if MP3 already exists
    if [ -f "$mp3_file" ]; then
        echo "Skipping (exists): $mp3_file"
        return 0
    fi
    
    echo "Converting: $input_file -> $mp3_file"
    
    # Convert with error handling
    if ! ffmpeg -i "$input_file" -ab 320k -map_metadata 0 -id3v2_version 3 -fps_mode passthrough "$mp3_file" -y 2>/dev/null; then
        echo "Error: Failed to convert '$input_file'" >&2
        # Remove partial file if conversion failed
        [ -f "$mp3_file" ] && rm -f "$mp3_file"
        return 1
    fi
    
    # Preserve file timestamps
    if command -v touch &> /dev/null; then
        touch -r "$input_file" "$mp3_file"
    fi
    
    echo "Completed: $mp3_file"
}

export -f convert_audio_file

echo "Starting conversion from '$SOURCE_DIR' to '$TARGET_DIR'"
echo "Using $(nproc) parallel processes"

# Find and convert all audio files
find "$SOURCE_DIR" -type f \( -iname "*.flac" -o -iname "*.wav" \) -print0 | \
    parallel -j"$(nproc)" -0 --bar convert_audio_file

echo "Conversion completed!"
