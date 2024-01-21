#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_directory> <target_directory>"
    exit 1
fi

SOURCE_DIR="$1"
TARGET_DIR="$2"

export SOURCE_DIR
export TARGET_DIR

# define function for converting
musicFile() {
    flacFile="$1"
    if [[ "$(basename "${flacFile}")" != ._* ]] ; then # Skip files starting with "._"
        tmpVar="${flacFile%.*}.mp3"
        mp3File="${tmpVar/$SOURCE_DIR/$TARGET_DIR}"
        mp3FilePath=$(dirname "${mp3File}")
        mkdir -p "${mp3FilePath}"
        if [ ! -f "$mp3File" ]; then # If the mp3 file doesn't exist already
            echo "Input: $flacFile"
            echo "Output: $mp3File"
            ffmpeg -i "$flacFile" -ab 320k -map_metadata 0 -id3v2_version 3 -vsync 2 "$mp3File" < /dev/null
        fi
    fi
}

export -f musicFile

# use function on find:
find "${SOURCE_DIR}" -type f \( -iname "*.flac" -or -iname "*.wav" \) -print0 |
    parallel -j$(nproc) -0 musicFile
