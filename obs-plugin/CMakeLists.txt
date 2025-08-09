cmake_minimum_required(VERSION 3.16...3.25)

project(stream-relay-plugin VERSION 1.0.0)
add_library(stream-relay-plugin MODULE)

# Set C++ standard
set_property(TARGET stream-relay-plugin PROPERTY CXX_STANDARD 17)
set_property(TARGET stream-relay-plugin PROPERTY CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(libobs REQUIRED)
find_package(obs-frontend-api REQUIRED)
find_package(Qt6 REQUIRED COMPONENTS Core Widgets)

# Enable Qt MOC
set_target_properties(stream-relay-plugin PROPERTIES AUTOMOC ON)
set_target_properties(stream-relay-plugin PROPERTIES AUTOUIC ON)
set_target_properties(stream-relay-plugin PROPERTIES AUTORCC ON)

# Add compiler definitions for proper compilation
target_compile_definitions(stream-relay-plugin PRIVATE
    OBS_STUDIO_BUILD
    QT_WIDGETS_LIB
    $<$<PLATFORM_ID:Windows>:WINDOWS_SDK_AVAILABLE>
)

# Add source files
target_sources(stream-relay-plugin PRIVATE
    stream-relay-plugin.cpp
)

# Link libraries
target_link_libraries(stream-relay-plugin
    OBS::libobs
    OBS::obs-frontend-api
    Qt6::Core
    Qt6::Widgets
)

# Set plugin properties
set_target_properties(stream-relay-plugin PROPERTIES
    FOLDER "plugins"
    PREFIX ""
)

# Platform-specific settings
if(OS_WINDOWS)
    set_target_properties(stream-relay-plugin PROPERTIES
        LINK_FLAGS "/SUBSYSTEM:WINDOWS"
    )
elseif(OS_MACOS)
    set_target_properties(stream-relay-plugin PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in"
    )
endif()

# Install plugin
setup_plugin_target(stream-relay-plugin)

# Copy additional files
if(OS_WINDOWS)
    # Copy nginx and ffmpeg binaries for Windows
    install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin/"
        DESTINATION "$<TARGET_FILE_DIR:stream-relay-plugin>/stream-relay-data/"
        FILES_MATCHING
        PATTERN "*.exe"
        PATTERN "*.dll"
    )
elseif(OS_LINUX)
    # Copy nginx and ffmpeg binaries for Linux
    install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin/"
        DESTINATION "$<TARGET_FILE_DIR:stream-relay-plugin>/stream-relay-data/"
        FILES_MATCHING
        PATTERN "nginx"
        PATTERN "ffmpeg"
        PATTERN "*.so*"
    )
endif()

# Copy configuration templates
install(FILES
    "${CMAKE_CURRENT_SOURCE_DIR}/data/nginx.conf.template"
    "${CMAKE_CURRENT_SOURCE_DIR}/data/README.txt"
    DESTINATION "$<TARGET_FILE_DIR:stream-relay-plugin>/stream-relay-data/"
)

# Set version info
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/plugin-macros.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/plugin-macros.h"
)

target_include_directories(stream-relay-plugin PRIVATE
    "${CMAKE_CURRENT_BINARY_DIR}"
)

# Add compiler definitions
target_compile_definitions(stream-relay-plugin PRIVATE
    PLUGIN_VERSION="${PROJECT_VERSION}"
    $<$<CONFIG:Debug>:DEBUG_BUILD>
)

# Enable warnings
if(MSVC)
    target_compile_options(stream-relay-plugin PRIVATE /W3)
else()
    target_compile_options(stream-relay-plugin PRIVATE -Wall -Wextra)
endif()

# Create package
if(ENABLE_PACKAGE)
    set(CPACK_PACKAGE_NAME "StreamRelay-OBS-Plugin")
    set(CPACK_PACKAGE_VENDOR "StreamRelay")
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Multi-Platform Streaming Plugin for OBS Studio")
    set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
    set(CPACK_PACKAGE_INSTALL_DIRECTORY "StreamRelay")
    
    if(OS_WINDOWS)
        set(CPACK_GENERATOR "NSIS")
        set(CPACK_NSIS_DISPLAY_NAME "StreamRelay OBS Plugin")
        set(CPACK_NSIS_PACKAGE_NAME "StreamRelay OBS Plugin")
        set(CPACK_NSIS_URL_INFO_ABOUT "https://github.com/streamrelay/obs-plugin")
        set(CPACK_NSIS_HELP_LINK "https://github.com/streamrelay/obs-plugin/wiki")
        set(CPACK_NSIS_CONTACT "support@streamrelay.com")
        set(CPACK_NSIS_MODIFY_PATH ON)
    elseif(OS_MACOS)
        set(CPACK_GENERATOR "DragNDrop")
        set(CPACK_DMG_VOLUME_NAME "StreamRelay OBS Plugin")
        set(CPACK_DMG_FORMAT "UDZO")
    elseif(OS_LINUX)
        set(CPACK_GENERATOR "DEB;RPM")
        set(CPACK_DEBIAN_PACKAGE_MAINTAINER "StreamRelay <support@streamrelay.com>")
        set(CPACK_DEBIAN_PACKAGE_DEPENDS "obs-studio (>= 28.0)")
        set(CPACK_RPM_PACKAGE_LICENSE "GPL-2.0")
        set(CPACK_RPM_PACKAGE_REQUIRES "obs-studio >= 28.0")
    endif()
    
    include(CPack)
endif()

# Development helpers
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    # Add debug symbols
    target_compile_options(stream-relay-plugin PRIVATE
        $<$<CXX_COMPILER_ID:MSVC>:/Zi>
        $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-g>
    )
    
    # Enable runtime checks
    if(MSVC)
        target_compile_options(stream-relay-plugin PRIVATE /RTC1)
    endif()
endif()

# Documentation
find_package(Doxygen)
if(DOXYGEN_FOUND)
    set(DOXYGEN_IN ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in)
    set(DOXYGEN_OUT ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)
    
    configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)
    
    add_custom_target(doc_stream_relay_plugin ALL
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Generating API documentation with Doxygen"
        VERBATIM
    )
endif()

# Testing
if(BUILD_TESTING)
    enable_testing()
    
    # Add unit tests here if needed
    # add_subdirectory(tests)
endif()

# Print build information
message(STATUS "StreamRelay Plugin Configuration:")
message(STATUS "  Version: ${PROJECT_VERSION}")
message(STATUS "  Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Qt Version: ${Qt6_VERSION}")
message(STATUS "  OBS Version: ${libobs_VERSION}")
message(STATUS "  Install Directory: ${CMAKE_INSTALL_PREFIX}")

# Validation
if(NOT TARGET OBS::libobs)
    message(FATAL_ERROR "OBS Studio development files not found. Please install OBS Studio development package.")
endif()

if(NOT TARGET Qt6::Core)
    message(FATAL_ERROR "Qt6 not found. Please install Qt6 development package.")
endif()