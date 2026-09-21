import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App(await availableCameras()));
}

class App extends StatelessWidget {
  final List<CameraDescription> cameras;

  const App(this.cameras, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'กล้องสแกนพระและเหรียญ',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.brown,
      ),
      home: HomePage(cameras: cameras),
    );
  }
}

// =====================================================
// CONSTANTS
// =====================================================

const List<String> areas = [
  'ด้านหน้า',
  'ด้านหลัง',
  'ด้านข้าง',
  'ก้นพระ',
];

const List<String> types = [
  'เหรียญ',
  'เหรียญหล่อ',
  'พระสมเด็จ',
  'รูปหล่อ',
  'พระกริ่ง',
  'พระปิดตาเนื้อผง/หว้าน',
  'พระปิดตาเนื้อโลหะ',
  'พระเนื้อผง',
  'พระเนื้อดิน',
  'นางพญา',
  'ผงสุพรรณ',
  'พระรอด',
  'พระซุ้มกอ',
  'พระขุนแผน',
  'หลวงปู่ทวดเนื้อหว้าน',
  'หลวงปู่ทวดหลังเตารีด',
  'เขี้ยวแกะ',
  'งาแกะ',
  'ตะกรุด',
  'อื่น ๆ',
];

// =====================================================
// SCAN RESULT
// =====================================================

class ScanResult {
  final String area;
  final String quality;
  final String details;
  final double brightness;
  final double sharpness;
  final bool fromGallery;

  ScanResult({
    required this.area,
    required this.quality,
    required this.details,
    required this.brightness,
    required this.sharpness,
    required this.fromGallery,
  });

  Map<String, dynamic> toMap() => {
        'area': area,
        'quality': quality,
        'details': details,
        'brightness': brightness,
        'sharpness': sharpness,
        'fromGallery': fromGallery,
      };

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      area: map['area']?.toString() ?? '',
      quality: map['quality']?.toString() ?? '',
      details: map['details']?.toString() ?? '',
      brightness: (map['brightness'] as num?)?.toDouble() ?? 0,
      sharpness: (map['sharpness'] as num?)?.toDouble() ?? 0,
      fromGallery: map['fromGallery'] == true,
    );
  }
}

// =====================================================
// REFERENCE DATA
// =====================================================

class ReferenceData {
  final String id;
  final String createdAt;

  String name;
  String model;
  String pim;
  String type;
  String temple;

  List<ScanResult> scans;

  ReferenceData({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.model,
    required this.pim,
    required this.type,
    required this.temple,
    required this.scans,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'createdAt': createdAt,
        'name': name,
        'model': model,
        'pim': pim,
        'type': type,
        'temple': temple,
        'scans': scans.map((e) => e.toMap()).toList(),
      };

  factory ReferenceData.fromMap(Map<String, dynamic> map) {
    final rawScans = map['scans'];
    final List<ScanResult> scanList = [];

    if (rawScans is List) {
      for (final scan in rawScans) {
        if (scan is Map) {
          try {
            scanList.add(
              ScanResult.fromMap(Map<String, dynamic>.from(scan)),
            );
          } catch (_) {}
        }
      }
    }

    return ReferenceData(
      id: map['id']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      model: map['model']?.toString() ?? '',
      pim: map['pim']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      temple: map['temple']?.toString() ?? '',
      scans: scanList,
    );
  }
}

// =====================================================
// STORAGE
// =====================================================

class ReferenceStorage {
  static const String dataKey = 'reference_data';

  static Future<List<ReferenceData>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(dataKey);

      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final result = <ReferenceData>[];

      for (final item in decoded) {
        if (item is! Map) continue;

        try {
          result.add(
            ReferenceData.fromMap(
              Map<String, dynamic>.from(item),
            ),
          );
        } catch (_) {}
      }

      return result;
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<ReferenceData> data) async {
    await _write(data);
  }

