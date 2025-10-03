#!/bin/bash

# Script to create a fake music library for testing
set -euo pipefail

TEST_DIR="${1:-./test_music_library}"
OUTPUT_DIR="${2:-./test_output}"

echo "Creating test music library in: $TEST_DIR"
echo "Output directory will be: $OUTPUT_DIR"

# Clean up existing test directory
rm -rf "$TEST_DIR" "$OUTPUT_DIR"

# Create directory structure
mkdir -p "$TEST_DIR/Rock/Led Zeppelin/IV (1971)"
mkdir -p "$TEST_DIR/Rock/Pink Floyd/The Wall (1979)"
mkdir -p "$TEST_DIR/Jazz/Miles Davis/Kind of Blue (1959)"
mkdir -p "$TEST_DIR/Classical/Bach/Brandenburg Concertos"
mkdir -p "$TEST_DIR/Electronic/Daft Punk/Random Access Memories (2013)"
mkdir -p "$TEST_DIR/Folk/Bob Dylan/Highway 61 Revisited (1965)"
mkdir -p "$TEST_DIR/Pop/The Beatles/Abbey Road (1969)"

# Function to create a fake audio file with silence
create_fake_audio() {
    local filepath="$1"
    local format="$2"
    local duration="${3:-30}"  # 30 seconds by default
    
    case "$format" in
        "flac")
            ffmpeg -f lavfi -i "sine=frequency=440:duration=$duration" -c:a flac -sample_fmt s16 -ar 44100 "$filepath" -y 2>/dev/null
            ;;
        "wav")
            ffmpeg -f lavfi -i "sine=frequency=880:duration=$duration" -c:a pcm_s16le -ar 44100 "$filepath" -y 2>/dev/null
            ;;
        "ape")
            # Create WAV first, then convert to APE (if ffmpeg supports it)
            local temp_wav="${filepath%.*}.tmp.wav"
            ffmpeg -f lavfi -i "sine=frequency=220:duration=$duration" -c:a pcm_s16le -ar 44100 "$temp_wav" -y 2>/dev/null
            if ffmpeg -i "$temp_wav" -c:a ape "$filepath" -y 2>/dev/null; then
                rm -f "$temp_wav"
            else
                # Fallback to WAV if APE not supported
                mv "$temp_wav" "${filepath%.*}.wav"
                echo "Warning: APE not supported, created WAV instead: ${filepath%.*}.wav"
            fi
            ;;
        "m4a")
            ffmpeg -f lavfi -i "sine=frequency=660:duration=$duration" -c:a aac -b:a 256k "$filepath" -y 2>/dev/null
            ;;
        "ogg")
            ffmpeg -f lavfi -i "sine=frequency=330:duration=$duration" -c:a libvorbis -b:a 192k "$filepath" -y 2>/dev/null
            ;;
        *)
            echo "Unsupported format: $format"
            return 1
            ;;
    esac
    
    # Add some metadata
    if command -v ffmpeg &> /dev/null; then
        local artist=$(basename "$(dirname "$(dirname "$filepath")")")
        local album=$(basename "$(dirname "$filepath")")
        local title=$(basename "$filepath" | sed 's/\.[^.]*$//')
        
        # Create temporary file with metadata
        local temp_file="${filepath}.tmp"
        mv "$filepath" "$temp_file"
        
        ffmpeg -i "$temp_file" \
            -metadata artist="$artist" \
            -metadata album="$album" \
            -metadata title="$title" \
            -metadata genre="Test" \
            -metadata date="2023" \
            -c copy "$filepath" -y 2>/dev/null || mv "$temp_file" "$filepath"
        
        rm -f "$temp_file"
    fi
}

echo "Creating fake audio files..."

# Rock - Led Zeppelin
create_fake_audio "$TEST_DIR/Rock/Led Zeppelin/IV (1971)/01 - Black Dog.flac" "flac" 25
create_fake_audio "$TEST_DIR/Rock/Led Zeppelin/IV (1971)/02 - Rock and Roll.flac" "flac" 30
create_fake_audio "$TEST_DIR/Rock/Led Zeppelin/IV (1971)/03 - The Battle of Evermore.wav" "wav" 35

