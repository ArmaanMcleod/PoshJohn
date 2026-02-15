cmake_minimum_required(VERSION 3.10)

project(archive7z_example)

# Ensure all targets are built with -fPIC for shared library compatibility
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add bit7z as a subdirectory (assumes bit7z is at ../../bit7z relative to this CMakeLists.txt)
add_subdirectory(${CMAKE_SOURCE_DIR}/../../bit7z ${CMAKE_BINARY_DIR}/bit7z)

# Source files
set(ARCHIVE7Z_SOURCES archive7z.cpp)
set(ARCHIVE7Z_MAIN archive7z_main.cpp)

# Executable (EXE)
add_executable(archive7z_app ${ARCHIVE7Z_MAIN} ${ARCHIVE7Z_SOURCES})
target_include_directories(archive7z_app PRIVATE
    ${CMAKE_SOURCE_DIR}/../../bit7z/include
)
target_link_libraries(archive7z_app PRIVATE bit7z)
set_target_properties(archive7z_app PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/dist
    OUTPUT_NAME archive7z
)

# Shared library (DLL) for native interop
add_library(archive7z_shared SHARED ${ARCHIVE7Z_SOURCES})
target_include_directories(archive7z_shared PRIVATE
    ${CMAKE_SOURCE_DIR}/../../bit7z/include
)
target_link_libraries(archive7z_shared PRIVATE bit7z)

set_target_properties(archive7z_shared PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/dist
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/dist
)

# Statically link MinGW/MSYS2 runtime libraries if building with MinGW
if(MINGW)
    target_link_options(archive7z_shared PRIVATE -static-libgcc -static-libstdc++ -static)
endif()
