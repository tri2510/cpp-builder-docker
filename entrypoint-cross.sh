#!/bin/bash
set -e

# C++ Cross-Compilation Builder Docker Entrypoint
# Usage:
#   TARGET=arm64 docker run ...          # Build for ARM64
#   TARGET=armhf docker run ...          # Build for ARMv7
#   TARGET=amd64 docker run ...          # Build native (default)

PROJECT_DIR="/project"
SRC_DIR="${PROJECT_DIR}/src"
BUILD_DIR="${PROJECT_DIR}/build"
OUTPUT_DIR="${PROJECT_DIR}/output"

# Default to native architecture
TARGET="${TARGET:-amd64}"

# Map target names to toolchain settings
case "${TARGET}" in
    amd64|x86_64)
        TOOLCHAIN_FILE=""
        TARGET_TRIPLET=""
        ;;
    arm64|aarch64)
        TOOLCHAIN_FILE="/opt/cmake-toolchains/aarch64-linux-gnu.cmake"
        TARGET_TRIPLET="aarch64-linux-gnu"
        ;;
    armhf|armv7|arm)
        TOOLCHAIN_FILE="/opt/cmake-toolchains/arm-linux-gnueabihf.cmake"
        TARGET_TRIPLET="arm-linux-gnueabihf"
        ;;
    *)
        echo "Error: Unknown target '${TARGET}'"
        echo "Supported targets: amd64, arm64, armhf"
        exit 1
        ;;
esac

echo "=========================================="
echo "C++ Cross-Compilation Builder"
echo "=========================================="
echo "Source directory: ${SRC_DIR}"
echo "Build directory: ${BUILD_DIR}"
echo "Output directory: ${OUTPUT_DIR}"
echo "Target architecture: ${TARGET}"
[[ -n "${TARGET_TRIPLET}" ]] && echo "Toolchain triplet: ${TARGET_TRIPLET}"
echo "C++ Standard: C++17"
echo "=========================================="

# Check if source directory exists
if [ ! -d "${SRC_DIR}" ] || [ -z "$(ls -A ${SRC_DIR})" ]; then
    echo "Error: Source directory is empty or does not exist."
    exit 1
fi

# Cross-compile with CMake
if [ -f "${SRC_DIR}/CMakeLists.txt" ]; then
    echo "Cross-compiling with CMake for ${TARGET}..."
    cd "${BUILD_DIR}"

    CMAKE_ARGS=(-DCMAKE_BUILD_TYPE=Release
                -DCMAKE_CXX_STANDARD=17
                -DCMAKE_EXPORT_COMPILE_COMMANDS=ON)

    if [ -n "${TOOLCHAIN_FILE}" ]; then
        CMAKE_ARGS+=(-DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN_FILE}")
    fi

    cmake "${CMAKE_ARGS[@]}" "${SRC_DIR}"
    cmake --build . --config Release -j$(nproc)

    # Copy artifacts to output with architecture suffix
    find . -maxdepth 1 -type f -executable -exec cp {} "${OUTPUT_DIR}/" \;
    find . -maxdepth 1 -name "*.a" -exec cp {} "${OUTPUT_DIR}/" \;
    find . -maxdepth 1 -name "*.so" -exec cp {} "${OUTPUT_DIR}/" \;

    # Rename binaries with architecture suffix
    for exe in ${OUTPUT_DIR}/*; do
        if [ -f "${exe}" ] && [ -x "${exe}" ]; then
            base=$(basename "${exe}")
            # Check if already has target suffix
            if [[ ! "${base}" =~ .*-${TARGET} ]]; then
                mv "${exe}" "${OUTPUT_DIR}/${base}-${TARGET}"
            fi
        fi
    done

    echo "Cross-compilation completed successfully!"
    ls -lh "${OUTPUT_DIR}"

elif [ -f "${SRC_DIR}/Makefile" ]; then
    echo "Warning: Makefile cross-compilation not fully supported."
    echo "For cross-compilation, please use CMake."
    exit 1

else
    # Direct compilation with cross-compiler
    if [ -z "${TARGET_TRIPLET}" ]; then
        echo "Native compilation of .cpp files..."
        CPP_COMPILER="g++"
    else
        echo "Cross-compiling .cpp files for ${TARGET}..."
        CPP_COMPILER="${TARGET_TRIPLET}-g++"
    fi

    CPP_FILES=$(find "${SRC_DIR}" -maxdepth 1 -name "*.cpp")

    if [ -z "${CPP_FILES}" ]; then
        echo "Error: No .cpp files found"
        exit 1
    fi

    for cpp_file in ${CPP_FILES}; do
        filename=$(basename "${cpp_file}" .cpp)
        echo "Compiling ${cpp_file} -> ${OUTPUT_DIR}/${filename}-${TARGET}"
        ${CPP_COMPILER} -std=c++17 -O2 -Wall -Wextra \
            "${cpp_file}" -o "${OUTPUT_DIR}/${filename}-${TARGET}"
    done

    echo "Build completed!"
    ls -lh "${OUTPUT_DIR}"
fi
