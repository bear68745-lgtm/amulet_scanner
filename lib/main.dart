import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(AmuletScannerApp(cameras: cameras));
}

class AmuletScannerApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const AmuletScannerApp({
    super.key,
    required this.cameras,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Amulet Scanner',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: ScanHomePage(cameras: cameras),
    );
  }
}

class ScanHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScanHomePage({
    super.key,
    required this.cameras,
  });

  @override
  State<ScanHomePage> createState() => _ScanHomePageState();
}

class _ScanHomePageState extends State<ScanHomePage> {
  CameraController? controller;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    if (widget.cameras.isEmpty) return;

    controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller!.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _scanAmulet() async {
    if (controller == null ||
        !controller!.value.isInitialized ||
        isScanning) {
      return;
    }

    setState(() {
      isScanning = true;
    });

    try {
      // ถ่ายภาพเพื่อใช้ในกระบวนการวิเคราะห์ชั่วคราว
      // ไม่มีการบันทึกภาพไว้ในแกลเลอรี
      await controller!.takePicture();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'เริ่มสแกนแล้ว กำลังวิเคราะห์พระ...',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่สามารถเริ่มสแกนได้: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null ||
        !controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'เครื่องสแกนพระและเหรียญ',
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(controller!),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ภาพจากกล้องใช้เพื่อวิเคราะห์ชั่วคราว\n'
                    'ระบบจะไม่บันทึกรูปภาพ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        isScanning ? null : _scanAmulet,
                    child: Text(
                      isScanning
                          ? 'กำลังสแกน...'
                          : 'เริ่มสแกน',
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
