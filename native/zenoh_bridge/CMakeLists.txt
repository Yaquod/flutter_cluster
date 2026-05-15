cmake_minimum_required(VERSION 3.16)
project(cluster_bridge C)

# zenoh-c is installed at /usr/local — cmake config is there
find_package(zenohc REQUIRED)

set(DART_SDK "/home/alaa-hassan/flutter/bin/cache/dart-sdk")


add_library(cluster_bridge SHARED
    src/cluster_bridge.c
    src/dart_api_dl.c
)

target_include_directories(cluster_bridge PRIVATE
    include   # dart_api_dl.h
     ${DART_SDK}/include     
)

target_link_libraries(cluster_bridge PRIVATE zenohc::lib)

set_target_properties(cluster_bridge PROPERTIES
    OUTPUT_NAME "cluster_bridge"
    PREFIX      "lib"
)
