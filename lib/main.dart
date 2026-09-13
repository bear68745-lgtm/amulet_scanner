
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(
    AmuletScannerApp(cameras: cameras),
  );
}

// ============================================================
// APP
// ============================================================

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
        colorSchemeSeed: Colors.brown,
      ),
      home: MainMenuPage(cameras: cameras),
    );
  }
}

// ============================================================
// SCAN SECTION
// ============================================================

enum ScanSection {
  front,
  back,
  side,
  ear,
  bottom,
}

String scanSectionName(ScanSection section) {
  switch (section) {
    case ScanSection.front:
      return 'ด้านหน้า';
    case ScanSection.back:
      return 'ด้านหลัง';
    case ScanSection.side:
      return 'ด้านข้าง';
    case ScanSection.ear:
      return 'หูเหรียญ';
    case ScanSection.bottom:
      return 'ก้นพระ';
  }
}

// ============================================================
// SCAN RECORD
// ============================================================

class ScanRecord {
  String id;
  int number;
  String section;
  String note;

  ScanRecord({
    required this.id,
    required this.number,
    required this.section,
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'section': section,
      'note': note,
    };
  }

  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    return ScanRecord(
      id: json['id'] ?? '',
      number: json['number'] ?? 1,
      section: json['section'] ?? '',
      note: json['note'] ?? '',
    );
  }
}

