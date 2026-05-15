# flutter_cluster
A cluster implementation for robo-taxi

## Prerequisites

### zenoh-c 1.9.0
This app communicates with Autoware via zenoh-c. Install it once:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env


git clone https://github.com/eclipse-zenoh/zenoh-c.git
cd zenoh-c && git checkout 1.9.0
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
sudo cmake --build . --target install


Then build and run normally:
```bash
flutter pub get
flutter run
```

