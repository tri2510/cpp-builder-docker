# C++ Builder Docker Image
# Base: Ubuntu 24.04 with CMake, GCC, and build tools
FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install build essentials, CMake, and common development tools
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    ninja-build \
    ccache \
    gdb \
    valgrind \
    cppcheck \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /project

# Default build script entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create directories for source and build
RUN mkdir -p /project/src /project/build /project/output

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
