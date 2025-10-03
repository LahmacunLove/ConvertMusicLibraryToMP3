#!/bin/bash

# Setup script for ConvertMusicLibraryToMP3
# Installs all required dependencies across different Linux distributions

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install packages for Ubuntu/Debian
install_debian() {
    print_status "Detected Debian/Ubuntu system"
    print_status "Updating package lists..."
    sudo apt update

    local packages=""
    
    # Check and add ffmpeg
    if ! command_exists ffmpeg; then
        packages="$packages ffmpeg"
    fi
    
    # Check and add parallel
    if ! command_exists parallel; then
        packages="$packages parallel"
    fi
    
    # Check and add mediainfo (optional)
    if ! command_exists mediainfo; then
        packages="$packages mediainfo"
    fi
    
    if [ -n "$packages" ]; then
        print_status "Installing packages:$packages"
        sudo apt install -y $packages
    else
        print_success "All required packages are already installed"
    fi
}

# Install packages for RHEL/CentOS/Fedora
install_rhel() {
    print_status "Detected RHEL/CentOS/Fedora system"
    
    local packages=""
    local package_manager=""
    
    # Determine package manager
    if command_exists dnf; then
        package_manager="dnf"
    elif command_exists yum; then
        package_manager="yum"
    else
        print_error "No supported package manager found (dnf/yum)"
        exit 1
    fi
    
    # Enable EPEL repository for CentOS/RHEL
    if [ "$ID" = "centos" ] || [ "$ID" = "rhel" ]; then
        print_status "Enabling EPEL repository..."
        sudo $package_manager install -y epel-release
    fi
    
    # Check and add ffmpeg
    if ! command_exists ffmpeg; then
        packages="$packages ffmpeg"
    fi
    
    # Check and add parallel
    if ! command_exists parallel; then
        packages="$packages parallel"
    fi
    
    # Check and add mediainfo (optional)
    if ! command_exists mediainfo; then
        packages="$packages mediainfo"
    fi
    
    if [ -n "$packages" ]; then
        print_status "Installing packages:$packages"
        sudo $package_manager install -y $packages
    else
        print_success "All required packages are already installed"
    fi
}

# Install packages for Arch Linux
install_arch() {
    print_status "Detected Arch Linux system"
    print_status "Updating package database..."
    sudo pacman -Sy
    
    local packages=""
    
    # Check and add ffmpeg
    if ! command_exists ffmpeg; then
        packages="$packages ffmpeg"
    fi
    
    # Check and add parallel
    if ! command_exists parallel; then
        packages="$packages parallel"
    fi
    
    # Check and add mediainfo (optional)
    if ! command_exists mediainfo; then
        packages="$packages mediainfo"
    fi
    
    if [ -n "$packages" ]; then
        print_status "Installing packages:$packages"
        sudo pacman -S --noconfirm $packages
    else
        print_success "All required packages are already installed"
    fi
}

# Install packages for openSUSE
install_suse() {
    print_status "Detected openSUSE system"
    
    local packages=""
    
    # Check and add ffmpeg
    if ! command_exists ffmpeg; then
        packages="$packages ffmpeg"
    fi
    
    # Check and add parallel
    if ! command_exists parallel; then
        packages="$packages parallel"
    fi
    
    # Check and add mediainfo (optional)
    if ! command_exists mediainfo; then
        packages="$packages mediainfo"
    fi
    
    if [ -n "$packages" ]; then
        print_status "Installing packages:$packages"
        sudo zypper install -y $packages
    else
        print_success "All required packages are already installed"
    fi
}

# Main installation function
main() {
    echo "=========================================="
    echo "ConvertMusicLibraryToMP3 Setup Script"
    echo "=========================================="
    echo
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root. Use sudo when prompted."
        exit 1
    fi
    
    # Check if sudo is available
    if ! command_exists sudo; then
        print_error "sudo is required but not available. Please install sudo or run as root."
        exit 1
    fi
    
    print_status "Checking system requirements..."
    
    # Detect distribution
    DISTRO=$(detect_distro)
    print_status "Detected distribution: $DISTRO"
    
    # Install based on distribution
    case "$DISTRO" in
        ubuntu|debian|linuxmint|elementary)
            install_debian
            ;;
        fedora|centos|rhel|rocky|almalinux)
            install_rhel
            ;;
        arch|manjaro|endeavouros)
            install_arch
            ;;
        opensuse*|sles)
            install_suse
            ;;
        *)
            print_warning "Unsupported distribution: $DISTRO"
            print_status "Please install the following packages manually:"
            echo "  - ffmpeg"
            echo "  - parallel (GNU parallel)"
            echo "  - mediainfo (optional, for quality validation)"
            echo
            ;;
    esac
    
    echo
    print_status "Verifying installation..."
    
    # Verify ffmpeg
    if command_exists ffmpeg; then
        FFMPEG_VERSION=$(ffmpeg -version | head -n1 | cut -d' ' -f3)
        print_success "ffmpeg is installed (version: $FFMPEG_VERSION)"
    else
        print_error "ffmpeg is not installed or not in PATH"
        exit 1
    fi
    
    # Verify parallel
    if command_exists parallel; then
        PARALLEL_VERSION=$(parallel --version | head -n1 | grep -o '[0-9]*')
        print_success "GNU parallel is installed (version: $PARALLEL_VERSION)"
    else
        print_error "GNU parallel is not installed or not in PATH"
        exit 1
    fi
    
    # Verify mediainfo (optional)
    if command_exists mediainfo; then
        MEDIAINFO_VERSION=$(mediainfo --version | head -n1 | grep -o 'v[0-9.]*')
        print_success "mediainfo is installed (version: $MEDIAINFO_VERSION) - enables quality validation"
    else
        print_warning "mediainfo is not installed - quality validation will be limited"
    fi
    
    # Make scripts executable
    print_status "Making scripts executable..."
    chmod +x convertMusicLibrary.sh
    chmod +x create_test_library.sh
    
    echo
    print_success "Setup completed successfully!"
    echo
    echo "=========================================="
    echo "Usage Examples:"
    echo "=========================================="
    echo
    echo "Basic usage:"
    echo "  ./convertMusicLibrary.sh /path/to/flac/music /path/to/mp3/output"
    echo
    echo "With options:"
    echo "  ./convertMusicLibrary.sh -b 256k -j 4 -v -q -l conversion.log /path/to/input /path/to/output"
    echo
    echo "Dry run (preview):"
    echo "  ./convertMusicLibrary.sh -d /path/to/input /path/to/output"
    echo
    echo "Resume interrupted conversion:"
    echo "  ./convertMusicLibrary.sh -r /path/to/input /path/to/output"
    echo
    echo "Create test library:"
    echo "  ./create_test_library.sh ./test_input ./test_output"
    echo
    echo "View help:"
    echo "  ./convertMusicLibrary.sh -h"
    echo
    print_status "For more information, see the README.md file"
}

# Run main function
main "$@"