# Rock - Pink Floyd
create_fake_audio "$TEST_DIR/Rock/Pink Floyd/The Wall (1979)/01 - In the Flesh.flac" "flac" 20
create_fake_audio "$TEST_DIR/Rock/Pink Floyd/The Wall (1979)/02 - The Thin Ice.wav" "wav" 28

# Jazz - Miles Davis
create_fake_audio "$TEST_DIR/Jazz/Miles Davis/Kind of Blue (1959)/01 - So What.flac" "flac" 45
create_fake_audio "$TEST_DIR/Jazz/Miles Davis/Kind of Blue (1959)/02 - Freddie Freeloader.flac" "flac" 40

# Classical - Bach
create_fake_audio "$TEST_DIR/Classical/Bach/Brandenburg Concertos/Brandenburg Concerto No. 1.wav" "wav" 60
create_fake_audio "$TEST_DIR/Classical/Bach/Brandenburg Concertos/Brandenburg Concerto No. 2.flac" "flac" 55

# Electronic - Daft Punk
create_fake_audio "$TEST_DIR/Electronic/Daft Punk/Random Access Memories (2013)/01 - Give Life Back to Music.m4a" "m4a" 25
create_fake_audio "$TEST_DIR/Electronic/Daft Punk/Random Access Memories (2013)/02 - The Game of Love.ogg" "ogg" 30

# Folk - Bob Dylan
create_fake_audio "$TEST_DIR/Folk/Bob Dylan/Highway 61 Revisited (1965)/01 - Like a Rolling Stone.flac" "flac" 35
create_fake_audio "$TEST_DIR/Folk/Bob Dylan/Highway 61 Revisited (1965)/02 - Tombstone Blues.wav" "wav" 28

# Pop - The Beatles
create_fake_audio "$TEST_DIR/Pop/The Beatles/Abbey Road (1969)/01 - Come Together.flac" "flac" 22
create_fake_audio "$TEST_DIR/Pop/The Beatles/Abbey Road (1969)/02 - Something.flac" "flac" 26

# Create some edge cases for testing
mkdir -p "$TEST_DIR/Edge Cases"

# Files with special characters
create_fake_audio "$TEST_DIR/Edge Cases/Song with spaces & special chars!.flac" "flac" 15
create_fake_audio "$TEST_DIR/Edge Cases/Ümlaut_and-dashes.wav" "wav" 18

# Hidden files (should be skipped)
create_fake_audio "$TEST_DIR/Edge Cases/._hidden_file.flac" "flac" 10

# Very short file
create_fake_audio "$TEST_DIR/Edge Cases/Short Song.flac" "flac" 5

# Longer file for quality testing
create_fake_audio "$TEST_DIR/Edge Cases/Long Song.wav" "wav" 120

echo "Test library created successfully!"
echo ""
echo "Directory structure:"
find "$TEST_DIR" -type f | sort
echo ""
echo "Total files created: $(find "$TEST_DIR" -type f | wc -l)"
echo "Total size: $(du -sh "$TEST_DIR" | cut -f1)"
echo ""
echo "You can now test the conversion script with:"
echo "./convertMusicLibrary.sh \"$TEST_DIR\" \"$OUTPUT_DIR\""
echo ""
echo "For testing different options:"
echo "./convertMusicLibrary.sh -d \"$TEST_DIR\" \"$OUTPUT_DIR\"  # Dry run"
echo "./convertMusicLibrary.sh -v -q -l test.log \"$TEST_DIR\" \"$OUTPUT_DIR\"  # Verbose with quality check and logging"
echo "./convertMusicLibrary.sh -b 192k -j 2 \"$TEST_DIR\" \"$OUTPUT_DIR\"  # Custom bitrate and job count"