#!/bin/bash
set -e

echo "Setting up zenoh_dart for Linux..."

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Step 1 - flutter pub get
cd "$PROJECT_DIR"
flutter pub get

# Step 2 - download zenoh binaries
cd ~/.pub-cache/hosted/pub.dev/zenoh_dart-0.2.0
dart run tool/fetch_zenoh_binaries.dart

# Step 3 - extract the zip
cd native/linux/x86_64
unzip -o "zenoh-c-1.6.2-x86_64-unknown-linux-gnu-standalone.zip"

# Step 4 - create missing linux/CMakeLists.txt with correct path
mkdir -p ~/.pub-cache/hosted/pub.dev/zenoh_dart-0.2.0/linux
cat > ~/.pub-cache/hosted/pub.dev/zenoh_dart-0.2.0/linux/CMakeLists.txt << CMAKE
cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "zenoh_dart")
project(\${PROJECT_NAME} LANGUAGES C)
set(PLUGIN_NAME "zenoh_dart_plugin")
set(ZENOH_LIB "${PROJECT_DIR}/linux/libs/libzenohc.so")
add_library(\${PLUGIN_NAME} INTERFACE)
set(zenoh_dart_bundled_libraries "\${ZENOH_LIB}" PARENT_SCOPE)
CMAKE

# Step 5 - copy .so into project
mkdir -p "$PROJECT_DIR/linux/libs"
cp ~/.pub-cache/hosted/pub.dev/zenoh_dart-0.2.0/native/linux/x86_64/lib/libzenohc.so \
   "$PROJECT_DIR/linux/libs/"

echo "Done! Now run: flutter run"
