# ConvertMusicLibraryToMP3

A robust Bash script that converts entire music libraries from lossless formats (FLAC/WAV) to high-quality MP3 (320kbps), while preserving directory structure, metadata, and file timestamps.

## Features

- **High-quality conversion**: 320kbps MP3 output with full metadata preservation
- **Parallel processing**: Utilizes all CPU cores for maximum performance
- **Smart skip logic**: Avoids re-converting existing MP3 files
- **Directory structure preservation**: Maintains complete folder hierarchy
- **Progress tracking**: Real-time progress bar and status updates
- **Error handling**: Robust validation and graceful failure recovery
- **Timestamp preservation**: Maintains original file modification times
- **Hidden file filtering**: Automatically skips system files (._*)

## Prerequisites

- `ffmpeg` - Audio conversion engine
- `parallel` - GNU parallel for concurrent processing
- Bash 4.0+ with standard Unix tools

## Usage

```bash
./convertMusicLibrary.sh <source_directory> <target_directory>
```

### Example

```bash
./convertMusicLibrary.sh /home/user/Music/FLAC /home/user/Music/MP3
```

## Output

The script provides detailed progress information:
- Conversion status for each file
- Progress bar showing overall completion
- Summary of total files processed
- Error reporting for failed conversions

## Error Handling

- Validates source directory existence and readability
- Creates target directory if needed
- Checks for required dependencies
- Handles conversion failures gracefully
- Removes incomplete files on error

## Performance

- Utilizes all available CPU cores by default
- Skips existing files to avoid redundant work
- Efficient memory usage with streaming conversion
- Optimized ffmpeg parameters for speed and quality
