# ConvertMusicLibraryToMP3

This script facilitates the conversion of an entire music library consisting of WAV or FLAC files to MP3 format (at 320kb/s). The conversion process preserves the complete folder structure and all associated metadata, ensuring a seamless transition.

"I wrote this script because I prefer FLAC files, but I also have some devices for playing music that do not support the FLAC codec."

## Prerequisites

Before running the script, make sure your Unix platform has the following prerequisites installed:

- [ffmpeg](https://ffmpeg.org/): A powerful multimedia processing tool.
- [GNU find](https://www.gnu.org/software/findutils/): The GNU implementation of the `find` command.
- [GNU parallel](https://www.gnu.org/software/parallel/): A shell tool for executing jobs in parallel.

## How to Run

Follow these steps to use the script:

1. **Clone Repository:**

git clone https://github.com/your-username/ConvertMusicLibraryToMP3.git


2. **Make Script Executable:**

chmod +x convertMusicLibrary.sh


3. **Add to PATH:**
Add the script to your `PATH` variable to make it globally executable. You can do this by adding the following line to your shell profile file (e.g., `.bashrc` or `.zshrc`):

export PATH="$PATH:/path/to/ConvertMusicLibraryToMP3"

Remember to restart your terminal or run `source ~/.bashrc` (or the appropriate file) for the changes to take effect.

4. **Run the Script:**

`convertMusicLibrary.sh <inputFolder> <outputFolder>`

Replace `<inputFolder>` with the path to your original music library and `<outputFolder>` with the desired destination for the converted MP3 files.

Feel free to customize the script according to your needs and contribute to the repository if you have improvements or additional features to suggest. Happy converting!


