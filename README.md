# ConvertMusicLibraryToMP3

A comprehensive, high-performance Bash script that converts entire music libraries from lossless and lossy formats to high-quality MP3, with advanced features like resume capability, quality validation, progress tracking, and extensive format support.

## Features

### 🎵 **Audio Processing**
- **Extended format support**: FLAC, WAV, APE, ALAC (M4A), OGG, WMA → MP3
- **Configurable quality**: Custom bitrates (default: 320kbps)
- **Metadata preservation**: Artist, album, title, genre, date, and more
- **Timestamp preservation**: Maintains original file modification times

### 🚀 **Performance & Optimization**
- **Parallel processing**: Configurable CPU core utilization
- **Memory optimization**: Streaming conversion with minimal RAM usage
- **Smart skip logic**: Avoids re-converting existing files
- **Resume capability**: Continue interrupted conversions
- **Disk space validation**: Pre-conversion space checking

### 📊 **Progress & Monitoring**
- **Real-time progress**: File count, percentage, rate, and ETA
- **Colored terminal output**: Easy-to-read status information
- **Comprehensive logging**: Detailed conversion logs with timestamps
- **Verbose mode**: Enhanced progress monitoring
- **Quality validation**: File size and duration verification

### 🛠️ **Advanced Features**
- **Dry-run mode**: Preview operations without conversion
- **Resume functionality**: Smart detection of completed/corrupted files
- **Signal handling**: Graceful cleanup on interruption
- **Hidden file filtering**: Automatically skips system files (._*)
- **Error recovery**: Robust validation and failure handling
- **Directory preservation**: Maintains complete folder hierarchy

## Prerequisites

### Required Dependencies
- **ffmpeg** - Audio conversion engine with libmp3lame codec
- **parallel** - GNU parallel for concurrent processing  
- **Bash 4.0+** - With standard Unix tools (awk, find, etc.)

### Optional Dependencies
- **mediainfo** - Enhanced quality validation (duration comparison)
- **bc** - Mathematical calculations (fallback: awk)

### Quick Setup

Run the automated setup script:

```bash
./setup.sh
```

This script automatically detects your Linux distribution and installs all required dependencies.

### Manual Installation

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install ffmpeg parallel mediainfo
```

**RHEL/CentOS/Fedora:**
```bash
sudo dnf install ffmpeg parallel mediainfo  # Fedora
sudo yum install epel-release && sudo yum install ffmpeg parallel mediainfo  # RHEL/CentOS
```

**Arch Linux:**
```bash
sudo pacman -S ffmpeg parallel mediainfo
```

**openSUSE:**
```bash
sudo zypper install ffmpeg parallel mediainfo
```

## Usage

### Basic Syntax

```bash
./convertMusicLibrary.sh [OPTIONS] <source_directory> <target_directory>
```

### Command Line Options

| Option | Description | Default |
|--------|-------------|----------|
| `-b, --bitrate RATE` | Output bitrate (e.g., 128k, 192k, 320k) | 320k |
| `-j, --jobs NUM` | Number of parallel jobs | CPU cores |
| `-l, --log FILE` | Log file path | None |
| `-d, --dry-run` | Preview operations without conversion | False |
| `-r, --resume` | Resume interrupted conversion | False |
| `-v, --verbose` | Verbose output with progress monitoring | False |
| `-q, --quality-check` | Validate output file quality | False |
| `-h, --help` | Show help message | - |

### Examples

**Basic conversion:**
```bash
./convertMusicLibrary.sh /home/user/Music/FLAC /home/user/Music/MP3
```

**High-performance conversion with logging:**
```bash
./convertMusicLibrary.sh -b 256k -j 8 -v -q -l conversion.log \
  /path/to/lossless/music /path/to/mp3/output
```

**Dry run (preview only):**
```bash
./convertMusicLibrary.sh -d /path/to/input /path/to/output
```

**Resume interrupted conversion:**
```bash
./convertMusicLibrary.sh -r /path/to/input /path/to/output
```

**Conservative conversion (fewer cores, lower bitrate):**
```bash
./convertMusicLibrary.sh -b 192k -j 2 /path/to/input /path/to/output
```

## Output

The script provides comprehensive progress information:

### Standard Output
- 🎵 **File scanning**: Total files found and format breakdown
- 🔄 **Conversion status**: Real-time file processing updates
- 📊 **Progress tracking**: Current/total files, percentage, rate, ETA
- ✅ **Completion summary**: Files processed, total time, failure count
- 🎨 **Color-coded messages**: Easy visual status identification

### Verbose Mode (`-v`)
- 📈 **Enhanced progress**: Background monitoring with 5-second updates
- 🕐 **Timestamp logging**: Detailed operation timestamps
- 📋 **Rate calculation**: Files per second processing rate
- ⏱️ **ETA estimation**: Estimated time to completion

### Logging (`-l logfile`)
- 📝 **Detailed logs**: Comprehensive conversion history
- 🚨 **Error tracking**: Failed conversions with reasons
- 🏷️ **Session metadata**: Start time, settings, file counts
- ⚠️ **Quality warnings**: File size and duration anomalies

### Example Output
```
🔍 Scanning for audio files...
📁 Found 156 audio files
🎵 Starting conversion from '/music/flac' to '/music/mp3'
⚙️ Using 8 parallel processes
🎼 Output bitrate: 320k

