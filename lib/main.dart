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

  List<ScanResult> scans;

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
      id: map['id']?.toString() ?? '',
      referenceNumber:
          int.tryParse(map['referenceNumber']?.toString() ?? '') ?? 0,
      createdAt: map['createdAt']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      model: map['model']?.toString() ?? '',
      pim: map['pim']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      temple: map['temple']?.toString() ?? '',
      scans: ((map['scans'] as List?) ?? [])
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
  static const String dataKey = 'reference_data';
  static const String numberKey = 'last_reference_number';

  static Future<List<ReferenceData>> load() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(dataKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      return decoded
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

  static Future<void> save(List<ReferenceData> data) async {
    await _write(data);
  }

  static Future<void> _write(List<ReferenceData> data) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = jsonEncode(
      data.map((e) => e.toMap()).toList(),
    );

    await prefs.setString(dataKey, raw);
  }

  static Future<int> nextReferenceNumber() async {
    final prefs = await SharedPreferences.getInstance();

    int last = prefs.getInt(numberKey) ?? 0;

    last++;

    await prefs.setInt(numberKey, last);

    return last;
  }

  static Future<void> updateReference(ReferenceData reference) async {
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

  static Future<void> updateReferenceInfo({
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

  static Future<void> deleteReference(String id) async {
    final list = await load();

    list.removeWhere(
      (e) => e.id == id,
    );

    await _write(list);
  }

  static Future<void> deleteGroup(
    String name,
    String model,
  ) async {
    final list = await load();

    list.removeWhere(
      (e) => e.name == name && e.model == model,
    );

    await _write(list);
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
  int savedCount = 0;

  @override
  void initState() {
    super.initState();
    loadCount();
  }

  Future<void> loadCount() async {
    final data = await ReferenceStorage.load();

    if (!mounted) return;

    setState(() {
      savedCount = data.length;
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

    loadCount();
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

            // -----------------------------------------
            // สร้าง / บันทึกข้อมูล
            // -----------------------------------------

            _menuCard(
              icon: Icons.add_circle_outline,
              title: 'สร้าง / บันทึกข้อมูล',
              subtitle: 'สร้างข้อมูลพระหรือเหรียญองค์อ้างอิงใหม่',
              onTap: createData,
            ),

            const SizedBox(height: 12),

            // -----------------------------------------
            // รายการข้อมูลที่บันทึก
            // -----------------------------------------

            _menuCard(
              icon: Icons.folder_open,
              title: 'รายการข้อมูลที่บันทึก',
              subtitle: 'ข้อมูลอ้างอิงทั้งหมด $savedCount องค์',
              onTap: openSavedData,
            ),

            const SizedBox(height: 12),

            // -----------------------------------------
            // สำรอง / นำเข้าข้อมูล
            // -----------------------------------------

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

            // -----------------------------------------
            // ตั้งค่า
            // -----------------------------------------

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
    setState(() {
      loading = true;
    });

    final data = await ReferenceStorage.load();

    data.sort(
      (a, b) => a.referenceNumber.compareTo(b.referenceNumber),
    );

    if (!mounted) return;

    setState(() {
      references = data;
      loading = false;
    });
  }

  Map<String, List<ReferenceData>> groupedData() {
    final Map<String, List<ReferenceData>> groups = {};

    for (final item in references) {
      final key = '${item.name}|||${item.model}';

      groups.putIfAbsent(
        key,
        () => [],
      );

      groups[key]!.add(item);
    }

    return groups;
  }

  Future<void> openGroup(
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

    loadData();
  }

  Future<void> deleteGroup(
    List<ReferenceData> group,
  ) async {
    if (group.isEmpty) return;

    final name = group.first.name;
    final model = group.first.model;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('ลบข้อมูลทั้งหมด?'),
          content: Text(
            'ต้องการลบข้อมูล "$name"\n'
            '${model.isEmpty ? '' : 'รุ่น $model\n'}'
            'ทั้งหมดหรือไม่?\n\n'
            'การลบจะลบข้อมูลอ้างอิงทุกองค์ในกลุ่มนี้',
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
      name,
      model,
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
                          'ยังไม่มีข้อมูลอ้างอิง',
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
    List<ReferenceData> group,
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
                child: Text(
                  'รุ่น: ${first.model}',
                ),
              ),

            const SizedBox(height: 8),

            Text(
              'มี ${group.length} รายการอ้างอิง',
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
                    icon: const Icon(Icons.visibility),
                    label: const Text('ดู / เพิ่ม'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'ลบกลุ่ม',
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

    nameController.text = widget.initialName ?? '';
    modelController.text = widget.initialModel ?? '';
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
              icon: const Icon(Icons.camera_alt),
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
              e.model == widget.model,
        )
        .toList();

    filtered.sort(
      (a, b) =>
          a.referenceNumber.compareTo(b.referenceNumber),
    );

    if (!mounted) return;

    setState(() {
      references = filtered;
      loading = false;
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

    loadReferences();
  }

  Future<void> openEdit(
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

  Future<void> deleteReference(
    ReferenceData reference,
  ) async {
    final confirm = await showDialog<bool>(
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Outlined
