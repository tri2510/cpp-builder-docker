# C++ Builder Docker

A standardized Docker-based build environment for C++ projects. Build any C++ project consistently across different machines with a single command.

## Overview

This Docker image provides a complete, isolated build environment for C++ projects. Simply mount your source code, and it will automatically detect your build system (CMake, Make, or plain .cpp files) and produce compiled binaries.

### Features

| Feature | Description |
|---------|-------------|
| **Base OS** | Ubuntu 24.04 (Noble) |
| **Compiler** | GCC/G++ with C++17 support |
| **Build Systems** | CMake 3.x, Make, Ninja |
| **Additional Tools** | ccache, gdb, valgrind, cppcheck |
| **Cross-Compilation** | ARM64, ARMv7, AMD64 support |
| **Image Sizes** | ~700MB (native), ~1.3GB (cross-compiler) |
| **Input** | Volume mount your project directory |
| **Output** | Compiled binaries to mounted output directory |

---

## Quick Start

### 1. Clone or Copy This Project

```bash
cd cpp-builder-docker
```

### 2. Build the Docker Image

Choose the image you need:

```bash
# Native build only (smaller, ~700MB)
docker build -t cpp-builder:latest .

# With cross-compilation support (larger, ~1.3GB)
docker build -f Dockerfile.cross -t cpp-builder:cross .
```

### 3. Run the Example Build

```bash
# Using the convenience script
./build.sh

# Or using docker-compose
docker compose run --rm cpp-builder

# Or using docker directly
docker run --rm \
  -v $(pwd)/example:/project/src:ro \
  -v $(pwd)/output:/project/output \
  cpp-builder:latest
```

### 4. Run the Compiled Binary

```bash
./output/hello
```

Output:
```
========================================
Hello, World!
Built with Docker C++ Builder
C++ Standard: C++17
========================================
Good day, World!

Vector contents:
  - 1
  - 2
  - 3
  - 4
  - 5
Vector size: 5
```

---

## Usage

### Building Your Own Project

```bash
docker run --rm \
  -v /absolute/path/to/your/project:/project/src:ro \
  -v /absolute/path/to/output:/project/output \
  cpp-builder:latest
```

### Using Docker Compose (Recommended)

Edit `docker-compose.yml`:

```yaml
services:
  cpp-builder:
    build: .
    volumes:
      - ./your-project:/project/src:ro    # Change this
      - ./output:/project/output          # Change this
```

Then run:

```bash
docker compose run --rm cpp-builder
```

### Using the Build Script

```bash
./build.sh /path/to/project /path/to/output
```

---

## Supported Project Types

The builder automatically detects and handles three types of projects:

### 1. CMake Projects (Recommended)

Your project should have a `CMakeLists.txt`:

```
your-project/
├── CMakeLists.txt
├── src/
│   └── main.cpp
└── include/
    └── header.h
```

**Example CMakeLists.txt:**

```cmake
cmake_minimum_required(VERSION 3.15)
project(MyApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(myapp src/main.cpp)
install(TARGETS myapp DESTINATION bin)
```

### 2. Makefile Projects

Your project should have a `Makefile`:

```
your-project/
├── Makefile
└── src/
    └── main.cpp
```

### 3. Simple .cpp Files

For single-file projects or simple scripts:

```
your-project/
├── main.cpp
└── utils.cpp
```

Each `.cpp` file will be compiled into its own executable.

---

## Directory Structure

