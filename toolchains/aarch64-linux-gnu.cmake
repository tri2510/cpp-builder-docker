# CMake Toolchain File for ARM64 (aarch64) Cross-Compilation
# Target: 64-bit ARM (Raspberry Pi 4, AWS Graviton, etc.)
# Usage: cmake -DCMAKE_TOOLCHAIN_FILE=/opt/cmake-toolchains/aarch64-linux-gnu.cmake

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Cross-compilation settings
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

# Don't run test programs during configuration
set(CMAKE_CROSSCOMPILING TRUE)

# Sysroot for ARM64
set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Additional flags for ARM64
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=armv8-a")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv8-a")
