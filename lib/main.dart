import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(
    AmuletScannerApp(cameras: cameras),
  );
}

// ======================================================
// APP
// ======================================================

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

// ======================================================
// HOME
// ======================================================

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

            _MenuButton(
              icon: Icons.menu_book,
              title: 'ฐานข้อมูลพระ',
              subtitle: 'เพิ่มและดูข้อมูลพระที่บันทึกไว้',
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

// ======================================================
// MENU BUTTON
// ======================================================

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

// ======================================================
// MODEL ข้อมูลพระ
// ======================================================

class AmuletData {
  String name;
  String model;
  String type;
  String temple;
  String province;
  String year;
  String material;
  String size;
  String reference;
  String frontDetail;
  String sideDetail;
  String backDetail;
  String importantPoints;
  String note;

  AmuletData({
    required this.name,
    required this.model,
    required this.type,
    required this.temple,
    required this.province,
    required this.year,
    required this.material,
    required this.size,
    required this.reference,
    required this.frontDetail,
    required this.sideDetail,
    required this.backDetail,
    required this.importantPoints,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'model': model,
      'type': type,
      'temple': temple,
      'province': province,
      'year': year,
      'material': material,
      'size': size,
      'reference': reference,
      'frontDetail': frontDetail,
      'sideDetail': sideDetail,
      'backDetail': backDetail,
      'importantPoints': importantPoints,
      'note': note,
    };
  }

  factory AmuletData.fromJson(
    Map<String, dynamic> json,
  ) {
    return AmuletData(
      name: json['name'] ?? '',
      model: json['model'] ?? '',
      type: json['type'] ?? '',
      temple: json['temple'] ?? '',
      province: json['province'] ?? '',
      year: json['year'] ?? '',
      material: json['material'] ?? '',
      size: json['size'] ?? '',
      reference: json['reference'] ?? '',
      frontDetail: json['frontDetail'] ?? '',
      sideDetail: json['sideDetail'] ?? '',
      backDetail: json['backDetail'] ?? '',
      importantPoints:
          json['importantPoints'] ?? '',
      note: json['note'] ?? '',
    );
  }
}

// ======================================================
// DATABASE PAGE
// ======================================================

class DatabasePage extends StatefulWidget {
  const DatabasePage({super.key});

  @override
  State<DatabasePage> createState() =>
      _DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> {
  List<AmuletData> amulets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs =
        await SharedPreferences.getInstance();

    final saved =
        prefs.getStringList('amulet_database') ?? [];

    setState(() {
      amulets = saved
          .map(
            (item) => AmuletData.fromJson(
              jsonDecode(item),
            ),
          )
          .toList();
    });
  }

  Future<void> _saveData() async {
    final prefs =
        await SharedPreferences.getInstance();

    final data = amulets
        .map(
          (item) => jsonEncode(item.toJson()),
        )
        .toList();

    await prefs.setStringList(
      'amulet_database',
      data,
    );
  }

  Future<void> _addAmulet() async {
    final result = await Navigator.push<AmuletData>(
      context,
      MaterialPageRoute(
        builder: (_) => const AmuletFormPage(),
      ),
    );

    if (result != null) {
      setState(() {
        amulets.add(result);
      });

      await _saveData();
    }
  }

  Future<void> _editAmulet(int index) async {
    final result =
        await Navigator.push<AmuletData>(
      context,
      MaterialPageRoute(
        builder: (_) => AmuletFormPage(
          existing: amulets[index],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        amulets[index] = result;
      });

      await _saveData();
    }
  }

  Future<void> _deleteAmulet(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ลบข้อมูล'),
          content: const Text(
            'ต้องการลบข้อมูลพระรายการนี้หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        amulets.removeAt(index);
      });

      await _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ฐานข้อมูลพระ'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAmulet,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มข้อมูลพระ'),
      ),
      body: amulets.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'ยังไม่มีข้อมูลพระ\n\n'
                  'กดปุ่ม “เพิ่มข้อมูลพระ” '
                  'เพื่อเริ่มสร้างฐานข้อมูล',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: amulets.length,
              itemBuilder: (context, index) {
                final item = amulets[index];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(
                        Icons.account_balance,
                      ),
                    ),
                    title: Text(
                      item.name.isEmpty
                          ? 'ไม่มีชื่อพระ'
                          : item.name,
                    ),
                    subtitle: Text(
                      'รุ่น: ${item.model}\n'
                      'พิมพ์: ${item.type}',
                    ),
                    isThreeLine: true,
                    onTap: () {
                      _editAmulet(index);
                    },
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                      onPressed: () {
                        _deleteAmulet(index);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ======================================================
// FORM PAGE
// ======================================================

class AmuletFormPage extends StatefulWidget {
  final AmuletData? existing;

  const AmuletFormPage({
    super.key,
    this.existing,
  });

  @override
  State<AmuletFormPage> createState() =>
      _AmuletFormPageState();
}

class _AmuletFormPageState
    extends State<AmuletFormPage> {
  final nameController = TextEditingController();
  final modelController = TextEditingController();
  final typeController = TextEditingController();
  final templeController = TextEditingController();
  final provinceController = TextEditingController();
  final yearController = TextEditingController();
  final materialController = TextEditingController();
  final sizeController = TextEditingController();
  final referenceController = TextEditingController();
  final frontController = TextEditingController();
  final sideController = TextEditingController();
  final backController = TextEditingController();
  final importantController =
      TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final item = widget.existing;

    if (item != null) {
      nameController.text = item.name;
      modelController.text = item.model;
      typeController.text = item.type;
      templeController.text = item.temple;
      provinceController.text = item.province;
      yearController.text = item.year;
      materialController.text = item.material;
      sizeController.text = item.size;
      referenceController.text = item.reference;
      frontController.text = item.frontDetail;
      sideController.text = item.sideDetail;
      backController.text = item.backDetail;
      importantController.text =
          item.importantPoints;
      noteController.text = item.note;
    }
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
    importantController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _save() {
    final result = AmuletData(
      name: nameController.text.trim(),
      model: modelController.text.trim(),
      type: typeController.text.trim(),
      temple: templeController.text.trim(),
      province: provinceController.text.trim(),
      year: yearController.text.trim(),
      material: materialController.text.trim(),
      size: sizeController.text.trim(),
      reference: referenceController.text.trim(),
      frontDetail: frontController.text.trim(),
      sideDetail: sideController.text.trim(),
      backDetail: backController.text.trim(),
      importantPoints:
          importantController.text.trim(),
      note: noteController.text.trim(),
    );

    Navigator.pop(context, result);
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing
              ? 'แก้ไขข้อมูลพระ'
              : 'เพิ่มข้อมูลพระ',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'ข้อมูลหลัก',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          _field('ชื่อพระ', nameController),
          _field('รุ่น', modelController),
          _field('พิมพ์', typeController),
          _field('วัด / สำนัก', templeController),
          _field('จังหวัด', provinceController),
          _field('ปีสร้าง', yearController),
          _field('เนื้อ', materialController),
          _field('ขนาด', sizeController),

          const SizedBox(height: 10),

          const Text(
            'ข้อมูลสำหรับการวิเคราะห์',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          _field(
            'องค์อ้างอิง',
            referenceController,
            maxLines: 2,
          ),

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

          _field(
            'จุดสังเกตสำคัญ',
            importantController,
            maxLines: 4,
          ),

          _field(
            'หมายเหตุ',
            noteController,
            maxLines: 4,
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(
                editing
                    ? 'บันทึกการแก้ไข'
                    : 'บันทึกข้อมูลพระ',
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ======================================================
// SCAN PAGE
// ======================================================

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

class _ScanHomePageState
    extends State<ScanHomePage> {
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

// ======================================================
// PILE SCAN
// ======================================================

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

// ======================================================
// SETTINGS
// ======================================================

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