✅ Converting: Artist - Album/01 - Song.flac -> Artist - Album/01 - Song.mp3
✅ Completed: Artist - Album/01 - Song.mp3

📊 Progress: 45/156 (28%) | Rate: 2.3/s | ETA: 00:00:48

🎉 Conversion completed!
📈 Processed: 156/156 files
⏱️ Total time: 00:01:07
```

## Error Handling

The script includes comprehensive error handling and recovery mechanisms:

### Pre-Conversion Validation
- ✅ **Source directory**: Existence, readability, and file permissions
- ✅ **Target directory**: Creation if needed, write permissions
- ✅ **Dependencies**: ffmpeg, parallel, and optional tools availability
- ✅ **Disk space**: Available space vs. estimated conversion size
- ✅ **File formats**: Supported input format verification

### Runtime Error Recovery
- 🔄 **Partial file cleanup**: Removes incomplete files on conversion failure
- 🛡️ **Signal handling**: Graceful cleanup on SIGINT/SIGTERM
- 📝 **Error logging**: Detailed failure reasons in log files
- 🔍 **Quality validation**: Detects corrupted or unusual output files
- ⚡ **Resume capability**: Validates existing files before skipping

### Failure Scenarios
- **Corrupted source files**: Logged and skipped, conversion continues
- **Insufficient disk space**: Early warning with user confirmation
- **Permission errors**: Clear error messages with suggested fixes
- **Process interruption**: Clean shutdown with progress preservation
- **Codec issues**: Fallback strategies and detailed error reporting

### Exit Codes
- `0` - Success: All files converted successfully
- `1` - Error: Invalid arguments, missing dependencies, or critical failures
- `130` - Interrupted: User cancellation via SIGINT (Ctrl+C)

## Performance

### Optimization Features
- 🚀 **Multi-core processing**: Configurable parallel job execution (default: all CPU cores)
- 💾 **Memory efficiency**: Streaming conversion with minimal RAM usage
- ⚡ **Smart skipping**: Existing file detection to avoid redundant work
- 🎯 **Optimized encoding**: libmp3lame codec with tuned ffmpeg parameters
- 🧵 **Thread management**: Single-threaded ffmpeg instances to prevent oversubscription

### Performance Tuning

**For maximum speed (high-end systems):**
```bash
./convertMusicLibrary.sh -j $(nproc) -b 192k /input /output
```

**For balanced performance (most systems):**
```bash
./convertMusicLibrary.sh -j $(($(nproc)/2)) -b 256k /input /output
```

**For low-resource systems:**
```bash
./convertMusicLibrary.sh -j 2 -b 128k /input /output
```

### Benchmark Results

Typical performance on modern hardware:

| System | Files/sec | Notes |
|--------|-----------|-------|
| 16-core CPU, NVMe SSD | 8-12 | High-end desktop |
| 8-core CPU, SATA SSD | 4-6 | Mid-range system |
| 4-core CPU, HDD | 2-3 | Budget/older system |

*Performance varies based on source file sizes, formats, and system resources.*

### Memory Usage
- **Base usage**: ~50-100MB for script and parallel processing
- **Per job**: ~20-50MB per concurrent ffmpeg process
- **Streaming**: No intermediate file storage required
- **Scalability**: Linear scaling with available CPU cores

## Testing

### Automated Test Suite

Create a comprehensive test library with sample audio files:

```bash
./create_test_library.sh [test_input_dir] [test_output_dir]
```

This generates:
- 📁 **Realistic directory structure**: Multiple artists, albums, and genres
- 🎵 **Multiple formats**: FLAC, WAV, M4A, OGG files with metadata
- 🔤 **Edge cases**: Special characters, Unicode, spaces in filenames
- ⏱️ **Various durations**: Short (5s) to long (120s) test files
- 📊 **Quality validation**: Files designed to test size/duration checks

### Test Scenarios

**Basic functionality:**
```bash
./create_test_library.sh
./convertMusicLibrary.sh ./test_music_library ./test_output
```

**Dry run testing:**
```bash
./convertMusicLibrary.sh -d ./test_music_library ./test_output
```

**Resume functionality:**
```bash
# Start conversion
./convertMusicLibrary.sh ./test_music_library ./test_output
# Interrupt with Ctrl+C
# Resume
./convertMusicLibrary.sh -r ./test_music_library ./test_output
```

**Quality validation:**
```bash
./convertMusicLibrary.sh -v -q -l test.log ./test_music_library ./test_output
```

## Supported Formats

### Input Formats
| Format | Extension | Notes |
|--------|-----------|-------|
| FLAC | `.flac` | Lossless, preferred source |
| WAV | `.wav` | Uncompressed, high quality |
| APE | `.ape` | Monkey's Audio (if ffmpeg supports) |
| ALAC | `.m4a` | Apple Lossless |
| OGG | `.ogg` | Vorbis encoded |
| WMA | `.wma` | Windows Media Audio |

### Output Format
- **MP3**: Variable/Constant bitrate, 128k-320k (default: 320k)
- **Codec**: libmp3lame with optimized settings
- **Metadata**: ID3v2.3 tags with full metadata preservation

## Advanced Usage

### Configuration Examples

**Archive-quality conversion:**
```bash
./convertMusicLibrary.sh -b 320k -q -l archive.log \
  /music/masters /music/archive
