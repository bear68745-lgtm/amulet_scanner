import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
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

  // ข้อมูลการสแกนแบบใหม่
  // แยกตามพื้นที่ และแต่ละพื้นที่สามารถสแกนได้หลายครั้ง
  List<ScanData> scans;

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
    List<ScanData>? scans,
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

      // บันทึกเฉพาะข้อมูลการสแกน
      // ไม่บันทึกรูปภาพ
      'scans': scans.map((scan) => scan.toMap()).toList(),
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

      scans: (map['scans'] as List? ?? [])
          .map(
            (scan) => ScanData.fromMap(
              Map<String, dynamic>.from(scan),
            ),
          )
          .toList(),
    );
  }
}


/// ข้อมูลการสแกนแต่ละครั้ง
///
/// 1 รายการ = 1 การสแกน
/// สามารถระบุได้ว่าเป็นพื้นที่ไหน
/// สแกนครั้งที่เท่าไร
/// และใช้วิธีใดในการนำข้อมูลเข้ามา
///
/// ไม่มีการเก็บรูปภาพ
class ScanData {
  String area;
  int scanNumber;
  String method;

  // รายละเอียดเพิ่มเติม
  // จะเปิดให้ AI และระบบในอนาคตเพิ่มข้อมูลได้
  Map<String, dynamic> details;

  ScanData({
    required this.area,
    required this.scanNumber,
    required this.method,
    Map<String, dynamic>? details,
  }) : details = details ?? {};

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'scanNumber': scanNumber,
      'method': method,
      'details': details,
    };
  }

  factory ScanData.fromMap(Map<String, dynamic> map) {
    return ScanData(
      area: map['area'] ?? '',
      scanNumber: map['scanNumber'] ?? 0,
      method: map['method'] ?? '',
      details: Map<String, dynamic>.from(
        map['details'] ?? {},
      ),
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
                    
                    onTap: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DetailPage(
        item: item,
        cameras: widget.cameras,
      ),
    ),
  );

  _loadData();
},
                  ),
                );
              },
            ),
    );
  }
}
// =====================================================
// หน้ารายละเอียดองค์จริง
// =====================================================

class DetailPage extends StatefulWidget {
  final AmuletData item;
  final List<CameraDescription> cameras;

