#!/bin/bash
set -e

# C++ Builder Docker - Build and Run Script
# Usage: ./build.sh [project_path] [output_path]

PROJECT_PATH="${1:-$(pwd)/example}"
OUTPUT_PATH="${2:-$(pwd)/output}"
IMAGE_NAME="cpp-builder:latest"

echo "=========================================="
echo "C++ Builder Docker"
echo "=========================================="
echo "Project path: ${PROJECT_PATH}"
echo "Output path: ${OUTPUT_PATH}"
echo "=========================================="

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_PATH}"

# Build the Docker image
echo "Building Docker image..."
docker build -t "${IMAGE_NAME}" .

# Run the build
echo "Running C++ build..."
docker run --rm \
  -v "${PROJECT_PATH}:/project/src:ro" \
  -v "${OUTPUT_PATH}:/project/output" \
  "${IMAGE_NAME}"

echo ""
echo "=========================================="
echo "Build completed! Output in: ${OUTPUT_PATH}"
echo "=========================================="
ls -lh "${OUTPUT_PATH}"
