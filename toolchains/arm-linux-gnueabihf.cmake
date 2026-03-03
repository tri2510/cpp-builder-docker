# CMake Toolchain File for ARMv7 (armhf) Cross-Compilation
# Target: 32-bit ARM (Raspberry Pi 2/3, BeagleBone, etc.)
# Usage: cmake -DCMAKE_TOOLCHAIN_FILE=/opt/cmake-toolchains/arm-linux-gnueabihf.cmake

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Cross-compilation settings
set(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++)

# Don't run test programs during configuration
set(CMAKE_CROSSCOMPILING TRUE)

# Sysroot for ARMv7
set(CMAKE_FIND_ROOT_PATH /usr/arm-linux-gnueabihf)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Additional flags for ARMv7 with hardware floating point
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard")
