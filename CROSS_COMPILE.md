# Cross-Compilation Guide

This guide explains how to use the C++ Builder Docker for cross-compilation to different architectures.

## Supported Architectures

| Architecture | Alias | Target Hardware | Docker Platform |
|--------------|-------|-----------------|-----------------|
| **AMD64** | amd64, x86_64 | Standard PC/Server | linux/amd64 |
| **ARM64** | arm64, aarch64 | Raspberry Pi 4/5, AWS Graviton | linux/arm64 |
| **ARMv7** | armhf, armv7, arm | Raspberry Pi 2/3, BeagleBone | linux/arm/v7 |

## Quick Start

### 1. Build the Cross-Compilation Image

```bash
# Build for current architecture only (faster)
docker build -f Dockerfile.cross -t cpp-builder:cross .

# Or build multi-arch image (slower, supports all platforms)
./build-multiarch.sh
```

### 2. Cross-Compile Your Project

```bash
# Build for ARM64 (Raspberry Pi 4/5)
docker run --rm \
  -v /path/to/project:/project/src:ro \
  -v /path/to/output:/project/output \
  -e TARGET=arm64 \
  cpp-builder:cross

# Build for ARMv7 (Raspberry Pi 2/3)
docker run --rm \
  -v /path/to/project:/project/src:ro \
  -v /path/to/output:/project/output \
  -e TARGET=armhf \
  cpp-builder:cross

# Build native (AMD64)
docker run --rm \
  -v /path/to/project:/project/src:ro \
  -v /path/to/output:/project/output \
  -e TARGET=amd64 \
  cpp-builder:cross
```

### 3. Output

Binaries are suffixed with target architecture:

```
output/
├── hello-arm64    # For Raspberry Pi 4/5
├── hello-armhf    # For Raspberry Pi 2/3
└── hello-amd64    # For standard PCs
```

## Docker Compose Example

```yaml
services:
  # Build for ARM64
  cpp-builder-arm64:
    build:
      context: .
      dockerfile: Dockerfile.cross
    volumes:
      - ./project:/project/src:ro
      - ./output-arm64:/project/output
    environment:
      - TARGET=arm64

  # Build for ARMv7
  cpp-builder-armhf:
    build:
      context: .
      dockerfile: Dockerfile.cross
    volumes:
      - ./project:/project/src:ro
      - ./output-armhf:/project/output
    environment:
      - TARGET=armhf
```

Run:

```bash
# Build for both ARM architectures
docker compose up
```

## Building Multi-Architecture Docker Images

Build a Docker image that works on all platforms:

```bash
# Build and load for current platform
./build-multiarch.sh --load

# Build and push to registry
./build-multiarch.sh --push

# Build specific platform only
docker buildx build \
  --platform linux/arm64 \
  --file Dockerfile.cross \
  --tag cpp-builder:arm64 \
  --load .
```

## Toolchain Files

CMake toolchain files are located at `/opt/cmake-toolchains/` inside the container:

| File | Target |
|------|--------|
| `aarch64-linux-gnu.cmake` | ARM64 (aarch64) |
| `arm-linux-gnueabihf.cmake` | ARMv7 (armhf) |

You can use these directly in your own CMake projects:

```cmake
cmake -DCMAKE_TOOLCHAIN_FILE=/opt/cmake-toolchains/aarch64-linux-gnu.cmake \
      -DCMAKE_BUILD_TYPE=Release \
      /path/to/source
```

## Examples

### Example 1: Build for Raspberry Pi 4

```bash
docker run --rm \
  -v $(pwd)/my-rpi-project:/project/src:ro \
  -v $(pwd)/output:/project/output \
  -e TARGET=arm64 \
  cpp-builder:cross

# Copy to Raspberry Pi
scp output/hello-arm64 pi@192.168.1.100:~/
ssh pi@192.168.1.100 ./hello-arm64
```

### Example 2: Build for Multiple Architectures at Once

```bash
#!/bin/bash

for arch in amd64 arm64 armhf; do
    echo "Building for ${arch}..."
    docker run --rm \
        -v $(pwd)/project:/project/src:ro \
        -v $(pwd)/output:/project/output \
        -e TARGET=${arch} \
        cpp-builder:cross
done

echo "All builds complete:"
ls -lh output/
```

### Example 3: Dockerfile for Multi-Arch Application

```dockerfile
# Build stage - uses multi-arch builder
FROM cpp-builder:cross AS builder

COPY . /project/src
ENV TARGET=arm64
# ENTRYPOINT is already set to entrypoint-cross.sh

# Runtime stage - use lightweight base for target
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# Copy the architecture-specific binary
COPY --from=builder /project/output/hello-arm64 /usr/local/bin/hello

CMD ["hello"]
```

## Verification

Check the architecture of compiled binaries:

```bash
# On Linux
file output/hello-arm64
# Output: ELF 64-bit LSB executable, ARM aarch64...

file output/hello-armhf
# Output: ELF 32-bit LSB executable, ARM EABI5...

file output/hello-amd64
# Output: ELF 64-bit LSB executable, x86-64...
```

## Troubleshooting

### "qemu-user-static not found"

The cross-compiler needs QEMU to run ARM binaries. Install:

```bash
# Ubuntu/Debian
sudo apt-get install qemu-user-static

# Or ensure Docker includes it
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### CMake can't find libraries

For cross-compilation with external libraries, you may need to:

1. Install the library's development package for the target architecture
2. Specify the library path in CMake

```bash
# Install ARM64 libraries in Dockerfile
RUN apt-get install -y libssl-dev:arm64
```

### Binary won't run on target device

1. Verify the binary matches the target architecture:
   ```bash
   file output/hello-arm64
   uname -m  # On target device, should show aarch64
   ```

2. Check for missing dependencies on target:
   ```bash
   # On Raspberry Pi
   ldd ./hello-arm64
   ```

## Adding New Architectures

To add support for a new architecture:

1. Install the cross-compiler toolchain in `Dockerfile.cross`:
   ```dockerfile
   RUN apt-get install -y gcc-ARCH-linux-gnu g++-ARCH-linux-gnu
   ```

2. Create a CMake toolchain file in `toolchains/`:
   ```cmake
   set(CMAKE_SYSTEM_NAME Linux)
   set(CMAKE_SYSTEM_PROCESSOR arch)
   set(CMAKE_C_COMPILER arch-linux-gnu-gcc)
   set(CMAKE_CXX_COMPILER arch-linux-gnu-g++)
   ```

3. Add the architecture mapping in `entrypoint-cross.sh`

4. Update the platforms list in `build-multiarch.sh`
