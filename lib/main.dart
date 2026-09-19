import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(App(cameras));
}

class App extends StatelessWidget {
  final List<CameraDescription> cameras;

  const App(this.cameras, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'กล้องสแกนพระและเหรียญ',
      theme: ThemeData(useMaterial3: true),
      home: HomePage(cameras),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomePage(this.cameras, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('กล้องสแกนพระและเหรียญ'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('เริ่มสแกน'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScanPage(cameras),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ScanPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScanPage(this.cameras, {super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? controller;
  bool ready = false;
  bool scanning = false;
  int frameCount = 0;

  @override
  void initState() {
    super.initState();
    startCamera();
  }

  Future<void> startCamera() async {
    if (widget.cameras.isEmpty) return;

    final camera = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller!.initialize();

    if (!mounted) return;

    setState(() {
      ready = true;
    });
  }

  Future<void> startScan() async {
    if (controller == null ||
        !controller!.value.isInitialized ||
        controller!.value.isStreamingImages) {
      return;
    }

    setState(() {
      scanning = true;
      frameCount = 0;
    });

    await controller!.startImageStream(
      (CameraImage image) {
        if (!scanning) return;

        frameCount++;

        if (frameCount % 10 == 0 && mounted) {
          setState(() {});
        }

        // ภาพใช้ชั่วคราวในหน่วยความจำ
        // ยังไม่มีการสร้างไฟล์และไม่มีการบันทึกรูป
      },
    );
  }

  Future<void> stopScan() async {
    if (controller != null &&
        controller!.value.isStreamingImages) {
      await controller!.stopImageStream();
    }

    if (!mounted) return;

    setState(() {
      scanning = false;
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ready || controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกนพระ'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                CameraPreview(controller!),

                if (scanning)
                  Positioned(
                    top: 15,
                    left: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.black54,
                      child: Text(
                        'กำลังรับภาพชั่วคราว\n'
                        'เฟรม: $frameCount\n'
                        'ยังไม่มีการบันทึกรูป',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text(
                  'ภาพจากกล้องใช้ชั่วคราวในหน่วยความจำ\n'
                  'ไม่มีการสร้างไฟล์รูปพระ',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                ElevatedButton.icon(
                  icon: Icon(
                    scanning ? Icons.stop : Icons.camera,
                  ),
                  label: Text(
                    scanning ? 'หยุดสแกน' : 'เริ่มรับภาพ',
                  ),
                  onPressed: scanning
                      ? stopScan
                      : startScan,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
