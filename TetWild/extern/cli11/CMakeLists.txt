cmake_minimum_required(VERSION 3.4...3.11)

if(${CMAKE_VERSION} VERSION_LESS 3.12)
    cmake_policy(VERSION ${CMAKE_VERSION})
endif()

set(VERSION_REGEX "#define CLI11_VERSION[ \t]+\"(.+)\"")

# Read in the line containing the version
file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/include/CLI/Version.hpp"
    VERSION_STRING REGEX ${VERSION_REGEX})

# Pick out just the version
string(REGEX REPLACE ${VERSION_REGEX} "\\1" VERSION_STRING "${VERSION_STRING}")

project(CLI11 LANGUAGES CXX VERSION ${VERSION_STRING})

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})

# Only if built as the main project
if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
    # User settable
    set(CLI11_CXX_STD "11"  CACHE STRING "The CMake standard to require")

    set(CUR_PROJ ON)
    set(CMAKE_CXX_STANDARD ${CLI11_CXX_STD})
    set(CMAKE_CXX_EXTENSIONS OFF)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)

    # Be moderately paranoid with flags
    if(MSVC)
        add_definitions("/W4")
    else()
        add_definitions(-Wall -Wextra -pedantic)
    endif()

    if(CMAKE_VERSION VERSION_GREATER 3.6)
        # Add clang-tidy if available
        option(CLANG_TIDY_FIX "Perform fixes for Clang-Tidy" OFF)
        find_program(
            CLANG_TIDY_EXE
            NAMES "clang-tidy"
            DOC "Path to clang-tidy executable"
        )

        if(CLANG_TIDY_EXE)
            if(CLANG_TIDY_FIX)
                set(DO_CLANG_TIDY "${CLANG_TIDY_EXE}" "-fix")
            else()
                set(DO_CLANG_TIDY "${CLANG_TIDY_EXE}")
            endif()
        endif()
    endif()
else()
    set(CUR_PROJ OFF)
endif()

# Allow dependent options
include(CMakeDependentOption)

# Allow IDE's to group targets into folders
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

file(GLOB CLI11_headers "${CMAKE_CURRENT_SOURCE_DIR}/include/CLI/*")
# To see in IDE, must be listed for target

add_library(CLI11 INTERFACE)

# Duplicated because CMake adds the current source dir if you don't.
target_include_directories(CLI11 INTERFACE
     $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
     $<INSTALL_INTERFACE:include>)

# Make add_subdirectory work like find_package
add_library(CLI11::CLI11 ALIAS CLI11)

# This folder should be installed
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/CLI DESTINATION include)

# Use find_package on the installed package
# Since we have no custom code, we can directly write this
# to Config.cmake (otherwise we'd have a custom config and would
# import Targets.cmake

# Add the version in a CMake readable way
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    CLI11ConfigVersion.cmake
    VERSION ${CLI11_VERSION}
    COMPATIBILITY AnyNewerVersion
    )

# Make version available in the install
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/CLI11ConfigVersion.cmake"
        DESTINATION lib/cmake/CLI11)

# Make an export target
install(TARGETS CLI11
        EXPORT CLI11Targets)

# Install the export target as a file
install(EXPORT CLI11Targets
        FILE CLI11Config.cmake
        NAMESPACE CLI11::
        DESTINATION lib/cmake/CLI11)

# Use find_package on the installed package
export(TARGETS CLI11
       NAMESPACE CLI11::
       FILE CLI11Targets.cmake)

# Register in the user cmake package registry
export(PACKAGE CLI11)

option(CLI11_SINGLE_FILE "Generate a single header file" OFF)

if(CLI11_SINGLE_FILE)
# Single file test
    if(CMAKE_VERSION VERSION_LESS 3.12)
        find_package(PythonInterp REQUIRED)
        set(Python_VERSION ${PYTHON_VERSION_STRING})
        set(Python_EXECUTABLE "${PYTHON_EXECUTABLE}")
    else()
        find_package(Python REQUIRED)
    endif()

    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include")
    add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/include/CLI11.hpp"
        COMMAND "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/scripts/MakeSingleHeader.py" "${CMAKE_CURRENT_BINARY_DIR}/include/CLI11.hpp"
        DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/include/CLI/CLI.hpp" ${CLI11_headers}
        )
    add_custom_target(generate_cli_single_file ALL
        DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/include/CLI11.hpp")
    set_target_properties(generate_cli_single_file
                          PROPERTIES FOLDER "Scripts")
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/CLI11.hpp DESTINATION include)
    add_library(CLI11_SINGLE INTERFACE)
    target_link_libraries(CLI11_SINGLE INTERFACE CLI11)
    add_dependencies(CLI11_SINGLE generate_cli_single_file)
    target_compile_definitions(CLI11_SINGLE INTERFACE -DCLI11_SINGLE_FILE)
    target_include_directories(CLI11_SINGLE INTERFACE "${CMAKE_CURRENT_BINARY_DIR}/include/")
endif()

cmake_dependent_option(CLI11_SINGLE_FILE_TESTS "Duplicate all the tests for a single file build" OFF "CLI11_SINGLE_FILE" OFF)

cmake_dependent_option(CLI11_TESTING "Build the tests and add them" ON "CUR_PROJ" OFF)
if(CLI11_TESTING)
    enable_testing()
    add_subdirectory(tests)
endif()

cmake_dependent_option(CLI11_EXAMPLES "Build the examples" ON "CUR_PROJ" OFF)
if(CLI11_EXAMPLES)
    add_subdirectory(examples)
endif()

# Packaging support
set(CPACK_PACKAGE_VENDOR "github.com/CLIUtils/CLI11")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Command line interface")
set(CPACK_PACKAGE_VERSION_MAJOR ${CLI11_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${CLI11_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${CLI11_VERSION_PATCH})
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
set(CPACK_SOURCE_GENERATOR "TGZ;ZIP")
# CPack collects *everything* except what's listed here.
set(CPACK_SOURCE_IGNORE_FILES
    /.git
    /dist
    /.*build.*
    /\\\\.DS_Store
    /.*\\\\.egg-info
    /var
    /Pipfile.*$
)
include(CPack)

