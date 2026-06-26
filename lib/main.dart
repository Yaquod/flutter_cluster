// import 'package:flutter/material.dart';
// import 'package:flutter_cluster/screen/cluster_screen.dart';
// import '../proto/vehicle_frame.pb.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//   final emptyFrame = VehicleFrame();

//     return MaterialApp(
//       home: Scaffold(
//         backgroundColor: Colors.black,
//         body: ClusterView(frame: emptyFrame ), 
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:flutter_cluster/screen/cluster_screen.dart';
// import 'package:provider/provider.dart';
// import 'services/cluster_client.dart';
// import 'provider/cluster_provider.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final client = ClusterClient(keyExpr: 'autoware/cluster');

//   runApp(
//     ChangeNotifierProvider(
//       create: (_) => VehicleFrameNotifier(client),
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Vehicle Cluster',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData.dark(),
//       home: const ClusterScreen(),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter_cluster/screen/cluster_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/cluster_client.dart';
import 'provider/cluster_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env', isOptional: true);

  final locator  = dotenv.env['ZENOH_LOCATOR'] ?? 'udp/127.0.0.1:7447';
  final keyExpr  = dotenv.env['ZENOH_KEY_EXPR'] ?? 'autoware/cluster';
  final libPath  = dotenv.env['ZENOH_LIBRARY_PATH'] ?? 'libcluster_bridge.so';

  final client = ClusterClient(
    locator: locator,
    keyExpr: keyExpr,
    libraryPath: libPath,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => VehicleFrameNotifier(client),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Cluster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const ClusterScreen(),
    );
  }
}