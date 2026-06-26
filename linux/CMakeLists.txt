# Project-level configuration.
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX C)

set(BINARY_NAME "flutter_cluster")
set(APPLICATION_ID "com.example.flutter_cluster")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Profile" "Release")
endif()

function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

# ── Zenoh bridge ──────────────────────────────────────────────────────────────
set(BRIDGE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../native/zenoh_bridge")

# Find zenoh-c
# For Yocto cross-compilation, set -DCMAKE_PREFIX_PATH=<sysroot>/usr
find_package(zenohc REQUIRED)

# Determine DART_SDK path
# Order of precedence:
#   1. -DDART_SDK=<path>  (CMake cache variable, set manually or by Yocto toolchain)
#   2. $ENV{DART_SDK}     (environment variable)
#   3. $ENV{FLUTTER_ROOT}/bin/cache/dart-sdk
#   4. $ENV{HOME}/flutter/bin/cache/dart-sdk  (common dev setup fallback)
if(NOT DART_SDK)
  if(DEFINED ENV{DART_SDK})
    set(DART_SDK "$ENV{DART_SDK}")
  elseif(DEFINED ENV{FLUTTER_ROOT})
    set(DART_SDK "$ENV{FLUTTER_ROOT}/bin/cache/dart-sdk")
  elseif(DEFINED ENV{HOME})
    set(DART_SDK "$ENV{HOME}/flutter/bin/cache/dart-sdk")
  else()
    message(FATAL_ERROR
      "DART_SDK not set. Pass -DDART_SDK=<path> to cmake or "
      "set FLUTTER_ROOT environment variable."
    )
  endif()
endif()
message(STATUS "[bridge] DART_SDK = ${DART_SDK}")

# Find dart_api_dl files
find_file(DART_API_DL_H dart_api_dl.h
  PATHS
    "${DART_SDK}/include"
)
find_file(DART_API_DL_C dart_api_dl.c
  PATHS
    "${DART_SDK}/include"
)
if(NOT DART_API_DL_H OR NOT DART_API_DL_C)
  message(FATAL_ERROR
    "[bridge] dart_api_dl.h/c not found at ${DART_SDK}/include/. "
    "Set DART_SDK correctly."
  )
endif()
get_filename_component(DART_API_DL_DIR "${DART_API_DL_H}" DIRECTORY)

add_library(cluster_bridge SHARED
  "${BRIDGE_DIR}/src/cluster_bridge.c"
  "${DART_API_DL_C}"
)
target_include_directories(cluster_bridge PRIVATE
  "${BRIDGE_DIR}/include"
  "${DART_API_DL_DIR}"
)
target_link_libraries(cluster_bridge PRIVATE ${ZENOH_LIB})
set_target_properties(cluster_bridge PROPERTIES
  OUTPUT_NAME "cluster_bridge"
  PREFIX      "lib"
)
# ─────────────────────────────────────────────────────────────────────────────

add_subdirectory("runner")

add_dependencies(${BINARY_NAME} flutter_assemble)

set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)

include(flutter/generated_plugins.cmake)

# === Installation ===
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

# Install the zenoh bridge library
install(TARGETS cluster_bridge
  LIBRARY DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
  DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
