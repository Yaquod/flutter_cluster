cmake_minimum_required(VERSION 3.16)
project(cluster_bridge C)

# zenoh-c — found via find_package (sysroot in Yocto, /usr/local on host)
find_package(zenohc REQUIRED)

# DART_SDK: pass via -DDART_SDK=<path> or set env FLUTTER_ROOT
if(NOT DART_SDK)
  if(DEFINED ENV{DART_SDK})
    set(DART_SDK "$ENV{DART_SDK}")
  elseif(DEFINED ENV{FLUTTER_ROOT})
    set(DART_SDK "$ENV{FLUTTER_ROOT}/bin/cache/dart-sdk")
  elseif(DEFINED ENV{HOME})
    set(DART_SDK "$ENV{HOME}/flutter/bin/cache/dart-sdk")
  else()
    message(FATAL_ERROR "DART_SDK not set. Pass -DDART_SDK=<path>")
  endif()
endif()
message(STATUS "DART_SDK = ${DART_SDK}")

add_library(cluster_bridge SHARED
    src/cluster_bridge.c
    src/dart_api_dl.c
)

target_include_directories(cluster_bridge PRIVATE
    include
    ${DART_SDK}/include
)

target_link_libraries(cluster_bridge PRIVATE zenohc::lib)

set_target_properties(cluster_bridge PROPERTIES
    OUTPUT_NAME "cluster_bridge"
    PREFIX      "lib"
)