  static Future<void> _write(List<ReferenceData> data) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      dataKey,
      jsonEncode(data.map((e) => e.toMap()).toList()),
    );
  }

  static Future<void> updateReference(
    ReferenceData reference,
  ) async {
    final list = await load();

    final index = list.indexWhere(
      (e) => e.id == reference.id,
    );

    if (index >= 0) {
      list[index] = reference;
    } else {
      list.add(reference);
    }

    await _write(list);
  }

  static Future<void> deleteReference(String id) async {
    final list = await load();

    list.removeWhere((e) => e.id == id);

    await _write(list);
  }

  static Future<void> deleteGroup({
    required String name,
    required String model,
    required String pim,
    required String type,
    required String temple,
  }) async {
    final list = await load();

    list.removeWhere(
      (e) =>
          e.name == name &&
          e.model == model &&
          e.pim == pim &&
          e.type == type &&
          e.temple == temple,
    );

    await _write(list);
  }
}

// =====================================================
// HOME
// =====================================================

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage({
    super.key,
    required this.cameras,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int savedCount = 0;

  @override
  void initState() {
    super.initState();
    loadCount();
  }

  Future<void> loadCount() async {
    final data = await ReferenceStorage.load();
    final groups = <String>{};

    for (final item in data) {
      groups.add([
        item.name.trim(),
        item.model.trim(),
        item.pim.trim(),
        item.type.trim(),
        item.temple.trim(),
      ].join('|||'));
    }

    if (!mounted) return;

    setState(() {
      savedCount = groups.length;
    });
  }

  Future<void> createData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReferencePage(
          cameras: widget.cameras,
        ),
      ),
    );

    await loadCount();
  }

  Future<void> openSavedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedDataPage(
          cameras: widget.cameras,
        ),
      ),
    );

    await loadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('กล้องสแกนพระและเหรียญ'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: loadCount,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            _menuCard(
              Icons.add_circle_outline,
              'สร้าง / บันทึกข้อมูล',
              'สร้างข้อมูลพระหรือเหรียญองค์อ้างอิงใหม่',
              createData,
            ),
            const SizedBox(height: 12),
            _menuCard(
              Icons.folder_open,
              'รายการข้อมูลที่บันทึก',
              'ข้อมูลหลักทั้งหมด $savedCount รายการ',
              openSavedData,
            ),
            const SizedBox(height: 12),
            _menuCard(
              Icons.import_export,
              'สำรอง / นำเข้าข้อมูล',
              'เมนูสำหรับจัดการข้อมูลสำรอง',
              () => msg(
                'ระบบสำรอง / นำเข้าข้อมูลจะเพิ่มในขั้นตอนถัดไป',
              ),
            ),
            const SizedBox(height: 12),
            _menuCard(
              Icons.settings,
              'ตั้งค่า',
              'ตั้งค่าการทำงานของแอป',
              () => msg(
                'ระบบตั้งค่าจะเพิ่มในขั้นตอนถัดไป',
              ),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สถานะข้อมูลอ้างอิง',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ข้อมูลแต่ละองค์สามารถเพิ่มข้อมูลการสแกนได้หลายครั้ง '
                      'และสามารถเพิ่มองค์อ้างอิงต่อไปได้เรื่อย ๆ',
                    ),
                    SizedBox(height: 6),
                    Text(
                      'ครบ 5 องค์เป็นเพียงตัวช่วยดูสถานะ ไม่ใช่จำนวนสูงสุด',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 25,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  void msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}

// =====================================================
// SAVED DATA
// =====================================================

class SavedDataPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SavedDataPage({
    super.key,
    required this.cameras,
  });

  @override
  State<SavedDataPage> createState() => _SavedDataPageState();
}

class _SavedDataPageState extends State<SavedDataPage> {
  List<ReferenceData> references = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final data = await ReferenceStorage.load();

    data.sort(
      (a, b) => a.createdAt.compareTo(b.createdAt),
    );

    if (!mounted) return;