| Docker Path | Purpose | Recommended Mount |
|-------------|---------|-------------------|
| `/project/src` | Source code (input) | Read-only (`:ro`) |
| `/project/build` | Temporary build files | Internal (don't mount) |
| `/project/output` | Compiled binaries (output) | Read-write |

---

## Advanced Usage

### Interactive Mode (for Debugging)

```bash
docker run --rm -it \
  -v ./project:/project/src \
  -v ./output:/project/output \
  cpp-builder:latest /bin/bash
```

Inside the container:

```bash
cd /project/build
cmake -DCMAKE_BUILD_TYPE=Debug /project/src
make -j$(nproc)
gdb /project/output/myapp
```

### Custom Build Type

Edit `entrypoint.sh` or pass environment variables:

```bash
docker run --rm \
  -v ./project:/project/src:ro \
  -v ./output:/project/output \
  -e CMAKE_BUILD_TYPE=Debug \
  cpp-builder:latest
```

### Verbose Output

```bash
docker run --rm \
  -v ./project:/project/src:ro \
  -v ./output:/project/output \
  cpp-builder:latest /bin/bash -c "cd /project/build && cmake -DCMAKE_BUILD_TYPE=Release /project/src && VERBOSE=1 cmake --build ."
```

---

## Cross-Compilation

Need to build for different architectures? See [CROSS_COMPILE.md](CROSS_COMPILE.md) for detailed instructions.

### Quick Example: Build for Raspberry Pi

```bash
# Build the cross-compiler image
docker build -f Dockerfile.cross -t cpp-builder:cross .

# Cross-compile for ARM64 (Raspberry Pi 4/5)
docker run --rm \
  -v ./project:/project/src:ro \
  -v ./output:/project/output \
  -e TARGET=arm64 \
  cpp-builder:cross

# Cross-compile for ARMv7 (Raspberry Pi 2/3)
docker run --rm \
  -v ./project:/project/src:ro \
  -v ./output:/project/output \
  -e TARGET=armhf \
  cpp-builder:cross
```

**Supported Targets:**
| Target | Hardware | Docker Platform |
|--------|----------|-----------------|
| `amd64` | Standard PC/Server | linux/amd64 |
| `arm64` | Raspberry Pi 4/5, AWS Graviton | linux/arm64 |
| `armhf` | Raspberry Pi 2/3, BeagleBone | linux/arm/v7 |

> **Note:** The `cpp-builder:cross` image uses `entrypoint-cross.sh` by default. Just set `TARGET` environment variable - no need to specify `--entrypoint`.
| `amd64` | Standard PC/Server | linux/amd64 |
| `arm64` | Raspberry Pi 4/5, AWS Graviton | linux/arm64 |
| `armhf` | Raspberry Pi 2/3, BeagleBone | linux/arm/v7 |

---

## CI/CD Integration

> **Automated Docker Publishing:** This project includes GitHub Actions workflows that automatically build and publish Docker images on release tags. See [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md) for setup.

### Manual CI/CD Examples

For other CI systems or custom workflows:

#### GitHub Actions (Build Your Project)

```yaml
name: Build My C++ Project

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build with cpp-builder
        run: |
          docker run --rm \
            -v ${{ github.workspace }}:/project/src:ro \
            -v ${{ github.workspace }}/artifacts:/project/output \
            ghcr.io/username/cpp-builder:latest

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: binaries
          path: artifacts/*
```

#### GitLab CI

```yaml
build:
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker run --rm
        -v $CI_PROJECT_DIR:/project/src:ro
        -v $CI_PROJECT_DIR/output:/project/output
        cpp-builder:latest
  artifacts:
    paths:
      - output/*
```

---

## Multi-Stage Deployment Example

Create a minimal runtime image for deployment:

```dockerfile
FROM cpp-builder:latest AS builder

COPY --chown=builder:builder . /project/src
RUN /usr/local/bin/entrypoint.sh

# Runtime image
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /project/output/* /usr/local/bin/

CMD ["hello"]
```

---

## Troubleshooting

### "Permission denied" on output binaries

```bash
chmod +x output/*
```

Or build with correct user ID:

```bash
docker run --rm \
  -v ./project:/project/src:ro \
  -v ./output:/project/output \
  -u $(id -u):$(id -g) \
  cpp-builder:latest
```

### Build fails with "CMake not found"

Check that your `CMakeLists.txt` is at the root of the mounted source directory.

### No binaries in output directory

1. Check the build logs for errors
2. Run in interactive mode to debug: `docker run -it ... /bin/bash`

### Large image size

The image includes debug tools. For production, consider:

1. Creating a multi-stage build (see above)
2. Removing unused tools from the Dockerfile

---

## File Reference

### Dockerfile

Defines the build environment with all required tools.

### entrypoint.sh

Automatically detects build system and compiles the project. Logic:

```
Does CMakeLists.txt exist?
  ├─ Yes → Build with CMake
  ├─ No → Does Makefile exist?
  │      ├─ Yes → Build with Make
  │      └─ No → Find *.cpp files and compile each with g++
```

### docker-compose.yml

Simplified configuration for running the builder.

### build.sh

Convenience script for quick builds.

### Cross-Compilation Files

| File | Purpose |
|------|---------|
| `Dockerfile.cross` | Multi-architecture Docker image with cross-compilers |
| `entrypoint-cross.sh` | Entrypoint that selects cross-compiler based on TARGET env |
| `build-multiarch.sh` | Build multi-arch Docker images using buildx |
| `toolchains/*.cmake` | CMake toolchain files for each architecture |
| `CROSS_COMPILE.md` | Full cross-compilation guide |

### CI/CD Files

| File | Purpose |
|------|---------|
| `.github/workflows/ci.yml` | CI testing on push/PR |
| `.github/workflows/docker-release.yml` | Auto-build Docker images on release tags |
| `GITHUB_ACTIONS.md` | GitHub Actions setup guide |

---

## CI/CD with GitHub Actions

This project includes GitHub Actions workflows for automated builds:

### Automatic Releases on Tags

When you push a version tag (e.g., `v1.0.0`), GitHub Actions automatically:

1. Builds native and cross-compiler Docker images
2. Publishes them to Docker Hub or GHCR
3. Creates a GitHub Release with usage notes

```bash
# Trigger a release
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### Setup Required

See [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md) for complete setup:

1. Add `DOCKER_USERNAME` and `DOCKER_PASSWORD` secrets to your repository
2. Push a version tag to trigger the workflow

### Pre-built Images

If using official pre-built images:

```bash
# Pull latest
docker pull yourusername/cpp-builder:latest
docker pull yourusername/cpp-builder:cross
```

---

## Requirements

- Docker 20.10 or later
- Docker Compose 2.0 or later (optional)

---

## License

This project is provided as-is for building C++ projects.

---

## Contributing

To extend this builder:

1. **Add tools**: Edit `Dockerfile` (native) or `Dockerfile.cross` (cross-compiler)
2. **Update build logic**: Edit `entrypoint.sh` or `entrypoint-cross.sh`
3. **Add new architecture**: See [CROSS_COMPILE.md](CROSS_COMPILE.md#adding-new-architectures)
4. **Update documentation**: Keep README.md and CROSS_COMPILE.md in sync
