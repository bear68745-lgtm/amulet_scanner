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
      title: 'กล้องสแกนพระและเหรียญ',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: HomePage(cameras: cameras),
    );
  }
}

// =====================================================
// โครงสร้างข้อมูลของพระ/เหรียญ 1 องค์
// =====================================================

class AmuletData {
  int id;
  int realItemNumber;

  String name;
  String model;
  String type;
  String temple;
  String province;
  String year;
  String material;
  String size;

  String frontDetail;
  String sideDetail;
  String backDetail;

  List<String> scans;

  AmuletData({
    required this.id,
    required this.realItemNumber,
    this.name = '',
    this.model = '',
    this.type = '',
    this.temple = '',
    this.province = '',
    this.year = '',
    this.material = '',
    this.size = '',
    this.frontDetail = '',
    this.sideDetail = '',
    this.backDetail = '',
    List<String>? scans,
  }) : scans = scans ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'realItemNumber': realItemNumber,
      'name': name,
      'model': model,
      'type': type,
      'temple': temple,
      'province': province,
      'year': year,
      'material': material,
      'size': size,
      'frontDetail': frontDetail,
      'sideDetail': sideDetail,
      'backDetail': backDetail,
      'scans': scans,
    };
  }

  factory AmuletData.fromMap(Map<String, dynamic> map) {
    return AmuletData(
      id: map['id'] ?? 0,
      realItemNumber: map['realItemNumber'] ?? 0,
      name: map['name'] ?? '',
      model: map['model'] ?? '',
      type: map['type'] ?? '',
      temple: map['temple'] ?? '',
      province: map['province'] ?? '',
      year: map['year'] ?? '',
      material: map['material'] ?? '',
      size: map['size'] ?? '',
      frontDetail: map['frontDetail'] ?? '',
      sideDetail: map['sideDetail'] ?? '',
      backDetail: map['backDetail'] ?? '',
      scans: List<String>.from(map['scans'] ?? []),
    );
  }
}

// =====================================================
// หน้าหลัก
// =====================================================

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
          'กล้องสแกนพระและเหรียญ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 10),

              _mainButton(
                context,
                icon: Icons.add_circle_outline,
                title: 'สร้าง / บันทึกข้อมูล',
                subtitle: 'สร้างข้อมูลพระหรือเหรียญใหม่',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateDataPage(
                        cameras: cameras,
                      ),
                    ),
                  );
                },
              ),

              _mainButton(
                context,
                icon: Icons.list_alt,
                title: 'รายการข้อมูลที่บันทึก',
                subtitle: 'ดู แก้ไข และสแกนเพิ่มข้อมูล',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedListPage(
                        cameras: cameras,
                      ),
                    ),
                  );
                },
              ),

              _mainButton(
                context,
                icon: Icons.import_export,
                title: 'สำรอง / นำเข้าข้อมูล',
                subtitle: 'จัดการข้อมูลฐานข้อมูล',
                color: Colors.orange,
                onTap: () {
                  _showComingSoon(context, 'สำรอง / นำเข้าข้อมูล');
                },
              ),

              _mainButton(
                context,
                icon: Icons.settings,
                title: 'ตั้งค่า',
                subtitle: 'ตั้งค่าการทำงานของแอป',
                color: Colors.grey,
                onTap: () {
                  _showComingSoon(context, 'ตั้งค่า');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title จะพัฒนาในขั้นต่อไป'),
      ),
    );
  }
}

// =====================================================
// หน้าสร้างข้อมูล
// =====================================================

class CreateDataPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CreateDataPage({
    super.key,
    required this.cameras,
  });

  @override
  State<CreateDataPage> createState() => _CreateDataPageState();
}

class _CreateDataPageState extends State<CreateDataPage> {
  final nameController = TextEditingController();
  final modelController = TextEditingController();
  final typeController = TextEditingController();
  final templeController = TextEditingController();
  final provinceController = TextEditingController();
  final yearController = TextEditingController();
  final materialController = TextEditingController();
  final sizeController = TextEditingController();
  final frontController = TextEditingController();
  final sideController = TextEditingController();
  final backController = TextEditingController();

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
    frontController.dispose();
    sideController.dispose();
    backController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้าง / บันทึกข้อมูล'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('ชื่อพระ / เหรียญ', nameController),
          _field('รุ่น', modelController),
          _field('พิมพ์', typeController),
          _field('วัด / สำนัก', templeController),
          _field('จังหวัด', provinceController),
          _field('ปีสร้าง', yearController),
          _field('เนื้อ', materialController),
          _field('ขนาด', sizeController),

          const SizedBox(height: 10),

          const Text(
            'รายละเอียดองค์จริง',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          _field('รายละเอียดด้านหน้า', frontController),
          _field('รายละเอียดด้านข้าง', sideController),
          _field('รายละเอียดด้านหลัง', backController),

          const SizedBox(height: 20),

          const Text(
            'การสแกน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'สามารถบันทึกข้อมูลโดยไม่สแกนได้ และสามารถกลับมาแก้ไขเพื่อสแกนเพิ่มภายหลัง',
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _saveData,
              icon: const Icon(Icons.save),
              label: const Text(
                'บันทึกข้อมูล',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    final oldData = prefs.getStringList('amulet_data') ?? [];

    final List<AmuletData> items = oldData.map((item) {
      return AmuletData.fromMap(
        jsonDecode(item),
      );
    }).toList();

    final nextNumber = items.length + 1;

    final newItem = AmuletData(
      id: DateTime.now().millisecondsSinceEpoch,
      realItemNumber: nextNumber,
      name: nameController.text,
      model: modelController.text,
      type: typeController.text,
      temple: templeController.text,
      province: provinceController.text,
      year: yearController.text,
      material: materialController.text,
      size: sizeController.text,
      frontDetail: frontController.text,
      sideDetail: sideController.text,
      backDetail: backController.text,
    );

    items.add(newItem);

    final saveData = items.map((item) {
      return jsonEncode(item.toMap());
    }).toList();

    await prefs.setStringList(
      'amulet_data',
      saveData,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'บันทึกองค์จริงลำดับที่ $nextNumber เรียบร้อยแล้ว',
        ),
      ),
    );

    Navigator.pop(context);
  }
}

// =====================================================
// รายการข้อมูลที่บันทึก
// =====================================================

class SavedListPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SavedListPage({
    super.key,
    required this.cameras,
  });

  @override
  State<SavedListPage> createState() => _SavedListPageState();
}

class _SavedListPageState extends State<SavedListPage> {
  List<AmuletData> items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getStringList('amulet_data') ?? [];

    final loaded = saved.map((item) {
      return AmuletData.fromMap(
        jsonDecode(item),
      );
    }).toList();

    setState(() {
      items = loaded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการข้อมูลที่บันทึก'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีข้อมูลที่บันทึก',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        '${item.realItemNumber}',
                      ),
                    ),
                    title: Text(
                      item.name.isEmpty
                          ? 'ยังไม่ได้ระบุชื่อ'
                          : item.name,
                    ),
                    subtitle: Text(
                      'องค์จริงลำดับที่ ${item.realItemNumber}'
                      '${item.model.isEmpty ? '' : ' • ${item.model}'}',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'หน้าแก้ไขและสแกนเพิ่ม จะเชื่อมต่อในขั้นต่อไป',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
