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

class App extends StatelessWidget {
  final List<CameraDescription> cameras;

  const App(this.cameras, {super.key});

  @override
  Widget build(BuildContext c) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'กล้องสแกนพระและเหรียญ',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: HomePage(cameras),
    );
  }
}

// =====================================================
// SCAN AREAS
// =====================================================

const areas = [
  'ด้านหน้า',
  'ด้านหลัง',
  'ด้านข้าง',
  'ก้นพระ',
];

// =====================================================
// TYPES
// =====================================================

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

  Map<String, dynamic> toMap() => {
        'area': area,
        'quality': quality,
        'details': details,
        'brightness': brightness,
        'sharpness': sharpness,
        'fromGallery': fromGallery,
      };

  factory ScanResult.fromMap(
    Map<String, dynamic> m,
  ) {
    return ScanResult(
      area: m['area'] ?? '',
      quality: m['quality'] ?? '',
      details: m['details'] ?? '',
      brightness: (m['brightness'] ?? 0).toDouble(),
      sharpness: (m['sharpness'] ?? 0).toDouble(),
      fromGallery: m['fromGallery'] ?? false,
    );
  }
}

// =====================================================
// REFERENCE DATA
// =====================================================

class ReferenceData {
  final String id;
  final int referenceNumber;
  final DateTime createdAt;

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

  Map<String, dynamic> toMap() => {
        'id': id,
        'referenceNumber': referenceNumber,
        'createdAt': createdAt.toIso8601String(),
        'name': name,
        'model': model,
        'pim': pim,
        'type': type,
        'temple': temple,
        'scans': scans.map((x) => x.toMap()).toList(),
      };

  factory ReferenceData.fromMap(
    Map<String, dynamic> m,
  ) {
    return ReferenceData(
      id: m['id'] ?? '',
      referenceNumber:
          (m['referenceNumber'] ?? 0).toInt(),
      createdAt:
          DateTime.tryParse(
                m['createdAt'] ?? '',
              ) ??
              DateTime.now(),
      name: m['name'] ?? '',
      model: m['model'] ?? '',
      pim: m['pim'] ?? '',
      type: m['type'] ?? '',
      temple: m['temple'] ?? '',
      scans: (m['scans'] as List? ?? [])
          .map(
            (x) => ScanResult.fromMap(
              Map<String, dynamic>.from(x),
            ),
          )
          .toList(),
    );
  }
}

// =====================================================
// STORAGE
// ไม่มี GZIP
// ไม่มี BASE64
// =====================================================

class ReferenceStorage {
  static const key = 'reference_data';

  static Future<List<ReferenceData>> load() async {
    final p = await SharedPreferences.getInstance();

    final raw = p.getString(key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final data = jsonDecode(raw);

      if (data is List) {
        return _toList(data);
      }
    } catch (_) {}

    return [];
  }

  static List<ReferenceData> _toList(
    List data,
  ) {
    return data
        .map(
          (x) => ReferenceData.fromMap(
            Map<String, dynamic>.from(x),
          ),
        )
        .toList();
  }

  static Future<void> save(
    ReferenceData item,
  ) async {
    final list = await load();

    list.add(item);

    await _write(list);
  }

  // ---------------------------------------------------
  // UPDATE องค์อ้างอิงที่เลือก
  // ---------------------------------------------------

  static Future<void> updateReference(
    ReferenceData updated,
  ) async {
    final list = await load();

    final index = list.indexWhere(
      (x) => x.id == updated.id,
    );

    if (index == -1) {
      return;
    }

    list[index] = updated;

    await _write(list);
  }

  // ---------------------------------------------------
  // UPDATE ข้อมูลหลักขององค์เดิม
  // ---------------------------------------------------

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

    if (index == -1) {
      return;
    }

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

