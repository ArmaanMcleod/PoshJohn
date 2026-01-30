cmake_minimum_required(VERSION 3.10)
project(repack7z_example)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add bit7z as a subdirectory (assumes bit7z is at ../../bit7z relative to this CMakeLists.txt)
add_subdirectory(${CMAKE_SOURCE_DIR}/../../bit7z ${CMAKE_BINARY_DIR}/bit7z)

# Source files
set(REPACK7Z_SOURCES repack7z.cpp)
set(REPACK7Z_MAIN repack7z_main.cpp)

# Executable (EXE)
add_executable(repack7z_app ${REPACK7Z_MAIN} ${REPACK7Z_SOURCES})
target_include_directories(repack7z_app PRIVATE
    ${CMAKE_SOURCE_DIR}/../../bit7z/include
)
target_link_libraries(repack7z_app PRIVATE bit7z)
set_target_properties(repack7z_app PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/dist
    OUTPUT_NAME repack7z
)

# Shared library (DLL) for native interop
add_library(repack7z_shared SHARED ${REPACK7Z_SOURCES})
target_include_directories(repack7z_shared PRIVATE
    ${CMAKE_SOURCE_DIR}/../../bit7z/include
)
target_link_libraries(repack7z_shared PRIVATE bit7z)
set_target_properties(repack7z_shared PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/dist
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/dist
)
