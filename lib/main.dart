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

// =====================================================
// แอปหลัก
// =====================================================

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
// ข้อมูลการสแกนแต่ละรายการ
// =====================================================

class ScanReference {
  int number;

  String frontDetail;
  String sideDetail;
  String backDetail;
  String bottomDetail;

  String note;

  ScanReference({
    required this.number,
    this.frontDetail = '',
    this.sideDetail = '',
    this.backDetail = '',
    this.bottomDetail = '',
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'frontDetail': frontDetail,
      'sideDetail': sideDetail,
      'backDetail': backDetail,
      'bottomDetail': bottomDetail,
      'note': note,
    };
  }

  factory ScanReference.fromJson(Map<String, dynamic> json) {
    return ScanReference(
      number: json['number'] ?? 1,
      frontDetail: json['frontDetail'] ?? '',
      sideDetail: json['sideDetail'] ?? '',
      backDetail: json['backDetail'] ?? '',
      bottomDetail: json['bottomDetail'] ?? '',
      note: json['note'] ?? '',
    );
  }
}

// =====================================================
// ข้อมูลพระ
// =====================================================

class AmuletData {
  String id;

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
  String bottomDetail;

  String bottomStatus;

  // ข้อมูลสแกน 1, 2, 3, 4...
  List<ScanReference> scanReferences;

  AmuletData({
    this.id = '',
    this.name = '',
    this.model = '',
    this.type = '',
    this.temple = '',
    this.province = '',
    this.year = '',
    this.material = '',
    this.size = '',
    this.reference = '',
    this.frontDetail = '',
    this.sideDetail = '',
    this.backDetail = '',
    this.bottomDetail = '',
    this.bottomStatus = 'ยังไม่ทราบ',
    List<ScanReference>? scanReferences,
  }) : scanReferences = scanReferences ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'bottomStatus': bottomStatus,
      'scanReferences':
          scanReferences.map((item) => item.toJson()).toList(),
    };
  }

  factory AmuletData.fromJson(Map<String, dynamic> json) {
    final scanList = json['scanReferences'];

    return AmuletData(
      id: json['id'] ?? '',
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
      bottomDetail: json['bottomDetail'] ?? '',
      bottomStatus: json['bottomStatus'] ?? 'ยังไม่ทราบ',
      scanReferences: scanList is List
          ? scanList
              .map(
                (item) => ScanReference.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : [],
    );
  }
}

// =====================================================
// ฐานข้อมูล
// =====================================================

class AmuletDatabase {
  static const String storageKey = 'amulet_database';

  static Future<List<AmuletData>> load() async {
    final prefs = await SharedPreferences.getInstance();

    final text = prefs.getString(storageKey);

    if (text == null || text.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(text);

      return decoded
          .map(
            (item) => AmuletData.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<AmuletData> list) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      list.map((item) => item.toJson()).toList(),
    );

    await prefs.setString(storageKey, encoded);
  }

  static Future<void> add(AmuletData data) async {
    final list = await load();

    if (data.id.isEmpty) {
      data.id = DateTime.now()
          .microsecondsSinceEpoch
          .toString();
    }

    list.add(data);

    await save(list);
  }

  static Future<void> update(AmuletData data) async {
    final list = await load();

    final index = list.indexWhere(
      (item) => item.id == data.id,
    );

    if (index >= 0) {
      list[index] = data;
      await save(list);
    }
  }

  static Future<void> delete(String id) async {
    final list = await load();

    list.removeWhere(
      (item) => item.id == id,
    );

    await save(list);
  }
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