    await _write(list);
  }

  // ---------------------------------------------------
  // ลบทั้งกลุ่ม
  // ---------------------------------------------------

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

  // ---------------------------------------------------
  // เลของค์อ้างอิง
  // ---------------------------------------------------
  //
  // เลขจะเพิ่มขึ้นเรื่อย ๆ
  // ลบองค์เก่าแล้วเลขจะไม่ย้อนกลับมาใช้
  //

  static Future<int> nextReferenceNumber() async {
    final p = await SharedPreferences.getInstance();

    final n =
        (p.getInt('last_reference_number') ?? 0) + 1;

    await p.setInt(
      'last_reference_number',
      n,
    );

    return n;
  }

  // ---------------------------------------------------
  // บันทึก JSON ตรง ๆ
  // ไม่มีการบีบอัด
  // ---------------------------------------------------

  static Future<void> _write(
    List<ReferenceData> list,
  ) async {
    final p = await SharedPreferences.getInstance();

    final text = jsonEncode(
      list.map((x) => x.toMap()).toList(),
    );

    await p.setString(
      key,
      text,
    );
  }
}

// =====================================================
// HOME
// =====================================================

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage(
    this.cameras, {
    super.key,
  });

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  List<ReferenceData> allData = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data =
        await ReferenceStorage.load();

    if (!mounted) return;

    setState(() {
      allData = data;
    });
  }

  List<List<ReferenceData>> getGroups() {
    final map =
        <String, List<ReferenceData>>{};

    for (final x in allData) {
      map
          .putIfAbsent(
            '${x.name}|||${x.model}',
            () => [],
          )
          .add(x);
    }

    return map.values.toList();
  }

  Future<void> open(
    Widget page,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );

    await loadData();
  }

  Future<void> editGroup(
    List<ReferenceData> group,
  ) async {
    if (group.isEmpty) return;

    await open(
      ReferenceListPage(
        cameras: widget.cameras,
        name: group.first.name,
        model: group.first.model,
      ),
    );
  }

  Future<void> deleteGroup(
    List<ReferenceData> group,
  ) async {
    if (group.isEmpty) return;

    final x = group.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text(
          'ลบข้อมูล',
        ),
        content: Text(
          'ต้องการลบรายการนี้ทั้งหมดหรือไม่?\n\n'
          'ชื่อพระ: ${x.name}\n'
          '${x.model.isEmpty ? '' : 'รุ่น: ${x.model}\n'}\n'
          'จะลบองค์อ้างอิงและข้อมูลสแกนทั้งหมด',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(d, false);
            },
            child: const Text(
              'ยกเลิก',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(d, true);
            },
            child: const Text(
              'ลบ',
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await ReferenceStorage.deleteGroup(
      x.name,
      x.model,
    );

    await loadData();

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'ลบข้อมูลทั้งหมดแล้ว',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final groups = getGroups();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'กล้องสแกนพระและเหรียญ',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            const SizedBox(
              height: 10,
            ),
            const Text(
              'ฐานข้อมูลส่วนตัว',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'มีชื่อพระ ${groups.length} รายการ',
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton.icon(
                icon: const Icon(
                  Icons.add_circle,
                ),
                label: const Text(
                  'สร้าง / เพิ่มองค์อ้างอิง',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                onPressed: () {
                  open(
                    CreateReferencePage(
                      cameras:
                          widget.cameras,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            if (groups.isEmpty)
              const Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.storage,
                        size: 50,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        'ยังไม่มีข้อมูลพระ',
                        style:
                            TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(
                        height: 6,
                      ),
                      Text(
                        'กดสร้าง / เพิ่มองค์อ้างอิง '
                        'เพื่อเริ่มสร้างฐานข้อมูล',
                        textAlign:
                            TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            for (final group in groups)
              buildGroupCard(group),
          ],
        ),
      ),
    );
  }

  Widget buildGroupCard(
    List<ReferenceData> group,
  ) {
    final x = group.first;

    final scanCount =
        group.fold<int>(
      0,
      (sum, item) =>
          sum + item.scans.length,
    );

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                open(
                  ReferenceListPage(
                    cameras:
                        widget.cameras,
                    name: x.name,
                    model: x.model,
                  ),
                );
              },
              child: Row(
                children: [
                  const CircleAvatar(
                    child: Icon(
                      Icons.auto_awesome,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          x.name.isEmpty
                              ? 'ไม่ระบุชื่อพระ'
                              : x.name,
                          style:
                              const TextStyle(
                            fontSize: 19,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        if (x.model
                            .isNotEmpty)
                          Text(
                            'รุ่น: ${x.model}',
                          ),
                        Text(
                          'มีองค์อ้างอิง '
                          '${group.length} องค์',
                        ),
                        Text(
                          'ข้อมูลสแกน '
                          '$scanCount รายการ',
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
            const Divider(),
            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    icon: const Icon(
                      Icons.edit,
                    ),
                    label: const Text(
                      'ดู / เพิ่ม',
                    ),
                    onPressed: () {
                      editGroup(group);
                    },
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child:
                      OutlinedButton.icon(
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                    label: const Text(
                      'ลบ',
                    ),
                    onPressed: () {
                      deleteGroup(group);
                    },
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
// REFERENCE LIST
// =====================================================

class ReferenceListPage
    extends StatefulWidget {
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
    final all =
        await ReferenceStorage.load();

    final list = all
        .where(
          (x) =>
              x.name == widget.name &&
              x.model == widget.model,
        )
        .toList()
      ..sort(
        (a, b) =>
            a.referenceNumber.compareTo(
          b.referenceNumber,
        ),
      );

    if (!mounted) return;

    setState(() {
      references = list;
    });
  }

  // ===================================================
  // เพิ่มองค์อ้างอิงใหม่ในกลุ่มเดิม
  // ===================================================

  Future<void> addNewReference() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateReferencePage(
          cameras: widget.cameras,

          // ส่งชื่อเดิมเข้าไป
          initialName: widget.name,

          // ส่งรุ่นเดิมเข้าไป
          initialModel: widget.model,
        ),
      ),
    );

    await loadReferences();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายการองค์อ้างอิง',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadReferences,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name.isEmpty
                          ? 'ไม่ระบุชื่อพระ'
                          : widget.name,
                      style:
                          const TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    if (widget.model
                        .isNotEmpty)
                      Text(
                        'รุ่น: ${widget.model}',
                        style:
                            const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      'มีองค์อ้างอิง '
                      '${references.length} องค์',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // =================================================
            // ปุ่มเพิ่มองค์อ้างอิงใหม่
            // =================================================

            SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton.icon(
                icon: const Icon(
                  Icons.add_circle,
                ),
                label: const Text(
                  'เพิ่มองค์อ้างอิงใหม่',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
                onPressed:
                    addNewReference,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            if (references.isEmpty)
              const Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(20),
                  child: Text(
                    'ยังไม่มีองค์อ้างอิง',
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              ),

            for (final x in references)
              buildReferenceCard(x),
          ],
        ),
      ),
    );
  }

  Widget buildReferenceCard(
    ReferenceData x,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReferenceDetailPage(
                      reference: x,
                      cameras:
                          widget.cameras,
                    ),
                  ),
                );

                await loadReferences();
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    child: Text(
                      '${x.referenceNumber}',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'องค์อ้างอิงที่ '
                          '${x.referenceNumber}',
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'ข้อมูลสแกน '
                          '${x.scans.length} / '
                          '${areas.length} ด้าน',
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

            const Divider(),

            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton.icon(
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
                        cameras:
                            widget.cameras,
                      ),
                    ),
                  );

                  await loadReferences();
                },
              ),
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

class ReferenceDetailPage
    extends StatelessWidget {
  final ReferenceData reference;
  final List<CameraDescription> cameras;

  const ReferenceDetailPage({
    super.key,
    required this.reference,
    required this.cameras,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'องค์อ้างอิงที่ '
          '${reference.referenceNumber}',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'องค์อ้างอิงที่ '
                    '${reference.referenceNumber}',
                    style:
                        const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  infoRow(
                    'ชื่อพระ',
                    reference.name,
                  ),
                  infoRow(
                    'รุ่น',
                    reference.model,
                  ),
                  infoRow(
                    'พิมพ์',
                    reference.pim,
                  ),
                  infoRow(
                    'ประเภท',
                    reference.type,
                  ),
                  infoRow(
                    'วัด',
                    reference.temple,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          const Text(
            'ข้อมูลจากการสแกน',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          for (final area in areas)
            _areaCard(area),
        ],
      ),
    );
  }

  Widget _areaCard(
    String area,
  ) {
    final scan = reference.scans
        .where(
          (x) => x.area == area,
        )
        .firstOrNull;

    if (scan == null) {
      return Card(
        child: ListTile(
          leading: const Icon(
            Icons.radio_button_unchecked,
          ),
          title: Text(area),
          subtitle: const Text(
            'ยังไม่มีข้อมูล',
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.check_circle,
        ),
        title: Text(area),
        subtitle: Text(
          '${scan.quality}\n'
          '${scan.details}',
        ),
      ),
    );
  }

  Widget infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 6,
      ),
      child: Text(
        '$title: '
        '${value.isEmpty ? "-" : value}',
      ),
    );
  }
}

// =====================================================
// CREATE
// =====================================================

class CreateReferencePage
    extends StatefulWidget {
  final List<CameraDescription> cameras;

  // ===================================================
  // ใช้สำหรับ "เพิ่มองค์อ้างอิงในกลุ่มเดิม"
  // ===================================================

  final String initialName;
  final String initialModel;

  const CreateReferencePage({
    super.key,
    required this.cameras,
    this.initialName = '',
    this.initialModel = '',
  });

  @override
  State<CreateReferencePage> createState() =>
      _CreateReferencePageState();
}

class _CreateReferencePageState
    extends State<CreateReferencePage> {
  final nameController =
      TextEditingController();

  final modelController =
      TextEditingController();

  final pimController =
      TextEditingController();

  final templeController =
      TextEditingController();

  String? selectedType;

  @override
  void initState() {
    super.initState();

    // =================================================
    // ถ้ามาจากปุ่ม "เพิ่มองค์อ้างอิงใหม่"
    // จะใส่ชื่อและรุ่นเดิมให้โดยอัตโนมัติ
    // =================================================

    nameController.text =
        widget.initialName;

    modelController.text =
        widget.initialModel;
  }

  @override
  void dispose() {
    nameController.dispose();
    modelController.dispose();
    pimController.dispose();
    templeController.dispose();
    super.dispose();
  }

  Future<void> next() async {
    final name =
        nameController.text.trim();

    if (name.isEmpty) {
      msg('กรุณาใส่ชื่อพระ');
      return;
    }

    if (selectedType == null) {
      msg('กรุณาเลือกประเภท');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          name: name,
          model:
              modelController.text.trim(),
          pim:
              pimController.text.trim(),
          type: selectedType!,
          temple:
              templeController.text.trim(),
        ),
      ),
    );
  }

  void msg(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final isAddingToExistingGroup =
        widget.initialName.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAddingToExistingGroup
              ? 'เพิ่มองค์อ้างอิงใหม่'
              : 'สร้าง / เพิ่มองค์อ้างอิง',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          if (isAddingToExistingGroup)
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(14),
                child: Text(
                  'กำลังเพิ่มองค์อ้างอิงใหม่\n'
                  'ในกลุ่ม "${widget.initialName}"'
                  '${widget.initialModel.isEmpty ? '' : '\nรุ่น: ${widget.initialModel}'}',
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'ข้อมูลหลัก',
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          field(
            nameController,
            'ชื่อพระ',
          ),

          field(
            modelController,
            'รุ่น',
          ),

          field(
            pimController,
            'พิมพ์',
          ),

          DropdownButtonFormField<String>(
            value: selectedType,
            decoration:
                const InputDecoration(
              labelText: 'ประเภท',
              border:
                  OutlineInputBorder(),
            ),
            items: types
                .map(
                  (x) =>
                      DropdownMenuItem(
                    value: x,
                    child: Text(x),
                  ),
                )
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedType = v;
              });
            },
          ),

          const SizedBox(
            height: 12,
          ),

          field(
            templeController,
            'วัด',
          ),

          const SizedBox(
            height: 20,
          ),

          SizedBox(
            width: double.infinity,
            child:
                ElevatedButton.icon(
              icon: const Icon(
                Icons.camera_alt,
              ),
              label: const Text(
                'ไปสแกนองค์อ้างอิง',
                style: TextStyle(
                  fontSize: 17,
                ),
              ),
              onPressed: next,
            ),
          ),
        ],
      ),
    );
  }

  Widget field(
    TextEditingController c,
    String label,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextField(
        controller: c,
        decoration:
            InputDecoration(
          labelText: label,
          border:
              const OutlineInputBorder(),
        ),
      ),
    );
  }
}

