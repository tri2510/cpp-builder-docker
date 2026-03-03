#!/bin/bash
set -e

# Multi-Architecture Docker Build Script
# Builds and pushes a multi-arch Docker image for amd64, arm64, and armv7

IMAGE_NAME="${IMAGE_NAME:-cpp-builder}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"

# Use buildx for multi-platform builds
echo "=========================================="
echo "Multi-Architecture Docker Build"
echo "=========================================="
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Platforms: ${PLATFORMS}"
echo "=========================================="

# Ensure buildx is available
if ! docker buildx version &>/dev/null; then
    echo "Error: docker buildx not available"
    echo "Please install docker-buildx or use Docker Desktop"
    exit 1
fi

# Create a new builder instance if it doesn't exist
BUILDER_NAME="cpp-builder-multiarch"
if ! docker buildx inspect "${BUILDER_NAME}" &>/dev/null; then
    echo "Creating new buildx builder: ${BUILDER_NAME}"
    docker buildx create --name "${BUILDER_NAME}" --driver docker-container --use
    docker buildx inspect --bootstrap
else
    echo "Using existing builder: ${BUILDER_NAME}"
    docker buildx use "${BUILDER_NAME}"
fi

# Build multi-architecture image
echo "Building multi-architecture image..."
docker buildx build \
    --platform "${PLATFORMS}" \
    --file Dockerfile.cross \
    --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
    --progress plain \
    "${@}"

echo ""
echo "=========================================="
echo "Multi-arch build completed!"
echo "=========================================="
echo "To push to registry, add --push flag:"
echo "  ./build-multiarch.sh --push"
echo ""
echo "To load specific platform, use:"
echo "  docker buildx build --platform linux/arm64 --load ."
