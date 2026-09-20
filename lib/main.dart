import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(App(cameras));
}

// =====================================================
// APP
// =====================================================

class App extends StatelessWidget {
  final List cameras;

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

const areas = [
  'ด้านหน้า',
  'ด้านหลัง',
  'ด้านข้าง',
  'ก้นพระ',
];

const types = [
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

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'quality': quality,
      'details': details,
      'brightness': brightness,
      'sharpness': sharpness,
      'fromGallery': fromGallery,
    };
  }

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
  final int referenceNumber;
  final String createdAt;

  String name;
  String model;
  String pim;
  String type;
  String temple;

  List scans;

  ReferenceData({
    required this.id,
    required this.referenceNumber,
    required this.createdAt,
    required this.name,
    required this.model,
    required this.pim,
    required this.type,
    required this.temple,
    required this.scans,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referenceNumber': referenceNumber,
      'createdAt': createdAt,
      'name': name,
      'model': model,
      'pim': pim,
      'type': type,
      'temple': temple,
      'scans': scans.map((e) => e.toMap()).toList(),
    };
  }

  factory ReferenceData.fromMap(Map<String, dynamic> map) {
    final rawScans = map['scans'];

    final List scanList = [];

    if (rawScans is List) {
      for (final scan in rawScans) {
        if (scan is Map) {
          try {
            scanList.add(
              ScanResult.fromMap(
                Map<String, dynamic>.from(scan),
              ),
            );
          } catch (_) {
            // ข้ามข้อมูลสแกนที่เสีย
          }
        }
      }
    }

    return ReferenceData(
      id: map['id']?.toString() ?? '',
      referenceNumber:
          int.tryParse(
                map['referenceNumber']?.toString() ?? '',
              ) ??
              0,
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
  static const String numberKey = 'last_reference_number';

  static Future load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final raw = prefs.getString(dataKey);

      if (raw == null || raw.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      final List<ReferenceData> result = [];

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        try {
          final reference = ReferenceData.fromMap(
            Map<String, dynamic>.from(item),
          );

          result.add(reference);
        } catch (_) {
          // ข้ามข้อมูลรายการที่อ่านไม่ได้
        }
      }

      return result;
    } catch (_) {
      return [];
    }
  }

  static Future save(List data) async {
    await _write(data);
  }

  static Future _write(List data) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = jsonEncode(
      data.map((e) => e.toMap()).toList(),
    );

    await prefs.setString(dataKey, raw);
  }

  static Future nextReferenceNumber() async {
    final prefs = await SharedPreferences.getInstance();

    int last = prefs.getInt(numberKey) ?? 0;

    last++;

    await prefs.setInt(numberKey, last);

    return last;
  }

  static Future updateReference(
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

  static Future updateReferenceInfo({
    required String id,
    required String name,
    required String model,
    required String pim,
    required String type,
    required String temple,
  }) async {
    final list = await load();

    final index = list.indexWhere(
      (e) => e.id == id,
    );

    if (index < 0) return;

    list[index].name = name;
    list[index].model = model;
    list[index].pim = pim;
    list[index].type = type;
    list[index].temple = temple;

    await _write(list);
  }

  static Future deleteReference(String id) async {
    final list = await load();

    list.removeWhere(
      (e) => e.id == id,
    );

    await _write(list);
  }

  // ลบเฉพาะรายการหลักที่ตรงกันครบทั้ง 5 ข้อมูล
  static Future deleteGroup({
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
// HOME PAGE
// =====================================================

class HomePage extends StatefulWidget {
  final List cameras;

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

  // นับ "รายการหลัก" ไม่ใช่จำนวนองค์อ้างอิง
  Future loadCount() async {
    final data = await ReferenceStorage.load();

    final Map<String, bool> uniqueGroups = {};

    for (final item in data) {
      final key = [
        item.name,
        item.model,
        item.pim,
        item.type,
        item.temple,
      ].join('|||');

      uniqueGroups[key] = true;
    }

    if (!mounted) return;

    setState(() {
      savedCount = uniqueGroups.length;
    });
  }

  Future createData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReferencePage(
          cameras: widget.cameras,
        ),
      ),
    );

    loadCount();
  }

  Future openSavedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedDataPage(
          cameras: widget.cameras,
        ),
      ),
    );

    loadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'กล้องสแกนพระและเหรียญ',
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: loadCount,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            _menuCard(
              icon: Icons.add_circle_outline,
              title: 'สร้าง / บันทึกข้อมูล',
              subtitle: 'สร้างข้อมูลพระหรือเหรียญองค์อ้างอิงใหม่',
              onTap: createData,
            ),
            const SizedBox(height: 12),
            _menuCard(
              icon: Icons.folder_open,
              title: 'รายการข้อมูลที่บันทึก',
              subtitle: 'ข้อมูลหลักทั้งหมด $savedCount รายการ',
              onTap: openSavedData,
            ),
            const SizedBox(height: 12),
            _menuCard(
              icon: Icons.import_export,
              title: 'สำรอง / นำเข้าข้อมูล',
              subtitle: 'เมนูสำหรับจัดการข้อมูลสำรอง',
              onTap: () {
                _message(
                  'ระบบสำรอง / นำเข้าข้อมูลจะเพิ่มในขั้นตอนถัดไป',
                );
              },
            ),
            const SizedBox(height: 12),
            _menuCard(
              icon: Icons.settings,
              title: 'ตั้งค่า',
              subtitle: 'ตั้งค่าการทำงานของแอป',
              onTap: () {
                _message(
                  'ระบบตั้งค่าจะเพิ่มในขั้นตอนถัดไป',
                );
              },
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }
}