// =====================================================
// EDIT
// =====================================================

class EditReferencePage
    extends StatefulWidget {
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
  late final TextEditingController
      nameController;

  late final TextEditingController
      modelController;

  late final TextEditingController
      pimController;

  late final TextEditingController
      templeController;

  String? selectedType;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(
      text: widget.reference.name,
    );

    modelController =
        TextEditingController(
      text: widget.reference.model,
    );

    pimController =
        TextEditingController(
      text: widget.reference.pim,
    );

    templeController =
        TextEditingController(
      text: widget.reference.temple,
    );

    selectedType =
        types.contains(
      widget.reference.type,
    )
            ? widget.reference.type
            : null;
  }

  @override
  void dispose() {
    nameController.dispose();
    modelController.dispose();
    pimController.dispose();
    templeController.dispose();
    super.dispose();
  }

  Future<bool> saveBasicInfo() async {
    final name =
        nameController.text.trim();

    if (name.isEmpty) {
      msg('กรุณาใส่ชื่อพระ');
      return false;
    }

    if (selectedType == null) {
      msg('กรุณาเลือกประเภท');
      return false;
    }

    await ReferenceStorage
        .updateReferenceInfo(
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

    return true;
  }

  Future<void> editAndScan() async {
    final ok =
        await saveBasicInfo();

    if (!ok) return;

    final all =
        await ReferenceStorage.load();

    final updated = all.firstWhere(
      (x) =>
          x.id == widget.reference.id,
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          existingReference:
              updated,
        ),
      ),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void msg(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'แก้ไของค์อ้างอิงที่ '
          '${widget.reference.referenceNumber}',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(14),
              child: Text(
                'องค์อ้างอิงที่ '
                '${widget.reference.referenceNumber}',
                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'ข้อมูลหลัก',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          field(
            nameController,
            'ชื่อพระ',
          ),

          field(
            modelController,
            'รุ่น',
          ),

          field(
            pimController,
            'พิมพ์',
          ),

          DropdownButtonFormField<String>(
            value: selectedType,
            decoration:
                const InputDecoration(
              labelText: 'ประเภท',
              border:
                  OutlineInputBorder(),
            ),
            items: types
                .map(
                  (x) =>
                      DropdownMenuItem(
                    value: x,
                    child: Text(x),
                  ),
                )
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedType = v;
              });
            },
          ),

          const SizedBox(
            height: 12,
          ),

          field(
            templeController,
            'วัด',
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'ข้อมูลสแกนเดิม',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          for (final area in areas)
            buildExistingScan(area),

          const SizedBox(
            height: 20,
          ),

          SizedBox(
            width: double.infinity,
            child:
                ElevatedButton.icon(
              icon: const Icon(
                Icons.edit,
              ),
              label: const Text(
                'แก้ไข / สแกนข้อมูลต่อ',
                style: TextStyle(
                  fontSize: 17,
                ),
              ),
              onPressed: editAndScan,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          const Text(
            'กดปุ่มนี้แล้วสามารถแก้ข้อมูลหลัก '
            'และเข้าสแกนด้านที่ยังไม่มีข้อมูลได้ '
            'โดยยังคงเป็นองค์อ้างอิงเดิม',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildExistingScan(
    String area,
  ) {
    final scan = widget.reference.scans
        .where(
          (x) => x.area == area,
        )
        .firstOrNull;

    return Card(
      child: ListTile(
        leading: Icon(
          scan == null
              ? Icons.radio_button_unchecked
              : Icons.check_circle,
        ),
        title: Text(area),
        subtitle: Text(
          scan == null
              ? 'ยังไม่มีข้อมูลสแกน'
              : 'มีข้อมูลแล้ว',
        ),
      ),
    );
  }

  Widget field(
    TextEditingController c,
    String label,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextField(
        controller: c,
        decoration:
            InputDecoration(
          labelText: label,
          border:
              const OutlineInputBorder(),
        ),
      ),
    );
  }
}

// =====================================================
// SCAN
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

  bool get isEditMode =>
      existingReference != null;

  @override
  State<ScanPage> createState() =>
      _ScanPageState();
}

class _ScanPageState
    extends State<ScanPage> {
  CameraController? controller;

  final picker = ImagePicker();

  int currentArea = 0;

  final Map<String, ScanResult>
      results = {};

  bool loadingCamera = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingReference !=
        null) {
      for (final scan
          in widget.existingReference!
              .scans) {
        results[scan.area] = scan;
      }

      for (int i = 0;
          i < areas.length;
          i++) {
        if (!results.containsKey(
          areas[i],
        )) {
          currentArea = i;
          break;
        }
      }
    }

    startCamera();
  }

  Future<void> startCamera() async {
    if (widget.cameras.isEmpty) {
      if (mounted) {
        setState(() {
          loadingCamera = false;
        });
      }

      return;
    }

    final camera =
        widget.cameras.firstWhere(
      (x) =>
          x.lensDirection ==
          CameraLensDirection.back,
      orElse: () =>
          widget.cameras.first,
    );

    final c = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    controller = c;

    try {
      await c.initialize();
    } catch (_) {}

    if (mounted) {
      setState(() {
        loadingCamera = false;
      });
    }
  }

  void selectArea(int i) {
    if (!saving) {
      setState(() {
        currentArea = i;
      });
    }
  }

  Future<void> takePhoto() async {
    if (saving) return;

    final c = controller;

    if (c == null ||
        !c.value.isInitialized ||
        c.value.isTakingPicture) {
      return;
    }

    try {
      await c.takePicture();

      await saveScanResult(
        fromGallery: false,
      );
    } catch (_) {
      if (mounted) {
        msg(
          'ถ่ายภาพไม่สำเร็จ',
        );
      }
    }
  }

  Future<void> chooseGallery() async {
    if (saving) return;

    try {
      final image =
          await picker.pickImage(
        source:
            ImageSource.gallery,
      );

      if (image == null) return;

      await saveScanResult(
        fromGallery: true,
      );
    } catch (_) {
      if (mounted) {
        msg(
          'เลือกรูปไม่สำเร็จ',
        );
      }
    }
  }

  Future<void> saveScanResult({
    required bool fromGallery,
  }) async {
    final area =
        areas[currentArea];

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

    if (!mounted) return;

    setState(() {
      results[area] = result;
    });

    msg(
      'บันทึกข้อมูล $area แล้ว',
    );
  }

  Future<void> exitScan() async {
    if (saving) return;

    if (results.isEmpty) {
      final leave =
          await showDialog<bool>(
        context: context,
        builder: (d) =>
            AlertDialog(
          title: const Text(
            'ออกจากการสแกน',
          ),
          content: Text(
            widget.isEditMode
                ? 'ยังไม่มีข้อมูลสแกนเพิ่มเติม\n'
                    'ต้องการออกหรือไม่?'
                : 'ยังไม่มีข้อมูลสแกน\n'
                    'ต้องการออกโดยไม่สร้างองค์อ้างอิงหรือไม่?',
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
        ),
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
    if (saving ||
        results.isEmpty) {
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      // =================================================
      // MODE แก้ไของค์เดิม
      // =================================================

      if (widget.existingReference !=
          null) {
        final old =
            widget.existingReference!;

        // -------------------------------------------------
        // สำคัญ:
        // results เริ่มต้นด้วยข้อมูลสแกนเดิมทั้งหมด
        // ถ้ามีการสแกนใหม่ในด้านใด จะถูกแทนที่เฉพาะด้านนั้น
        // -------------------------------------------------

        final updated =
            ReferenceData(
          id: old.id,
          referenceNumber:
              old.referenceNumber,
          createdAt: old.createdAt,

          // ข้อมูลหลักขององค์เดิม
          name: old.name,
          model: old.model,
          pim: old.pim,
          type: old.type,
          temple: old.temple,

          scans:
              results.values.toList(),
        );

        await ReferenceStorage
            .updateReference(
          updated,
        );

        if (!mounted) return;

        Navigator.pop(context);

        return;
      }

      // =================================================
      // MODE สร้างองค์ใหม่
      // =================================================

      final number =
          await ReferenceStorage
              .nextReferenceNumber();

      final item = ReferenceData(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        referenceNumber: number,
        createdAt:
            DateTime.now(),

        name: widget.name ?? '',
        model: widget.model ?? '',
        pim: widget.pim ?? '',
        type: widget.type ?? '',
        temple: widget.temple ?? '',

        scans:
            results.values.toList(),
      );

      await ReferenceStorage.save(
        item,
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      msg(
        'บันทึกข้อมูลไม่สำเร็จ',
      );
    }
  }

  Widget areaButton(
    int index,
  ) {
    final area = areas[index];

    final selected =
        currentArea == index;

    final hasData =
        results.containsKey(area);

    return Expanded(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 3,
        ),
        child: OutlinedButton(
          style:
              OutlinedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(
              vertical: 10,
            ),
            side: BorderSide(
              width:
                  selected ? 2 : 1,
            ),
          ),
          onPressed: () {
            selectArea(index);
          },
          child: Text(
            hasData
                ? '$area ✓'
                : area,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontWeight:
                  selected
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final initialized =
        controller
                ?.value.isInitialized ??
            false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (didPop, result) {
        if (!didPop) {
          exitScan();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditMode
                ? 'แก้ไข / สแกนองค์อ้างอิงที่ '
                    '${widget.existingReference!.referenceNumber}'
                : 'สแกนองค์อ้างอิง',
          ),
          actions: [
            TextButton.icon(
              onPressed:
                  saving
                      ? null
                      : exitScan,
              icon: const Icon(
                Icons.exit_to_app,
              ),
              label: const Text(
                'ออก',
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                8,
                8,
                8,
                4,
              ),
              child: Row(
                children: [
                  areaButton(0),
                  areaButton(1),
                  areaButton(2),
                  areaButton(3),
                ],
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 6,
              ),
              child: Text(
                'กำลังเลือก: '
                '${areas[currentArea]}',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: initialized
                  ? Stack(
                      fit:
                          StackFit.expand,
                      children: [
                        CameraPreview(
                          controller!,
                        ),

                        Center(
                          child:
                              Container(
                            width: 260,
                            height: 320,
                            decoration:
                                BoxDecoration(
                              border:
                                  Border.all(
                                color:
                                    Colors.white,
                                width: 2,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: Card(
                            color: Colors
                                .black
                                .withOpacity(
                              .60,
                            ),
                            child:
                                Padding(
                              padding:
                                  const EdgeInsets
                                      .all(
                                10,
                              ),
                              child: Text(
                                areas[
                                    currentArea],
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize:
                                      18,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : loadingCamera
                      ? const Center(
                          child:
                              CircularProgressIndicator(),
                        )
                      : const Center(
                          child: Text(
                            'ไม่สามารถเปิดกล้องได้',
                          ),
                        ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  10,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:
                              ElevatedButton
                                  .icon(
                            icon:
                                const Icon(
                              Icons
                                  .camera_alt,
                            ),
                            label:
                                const Text(
                              'ถ่ายภาพ',
                            ),
                            onPressed:
                                initialized &&
                                        !saving
                                    ? takePhoto
                                    : null,
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Expanded(
                          child:
                              OutlinedButton
                                  .icon(
                            icon:
                                const Icon(
                              Icons
                                  .photo_library,
                            ),
                            label:
                                const Text(
                              'เลือกรูป',
                            ),
                            onPressed:
                                saving
                                    ? null
                                    : chooseGallery,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          OutlinedButton
                              .icon(
                        icon:
                            const Icon(
                          Icons.save,
                        ),
                        label: Text(
                          widget.isEditMode
                              ? 'บันทึกการแก้ไของค์เดิม'
                              : 'ออกและบันทึก',
                        ),
                        onPressed:
                            saving
                                ? null
                                : exitScan,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      'บันทึกแล้ว '
                      '${results.length} / '
                      '${areas.length} ด้าน',
                      style:
                          const TextStyle(
                        fontSize: 13,
                      ),
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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
