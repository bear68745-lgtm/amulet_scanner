
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'pages/home_page.dart';

import 'pages/menu/create_reference_page.dart';
import 'pages/menu/model_page.dart';

// =====================================================
// MAIN
// =====================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> cameras = [];

  try {
    cameras = await availableCameras();
  } catch (_) {}

  runApp(
    App(cameras),
  );
}

// =====================================================
// APP
// =====================================================

class App extends StatelessWidget {
  final List<CameraDescription> cameras;

  const App(
    this.cameras, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'กล้องสแกนพระและเหรียญ',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
        ),
        useMaterial3: true,
      ),

      home: HomePage(
        cameras: cameras,

        createReferencePageBuilder: () {
          return CreateReferencePage(
            cameras: cameras,
          );
        },

        modelPageBuilder: (group) {
          return ModelPage(
            cameras: cameras,
            group: group,
          );
        },
      ),
    );
  }
}