// =====================================================
// SAVED DATA PAGE
// =====================================================

class SavedDataPage extends StatefulWidget {
  final List cameras;

  const SavedDataPage({
    super.key,
    required this.cameras,
  });

  @override
  State<SavedDataPage> createState() => _SavedDataPageState();
}

class _SavedDataPageState extends State<SavedDataPage> {
  List references = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future loadData() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final data = await ReferenceStorage.load();

      data.sort(
        (a, b) =>
            a.referenceNumber.compareTo(
              b.referenceNumber,
            ),
      );

      if (!mounted) return;

      setState(() {
        references = data;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        references = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ไม่สามารถอ่านรายการข้อมูลที่บันทึกได้',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ===================================================
  // จัดกลุ่มรายการหลัก
  // ใช้ข้อมูล 5 ช่องเป็นตัวระบุรายการหลัก
  // ===================================================

  Map<String, List> groupedData() {
    final Map<String, List> groups = {};

    for (final item in references) {
      final key = [
        item.name,
        item.model,
        item.pim,
        item.type,
        item.temple,
      ].join('|||');

      groups.putIfAbsent(
        key,
        () => [],
      );

      groups[key]!.add(item);
    }

    return groups;
  }

  Future openGroup(
    List group,
  ) async {
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

    loadData();
  }

  Future deleteGroup(
    List group,
  ) async {
    if (group.isEmpty) return;

    final first = group.first;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('ลบรายการหลัก?'),
          content: Text(
            'ต้องการลบรายการนี้ทั้งหมดหรือไม่?\n\n'
            'ชื่อพระ: ${first.name}\n'
            '${first.model.isEmpty ? '' : 'รุ่น: ${first.model}\n'}'
            '${first.type.isEmpty ? '' : 'ประเภท: ${first.type}\n'}'
            '${first.pim.isEmpty ? '' : 'พิมพ์: ${first.pim}\n'}'
            '${first.temple.isEmpty ? '' : 'วัด / สำนัก: ${first.temple}\n'}'
            '\n'
            'จะลบองค์อ้างอิงทั้งหมด ${group.length} องค์ในรายการนี้',
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
              child: const Text('ลบทั้งหมด'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await ReferenceStorage.deleteGroup(
      name: first.name,
      model: first.model,
      pim: first.pim,
      type: first.type,
      temple: first.temple,
    );

    loadData();
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupedData();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายการข้อมูลที่บันทึก',
        ),
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
                          style: TextStyle(
                            fontSize: 18,
                          ),
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

          loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('สร้างข้อมูล'),
      ),
    );
  }

  Widget _groupCard(
    List group,
  ) {
    final first = group.first;

    int scanCount = 0;

    for (final item in group) {
      scanCount += item.scans.length;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              first.name.isEmpty
                  ? 'ไม่ระบุชื่อ'
                  : first.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (first.model.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'รุ่น: ${first.model}',
                ),
              ),
            if (first.type.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'ประเภท: ${first.type}',
                ),
              ),
            if (first.pim.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'พิมพ์: ${first.pim}',
                ),
              ),
            if (first.temple.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'วัด / สำนัก: ${first.temple}',
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'มี ${group.length} องค์อ้างอิง',
            ),
            Text(
              'มีข้อมูลการสแกน $scanCount รายการ',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      openGroup(group);
                    },
                    icon: const Icon(
                      Icons.visibility,
                    ),
                    label: const Text('ดู / เพิ่มอ้างอิง'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'ลบรายการหลัก',
                  onPressed: () {
                    deleteGroup(group);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
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
// CREATE REFERENCE PAGE
// =====================================================

class CreateReferencePage extends StatefulWidget {
  final List cameras;

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

    nameController.text =
        widget.initialName ?? '';

    modelController.text =
        widget.initialModel ?? '';

    pimController.text =
        widget.initialPim ?? '';

    templeController.text =
        widget.initialTemple ?? '';

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

  Future startScan() async {
    final name = nameController.text.trim();
    final model = modelController.text.trim();
    final pim = pimController.text.trim();
    final temple = templeController.text.trim();

    if (name.isEmpty) {
      msg('กรุณาใส่ชื่อพระ');
      return;
    }

    if (selectedType == null ||
        selectedType!.trim().isEmpty) {
      msg('กรุณาเลือกประเภท');
      return;
    }

    await Navigator.push(
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
  }

  void msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'สร้าง / บันทึกข้อมูล',
        ),
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
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedType = value;
              });
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
                'หลังจากกดเริ่มสแกน สามารถเลือกถ่ายภาพ '
                'หรือเลือกรูปเพื่อเก็บเฉพาะข้อมูลการวิเคราะห์ '
                'โดยแอปจะไม่เก็บไฟล์รูปภาพไว้เป็นข้อมูลอ้างอิง',
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: startScan,
              icon: const Icon(
                Icons.camera_alt,
              ),
              label: const Text(
                'เริ่มสแกนและบันทึกข้อมูล',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// REFERENCE LIST PAGE
// =====================================================

class ReferenceListPage extends StatefulWidget {
  final List cameras;

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
  List references = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadReferences();
  }

  Future loadReferences() async {
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
      (a, b) =>
          a.referenceNumber.compareTo(
            b.referenceNumber,
          ),
    );

    if (!mounted) return;

    setState(() {
      references = filtered;
      loading = false;
    });
  }

  Future addNewReference() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReferencePage(
          cameras: widget.cameras,
          initialName: widget.name,
          initialModel: widget.model,
          initialPim: widget.pim,
          initialType: widget.type,
          initialTemple: widget.temple,
        ),
      ),
    );

    loadReferences();
  }

  Future openEdit(
    ReferenceData reference,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditReferencePage(
          cameras: widget.cameras,
          reference: reference,
        ),
      ),
    );

    loadReferences();
  }

  Future deleteReference(
    ReferenceData reference,
  ) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('ลบองค์นี้?'),
          content: Text(
            'ต้องการลบองค์อ้างอิงลำดับ '
            '${reference.referenceNumber} หรือไม่?\n\n'
            'ข้อมูลการสแกนขององค์นี้จะถูกลบทั้งหมด',
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

    await ReferenceStorage.deleteReference(
      reference.id,
    );

    loadReferences();
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
                  child: Text(
                    'ยังไม่มีองค์อ้างอิง',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: references.length,
                  itemBuilder: (context, index) {
                    final item = references[index];

                    return _referenceCard(item);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addNewReference,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มองค์อ้างอิง'),
      ),
    );
  }

  Widget _referenceCard(
    ReferenceData item,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'องค์อ้างอิงลำดับ ${item.referenceNumber}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ชื่อพระ: ${item.name}',
            ),
            if (item.model.isNotEmpty)
              Text(
                'รุ่น: ${item.model}',
              ),
            if (item.type.isNotEmpty)
              Text(
                'ประเภท: ${item.type}',
              ),
            if (item.pim.isNotEmpty)
              Text(
                'พิมพ์: ${item.pim}',
              ),
            if (item.temple.isNotEmpty)
              Text(
                'วัด / สำนัก: ${item.temple}',
              ),
            const SizedBox(height: 6),
            Text(
              'ข้อมูลสแกน ${item.scans.length} ด้าน',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReferenceDetailPage(
                            reference: item,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.visibility,
                    ),
                    label: const Text('ดูข้อมูล'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'แก้ไข',
                  onPressed: () {
                    openEdit(item);
                  },
                  icon: const Icon(
                    Icons.edit,
                  ),
                ),
                IconButton(
                  tooltip: 'ลบ',
                  onPressed: () {
                    deleteReference(item);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
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
          'องค์อ้างอิง ${reference.referenceNumber}',
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
                child: Text(
                  'ยังไม่มีข้อมูลการสแกน',
                ),
              ),
            ),
          for (final scan in reference.scans)
            _scanCard(scan),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'องค์อ้างอิงลำดับ ${reference.referenceNumber}',
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

  Widget _scanCard(
    ScanResult scan,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              scan.area,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'คุณภาพ: ${scan.quality}',
            ),
            const SizedBox(height: 6),
            Text(
              scan.details,
            ),
            const SizedBox(height: 6),
            Text(
              scan.fromGallery
                  ? 'แหล่งภาพ: เลือกจากคลังรูป'
                  : 'แหล่งภาพ: กล้อง',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// EDIT REFERENCE PAGE
// =====================================================

class EditReferencePage extends StatefulWidget {
  final List cameras;
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

    if (selectedType == null ||
        selectedType!.isEmpty) {
      msg('กรุณาเลือกประเภท');
      return null;
    }

    final updated = ReferenceData(
      id: widget.reference.id,
      referenceNumber:
          widget.reference.referenceNumber,
      createdAt: widget.reference.createdAt,
      name: name,
      model: model,
      pim: pim,
      type: selectedType!,
      temple: temple,
      scans: List<ScanResult>.from(
        widget.reference.scans,
      ),
    );

    await ReferenceStorage.updateReference(
      updated,
    );

    return updated;
  }

  Future saveOnly() async {
    final updated = await saveBasicInfo();

    if (updated == null) return;

    if (!mounted) return;

    msg('บันทึกข้อมูลแล้ว');

    Navigator.pop(context);
  }

  Future editAndScan() async {
    final updated = await saveBasicInfo();

    if (updated == null) return;

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          existingReference: updated,
        ),
      ),
    );
  }

  void msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'แก้ไของค์ ${widget.reference.referenceNumber}',
        ),
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
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedType = value;
              });
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
              label: const Text(
                'บันทึกข้อมูล',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: editAndScan,
              icon: const Icon(
                Icons.camera_alt,
              ),
              label: const Text(
                'แก้ไขและสแกนข้อมูล',
              ),
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
  final List cameras;

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

  bool get isEditMode =>
      widget.existingReference != null;

  @override
  void initState() {
    super.initState();

    if (widget.existingReference != null) {
      for (final scan
          in widget.existingReference!.scans) {
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

  Future startCamera() async {
    if (widget.cameras.isEmpty) {
      if (!mounted) return;

      setState(() {
        loadingCamera = false;
      });

      return;
    }

    CameraDescription selectedCamera =
        widget.cameras.first;

    for (final camera in widget.cameras) {
      if (camera.lensDirection ==
          CameraLensDirection.back) {
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

      setState(() {
        loadingCamera = false;
      });
    } catch (_) {
      await newController.dispose();

      if (!mounted) return;

      setState(() {
        loadingCamera = false;
      });

      msg('ไม่สามารถเปิดกล้องได้');
    }
  }

  Future takePhoto() async {
    if (controller == null ||
        !controller!.value.isInitialized) {
      msg('กล้องยังไม่พร้อม');
      return;
    }

    try {
      final XFile file =
          await controller!.takePicture();

      await saveScanResult(
        currentArea,