// ============================================================
// AMULET DATA
// ============================================================

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

  List<ScanRecord> scans;

  AmuletData({
    required this.id,
    this.name = '',
    this.model = '',
    this.type = '',
    this.temple = '',
    this.province = '',
    this.year = '',
    this.material = '',
    this.size = '',
    this.reference = '',
    List<ScanRecord>? scans,
  }) : scans = scans ?? [];

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
      'scans': scans.map((e) => e.toJson()).toList(),
    };
  }

  factory AmuletData.fromJson(Map<String, dynamic> json) {
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
      scans: (json['scans'] as List? ?? [])
          .map(
            (e) => ScanRecord.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

// ============================================================
// DATABASE
// ============================================================

class AmuletDatabase {
  static const String key = 'amulet_database';

  static Future<List<AmuletData>> getAll() async {
    final prefs = await SharedPreferences.getInstance();

    final text = prefs.getString(key);

    if (text == null || text.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> data = jsonDecode(text);

      return data
          .map(
            (e) => AmuletData.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<AmuletData> items) async {
    final prefs = await SharedPreferences.getInstance();

    final data = items.map((e) => e.toJson()).toList();

    await prefs.setString(
      key,
      jsonEncode(data),
    );
  }

  static Future<void> add(AmuletData item) async {
    final items = await getAll();

    items.add(item);

    await saveAll(items);
  }

  static Future<void> update(AmuletData item) async {
    final items = await getAll();

    final index = items.indexWhere(
      (e) => e.id == item.id,
    );

    if (index != -1) {
      items[index] = item;
    }

    await saveAll(items);
  }

  static Future<void> delete(String id) async {
    final items = await getAll();

    items.removeWhere(
      (e) => e.id == id,
    );

    await saveAll(items);
  }
}

// ============================================================
// MAIN MENU
// ============================================================

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
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _menuButton(
            context,
            icon: Icons.note_add,
            title: 'สร้างข้อมูล',
            subtitle: 'สร้างข้อมูลพระหรือเหรียญใหม่',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DataPage(
                    cameras: cameras,
                    item: AmuletData(
                      id: DateTime.now()
                          .microsecondsSinceEpoch
                          .toString(),
                    ),
                    isNew: true,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          _menuButton(
            context,
            icon: Icons.camera_alt,
            title: 'สแกน',
            subtitle: 'เข้าสแกนข้อมูลของรายการที่เลือก',
            onTap: () async {
              final items = await AmuletDatabase.getAll();

              if (!context.mounted) return;

              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ยังไม่มีข้อมูล กรุณาสร้างข้อมูลก่อน',
                    ),
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanChoosePage(
                    cameras: cameras,
                    items: items,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          _menuButton(
            context,
            icon: Icons.save,
            title: 'บันทึก',
            subtitle: 'บันทึกรายการที่กำลังสร้างหรือแก้ไข',
            onTap: () async {
              final items = await AmuletDatabase.getAll();

              if (!context.mounted) return;

              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ยังไม่มีรายการให้บันทึก'),
                  ),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'ข้อมูลทั้งหมดที่สร้างไว้ถูกบันทึกแล้ว',
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          _menuButton(
            context,
            icon: Icons.list_alt,
            title: 'รายการบันทึก + แก้ไข',
            subtitle: 'ค้นหา ดู แก้ไข และลบรายการ',
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
        ],
      ),
    );
  }

  Widget _menuButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          icon,
          size: 38,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// DATA PAGE
// ============================================================

class DataPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final AmuletData item;
  final bool isNew;

  const DataPage({
    super.key,
    required this.cameras,
    required this.item,
    required this.isNew,
  });

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  late AmuletData item;

  late TextEditingController nameController;
  late TextEditingController modelController;
  late TextEditingController typeController;
  late TextEditingController templeController;
  late TextEditingController provinceController;
  late TextEditingController yearController;
  late TextEditingController materialController;
  late TextEditingController sizeController;
  late TextEditingController referenceController;

  @override
  void initState() {
    super.initState();

    item = widget.item;

    nameController = TextEditingController(text: item.name);
    modelController = TextEditingController(text: item.model);
    typeController = TextEditingController(text: item.type);
    templeController = TextEditingController(text: item.temple);
    provinceController = TextEditingController(text: item.province);
    yearController = TextEditingController(text: item.year);
    materialController = TextEditingController(text: item.material);
    sizeController = TextEditingController(text: item.size);
    referenceController =
        TextEditingController(text: item.reference);
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

    super.dispose();
  }

  void updateData() {
    item.name = nameController.text.trim();
    item.model = modelController.text.trim();
    item.type = typeController.text.trim();
    item.temple = templeController.text.trim();
    item.province = provinceController.text.trim();
    item.year = yearController.text.trim();
    item.material = materialController.text.trim();
    item.size = sizeController.text.trim();
    item.reference = referenceController.text.trim();
  }

  Future<void> saveItem() async {
    updateData();

    if (item.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาใส่ชื่อพระก่อนบันทึก'),
        ),
      );
      return;
    }

    if (widget.isNew) {
      await AmuletDatabase.add(item);
    } else {
      await AmuletDatabase.update(item);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('บันทึกข้อมูลเรียบร้อยแล้ว'),
      ),
    );

    Navigator.pop(context);
  }

  Future<void> deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ลบรายการ'),
          content: const Text(
            'ต้องการลบรายการนี้ใช่หรือไม่?\n'
            'ข้อมูลสแกนของรายการนี้จะถูกลบด้วย',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await AmuletDatabase.delete(item.id);

    if (!mounted) return;

    Navigator.pop(context);
  }

  Future<void> openScan(ScanSection section) async {
    updateData();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          item: item,
          section: section,
        ),
      ),
    );

    if (result is AmuletData) {
      setState(() {
        item = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isNew ? 'สร้างข้อมูล' : 'แก้ไขข้อมูล',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(
            nameController,
            'ชื่อพระ',
          ),
          _field(
            modelController,
            'รุ่น',
          ),
          _field(
            typeController,
            'พิมพ์',
          ),
          _field(
            templeController,
            'วัด / สำนัก',
          ),
          _field(
            provinceController,
            'จังหวัด',
          ),
          _field(
            yearController,
            'ปีสร้าง',
          ),
          _field(
            materialController,
            'เนื้อ',
          ),
          _field(
            sizeController,
            'ขนาด',
          ),
          _field(
            referenceController,
            'องค์อ้างอิง',
          ),

          const SizedBox(height: 12),

          const Text(
            'ส่วนสำหรับสแกน',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'แตะค้าง หรือแตะ 2 ครั้งติดกัน เพื่อเข้าสแกนส่วนนั้น',
          ),

          const SizedBox(height: 12),

          _scanSectionTile(
            ScanSection.front,
          ),

          _scanSectionTile(
            ScanSection.back,
          ),

          _scanSectionTile(
            ScanSection.side,
          ),

          _scanSectionTile(
            ScanSection.ear,
          ),

          _scanSectionTile(
            ScanSection.bottom,
          ),

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: saveItem,
            icon: const Icon(Icons.save),
            label: const Text(
              'บันทึก',
              style: TextStyle(fontSize: 18),
            ),
          ),

          if (!widget.isNew) ...[
            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: deleteItem,
              icon: const Icon(Icons.delete),
              label: const Text(
                'ลบรายการ',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
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

  Widget _scanSectionTile(ScanSection section) {
    final name = scanSectionName(section);

    final count = item.scans
        .where((e) => e.section == name)
        .length;

    return GestureDetector(
      onDoubleTap: () {
        openScan(section);
      },
      onLongPress: () {
        openScan(section);
      },
      child: Card(
        child: ListTile(
          leading: const Icon(
            Icons.camera_alt,
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: count == 0
              ? const Text('ยังไม่มีข้อมูลสแกน')
              : Text(
                  'มีข้อมูลสแกน $count รายการ',
                ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'แตะค้าง หรือแตะ 2 ครั้งที่ "$name" เพื่อเข้าสแกน',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// CHOOSE ITEM FOR SCAN
// ============================================================

class ScanChoosePage extends StatelessWidget {
  final List<CameraDescription> cameras;
  final List<AmuletData> items;

  const ScanChoosePage({
    super.key,
    required this.cameras,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกข้อมูลที่จะสแกน'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return ListTile(
            leading: const Icon(
              Icons.description,
            ),
            title: Text(
              item.name.isEmpty
                  ? 'ยังไม่มีชื่อ'
                  : item.name,
            ),
            subtitle: item.model.isEmpty
                ? null
                : Text(item.model),
            trailing: const Icon(
              Icons.arrow_forward_ios,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DataPage(
                    cameras: cameras,
                    item: item,
                    isNew: false,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// SCAN PAGE
// ============================================================

class ScanPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final AmuletData item;
  final ScanSection section;

  const ScanPage({
    super.key,
    required this.cameras,
    required this.item,
    required this.section,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? controller;

  bool cameraReady = false;

  int nextNumber = 1;

  @override
  void initState() {
    super.initState();

    _findNextNumber();
    _startCamera();
  }

  void _findNextNumber() {
    final name = scanSectionName(widget.section);

    final numbers = widget.item.scans
        .where((e) => e.section == name)
        .map((e) => e.number)
        .toList();

    if (numbers.isEmpty) {
      nextNumber = 1;
    } else {
      nextNumber = numbers.reduce(
            (a, b) => a > b ? a : b,
          ) +
          1;
    }
  }

  Future<void> _startCamera() async {
    if (widget.cameras.isEmpty) {
      return;
    }

    final camera = widget.cameras.first;

    controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller!.initialize();

      if (!mounted) return;

      setState(() {
        cameraReady = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        cameraReady = false;
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> saveScan() async {
    final sectionName = scanSectionName(widget.section);

    final scan = ScanRecord(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      number: nextNumber,
      section: sectionName,
      note: 'ข้อมูลจากการสแกนครั้งที่ $nextNumber',
    );

    widget.item.scans.add(scan);

    // เก็บข้อมูลรายการสแกน แต่ไม่เก็บไฟล์รูป
    await AmuletDatabase.update(widget.item);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'บันทึก $sectionName ครั้งที่ $nextNumber แล้ว',
        ),
      ),
    );

    setState(() {
      nextNumber++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sectionName = scanSectionName(widget.section);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'สแกน: $sectionName',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: cameraReady && controller != null
                ? CameraPreview(controller!)
                : const Center(
                    child: Text(
                      'กำลังเปิดกล้อง...',
                    ),
                  ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  widget.item.name.isEmpty
                      ? 'ยังไม่มีชื่อ'
                      : widget.item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  sectionName,
                  style: const TextStyle(
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'สแกนครั้งที่ $nextNumber',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 12),

                FilledButton.icon(
                  onPressed: saveScan,
                  icon: const Icon(
                    Icons.check,
                  ),
                  label: const Text(
                    'บันทึกข้อมูลสแกน',
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'ระบบจะไม่บันทึกรูปพระลงเครื่อง',
                  style: TextStyle(
                    fontSize: 12,
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

// ============================================================
// SAVED LIST PAGE
// ============================================================

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

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    loadData();

    searchController.addListener(
      () {
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final data = await AmuletDatabase.getAll();

    if (!mounted) return;

    setState(() {
      items = data;
    });
  }

  List<AmuletData> get filteredItems {
    final keyword =
        searchController.text.trim().toLowerCase();

    if (keyword.isEmpty) {
      return items;
    }

    return items.where((item) {
      return item.name
              .toLowerCase()
              .contains(keyword) ||
          item.model
              .toLowerCase()
              .contains(keyword);
    }).toList();
  }

  Future<void> openItem(AmuletData item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DataPage(
          cameras: widget.cameras,
          item: item,
          isNew: false,
        ),
      ),
    );

    await loadData();
  }

  Future<void> deleteItem(AmuletData item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ลบรายการ'),
          content: Text(
            'ต้องการลบ "${item.name}" ใช่หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await AmuletDatabase.delete(item.id);

    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการบันทึก'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'ค้นหาชื่อพระ',
                hintText: 'พิมพ์ชื่อพระ',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon:
                    searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              searchController.clear();
                            },
                            icon: const Icon(
                              Icons.clear,
                            ),
                          ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'ไม่พบรายการ',
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];

                      return Dismissible(
                        key: ValueKey(item.id),
                        direction:
                            DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          await deleteItem(item);
                          return false;
                        },
                        background: Container(
                          color: Colors.red,
                          alignment:
                              Alignment.centerRight,
                          padding:
                              const EdgeInsets.only(
                            right: 20,
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.book,
                          ),
                          title: Text(
                            item.name.isEmpty
                                ? 'ยังไม่มีชื่อ'
                                : item.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                          ),
                          onTap: () {
                            openItem(item);
                          },
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
