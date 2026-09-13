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
      home: HomePage(cameras: cameras),
    );
  }
}

// ===============================
// หน้าหลัก
// ===============================

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomePage({
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
              Icons.search,
              size: 80,
              color: Colors.brown,
            ),

            const SizedBox(height: 12),

            const Text(
              'เครื่องมือศึกษาพระและเหรียญ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // สแกนพระ
            _MenuButton(
              icon: Icons.camera_alt,
              title: 'สแกนพระ',
              subtitle: 'เปิดกล้องเพื่อสแกนและวิเคราะห์',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanHomePage(
                      cameras: cameras,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // ฐานข้อมูล
            _MenuButton(
              icon: Icons.menu_book,
              title: 'ฐานข้อมูลพระ',
              subtitle: 'ข้อมูลพระ รุ่น พิมพ์ เนื้อ และรายละเอียด',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DatabasePage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // โหมดคัดจากกอง
            _MenuButton(
              icon: Icons.center_focus_strong,
              title: 'โหมดคัดจากกอง',
              subtitle: 'เตรียมไว้สำหรับคัดพระจากกองจำนวนมาก',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PileScanPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // ตั้งค่า
            _MenuButton(
              icon: Icons.settings,
              title: 'ตั้งค่า',
              subtitle: 'การตั้งค่าของแอป',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================
// ปุ่มเมนู
// ===============================

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 42,
                  color: Colors.brown,
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================
// หน้าสแกนพระ
// ===============================

class ScanHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScanHomePage({
    super.key,
    required this.cameras,
  });

  @override
  State<ScanHomePage> createState() =>
      _ScanHomePageState();
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
        title: const Text('สแกนพระ'),
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
                    borderRadius:
                        BorderRadius.circular(12),
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

// ===============================
// ฐานข้อมูลพระ
// ===============================

class DatabasePage extends StatelessWidget {
  const DatabasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ฐานข้อมูลพระ'),
      ),
      body: const Center(
        child: Text(
          'หน้านี้จะใช้สร้างฐานข้อมูลพระ\n'
          'ชื่อ รุ่น พิมพ์ วัด ปี เนื้อ และรายละเอียดต่าง ๆ\n\n'
          'กำลังพัฒนา',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// ===============================
// โหมดคัดจากกอง
// ===============================

class PileScanPage extends StatelessWidget {
  const PileScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('โหมดคัดจากกอง'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'โหมดนี้เป็นเป้าหมายสำคัญของส่องพระ\n\n'
            'ในอนาคตจะใช้ช่วยคัดพระจากกองจำนวนมาก\n'
            'เช่น 100–200 องค์\n\n'
            'ระบบจะช่วยหาองค์ที่ควรหยิบมาตรวจต่อ\n\n'
            'กำลังพัฒนา',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

// ===============================
// ตั้งค่า
// ===============================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่า'),
      ),
      body: const Center(
        child: Text(
          'การตั้งค่า\n\nกำลังพัฒนา',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
