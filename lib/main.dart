import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(App(cameras));
}

// =====================================================
// APP
// =====================================================

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
      area: map['area'] ?? '',
      quality: map['quality'] ?? '',
      details: map['details'] ?? '',
      brightness: (map['brightness'] ?? 0).toDouble(),
      sharpness: (map['sharpness'] ?? 0).toDouble(),
      fromGallery: map['fromGallery'] ?? false,
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

  final String name;
  final String model;
  final String pim;
  final String type;
  final String temple;

  final List<ScanResult> scans;

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
    return ReferenceData(
      id: map['id'] ?? '',
      referenceNumber: map['referenceNumber'] ?? 0,
      createdAt: map['createdAt'] ?? '',
      name: map['name'] ?? '',
      model: map['model'] ?? '',
      pim: map['pim'] ?? '',
      type: map['type'] ?? '',
      temple: map['temple'] ?? '',
      scans: (map['scans'] as List? ?? [])
          .map(
            (e) => ScanResult.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

// =====================================================
// STORAGE
// =====================================================

class ReferenceStorage {
  static const String key = 'reference_data';

  static Future<List<ReferenceData>> load() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final data = jsonDecode(raw);

      if (data is! List) {
        return [];
      }

      return data
          .map(
            (e) => ReferenceData.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(ReferenceData reference) async {
    final list = await load();

    list.add(reference);

    await _write(list);
  }

  static Future<void> updateReference(
    ReferenceData updated,
  ) async {
    final list = await load();

    final index = list.indexWhere(
      (x) => x.id == updated.id,
    );

    if (index >= 0) {
      list[index] = updated;
    }

    await _write(list);
  }

  static Future<void> updateReferenceInfo({
    required String id,
    required String newName,
    required String newModel,
    required String newPim,
    required String newType,
    required String newTemple,
  }) async {
    final list = await load();

    final index = list.indexWhere(
      (x) => x.id == id,
    );

    if (index >= 0) {
      final old = list[index];

      list[index] = ReferenceData(
        id: old.id,
        referenceNumber: old.referenceNumber,
        createdAt: old.createdAt,
        name: newName,
        model: newModel,
        pim: newPim,
        type: newType,
        temple: newTemple,
        scans: old.scans,
      );
    }

    await _write(list);
  }

  static Future<void> deleteGroup(
    String name,
    String model,
  ) async {
    final list = await load();

    list.removeWhere(
      (x) =>
          x.name == name &&
          x.model == model,
    );

    await _write(list);
  }

  static Future<int> nextReferenceNumber() async {
    final prefs = await SharedPreferences.getInstance();

    final last =
        prefs.getInt('last_reference_number') ?? 0;

    final next = last + 1;

    await prefs.setInt(
      'last_reference_number',
      next,
    );

    return next;
  }

  static Future<void> _write(
    List<ReferenceData> list,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = jsonEncode(
      list.map((e) => e.toMap()).toList(),
    );

    await prefs.setString(key, raw);
  }
}

// =====================================================
// HOME PAGE
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
  List<ReferenceData> references = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await ReferenceStorage.load();

    if (!mounted) return;

    setState(() {
      references = data;
    });
  }

  Map<String, List<ReferenceData>> groupedData() {
    final Map<String, List<ReferenceData>> groups = {};

    for (final x in references) {
      final key = '${x.name}|||${x.model}';

      groups.putIfAbsent(key, () => []);

      groups[key]!.add(x);
    }

    return groups;
  }

  Future<void> editGroup(
    List<ReferenceData> group,
  ) async {
    if (group.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReferenceListPage(
          cameras: widget.cameras,
          name: group.first.name,
          model: group.first.model,
        ),
      ),
    );

    await loadData();
  }

  Future<void> deleteGroup(
    List<ReferenceData> group,
  ) async {
    if (group.isEmpty) return;

    final first = group.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) {
        return AlertDialog(
          title: const Text('ลบข้อมูลทั้งหมด'),
          content: Text(
            'ต้องการลบข้อมูล\n'
            '${first.name}\n'
            '${first.model}\n'
            'ทั้งหมดหรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(d, false);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(d, true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    await ReferenceStorage.deleteGroup(
      first.name,
      first.model,
    );

    await loadData();
  }

  Future<void> createNew() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReferencePage(
          cameras: widget.cameras,
        ),
      ),
    );

    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupedData();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'กล้องสแกนพระและเหรียญ',
        ),
      ),
      body: groups.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีข้อมูลอ้างอิง',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: groups.values.map((group) {
                final first = group.first;

                final scanCount = group.fold<int>(
                  0,
                  (sum, item) =>
                      sum + item.scans.length,
                );

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          first.name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          first.model.isEmpty
                              ? 'ไม่ระบุรุ่น'
                              : first.model,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'มี ${group.length} รายการอ้างอิง',
                        ),
                        Text(
                          'ข้อมูลสแกนทั้งหมด $scanCount ด้าน',
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  editGroup(group);
                                },
                                child: const Text(
                                  'ดู / เพิ่ม',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  deleteGroup(group);
                                },
                                child: const Text(
                                  'ลบ',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createNew,
        icon: const Icon(Icons.add),
        label: const Text(
          'สร้าง / เพิ่มองค์อ้างอิง',
        ),
      ),
    );
  }
}

