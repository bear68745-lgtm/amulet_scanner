import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(
    AmuletScannerApp(cameras: cameras),
  );
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
      home: MainMenuPage(cameras: cameras),
    );
  }
}

// ======================================================
// สถานะการสแกน
// ======================================================

class ScanState {
  bool isScanning = false;
  int currentStep = 0;

  final List<String> steps = [
    'ด้านหน้า',
    'ด้านข้าง',
    'ด้านหลัง',
    'ก้นพระ',
  ];

  void start() {
    isScanning = true;
    currentStep = 0;
  }

  void next() {
    if (currentStep < steps.length - 1) {
      currentStep++;
    }
  }

  void finish() {
    isScanning = false;
  }

  void reset() {
    isScanning = false;
    currentStep = 0;
  }
}

// ======================================================
// หน้าเมนูหลัก
// ======================================================

class MainMenuPage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MainMenuPage({
    super.key,
    required this.cameras,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ส่องพระ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.center_focus_strong,
              size: 80,
            ),

            const SizedBox(height: 20),

            const Text(
              'กล้องสแกนพระและเหรียญ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 35),

            _menuButton(
              context,
              Icons.camera_alt,
              'เริ่มสแกนพระ',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanPage(
                      cameras: cameras,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            _menuButton(
              context,
              Icons.image,
              'สแกนภาพบนหน้าจอ',
              () {
                _message(
                  context,
                  'ฟังก์ชันสแกนภาพบนหน้าจอจะเพิ่มในขั้นต่อไป',
                );
              },
            ),

            const SizedBox(height: 15),

            _menuButton(
              context,
              Icons.edit_note,
              'สร้างข้อมูลพระ',
              () {
                _message(
                  context,
                  'หน้าสร้างข้อมูลพระจะเพิ่มในขั้นต่อไป',
                );
              },
            ),

            const SizedBox(height: 15),

            _menuButton(
              context,
              Icons.menu_book,
              'ฐานข้อมูลพระ',
              () {
                _message(
                  context,
                  'ฐานข้อมูลพระจะเพิ่มในขั้นต่อไป',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(
    BuildContext context,
    IconData icon,
    String text,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 28,
        ),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _message(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

// ======================================================
// หน้าสแกน
// ======================================================

class ScanPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScanPage({
    super.key,
    required this.cameras,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? controller;

  // เก็บสถานะไว้ตลอดเวลาที่อยู่ในหน้าสแกน
  final ScanState scanState = ScanState();

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    if (widget.cameras.isEmpty) {
      return;
    }

    controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller!.initialize();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _startScan() {
    setState(() {
      scanState.start();
    });
  }

  void _nextStep() {
    setState(() {
      scanState.next();
    });
  }

  void _finishScan() {
    setState(() {
      scanState.finish();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'จบการสแกนแล้ว',
        ),
      ),
    );
  }

  void _skipBottom() {
    setState(() {
      scanState.finish();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'ข้ามการสแกนก้นพระแล้ว',
        ),
      ),
    );
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller!),

          // ============================================
          // ปุ่ม 3 ขีดที่เด่นชัด
          // ============================================

          Positioned(
            top: 35,
            left: 15,
            child: SafeArea(
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.80),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: IconButton(
                  iconSize: 36,
                  color: Colors.white,
                  tooltip: 'เมนู',
                  icon: const Icon(
                    Icons.menu,
                  ),
                  onPressed: _openMenu,
                ),
              ),
            ),
          ),

          // ============================================
          // กรอบสแกน
          // ============================================

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

          // ============================================
          // สถานะการสแกน
          // ============================================

          Positioned(
            top: 45,
            left: 90,
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
                    scanState.isScanning
                        ? 'กำลังสแกน: '
                          '${scanState.steps[scanState.currentStep]}'
                        : 'พร้อมส่องพระ',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (scanState.isScanning)
                    Text(
                      '${scanState.currentStep + 1} / '
                      '${scanState.steps.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ============================================
          // ปุ่มด้านล่าง
          // ============================================

          Positioned(
            bottom: 25,
            left: 15,
            right: 15,
            child: Column(
              children: [
                if (!scanState.isScanning)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(
                        Icons.center_focus_strong,
                      ),
                      label: const Text(
                        'เริ่มสแกน',
                      ),
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          scanState.currentStep ==
                                  scanState.steps.length - 1
                              ? _finishScan
                              : _nextStep,
                      child: Text(
                        scanState.currentStep ==
                                scanState.steps.length - 1
                            ? 'เสร็จสิ้น'
                            : 'มุมนี้พร้อมแล้ว →',
                      ),
                    ),
                  ),

                  if (scanState.currentStep == 3)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _skipBottom,
                        child: const Text(
                          'องค์นี้ไม่มีก้นพระ / ข้าม',
                        ),
                      ),
                    ),
                ],

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

  // ====================================================
  // เมนูระหว่างสแกน
  // ====================================================

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      builder: (menuContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                ),
                title: const Text(
                  'กลับไปสแกน',
                ),
                onTap: () {
                  Navigator.pop(menuContext);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.image,
                ),
                title: const Text(
                  'สแกนภาพบนหน้าจอ',
                ),
                onTap: () {
                  Navigator.pop(menuContext);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'ฟังก์ชันนี้จะเพิ่มในขั้นต่อไป',
                      ),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.edit_note,
                ),
                title: const Text(
                  'สร้าง / แก้ไขข้อมูลพระ',
                ),
                onTap: () {
                  Navigator.pop(menuContext);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'หน้าข้อมูลพระจะเพิ่มในขั้นต่อไป',
                      ),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.menu_book,
                ),
                title: const Text(
                  'ฐานข้อมูลพระ',
                ),
                onTap: () {
                  Navigator.pop(menuContext);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'ฐานข้อมูลจะเพิ่มในขั้นต่อไป',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