  const DetailPage({
    super.key,
    required this.item,
    required this.cameras,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late TextEditingController nameController;
  late TextEditingController modelController;
  late TextEditingController typeController;
  late TextEditingController templeController;
  late TextEditingController provinceController;
  late TextEditingController yearController;
  late TextEditingController materialController;
  late TextEditingController sizeController;
  late TextEditingController frontController;
  late TextEditingController sideController;
  late TextEditingController backController;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    nameController = TextEditingController(text: item.name);
    modelController = TextEditingController(text: item.model);
    typeController = TextEditingController(text: item.type);
    templeController = TextEditingController(text: item.templfinal   provinceController = TextEditingController(text: item.province);
    yearController = TextEditingController(text: item.year);
    materialController = TextEditingController(text: item.material);
    sizeController = TextEditingController(text: item.size);
    frontController = TextEditingController(text: item.frontDetail);
    sideController = TextEditingController(text: item.sideDetail);
    backController = TextEditingController(text: item.backDetail);
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
    frontController.dispose();
    sideController.dispose();
    backController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'องค์จริง ${widget.item.realItemNumber}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'องค์จริงลำดับที่ ${widget.item.realItemNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _field('ชื่อพระ / เหรียญ', nameController),
          _field('รุ่น', modelController),
          _field('พิมพ์', typeController),
          _field('วัด / สำนัก', templeController),
          _field('จังหวัด', provinceController),
          _field('ปีสร้าง', yearController),
          _field('เนื้อ', materialController),
          _field('ขนาด', sizeController),

          const SizedBox(height: 8),

          const Text(
            'รายละเอียด',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

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

                      Card(
            child: ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text(
                'สแกนเพิ่ม',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                widget.item.scans.isEmpty
                    ? 'ยังไม่มีข้อมูลการสแกน'
                    : 'มีข้อมูลการสแกน ${widget.item.scans.length} รายการ',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanPage(
                      item: widget.item,
                      cameras: widget.cameras,
                    ),
                  ),
                );

                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 20),        
          
          
            

        
        
          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text(
                'บันทึกการแก้ไข',
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

  Future<void> _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getStringList('amulet_data') ?? [];

    final items = saved.map((item) {
      return AmuletData.fromMap(
        jsonDecode(item),
      );
    }).toList();

    final index = items.indexWhere(
      (element) => element.id == widget.item.id,
    );

    if (index == -1) {
      return;
    }

    final oldItem = items[index];

    items[index] = AmuletData(
      id: oldItem.id,

      // สำคัญ:
      // เลของค์จริงเดิมจะไม่เปลี่ยน
      realItemNumber: oldItem.realItemNumber,

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

      // เก็บข้อมูลการสแกนเดิมไว้
      scans: oldItem.scans,
    );

    final newData = items.map((item) {
      return jsonEncode(item.toMap());
    }).toList();

    await prefs.setStringList(
      'amulet_data',
      newData,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'บันทึกการแก้ไขเรียบร้อยแล้ว',
        ),
      ),
    );

    Navigator.pop(context);
  }
}

// =====================================================
// หน้าสแกนเพิ่ม
// =====================================================

class ScanPage extends StatefulWidget {
  final AmuletData item;
  final List<CameraDescription> cameras;

  const ScanPage({
    super.key,
    required this.item,
    required this.cameras,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? controller;

  final ImagePicker _picker = ImagePicker();

  final List<String> defaultAreas = [
    'ด้านหน้า',
    'ด้านหลัง',
    'ด้านข้าง',
    'หูเหรียญ',
    'ตูดพระ',
    'จุดเฉพาะ',
  ];

  String selectedArea = 'ด้านหน้า';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _saveScan(String method) async {
    final int scanNumber = widget.item.scans
            .where((scan) => scan.area == selectedArea)
            .length +
        1;

    final scan = ScanData(
      area: selectedArea,
      scanNumber: scanNumber,
      method: method,
      details: {},
    );

    widget.item.scans.add(scan);

    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList('amulet_data') ?? [];

    final updatedData = data.map((jsonString) {
      final map = jsonDecode(jsonString);

      if (map['id'] == widget.item.id) {
        map['scans'] =
            widget.item.scans.map((scan) => scan.toMap()).toList();
      }

      return jsonEncode(map);
    }).toList();

    await prefs.setStringList('amulet_data', updatedData);

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'บันทึก $selectedArea • สแกนครั้งที่ $scanNumber แล้ว',
        ),
      ),
    );
  }

  Future<void> _scanFromCamera(String method) async {
    if (controller == null || !controller!.value.isInitialized) {
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$selectedArea\n$method',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                AspectRatio(
                  aspectRatio: controller!.value.aspectRatio,
                  child: CameraPreview(controller!),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: Text(
                      'บันทึกการสแกนครั้งที่ '
                      '${widget.item.scans.where((s) => s.area == selectedArea).length + 1}',
                    ),
                    onPressed: () {
                      _saveScan(method);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFromPhone() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    // ใช้ภาพเพื่อการสแกนเท่านั้น
    // ไม่บันทึก path หรือรูปภาพลงในฐานข้อมูล
    await _saveScan('จากหน้าจอ/ภาพในโทรศัพท์นี้');
  }

  Future<void> _addCustomArea() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('เพิ่มหมวดพื้นที่'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'เช่น ขอบล่าง / หลังหู / จุดตำหนิ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('เพิ่ม'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    setState(() {
      selectedArea = result;
    });
  }

  int _scanCount(String area) {
    return widget.item.scans
        .where((scan) => scan.area == area)
        .length;
  }

  Widget _areaButton(String area) {
    final count = _scanCount(area);

    return Card(
      child: ListTile(
        leading: Icon(
          selectedArea == area
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
        ),
        title: Text(area),
        subtitle: Text('สแกนแล้ว $count ครั้ง'),
        onTap: () {
          setState(() {
            selectedArea = area;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final areas = [...defaultAreas];

    final customAreas = widget.item.scans
        .map((scan) => scan.area)
        .where((area) => !defaultAreas.contains(area))
        .toSet()
        .toList();

    areas.addAll(customAreas);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกพื้นที่สแกน'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'องค์จริงลำดับที่ ${widget.item.realItemNumber}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'เลือกพื้นที่ที่ต้องการเก็บข้อมูล',
            style: TextStyle(fontSize: 15),
          ),

          const SizedBox(height: 16),

          ...areas.map(_areaButton),

          Card(
            child: ListTile(
              leading: const Icon(Icons.add),
              title: const Text('เพิ่มหมวดเอง'),
              subtitle: const Text(
                'สำหรับพื้นที่ที่พระหรือเหรียญบางรายการมีเฉพาะ',
              ),
              onTap: _addCustomArea,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'วิธีนำเข้าข้อมูล',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('สแกนองค์จริง'),
            onPressed: () {
              _scanFromCamera('สแกนองค์จริง');
            },
          ),

          const SizedBox(height: 8),

          ElevatedButton.icon(
            icon: const Icon(Icons.phone_android),
            label: const Text('สแกนผ่านหน้าจอเครื่องอื่น'),
            onPressed: () {
              _scanFromCamera('สแกนผ่านหน้าจอเครื่องอื่น');
            },
          ),

          const SizedBox(height: 8),

          ElevatedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text(
              'สแกนจากหน้าจอ/ภาพในโทรศัพท์นี้',
            ),
            onPressed: _pickFromPhone,
          ),

          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ประวัติการสแกน',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (widget.item.scans.isEmpty)
                    const Text('ยังไม่มีข้อมูลการสแกน'),

                  ...widget.item.scans.map(
                    (scan) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(
                        '${scan.area} • สแกน ${scan.scanNumber}',
                      ),
                      subtitle: Text(scan.method),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

                                             

                                             