// =====================================================
// REFERENCE LIST PAGE
// =====================================================

class ReferenceListPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String name;
  final String model;

  const ReferenceListPage({
    super.key,
    required this.cameras,
    required this.name,
    required this.model,
  });

  @override
  State<ReferenceListPage> createState() =>
      _ReferenceListPageState();
}

class _ReferenceListPageState
    extends State<ReferenceListPage> {
  List<ReferenceData> references = [];

  @override
  void initState() {
    super.initState();
    loadReferences();
  }

  Future<void> loadReferences() async {
    final all = await ReferenceStorage.load();

    final filtered = all
        .where(
          (x) =>
              x.name == widget.name &&
              x.model == widget.model,
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
    });
  }

  Future<void> addNewReference() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReferencePage(
          cameras: widget.cameras,
          initialName: widget.name,
          initialModel: widget.model,
        ),
      ),
    );

    await loadReferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.name,
        ),
      ),
      body: references.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีรายการอ้างอิง',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: references.length,
              itemBuilder: (context, index) {
                final x = references[index];

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: ListTile(
                    title: Text(
                      'องค์อ้างอิงที่ ${x.referenceNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'สแกนแล้ว ${x.scans.length} ด้าน',
                    ),
                    trailing: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.edit,
                      ),
                      label: const Text(
                        'แก้ไข',
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditReferencePage(
                              reference: x,
                              cameras: widget.cameras,
                            ),
                          ),
                        );

                        await loadReferences();
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addNewReference,
        icon: const Icon(Icons.add),
        label: const Text(
          'เพิ่มองค์อ้างอิง',
        ),
      ),
    );
  }
}

// =====================================================
// REFERENCE DETAIL PAGE
// =====================================================

class ReferenceDetailPage extends StatelessWidget {
  final ReferenceData reference;

  const ReferenceDetailPage({
    super.key,
    required this.reference,
  });

