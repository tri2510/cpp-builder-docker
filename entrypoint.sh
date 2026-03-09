#!/bin/bash
set -e

# C++ Builder Docker Entrypoint
# Usage: docker run -v /path/to/project:/project/src -v /path/to/output:/project/output cpp-builder

PROJECT_DIR="/project"
SRC_DIR="${PROJECT_DIR}/src"
BUILD_DIR="${PROJECT_DIR}/build"
OUTPUT_DIR="${PROJECT_DIR}/output"

echo "=========================================="
echo "C++ Builder Docker"
echo "=========================================="
echo "Source directory: ${SRC_DIR}"
echo "Build directory: ${BUILD_DIR}"
echo "Output directory: ${OUTPUT_DIR}"
echo "C++ Standard: C++17"
echo "=========================================="

# Check if source directory exists and has files
if [ ! -d "${SRC_DIR}" ] || [ -z "$(ls -A ${SRC_DIR})" ]; then
    echo "Error: Source directory is empty or does not exist."
    echo "Please mount your project: docker run -v /path/to/project:/project/src ..."
    exit 1
fi

# Check for CMakeLists.txt
if [ -f "${SRC_DIR}/CMakeLists.txt" ]; then
    echo "Building with CMake..."
    cd "${BUILD_DIR}"
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CXX_STANDARD=17 \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
          "${SRC_DIR}"
    cmake --build . --config Release -j$(nproc)

    # Copy all executables and libraries to output directory
    find . -maxdepth 1 -type f -executable -exec cp {} "${OUTPUT_DIR}/" \;
    find . -maxdepth 1 -name "*.a" -exec cp {} "${OUTPUT_DIR}/" \;
    find . -maxdepth 1 -name "*.so" -exec cp {} "${OUTPUT_DIR}/" \;

    # Make output files writable by host user
    chmod -R a+rw "${OUTPUT_DIR}"

    echo "Build completed successfully!"
    ls -lh "${OUTPUT_DIR}"

elif [ -f "${SRC_DIR}/Makefile" ]; then
    echo "Building with Make..."
    cd "${SRC_DIR}"
    make -j$(nproc)

    # Copy binaries to output (assumes binaries in current dir or common locations)
    find . -maxdepth 1 -type f -executable -exec cp {} "${OUTPUT_DIR}/" \;

    # Make output files writable by host user
    chmod -R a+rw "${OUTPUT_DIR}"

    echo "Build completed successfully!"
    ls -lh "${OUTPUT_DIR}"

else
    echo "No CMakeLists.txt or Makefile found."
    echo "Looking for .cpp files to compile directly..."

    # Find all .cpp files in the source directory
    CPP_FILES=$(find "${SRC_DIR}" -maxdepth 1 -name "*.cpp")

    if [ -z "${CPP_FILES}" ]; then
        echo "Error: No .cpp files found in ${SRC_DIR}"
        exit 1
    fi

    # Compile each .cpp file to its own binary
    for cpp_file in ${CPP_FILES}; do
        filename=$(basename "${cpp_file}" .cpp)
        echo "Compiling ${cpp_file} -> ${OUTPUT_DIR}/${filename}"
        g++ -std=c++17 -O2 -Wall -Wextra "${cpp_file}" -o "${OUTPUT_DIR}/${filename}"
    done

    # Make output files writable by host user
    chmod -R a+rw "${OUTPUT_DIR}"

    echo "Build completed successfully!"
    ls -lh "${OUTPUT_DIR}"
fi
