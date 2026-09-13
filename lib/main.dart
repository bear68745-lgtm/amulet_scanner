
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
      title: 'ส่องพระ',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.brown,
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
  int currentStep = 0;

  final List<String> scanSteps = [
    'ด้านหน้า',
    'ด้านข้าง',
    'ด้านหลัง',
    'ก้นพระ',
  ];

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

    if (!mounted) return;

    setState(() {});
  }

  void _startScan() {
    setState(() {
      isScanning = true;
      currentStep = 0;
    });
  }

  void _nextStep() {
    if (currentStep < scanSteps.length - 1) {
      setState(() {
        currentStep++;
      });
    } else {
      _finishScan();
    }
  }

  void _skipBottom() {
    if (currentStep == 3) {
      _finishScan();
    }
  }

  void _finishScan() {
    setState(() {
      isScanning = false;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ตรวจสอบเบื้องต้นเสร็จแล้ว'),
          content: const Text(
            'ข้อมูลภาพที่ใช้ตรวจสอบจะไม่ถูกบันทึกเป็นรูปภาพลงเครื่อง',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller!),

          // กรอบสำหรับวางองค์พระ
          Center(
            child: Container(
              width: 270,
              height: 360,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // ข้อความด้านบน
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.70),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    isScanning
                        ? 'กำลังสแกน: ${scanSteps[currentStep]}'
                        : 'พร้อมส่องพระ',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isScanning)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${currentStep + 1} / ${scanSteps.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ปุ่มด้านล่าง
          Positioned(
            bottom: 30,
            left: 15,
            right: 15,
            child: Column(
              children: [
                if (isScanning) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      child: Text(
                        currentStep == scanSteps.length - 1
                            ? 'เสร็จสิ้น'
                            : 'มุมนี้พร้อมแล้ว →',
                      ),
                    ),
                  ),

                  if (currentStep == 3)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _skipBottom,
                        child: const Text(
                          'องค์นี้ไม่มีก้นพระ / ข้าม',
                        ),
                      ),
                    ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(
                        Icons.center_focus_strong,
                      ),
                      label: const Text('เริ่มสแกน'),
                    ),
                  ),

                const SizedBox(height: 8),

                const Text(
                  'ระบบไม่บันทึกรูปพระ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        offset: Offset(1, 1),
                      ),
                    ],
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