  ScanResult? getScan(String area) {
    for (final x in reference.scans) {
      if (x.area == area) {
        return x;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'องค์อ้างอิงที่ ${reference.referenceNumber}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            reference.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('รุ่น: ${reference.model}'),
          Text('พิมพ์: ${reference.pim}'),
          Text('ประเภท: ${reference.type}'),
          Text('วัด / สำนัก: ${reference.temple}'),
          const SizedBox(height: 20),
          ...areas.map(
            (area) {
              final scan = getScan(area);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        area,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (scan == null)
                        const Text(
                          'ยังไม่มีข้อมูล',
                        )
                      else ...[
                        Text(
                          'คุณภาพ: ${scan.quality}',
                        ),
                        const SizedBox(height: 5),
                        Text(
                          scan.details,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================
// CREATE REFERENCE PAGE
// =====================================================

class CreateReferencePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  final String? initialName;
  final String? initialModel;

  const CreateReferencePage({
    super.key,
    required this.cameras,
    this.initialName,
    this.initialModel,
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
  }

  @override
  void dispose() {
    nameController.dispose();
    modelController.dispose();
    pimController.dispose();
    templeController.dispose();

    super.dispose();
  }

  void msg(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  Future<void> next() async {
    final name =
        nameController.text.trim();

    final model =
        modelController.text.trim();

    final pim =
        pimController.text.trim();

    final temple =
        templeController.text.trim();

    if (name.isEmpty) {
      msg('กรุณาใส่ชื่อพระ');
      return;
    }

    if (selectedType == null ||
        selectedType!.isEmpty) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'สร้างข้อมูลอ้างอิง',
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
              labelText: 'รุ่น',
              border: OutlineInputBorder(),
            ),
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
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration: const InputDecoration(
              labelText: 'ประเภท',
              border: OutlineInputBorder(),
            ),
            items: types
                .map(
                  (x) => DropdownMenuItem(
                    value: x,
                    child: Text(x),
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
            controller: templeController,
            decoration: const InputDecoration(
              labelText: 'วัด / สำนัก',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: next,
              child: const Text(
                'ไปสแกนข้อมูล',
                style: TextStyle(
                  fontSize: 17,
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
// EDIT REFERENCE PAGE
// =====================================================

class EditReferencePage extends StatefulWidget {
  final ReferenceData reference;
  final List<CameraDescription> cameras;

  const EditReferencePage({
    super.key,
    required this.reference,
    required this.cameras,
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

  void msg(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  Future<void> saveBasicInfo() async {
    final name =
        nameController.text.trim();

    if (name.isEmpty) {
      msg('กรุณาใส่ชื่อพระ');
      return;
    }

    if (selectedType == null ||
        selectedType!.isEmpty) {
      msg('กรุณาเลือกประเภท');
      return;
    }

    await ReferenceStorage.updateReferenceInfo(
      id: widget.reference.id,
      newName: name,
      newModel:
          modelController.text.trim(),
      newPim:
          pimController.text.trim(),
      newType: selectedType!,
      newTemple:
          templeController.text.trim(),
    );

    msg('บันทึกข้อมูลแล้ว');
  }

  Future<void> editAndScan() async {
    await saveBasicInfo();

    final all =
        await ReferenceStorage.load();

    final updated = all.firstWhere(
      (x) => x.id == widget.reference.id,
      orElse: () => widget.reference,
    );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'แก้ไของค์อ้างอิงที่ '
          '${widget.reference.referenceNumber}',
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
              labelText: 'รุ่น',
              border: OutlineInputBorder(),
            ),
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
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration: const InputDecoration(
              labelText: 'ประเภท',
              border: OutlineInputBorder(),
            ),
            items: types
                .map(
                  (x) => DropdownMenuItem(
                    value: x,
                    child: Text(x),
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
            controller: templeController,
            decoration: const InputDecoration(
              labelText: 'วัด / สำนัก',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: saveBasicInfo,
              child: const Text(
                'บันทึกข้อมูล',
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
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
  State<ScanPage> createState() =>
      _ScanPageState();
}

class _ScanPageState
    extends State<ScanPage> {
  CameraController? controller;

  final ImagePicker picker =
      ImagePicker();

  String currentArea = areas.first;

  final Map<String, ScanResult> results =
      {};

  bool loadingCamera = true;
  bool saving = false;

  bool get isEditMode =>
      widget.existingReference != null;

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      final old =
          widget.existingReference!;

      for (final scan in old.scans) {
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

  Future<void> startCamera() async {
    try {
      if (widget.cameras.isEmpty) {
        if (mounted) {
          setState(() {
            loadingCamera = false;
          });
        }
        return;
      }

      CameraDescription selected =
          widget.cameras.first;

      for (final camera
          in widget.cameras) {
        if (camera.lensDirection ==
            CameraLensDirection.back) {
          selected = camera;
          break;
        }
      }

      final c = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await c.initialize();

      if (!mounted) {
        await c.dispose();
        return;
      }

      controller = c;

      setState(() {
        loadingCamera = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingCamera = false;
      });

      msg(
        'เปิดกล้องไม่ได้: $e',
      );
    }
  }

  Future<void> takePhoto() async {
    final c = controller;

    if (c == null ||
        !c.value.isInitialized) {
      msg('กล้องยังไม่พร้อม');
      return;
    }

    if (c.value.isTakingPicture) {
      return;
    }

    try {
      await c.takePicture();

      await saveScanResult(
        fromGallery: false,
      );
    } catch (e) {
      msg(
        'ถ่ายภาพไม่สำเร็จ: $e',
      );
    }
  }

  Future<void> chooseGallery() async {
    try {
      final image =
          await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) {
        return;
      }

      // ไม่บันทึกไฟล์รูปถาวร
      await saveScanResult(
        fromGallery: true,
      );
    } catch (e) {
      msg(
        'เลือกรูปไม่สำเร็จ: $e',
      );
    }
  }

  Future<void> saveScanResult({
    required bool fromGallery,
  }) async {
    final area = currentArea;

    final result = ScanResult(
      area: area,
      brightness: 0,
      sharpness: 0,
      quality:
          'พร้อมสำหรับเก็บข้อมูลอ้างอิง',
      details:
          'รอระบบ AI วิเคราะห์รายละเอียดทั้งหมดที่มองเห็นในองค์พระ',
      fromGallery: fromGallery,
    );

    setState(() {
      results[area] = result;
    });

    msg(
      'บันทึกข้อมูล $area แล้ว',
    );
  }

  Future<void> exitScan() async {
    if (results.isEmpty) {
      final leave =
          await showDialog<bool>(
        context: context,
        builder: (d) {
          return AlertDialog(
            title: const Text(
              'ออกจากการสแกน',
            ),
            content: const Text(
              'ยังไม่มีข้อมูลสแกน ต้องการออกหรือไม่?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    d,
                    false,
                  );
                },
                child: const Text(
                  'อยู่ต่อ',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    d,
                    true,
                  );
                },
                child: const Text(
                  'ออก',
                ),
              ),
            ],
          );
        },
      );

      if (leave == true &&
          mounted) {
        Navigator.pop(context);
      }

      return;
    }

    await saveReference();
  }

  Future<void> saveReference() async {
    if (saving) return;

    setState(() {
      saving = true;
    });

    try {
      if (isEditMode) {
        final old =
            widget.existingReference!;

        final updated =
            ReferenceData(
          id: old.id,
          referenceNumber:
              old.referenceNumber,
          createdAt: old.createdAt,
          name: old.name,
          model: old.model,
          pim: old.pim,
          type: old.type,
          temple: old.temple,
          scans: results.values.toList(),
        );

        await ReferenceStorage
            .updateReference(updated);

        msg(
          'บันทึกการแก้ไของค์เดิมแล้ว',
        );
      } else {
        final number =
            await ReferenceStorage
                .nextReferenceNumber();

        final reference =
            ReferenceData(
          id: DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
          referenceNumber: number,
          createdAt:
              DateTime.now()
                  .toIso8601String(),
          name: widget.name ?? '',
          model: widget.model ?? '',
          pim: widget.pim ?? '',
          type: widget.type ?? '',
          temple: widget.temple ?? '',
          scans: results.values.toList(),
        );

        await ReferenceStorage.save(
          reference,
        );

        msg(
          'บันทึกองค์อ้างอิงที่ $number แล้ว',
        );
      }

      await Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      msg(
        'บันทึกไม่สำเร็จ: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  // ===================================================
  // FIX: msg() ที่ขาดหายไป
  // ===================================================

  void msg(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  // ===================================================
  // AREA BUTTON
  // ===================================================

  Widget areaButton(String area) {
    final selected =
        currentArea == area;

    final scanned =
        results.containsKey(area);

    return Expanded(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 3,
        ),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: selected
                ? Colors.brown.shade100
                : null,
          ),
          onPressed: () {
            setState(() {
              currentArea = area;
            });
          },
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Text(
                area,
                textAlign:
                    TextAlign.center,
              ),
              if (scanned)
                const Icon(
                  Icons.check,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode
              ? 'แก้ไขข้อมูลการสแกน'
              : 'สแกนข้อมูลอ้างอิง',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(8),
            child: Row(
              children: [
                areaButton(
                  areas[0],
                ),
                areaButton(
                  areas[1],
                ),
                areaButton(
                  areas[2],
                ),
                areaButton(
                  areas[3],
                ),
              ],
            ),
          ),
          Expanded(
            child: loadingCamera
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : controller == null ||
                        !controller!
                            .value
                            .isInitialized
                    ? const Center(
                        child: Text(
                          'ไม่สามารถเปิดกล้องได้',
                        ),
                      )
                    : Center(
                        child: AspectRatio(
                          aspectRatio:
                              controller!
                                  .value
                                  .aspectRatio,
                          child:
                              CameraPreview(
                            controller!,
                          ),
                        ),
                      ),
          ),
          Padding(
            padding:
                const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  'กำลังสแกน: $currentArea',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  'บันทึกแล้ว ${results.length} / ${areas.length} ด้าน',
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            saving
                                ? null
                                : takePhoto,
                        icon: const Icon(
                          Icons.camera_alt,
                        ),
                        label: const Text(
                          'ถ่ายภาพ',
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            saving
                                ? null
                                : chooseGallery,
                        icon: const Icon(
                          Icons.photo,
                        ),
                        label: const Text(
                          'เลือกรูป',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        saving
                            ? null
                            : exitScan,
                    child: Text(
                      saving
                          ? 'กำลังบันทึก...'
                          : isEditMode
                              ? 'บันทึกการแก้ไของค์เดิม'
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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
