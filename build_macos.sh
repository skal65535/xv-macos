#!/bin/bash

# Script to build XV on macOS

# Capture the script's absolute directory
TOP_DIR=$(pwd)

# --- Configuration ---
# Use absolute paths
XV_ARCHIVE="./xv-3.10a-patched.tgz"
XV_SOURCE_DIR="${TOP_DIR}/xv-3.10a/" # This is where the source will be extracted
BUILD_DIR="${TOP_DIR}/build"  # This is where the binaries are built

# --- Functions ---

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Homebrew if not found
install_homebrew() {
    if ! command_exists brew;
    then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ $? -ne 0 ]; then
            echo "Error: Homebrew installation failed. Please install it manually from https://brew.sh/"
            exit 1
        fi
        echo "Homebrew installed successfully."
    fi
}

# Function to install Homebrew dependencies
install_dependencies() {
    echo "Installing Homebrew dependencies..."
    brew install --cask xquartz > /dev/null 2>&1
    brew install cmake > /dev/null 2>&1
    brew install jpeg-turbo libtiff libpng jasper > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install one or more dependencies. Please check Homebrew output and your internet connection."
        exit 1
    fi
    echo "Dependencies installed successfully."
}

# Function to extract XV source archive
extract_xv_source() {
    echo "Extracting XV source archive..."
    if [ ! -f "$XV_ARCHIVE" ]; then
        echo "Error: XV source archive not found at '$XV_ARCHIVE'. Please ensure it is in the correct location."
        exit 1
    fi
    mkdir -p "$XV_SOURCE_DIR"
    tar -xzf "$XV_ARCHIVE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to extract XV source archive."
        exit 1
    fi
    echo "XV source extracted successfully."
}

# Function to apply patch
apply_patch() {
    echo "Applying patch..."
    cd "$XV_SOURCE_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to change directory to '$XV_SOURCE_DIR'."
        exit 1
    fi

    # Apply macOS modernization patch
    if [ -f "../macos-compile.patch" ]; then
        echo "Applying macOS modernization patch..."
        patch -p1 < "../macos-compile.patch"
        if [ $? -ne 0 ]; then
            echo "  Warning: macOS modernization patch application may have failed."
            exit 1
        fi
    else
        echo "  macOS modernization patch not found."
        exit 1
    fi

    # Go back to TOP_DIR
    cd "$TOP_DIR"
    echo "Patching complete."
}

# Function to configure and build with CMake
build_with_cmake() {
    echo "Configuring and building XV with CMake..."
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create or change to build directory '$BUILD_DIR'."
        exit 1
    fi

    # Use CMakeLists.txt from TOP_DIR, sources from XV_SOURCE_DIR
    cmake -S "${TOP_DIR}" -B . -DXV_SOURCE_DIR="${XV_SOURCE_DIR}"
    if [ $? -ne 0 ]; then
        echo "Error: CMake configuration failed."
        exit 1
    fi

    # Build with parallel jobs (-j4)
    cmake --build . -j4
    if [ $? -ne 0 ]; then
        echo "Error: CMake build failed."
        exit 1
    fi
    echo "XV build complete."

    # Go back to TOP_DIR
    cd "$TOP_DIR"
}

# --- Main Execution ---

echo "Starting XV build process for macOS..."



install_homebrew
install_dependencies
extract_xv_source
apply_patch
build_with_cmake

echo "XV build process finished."
echo "Binaries are located in the '$BUILD_DIR' directory."
exit 0