```

**Streaming-quality batch:**
```bash
./convertMusicLibrary.sh -b 128k -j 16 \
  /music/source /music/streaming
```

**Careful conversion with validation:**
```bash
./convertMusicLibrary.sh -v -q -j 4 -l detailed.log \
  /precious/music /backup/mp3
```

### Integration Examples

**Cron job for automatic conversion:**
```bash
# Convert new files daily at 2 AM
0 2 * * * /path/to/convertMusicLibrary.sh -r -l /var/log/music-convert.log /music/new /music/mp3
```

**Script integration:**
```bash
#!/bin/bash
# Batch processing multiple directories
for dir in /music/*/; do
    ./convertMusicLibrary.sh -r "$dir" "/converted/$(basename "$dir")"
done
```

## Troubleshooting

### Common Issues

**"ffmpeg not found"**
```bash
# Run setup script
./setup.sh
# Or install manually (Ubuntu/Debian)
sudo apt install ffmpeg
```

**"parallel not found"**
```bash
# Install GNU parallel
sudo apt install parallel  # Ubuntu/Debian
sudo dnf install parallel  # Fedora
```

**Permission denied errors**
```bash
# Make scripts executable
chmod +x *.sh
# Check directory permissions
ls -la /path/to/music
```

**Conversion failures**
```bash
# Test with verbose mode and logging
./convertMusicLibrary.sh -v -l debug.log /input /output
# Check log file for details
cat debug.log
```

**Out of disk space**
```bash
# Check available space
df -h /output/path
# Clean up partial files
find /output -name "*.mp3" -size 0 -delete
```

### Performance Issues

**Slow conversion speed:**
- Reduce parallel jobs: `-j 2`
- Lower bitrate: `-b 192k`
- Check system resources: `htop`

**High memory usage:**
- Limit concurrent jobs: `-j 4`
- Monitor with: `ps aux | grep ffmpeg`

**High CPU usage:**
- Reduce parallel jobs
- Run during off-peak hours
- Use `nice` for lower priority

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Test your changes with the test suite
4. Commit your changes: `git commit -am 'Add feature'`
5. Push to the branch: `git push origin feature-name`
6. Submit a pull request

### Development

**Testing changes:**
```bash
# Create test environment
./create_test_library.sh test_input test_output

# Test your modified script
./convertMusicLibrary.sh -d test_input test_output
```

**Code style:**
- Follow existing bash conventions
- Add comments for complex logic
- Test with `shellcheck` if available
- Ensure POSIX compliance where possible

## License

This project is open source. Feel free to use, modify, and distribute.

## Changelog

### v2.0.0 (Latest)
- ➕ Extended format support (APE, M4A, OGG, WMA)
- 📊 Advanced progress tracking with ETA
- 🔄 Resume capability for interrupted conversions
- 🎯 Quality validation and verification
- 🖥️ Colored terminal output
- 📝 Comprehensive logging system
- 🛠️ Automated setup script
- 🧪 Complete test suite
- ⚡ Performance optimizations
- 🛡️ Enhanced error handling

### v1.0.0
- 🎵 Basic FLAC/WAV to MP3 conversion
- 🚀 Parallel processing support
- 📁 Directory structure preservation
- 🏷️ Metadata preservation
- ⏰ Timestamp preservation
