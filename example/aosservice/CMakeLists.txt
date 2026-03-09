cmake_minimum_required(VERSION 3.15)
project(AosEdgeAgent VERSION 1.0.0 LANGUAGES CXX)

# C++20 for better JSON/std::format support
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Compiler warnings
if(MSVC)
    add_compile_options(/W4 /utf-8)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# AosEdge Agent executable
add_executable(aos-agent
    src/main.cpp
    src/agent.cpp
    src/unit_info.cpp
)

# Include directories
target_include_directories(aos-agent PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# Installation - install to /bin (not /usr/local/bin)
install(TARGETS aos-agent DESTINATION .)