    setState(() {
      references = data;
      loading = false;
    });
  }

  Map<String, List<ReferenceData>> groupedData() {
    final groups = <String, List<ReferenceData>>{};

    for (final item in references) {
      final key = [
        item.name.trim(),
        item.model.trim(),
        item.pim.trim(),
        item.type.trim(),
        item.temple.trim(),
      ].join('|||');

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(item);
    }

    return groups;
  }

  Future<void> openGroup(List<ReferenceData> group) async {
    if (group.isEmpty) return;

    final first = group.first;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReferenceListPage(
          cameras: widget.cameras,
          name: first.name,
          model: first.model,
          pim: first.pim,
          type: first.type,
          temple: first.temple,
        ),
      ),
    );

    await loadData();
  }

  Future<void> deleteGroup(List<ReferenceData> group) async {
    if (group.isEmpty) return;

    final first = group.first;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบรายการหลัก?'),
        content: Text(
          'ต้องการลบรายการนี้ทั้งหมดหรือไม่?\n\n'
          'ชื่อพระ: ${first.name}\n'
          '${first.model.isEmpty ? '' : 'รุ่น: ${first.model}\n'}'
          '${first.type.isEmpty ? '' : 'ประเภท: ${first.type}\n'}'
          '${first.pim.isEmpty ? '' : 'พิมพ์: ${first.pim}\n'}'
          '${first.temple.isEmpty ? '' : 'วัด / สำนัก: ${first.temple}\n'}'
          '\nจะลบองค์อ้างอิงทั้งหมด ${group.length} องค์',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบทั้งหมด'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ReferenceStorage.deleteGroup(
      name: first.name,
      model: first.model,
      pim: first.pim,
      type: first.type,
      temple: first.temple,
    );

    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupedData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการข้อมูลที่บันทึก'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : groups.isEmpty
              ? RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView(
                    children: const [
                      SizedBox(height: 180),
                      Center(
                        child: Text(
                          'ยังไม่มีข้อมูลหลัก',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final group in groups.values)
                        _groupCard(group),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateReferencePage(
                cameras: widget.cameras,
              ),
            ),
          );

          await loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('สร้างข้อมูล'),
      ),
    );
  }

  Widget _groupCard(List<ReferenceData> group) {
    final first = group.first;
    final scanCount =
        group.fold<int>(0, (sum, item) => sum + item.scans.length);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              first.name.isEmpty ? 'ไม่ระบุชื่อ' : first.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (first.model.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('รุ่น: ${first.model}'),
              ),
            if (first.type.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('ประเภท: ${first.type}'),
              ),
            if (first.pim.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('พิมพ์: ${first.pim}'),
              ),
            if (first.temple.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('วัด / สำนัก: ${first.temple}'),
              ),
            const SizedBox(height: 8),
            Text('มี ${group.length} รายการอ้างอิง'),
            Text('มีข้อมูลการสแกน $scanCount รายการ'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openGroup(group),
                    icon: const Icon(Icons.visibility),
                    label: const Text('ดู / เพิ่มอ้างอิง'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'ลบรายการหลัก',
                  onPressed: () => deleteGroup(group),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// CREATE REFERENCE
// =====================================================

class CreateReferencePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  final String? initialName;
  final String? initialModel;
  final String? initialPim;
  final String? initialType;
  final String? initialTemple;

  const CreateReferencePage({
    super.key,
    required this.cameras,
    this.initialName,
    this.initialModel,
    this.initialPim,
    this.initialType,
    this.initialTemple,
  });

  @override
  State<CreateReferencePage> createState() =>
      _CreateReferencePageState();
}

class _CreateReferencePageState
    extends State<CreateReferencePage> {
  final nameController = TextEditingController();
  final modelController = TextEditingController();
  final pimController = TextEditingController();
  final templeController = TextEditingController();

  String? selectedType;

  @override
  void initState() {
    super.initState();

    nameController.text = widget.initialName ?? '';
    modelController.text = widget.initialModel ?? '';
    pimController.text = widget.initialPim ?? '';
    templeController.text = widget.initialTemple ?? '';
    selectedType = widget.initialType;
  }

  @override
  void dispose() {
    nameController.dispose();
    modelController.dispose();
    pimController.dispose();
    templeController.dispose();
    super.dispose();
  }

  Future<void> startScan() async {
    final name = nameController.text.trim();
    final model = modelController.text.trim();
    final pim = pimController.text.trim();
    final temple = templeController.text.trim();

    if (name.isEmpty) {
      msg('กรุณาใส่ชื่อพระ');
      return;
    }

    if (selectedType == null || selectedType!.trim().isEmpty) {
      msg('กรุณาเลือกประเภท');
      return;
    }

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          name: name,
          model: model,
          pim: pim,
          type: selectedType!,
          temple: temple,
        ),
      ),
    );

    if (saved == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
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
          const Text(
            'ข้อมูลพื้นฐาน',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'ชื่อพระ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: modelController,
            decoration: const InputDecoration(
              labelText: 'รุ่น / แบบ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedType,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'ประเภท',
              border: OutlineInputBorder(),
            ),
            items: types
                .map(
                  (type) => DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => selectedType = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pimController,
            decoration: const InputDecoration(
              labelText: 'พิมพ์',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: templeController,
            decoration: const InputDecoration(
              labelText: 'วัด / สำนัก',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'หลังจากกดเริ่มสแกน สามารถเลือกถ่ายภาพหรือเลือกรูป '
                'เพื่อเก็บเฉพาะข้อมูลการวิเคราะห์ '
                'โดยแอปจะไม่เก็บไฟล์รูปภาพไว้เป็นข้อมูลอ้างอิง',
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: startScan,
              icon: const Icon(Icons.camera_alt),
              label: const Text(
                'เริ่มสแกนและบันทึกข้อมูล',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// REFERENCE LIST
// =====================================================

class ReferenceListPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  final String name;
  final String model;
  final String pim;
  final String type;
  final String temple;

  const ReferenceListPage({
    super.key,
    required this.cameras,
    required this.name,
    required this.model,
    required this.pim,
    required this.type,
    required this.temple,
  });

  @override
  State<ReferenceListPage> createState() =>
      _ReferenceListPageState();
}

class _ReferenceListPageState
    extends State<ReferenceListPage> {
  List<ReferenceData> references = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadReferences();
  }

  Future<void> loadReferences() async {
    final all = await ReferenceStorage.load();

    final filtered = all
        .where(
          (e) =>
              e.name == widget.name &&
              e.model == widget.model &&
              e.pim == widget.pim &&
              e.type == widget.type &&
              e.temple == widget.temple,
        )
        .toList();

    filtered.sort(
      (a, b) => a.createdAt.compareTo(b.createdAt),
    );

    if (!mounted) return;

    setState(() {
      references = filtered;
      loading = false;
    });
  }

  // ===================================================
  // สำคัญ:
  // + เพิ่มองค์อ้างอิง
  // เปิด ScanPage โดยตรง
  // ใช้ข้อมูลกลุ่มเดิม
  // และสร้างองค์ใหม่ ไม่แก้ของเดิม
  // ===================================================

  Future<void> addNewReference() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          name: widget.name,
          model: widget.model,
          pim: widget.pim,
          type: widget.type,
          temple: widget.temple,
        ),
      ),
    );

    if (saved == true) {
      await loadReferences();
    }
  }

  Future<void> openEdit(ReferenceData reference) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditReferencePage(
          cameras: widget.cameras,
          reference: reference,
        ),
      ),
    );

    await loadReferences();
  }

  Future<void> deleteReference(ReferenceData reference) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบองค์นี้?'),
        content: const Text(
          'ต้องการลบองค์อ้างอิงนี้หรือไม่?\n\n'
          'ข้อมูลการสแกนขององค์นี้จะถูกลบทั้งหมด',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ReferenceStorage.deleteReference(reference.id);
    await loadReferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.name.isEmpty
              ? 'รายการอ้างอิง'
              : widget.name,
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : references.isEmpty
              ? const Center(
                  child: Text('ยังไม่มีองค์อ้างอิง'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: references.length,
                  itemBuilder: (context, index) {
                    return _referenceCard(references[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addNewReference,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มองค์อ้างอิง'),
      ),
    );
  }

  Widget _referenceCard(ReferenceData item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name.isEmpty ? 'ไม่ระบุชื่อ' : item.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (item.model.isNotEmpty)
              Text('รุ่น: ${item.model}'),
            if (item.type.isNotEmpty)
              Text('ประเภท: ${item.type}'),
            if (item.pim.isNotEmpty)
              Text('พิมพ์: ${item.pim}'),
            if (item.temple.isNotEmpty)
              Text('วัด / สำนัก: ${item.temple}'),
            const SizedBox(height: 6),
            Text('ข้อมูลสแกน ${item.scans.length} ด้าน'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReferenceDetailPage(
                            reference: item,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('ดูข้อมูล'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'แก้ไข',
                  onPressed: () => openEdit(item),
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  tooltip: 'ลบ',
                  onPressed: () => deleteReference(item),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// REFERENCE DETAIL
// =====================================================

class ReferenceDetailPage extends StatelessWidget {
  final ReferenceData reference;

  const ReferenceDetailPage({
    super.key,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          reference.name.isEmpty
              ? 'รายละเอียดองค์อ้างอิง'
              : reference.name,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(),
          const SizedBox(height: 14),
          const Text(
            'ข้อมูลการสแกน',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (reference.scans.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('ยังไม่มีข้อมูลการสแกน'),
              ),
            ),
          for (final scan in reference.scans) _scanCard(scan),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reference.name.isEmpty
                  ? 'ไม่ระบุชื่อ'
                  : reference.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('ชื่อพระ: ${reference.name}'),
            Text('รุ่น: ${reference.model}'),
            Text('ประเภท: ${reference.type}'),
            Text('พิมพ์: ${reference.pim}'),
            Text('วัด / สำนัก: ${reference.temple}'),
          ],
        ),
      ),
    );
  }

  Widget _scanCard(ScanResult scan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scan.area,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text('คุณภาพ: ${scan.quality}'),
            const SizedBox(height: 6),
            Text(scan.details),
            const SizedBox(height: 6),
            Text(
              scan.fromGallery
                  ? 'แหล่งภาพ: เลือกจากคลังรูป'
                  : 'แหล่งภาพ: กล้อง',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// EDIT REFERENCE
// =====================================================

class EditReferencePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final ReferenceData reference;

  const EditReferencePage({
    super.key,
    required this.cameras,
    required this.reference,
  });

  @override
  State<EditReferencePage> createState() =>
      _EditReferencePageState();
}

class _EditReferencePageState
    extends State<EditReferencePage> {
  late TextEditingController nameController;
  late TextEditingController modelController;
  late TextEditingController pimController;
  late TextEditingController templeController;

  String? selectedType;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.reference.name,
    );
    modelController = TextEditingController(
      text: widget.reference.model,
    );
    pimController = TextEditingController(
      text: widget.reference.pim,
    );
    templeController = TextEditingController(
      text: widget.reference.temple,
    );

    selectedType = widget.reference.type;
  }

  @override
  void dispose() {
    nameController.dispose();
    modelController.dispose();
    pimController.dispose();
    templeController.dispose();
    super.dispose();
  }

  Future<ReferenceData?> saveBasicInfo() async {
    final name = nameController.text.trim();
    final model = modelController.text.trim();
    final pim = pimController.text.trim();
    final temple = templeController.text.trim();

    if (name.isEmpty) {
      msg('กรุณาใส่ชื่อพระ');
      return null;
    }

    if (selectedType == null || selectedType!.isEmpty) {
      msg('กรุณาเลือกประเภท');
      return null;
    }

    final updated = ReferenceData(
      id: widget.reference.id,
      createdAt: widget.reference.createdAt,
      name: name,
      model: model,
      pim: pim,
      type: selectedType!,
      temple: temple,
      scans: List<ScanResult>.from(widget.reference.scans),
    );

    await ReferenceStorage.updateReference(updated);
    return updated;
  }

  Future<void> saveOnly() async {
    final updated = await saveBasicInfo();

    if (updated == null || !mounted) return;

    msg('บันทึกข้อมูลแล้ว');
    Navigator.pop(context);
  }

  Future<void> editAndScan() async {
    final updated = await saveBasicInfo();

    if (updated == null || !mounted) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          existingReference: updated,
        ),
      ),
    );

    if (saved == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูล'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'ชื่อพระ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: modelController,
            decoration: const InputDecoration(
              labelText: 'รุ่น / แบบ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: types.contains(selectedType)
                ? selectedType
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'ประเภท',
              border: OutlineInputBorder(),
            ),
            items: types
                .map(
                  (type) => DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => selectedType = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pimController,
            decoration: const InputDecoration(
              labelText: 'พิมพ์',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: templeController,
            decoration: const InputDecoration(
              labelText: 'วัด / สำนัก',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: saveOnly,
              icon: const Icon(Icons.save),
              label: const Text('บันทึกข้อมูล'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: editAndScan,
              icon: const Icon(Icons.camera_alt),
              label: const Text('แก้ไขและสแกนข้อมูล'),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// SCAN PAGE
// =====================================================

class ScanPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  final String? name;
  final String? model;
  final String? pim;
  final String? type;
  final String? temple;

  final ReferenceData? existingReference;

  const ScanPage({
    super.key,
    required this.cameras,
    this.name,
    this.model,
    this.pim,
    this.type,
    this.temple,
    this.existingReference,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? controller;
  final ImagePicker picker = ImagePicker();

  String currentArea = areas.first;
  final Map<String, ScanResult> results = {};

  bool loadingCamera = true;
  bool saving = false;

  bool get isEditMode => widget.existingReference != null;

  @override
  void initState() {
    super.initState();

    if (widget.existingReference != null) {
      for (final scan in widget.existingReference!.scans) {
        results[scan.area] = scan;
      }

      for (final area in areas) {
        if (!results.containsKey(area)) {
          currentArea = area;
          break;
        }
      }
    }

    startCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> startCamera() async {
    if (widget.cameras.isEmpty) {
      if (!mounted) return;
      setState(() => loadingCamera = false);
      return;
    }

    CameraDescription selectedCamera = widget.cameras.first;

    for (final camera in widget.cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        selectedCamera = camera;
        break;
      }
    }

    final newController = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await newController.initialize();

      if (!mounted) {
        await newController.dispose();
        return;
      }

      controller = newController;

      setState(() => loadingCamera = false);
    } catch (_) {
      await newController.dispose();

      if (!mounted) return;

      setState(() => loadingCamera = false);
      msg('ไม่สามารถเปิดกล้องได้');
    }
  }

  Future<void> takePhoto() async {
    if (controller == null ||
        !controller!.value.isInitialized) {
      msg('กล้องยังไม่พร้อม');
      return;
    }

    try {
      final XFile file = await controller!.takePicture();

      await saveScanResult(
        currentArea,
        fromGallery: false,
      );

      try {
        await File(file.path).delete();
      } catch (_) {}
    } catch (_) {
      msg('ถ่ายภาพไม่สำเร็จ');
    }
  }

  Future<void> chooseGallery() async {
    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (file == null) return;

      await saveScanResult(
        currentArea,
        fromGallery: true,
      );
    } catch (_) {
      msg('ไม่สามารถเลือกรูปได้');
    }
  }

  Future<void> saveScanResult(
    String area, {
    required bool fromGallery,
  }) async {
    final result = ScanResult(
      area: area,
      brightness: 0,
      sharpness: 0,
      quality: 'พร้อมสำหรับเก็บข้อมูลอ้างอิง',
      details: 'รอระบบ AI วิเคราะห์รายละเอียดทั้งหมดที่มองเห็นในองค์พระ',
      fromGallery: fromGallery,
    );

    if (!mounted) return;

    setState(() {
      results[area] = result;
    });

    msg('บันทึกข้อมูล $area แล้ว');
  }

  Future<void> exitScan() async {
    if (results.isEmpty) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('ออกจากการสแกน?'),
          content: const Text('ยังไม่มีข้อมูลการสแกน'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('อยู่ต่อ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ออก'),
            ),
          ],
        ),
      );

      if (leave == true && mounted) {
        Navigator.pop(context);
      }

      return;
    }

    await saveReference();
  }

  Future<void> saveReference() async {
    if (saving) return;

    setState(() => saving = true);

    try {
      final scanList = results.values.toList();

      // แก้ไของค์เดิม
      if (isEditMode) {
        final old = widget.existingReference!;

        final updated = ReferenceData(
          id: old.id,
          createdAt: old.createdAt,
          name: old.name,
          model: old.model,
          pim: old.pim,
          type: old.type,
          temple: old.temple,
          scans: scanList,
        );

        await ReferenceStorage.updateReference(updated);

        if (!mounted) return;

        msg('บันทึกการแก้ไขข้อมูลแล้ว');
        Navigator.pop(context, true);
        return;
      }

      // =================================================
      // สร้างองค์อ้างอิงใหม่
      //
      // ข้อมูล name/model/pim/type/temple
      // ถูกส่งมาจากกลุ่มเดิม
      //
      // ดังนั้น + เพิ่มองค์อ้างอิง
      // จะสร้างองค์ใหม่ในกลุ่มเดิมเสมอ
      // =================================================

      final now = DateTime.now().toIso8601String();

      final reference = ReferenceData(
        id: now,
        createdAt: now,
        name: widget.name ?? '',
        model: widget.model ?? '',
        pim: widget.pim ?? '',
        type: widget.type ?? '',
        temple: widget.temple ?? '',
        scans: scanList,
      );

      await ReferenceStorage.updateReference(reference);

      if (!mounted) return;

      msg('บันทึกองค์อ้างอิงใหม่เรียบร้อยแล้ว');
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        msg('เกิดข้อผิดพลาดในการบันทึกข้อมูล');
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void msg(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget areaButton(String area) {
    final selected = currentArea == area;
    final hasData = results.containsKey(area);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: selected
                ? Colors.brown.withOpacity(0.12)
                : null,
          ),
          onPressed: () {
            setState(() => currentArea = area);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                area,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (hasData)
                const Icon(
                  Icons.check_circle,
                  size: 15,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady =
        controller != null &&
        controller!.value.isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode
              ? 'แก้ไขและสแกนข้อมูล'
              : 'สแกนข้อมูลอ้างอิง',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
            child: Row(
              children: [
                for (final area in areas) areaButton(area),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'กำลังเก็บข้อมูล: $currentArea',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: loadingCamera
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : cameraReady
                      ? CameraPreview(controller!)
                      : const Center(
                          child: Text(
                            'ไม่พบกล้อง',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            loadingCamera || saving
                                ? null
                                : takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('ถ่ายภาพ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: saving
                            ? null
                            : chooseGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('เลือกรูป'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: saving ? null : exitScan,
                    icon: Icon(
                      isEditMode
                          ? Icons.save
                          : Icons.check,
                    ),
                    label: Text(
                      isEditMode
                          ? 'บันทึกการแก้ไขข้อมูล'
                          : 'ออกและบันทึก',
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