            _button(
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

            _button(
              context,
              Icons.image,
              'สแกนภาพบนหน้าจอ',
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ระบบสแกนภาพบนหน้าจอจะเพิ่มในขั้นต่อไป',
                    ),
                  ),
                );
              },
            ),

            _button(
              context,
              Icons.add_box,
              'สร้างข้อมูล',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AmuletDataPage(
                      data: AmuletData(),
                      isNew: true,
                    ),
                  ),
                );
              },
            ),

            _button(
              context,
              Icons.storage,
              'รายการที่บันทึก',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DatabasePage(
                      cameras: cameras,
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

  Widget _button(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
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

  bool isScanning = false;

  int scanNumber = 1;

  // ข้อมูลพระที่กำลังทำงาน
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
      isScanning = true;
    });
  }

  Future<void> _saveScanReference() async {
    final newScan = ScanReference(
      number: scanNumber,
      note: 'ข้อมูลสแกนครั้งที่ $scanNumber',
    );

    amuletData.scanReferences.add(newScan);

    scanNumber++;

    setState(() {
      isScanning = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'บันทึกข้อมูลสแกนครั้งที่ ${scanNumber - 1} แล้ว',
        ),
      ),
    );
  }

  Future<void> _openDataPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AmuletDataPage(
          data: amuletData,
          isNew: amuletData.id.isEmpty,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('กลับไปสแกน'),
                onTap: () {
                  Navigator.pop(sheetContext);
                },
              ),

              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('ข้อมูลรายการนี้'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openDataPage();
                },
              ),

              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('รายการที่บันทึก'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DatabasePage(
                        cameras: widget.cameras,
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

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(controller!),
          ),

          // เมนู
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

          // สถานะ
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
                isScanning
                    ? 'กำลังสแกน: ครั้งที่ $scanNumber'
                    : 'พร้อมสแกน',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // กรอบสแกน
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

          Positioned(
            left: 15,
            right: 15,
            bottom: 25,
            child: Column(
              children: [
                if (!isScanning)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _startScan,
                      child: Text(
                        'เริ่มสแกน ${scanNumber}',
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),

                if (isScanning) ...[
                  Text(
                    'กำลังเก็บข้อมูลสแกนครั้งที่ $scanNumber',
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

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveScanReference,
                      child: Text(
                        'เสร็จสิ้นสแกน $scanNumber',
                        style: const TextStyle(
                          fontSize: 19,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                Text(
                  'มีข้อมูลสแกนแล้ว ${amuletData.scanReferences.length} รายการ',
                  style: const TextStyle(
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
// หน้าข้อมูลพระ
// =====================================================

class AmuletDataPage extends StatefulWidget {
  final AmuletData data;
  final bool isNew;

  const AmuletDataPage({
    super.key,
    required this.data,
    required this.isNew,
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

  Future<void> _saveData() async {
    final data = widget.data;

    data.name = nameController.text.trim();
    data.model = modelController.text.trim();
    data.type = typeController.text.trim();
    data.temple = templeController.text.trim();
    data.province = provinceController.text.trim();
    data.year = yearController.text.trim();
    data.material = materialController.text.trim();
    data.size = sizeController.text.trim();
    data.reference = referenceController.text.trim();

    data.frontDetail = frontController.text.trim();
    data.sideDetail = sideController.text.trim();
    data.backDetail = backController.text.trim();
    data.bottomDetail = bottomController.text.trim();

    if (data.id.isEmpty) {
      await AmuletDatabase.add(data);
    } else {
      await AmuletDatabase.update(data);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'บันทึกข้อมูลเรียบร้อยแล้ว',
        ),
      ),
    );

    setState(() {});
  }

  Future<void> _deleteScan(int index) async {
    final scan = widget.data.scanReferences[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ลบข้อมูลสแกน'),
          content: Text(
            'ต้องการลบข้อมูลสแกน ${scan.number} หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      widget.data.scanReferences.removeAt(index);
    });

    await _renumberScans();
  }

  Future<void> _renumberScans() async {
    for (int i = 0;
        i < widget.data.scanReferences.length;
        i++) {
      widget.data.scanReferences[i].number = i + 1;
    }

    await AmuletDatabase.update(widget.data);
  }

  Future<void> _addScanManually() async {
    final number =
        widget.data.scanReferences.length + 1;

    final newScan = ScanReference(
      number: number,
    );

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanDetailPage(
          scan: newScan,
        ),
      ),
    );

    if (result == true) {
      setState(() {
        widget.data.scanReferences.add(newScan);
      });

      await AmuletDatabase.update(widget.data);
    }
  }

  Future<void> _editScan(int index) async {
    final scan = widget.data.scanReferences[index];

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanDetailPage(
          scan: scan,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
      await AmuletDatabase.update(widget.data);
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
    bottomController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isNew
              ? 'สร้างข้อมูล'
              : 'แก้ไขข้อมูล',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'ข้อมูลหลัก',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _field('ชื่อพระ', nameController),
          _field('รุ่น', modelController),
          _field('พิมพ์', typeController),
          _field('วัด / สำนัก', templeController),
          _field('จังหวัด', provinceController),
          _field('ปีสร้าง', yearController),
          _field('เนื้อ', materialController),
          _field('ขนาด', sizeController),
          _field('องค์อ้างอิง', referenceController),

          const SizedBox(height: 10),

          const Text(
            'รายละเอียดเฉพาะองค์',
            style: TextStyle(
              fontSize: 21,
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

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: data.bottomStatus,
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
                  data.bottomStatus = value;
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

          // =================================================
          // ข้อมูลสแกน
          // =================================================

          Row(
            children: [
              const Expanded(
                child: Text(
                  'ข้อมูลสแกนเปรียบเทียบ',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed: _addScanManually,
                icon: const Icon(Icons.add),
                label: const Text('เพิ่มสแกน'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'จำนวนข้อมูลสแกน: ${data.scanReferences.length} รายการ',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 10),

          if (data.scanReferences.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'ยังไม่มีข้อมูลสแกน\n'
                'สามารถเพิ่มภายหลังได้',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),

          ...List.generate(
            data.scanReferences.length,
            (index) {
              final scan =
                  data.scanReferences[index];

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      '${scan.number}',
                    ),
                  ),
                  title: Text(
                    'สแกน ${scan.number}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    scan.note.isEmpty
                        ? 'ยังไม่มีหมายเหตุ'
                        : scan.note,
                  ),
                  onTap: () {
                    _editScan(index);
                  },
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                    onPressed: () {
                      _deleteScan(index);
                    },
                  ),
                ),
              );
            },
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

          const SizedBox(height: 12),

          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'กลับ',
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

// =====================================================
// หน้าแก้ไขข้อมูลสแกน
// =====================================================

class ScanDetailPage extends StatefulWidget {
  final ScanReference scan;

  const ScanDetailPage({
    super.key,
    required this.scan,
  });

  @override
  State<ScanDetailPage> createState() =>
      _ScanDetailPageState();
}

class _ScanDetailPageState extends State<ScanDetailPage> {
  late final TextEditingController frontController;
  late final TextEditingController sideController;
  late final TextEditingController backController;
  late final TextEditingController bottomController;
  late final TextEditingController noteController;

  @override
  void initState() {
    super.initState();

    frontController = TextEditingController(
      text: widget.scan.frontDetail,
    );

    sideController = TextEditingController(
      text: widget.scan.sideDetail,
    );

    backController = TextEditingController(
      text: widget.scan.backDetail,
    );

    bottomController = TextEditingController(
      text: widget.scan.bottomDetail,
    );

    noteController = TextEditingController(
      text: widget.scan.note,
    );
  }

  void _save() {
    widget.scan.frontDetail =
        frontController.text.trim();

    widget.scan.sideDetail =
        sideController.text.trim();

    widget.scan.backDetail =
        backController.text.trim();

    widget.scan.bottomDetail =
        bottomController.text.trim();

    widget.scan.note =
        noteController.text.trim();

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    frontController.dispose();
    sideController.dispose();
    backController.dispose();
    bottomController.dispose();
    noteController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ข้อมูลสแกน ${widget.scan.number}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'สแกน ${widget.scan.number}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          _field(
            'รายละเอียดด้านหน้า',
            frontController,
          ),

          _field(
            'รายละเอียดด้านข้าง',
            sideController,
          ),

          _field(
            'รายละเอียดด้านหลัง',
            backController,
          ),

          _field(
            'รายละเอียดก้นพระ',
            bottomController,
          ),

          _field(
            'หมายเหตุของการสแกนครั้งนี้',
            noteController,
            maxLines: 4,
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text(
                'บันทึกข้อมูลสแกน',
                style: TextStyle(
                  fontSize: 18,
                ),
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
    int maxLines = 3,
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

// =====================================================
// หน้ารายการที่บันทึก
// =====================================================

class DatabasePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const DatabasePage({
    super.key,
    required this.cameras,
  });

  @override
  State<DatabasePage> createState() =>
      _DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> {
  List<AmuletData> items = [];

  bool loading = true;

  String searchText = '';

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    final result = await AmuletDatabase.load();

    if (!mounted) return;

    setState(() {
      items = result;
      loading = false;
    });
  }

  List<AmuletData> get filteredItems {
    if (searchText.trim().isEmpty) {
      return items;
    }

    final q = searchText.toLowerCase();

    return items.where((item) {
      return item.name.toLowerCase().contains(q) ||
          item.model.toLowerCase().contains(q) ||
          item.type.toLowerCase().contains(q) ||
          item.temple.toLowerCase().contains(q) ||
          item.province.toLowerCase().contains(q) ||
          item.material.toLowerCase().contains(q) ||
          item.year.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _addNew() async {
    final data = AmuletData();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AmuletDataPage(
          data: data,
          isNew: true,
        ),
      ),
    );

    await _loadDatabase();
  }

  Future<void> _edit(AmuletData data) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AmuletDataPage(
          data: data,
          isNew: false,
        ),
      ),
    );

    await _loadDatabase();
  }

  Future<void> _delete(AmuletData data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ลบรายการทั้งหมด'),
          content: Text(
            'ต้องการลบข้อมูล '
            '"${data.name.isEmpty ? 'พระองค์นี้' : data.name}" '
            'ทั้งหมดหรือไม่?\n\n'
            'ข้อมูลสแกนทั้งหมดของรายการนี้จะถูกลบด้วย',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'ลบทั้งหมด',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await AmuletDatabase.delete(data.id);

    await _loadDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายการที่บันทึก',
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _addNew,
        icon: const Icon(Icons.add),
        label: const Text('สร้างข้อมูล'),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration:
                        const InputDecoration(
                      labelText:
                          'ค้นหา ชื่อ / รุ่น / พิมพ์ / วัด / จังหวัด / เนื้อ / ปี',
                      prefixIcon:
                          Icon(Icons.search),
                      border:
                          OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      'จำนวนรายการ: '
                      '${filteredItems.length} รายการ',
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: filteredItems.isEmpty
                      ? const Center(
                          child: Text(
                            'ยังไม่มีข้อมูล\n'
                            'กด + สร้างข้อมูลรายการแรก',
                            textAlign:
                                TextAlign.center,
                            style:
                                TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.only(
                            bottom: 90,
                          ),
                          itemCount:
                              filteredItems.length,
                          itemBuilder:
                              (context, index) {
                            final item =
                                filteredItems[
                                    index];

                            return Card(
                              margin:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              child: ListTile(
                                leading:
                                    CircleAvatar(
                                  child: Text(
                                    '${index + 1}',
                                  ),
                                ),

                                title: Text(
                                  item.name.isEmpty
                                      ? 'ยังไม่ได้ระบุชื่อพระ'
                                      : item.name,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                subtitle:
                                    Text(
                                  'รุ่น: ${item.model.isEmpty ? '-' : item.model}\n'
                                  'พิมพ์: ${item.type.isEmpty ? '-' : item.type}\n'
                                  'วัด: ${item.temple.isEmpty ? '-' : item.temple}\n'
                                  'ข้อมูลสแกน: ${item.scanReferences.length} รายการ',
                                ),

                                isThreeLine: false,

                                onTap: () {
                                  _edit(item);
                                },

                                trailing:
                                    IconButton(
                                  icon:
                                      const Icon(
                                    Icons
                                        .delete_outline,
                                  ),
                                  onPressed: () {
                                    _delete(
                                        item);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
