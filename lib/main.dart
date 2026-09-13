
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
      title: 'Amulet Scanner',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: MainMenuPage(cameras: cameras),
    );
  }
}

// =====================================================
// สถานะการสแกน
// =====================================================

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

// =====================================================
// ข้อมูลพระ
// =====================================================

class AmuletData {
  String name = '';
  String model = '';
  String type = '';
  String temple = '';
  String province = '';
  String year = '';
  String material = '';
  String size = '';
  String reference = '';

  String frontDetail = '';
  String sideDetail = '';
  String backDetail = '';
  String bottomDetail = '';

  String bottomStatus = 'ยังไม่ทราบ';
}

// =====================================================
// หน้าเมนูหลัก
// =====================================================

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
        title: const Text('กล้องสแกนพระและเหรียญ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.camera_alt,
              size: 80,
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                'ระบบสแกนพระและเหรียญ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                'ไม่บันทึกรูปพระ',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(height: 40),

            _menuButton(
              context,
              icon: Icons.camera_alt,
              title: 'เริ่มสแกนพระ',
              onTap: () {
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

            _menuButton(
              context,
              icon: Icons.image,
              title: 'สแกนภาพบนหน้าจอ',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ระบบสแกนภาพบนหน้าจอจะเพิ่มในขั้นต่อไป',
                    ),
                  ),
                );
              },
            ),

            _menuButton(
              context,
              icon: Icons.edit_note,
              title: 'สร้าง / แก้ไขข้อมูลพระ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AmuletDataPage(
                      data: AmuletData(),
                    ),
                  ),
                );
              },
            ),

            _menuButton(
              context,
              icon: Icons.storage,
              title: 'ฐานข้อมูลพระ',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ระบบฐานข้อมูลจะเพิ่มในขั้นต่อไป',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 60,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 28),
          label: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// หน้าสแกน
// =====================================================

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

  final ScanState scanState = ScanState();

  // ข้อมูลของพระองค์ที่กำลังสแกน
  final AmuletData amuletData = AmuletData();

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

    if (mounted) {
      setState(() {});
    }
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
  }

  void _skipBottom() {
    setState(() {
      scanState.finish();
    });
  }

  // เปิดหน้าข้อมูลโดยไม่ปิดหน้าสแกน
  Future<void> _openDataPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AmuletDataPage(
          data: amuletData,
        ),
      ),
    );

    // กลับมาแล้ว หน้าสแกนและสถานะเดิมยังอยู่
    if (mounted) {
      setState(() {});
    }
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('กลับไปสแกน'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('สแกนภาพบนหน้าจอ'),
                onTap: () {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'ระบบสแกนภาพบนหน้าจอจะเพิ่มในขั้นต่อไป',
                      ),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('สร้าง / แก้ไขข้อมูลพระ'),
                onTap: () {
                  Navigator.pop(context);
                  _openDataPage();
                },
              ),

              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('ฐานข้อมูลพระ'),
                onTap: () {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'ระบบฐานข้อมูลจะเพิ่มในขั้นต่อไป',
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

    final currentStep =
        scanState.steps[scanState.currentStep];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(controller!),
          ),

          // =================================================
          // ปุ่ม 3 ขีด
          // =================================================

          Positioned(
            top: 35,
            left: 15,
            child: Material(
              color: Colors.black.withOpacity(0.65),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _openMenu,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
          ),

          // =================================================
          // สถานะด้านบน
          // =================================================

          Positioned(
            top: 45,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                scanState.isScanning
                    ? 'กำลังสแกน: $currentStep'
                    : 'พร้อมสแกน',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // =================================================
          // กรอบสแกน
          // =================================================

          Center(
            child: Container(
              width: 260,
              height: 340,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // =================================================
          // ปุ่มด้านล่าง
          // =================================================

          Positioned(
            left: 15,
            right: 15,
            bottom: 25,
            child: Column(
              children: [
                if (!scanState.isScanning)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _startScan,
                      child: const Text(
                        'เริ่มสแกน',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),

                if (scanState.isScanning) ...[
                  Text(
                    'กำลังตรวจ: $currentStep',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 5,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      if (scanState.currentStep < 3)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _nextStep,
                            child: const Text(
                              'ไปด้านต่อไป',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),

                      if (scanState.currentStep == 3) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _finishScan,
                            child: const Text(
                              'เสร็จสิ้น',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(width: 10),

                      if (scanState.currentStep == 3)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _skipBottom,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white,
                              ),
                            ),
                            child: const Text(
                              'ไม่มี / ข้าม',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),

                const Text(
                  'ระบบไม่บันทึกรูปพระ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    shadows: [
                      Shadow(
                        blurRadius: 5,
                        color: Colors.black,
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

// =====================================================
// หน้าสร้าง / แก้ไขข้อมูลพระ
// =====================================================

class AmuletDataPage extends StatefulWidget {
  final AmuletData data;

  const AmuletDataPage({
    super.key,
    required this.data,
  });

  @override
  State<AmuletDataPage> createState() =>
      _AmuletDataPageState();
}

class _AmuletDataPageState extends State<AmuletDataPage> {
  late final TextEditingController nameController;
  late final TextEditingController modelController;
  late final TextEditingController typeController;
  late final TextEditingController templeController;
  late final TextEditingController provinceController;
  late final TextEditingController yearController;
  late final TextEditingController materialController;
  late final TextEditingController sizeController;
  late final TextEditingController referenceController;

  late final TextEditingController frontController;
  late final TextEditingController sideController;
  late final TextEditingController backController;
  late final TextEditingController bottomController;

  @override
  void initState() {
    super.initState();

    final data = widget.data;

    nameController =
        TextEditingController(text: data.name);
    modelController =
        TextEditingController(text: data.model);
    typeController =
        TextEditingController(text: data.type);
    templeController =
        TextEditingController(text: data.temple);
    provinceController =
        TextEditingController(text: data.province);
    yearController =
        TextEditingController(text: data.year);
    materialController =
        TextEditingController(text: data.material);
    sizeController =
        TextEditingController(text: data.size);
    referenceController =
        TextEditingController(text: data.reference);

    frontController =
        TextEditingController(text: data.frontDetail);
    sideController =
        TextEditingController(text: data.sideDetail);
    backController =
        TextEditingController(text: data.backDetail);
    bottomController =
        TextEditingController(text: data.bottomDetail);
  }

  void _saveData() {
    final data = widget.data;

    data.name = nameController.text;
    data.model = modelController.text;
    data.type = typeController.text;
    data.temple = templeController.text;
    data.province = provinceController.text;
    data.year = yearController.text;
    data.material = materialController.text;
    data.size = sizeController.text;
    data.reference = referenceController.text;

    data.frontDetail = frontController.text;
    data.sideDetail = sideController.text;
    data.backDetail = backController.text;
    data.bottomDetail = bottomController.text;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('บันทึกข้อมูลในรายการสแกนแล้ว'),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    modelController.dispose();
    typeController.dispose();
    templeController.dispose();
    provinceController.dispose();
    yearController.dispose();
    materialController.dispose();
    sizeController.dispose();
    referenceController.dispose();

    frontController.dispose();
    sideController.dispose();
    backController.dispose();
    bottomController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้าง / แก้ไขข้อมูลพระ'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(
            'ชื่อพระ',
            nameController,
          ),

          _field(
            'รุ่น',
            modelController,
          ),

          _field(
            'พิมพ์',
            typeController,
          ),

          _field(
            'วัด / สำนัก',
            templeController,
          ),

          _field(
            'จังหวัด',
            provinceController,
          ),

          _field(
            'ปีสร้าง',
            yearController,
          ),

          _field(
            'เนื้อ',
            materialController,
          ),

          _field(
            'ขนาด',
            sizeController,
          ),

          _field(
            'องค์อ้างอิง',
            referenceController,
          ),

          const SizedBox(height: 10),

          const Text(
            'รายละเอียดจากการสแกน',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          _field(
            'รายละเอียดด้านหน้า',
            frontController,
            maxLines: 4,
          ),

          _field(
            'รายละเอียดด้านข้าง',
            sideController,
            maxLines: 4,
          ),

          _field(
            'รายละเอียดด้านหลัง',
            backController,
            maxLines: 4,
          ),

          const SizedBox(height: 10),

          const Text(
            'ก้นพระ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          DropdownButtonFormField<String>(
            value: widget.data.bottomStatus,
            decoration: const InputDecoration(
              labelText: 'สถานะก้นพระ',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'มี',
                child: Text('มี'),
              ),
              DropdownMenuItem(
                value: 'ไม่มี',
                child: Text('ไม่มี'),
              ),
              DropdownMenuItem(
                value: 'ยังไม่ทราบ',
                child: Text('ยังไม่ทราบ'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  widget.data.bottomStatus = value;
                });
              }
            },
          ),

          const SizedBox(height: 12),

          _field(
            'รายละเอียดก้นพระ',
            bottomController,
            maxLines: 4,
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _saveData,
              icon: const Icon(Icons.save),
              label: const Text(
                'บันทึกข้อมูล',
                style: TextStyle(
                  fontSize: 19,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'กลับไปสแกน',
                style: TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
