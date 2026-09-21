import 'dart:convert';
import 'dart:io';

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
  final String updatedAt;

  List<ScanResult> scans;

  ReferenceData({
    required this.id,
    required this.referenceNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.scans,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referenceNumber': referenceNumber,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'scans': scans.map((e) => e.toMap()).toList(),
    };
  }

  factory ReferenceData.fromMap(Map<String, dynamic> map) {
    final rawScans = map['scans'];
    final scanList = <ScanResult>[];

    if (rawScans is List) {
      for (final scan in rawScans) {
        if (scan is Map) {
          try {
            scanList.add(
              ScanResult.fromMap(
                Map<String, dynamic>.from(scan),
              ),
            );
          } catch (_) {}
        }
      }
    }

    return ReferenceData(
      id: map['id']?.toString() ?? '',
      referenceNumber:
          int.tryParse(map['referenceNumber']?.toString() ?? '') ?? 0,
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
      scans: scanList,
    );
  }
}

// =====================================================
// REFERENCE GROUP
// =====================================================

class ReferenceGroup {
  final String id;
  final String createdAt;
  String updatedAt;

  String name;
  String model;
  String pim;
  String type;
  String temple;

  List<ReferenceData> references;

  ReferenceGroup({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.model,
    required this.pim,
    required this.type,
    required this.temple,
    required this.references,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'name': name,
      'model': model,
      'pim': pim,
      'type': type,
      'temple': temple,
      'references':
          references.map((e) => e.toMap()).toList(),
    };
  }

  factory ReferenceGroup.fromMap(Map<String, dynamic> map) {
    final rawReferences = map['references'];
    final referenceList = <ReferenceData>[];

    if (rawReferences is List) {
      for (final item in rawReferences) {
        if (item is Map) {
          try {
            referenceList.add(
              ReferenceData.fromMap(
                Map<String, dynamic>.from(item),
              ),
            );
          } catch (_) {}
        }
      }
    }

    return ReferenceGroup(
      id: map['id']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      model: map['model']?.toString() ?? '',
      pim: map['pim']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      temple: map['temple']?.toString() ?? '',
      references: referenceList,
    );
  }
}

// =====================================================
// STORAGE
// =====================================================

class ReferenceStorage {
  static const String groupKey = 'reference_groups';
  static const String oldKey = 'reference_data';

  static Future<List<ReferenceGroup>> loadGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final newRaw = prefs.getString(groupKey);

      if (newRaw != null && newRaw.isNotEmpty) {
        final decoded = jsonDecode(newRaw);

        if (decoded is List) {
          final groups = <ReferenceGroup>[];

          for (final item in decoded) {
            if (item is Map) {
              try {
                groups.add(
                  ReferenceGroup.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                );
              } catch (_) {}
            }
          }

          return groups;
        }
      }

      return await _migrateOldData(prefs);
    } catch (_) {
      return [];
    }
  }

  static Future<List<ReferenceGroup>> _migrateOldData(
    SharedPreferences prefs,
  ) async {
    try {
      final raw = prefs.getString(oldKey);

      if (raw == null || raw.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      final oldReferences = <Map<String, dynamic>>[];

      for (final item in decoded) {
        if (item is Map) {
          oldReferences.add(
            Map<String, dynamic>.from(item),
          );
        }
      }

      final groups = <ReferenceGroup>[];

      for (final oldMap in oldReferences) {
        final name = oldMap['name']?.toString() ?? '';
        final model = oldMap['model']?.toString() ?? '';
        final pim = oldMap['pim']?.toString() ?? '';
        final type = oldMap['type']?.toString() ?? '';
        final temple = oldMap['temple']?.toString() ?? '';

        ReferenceGroup? group;

        for (final existing in groups) {
          if (_sameGroup(
            existing,
            name,
            model,
            pim,
            type,
            temple,
          )) {
            group = existing;
            break;
          }
        }

        if (group == null) {
          final groupId =
              'group_${DateTime.now().microsecondsSinceEpoch}_${groups.length}';

          final now = DateTime.now().toIso8601String();

          group = ReferenceGroup(
            id: groupId,
            createdAt: now,
            updatedAt: now,
            name: name,
            model: model,
            pim: pim,
            type: type,
            temple: temple,
            references: [],
          );

          groups.add(group);
        }

        final oldReference =
            ReferenceData.fromMap(oldMap);

        final number = group.references.length + 1;

        final newReference = ReferenceData(
          id: oldReference.id.isEmpty
              ? 'reference_${DateTime.now().microsecondsSinceEpoch}'
              : oldReference.id,
          referenceNumber: number,
          createdAt: oldReference.createdAt.isEmpty
              ? DateTime.now().toIso8601String()
              : oldReference.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
          scans: oldReference.scans,
        );

        group.references.add(newReference);
      }

      await _writeGroups(prefs, groups);

      await prefs.remove(oldKey);

      return groups;
    } catch (_) {
      return [];
    }
  }

  static bool _sameGroup(
    ReferenceGroup group,
    String name,
    String model,
    String pim,
    String type,
    String temple,
  ) {
    return group.name.trim() == name.trim() &&
        group.model.trim() == model.trim() &&
        group.pim.trim() == pim.trim() &&
        group.type.trim() == type.trim() &&
        group.temple.trim() == temple.trim();
  }

  static Future<void> saveGroups(
    List<ReferenceGroup> groups,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await _writeGroups(prefs, groups);
  }

  static Future<void> _writeGroups(
    SharedPreferences prefs,
    List<ReferenceGroup> groups,
  ) async {
    await prefs.setString(
      groupKey,
      jsonEncode(
        groups.map((e) => e.toMap()).toList(),
      ),
    );
  }

  static Future<ReferenceGroup?> findGroup(
    String groupId,
  ) async {
    final groups = await loadGroups();

    for (final group in groups) {
      if (group.id == groupId) {
        return group;
      }
    }

    return null;
  }

  static Future<ReferenceData?> findReference(
    String groupId,
    String referenceId,
  ) async {
    final group = await findGroup(groupId);

    if (group == null) return null;

    for (final reference in group.references) {
      if (reference.id == referenceId) {
        return reference;
      }
    }

    return null;
  }

  static Future<void> createGroupWithReference(
    ReferenceGroup group,
    ReferenceData reference,
  ) async {
    final groups = await loadGroups();

    group.references = [reference];

    groups.add(group);

    await saveGroups(groups);
  }

  static Future<void> addReference(
    String groupId,
    ReferenceData reference,
  ) async {
    final groups = await loadGroups();

    final groupIndex = groups.indexWhere(
      (e) => e.id == groupId,
    );

    if (groupIndex < 0) return;

    final group = groups[groupIndex];

    group.references.add(reference);
    group.updatedAt = DateTime.now().toIso8601String();

    groups[groupIndex] = group;

    await saveGroups(groups);
  }

  static Future<void> updateReference(
    String groupId,
    ReferenceData reference,
  ) async {
    final groups = await loadGroups();

    final groupIndex = groups.indexWhere(
      (e) => e.id == groupId,
    );

    if (groupIndex < 0) return;

    final group = groups[groupIndex];

    final referenceIndex = group.references.indexWhere(
      (e) => e.id == reference.id,
    );

    if (referenceIndex >= 0) {
      group.references[referenceIndex] = reference;
    }

    group.updatedAt = DateTime.now().toIso8601String();

    groups[groupIndex] = group;

    await saveGroups(groups);
  }

  static Future<void> updateGroup(
    ReferenceGroup updatedGroup,
  ) async {
    final groups = await loadGroups();

    final index = groups.indexWhere(
      (e) => e.id == updatedGroup.id,
    );

    if (index < 0) return;

    updatedGroup.updatedAt =
        DateTime.now().toIso8601String();

    groups[index] = updatedGroup;

    await saveGroups(groups);
  }

  static Future<void> deleteReference(
    String groupId,
    String referenceId,
  ) async {
    final groups = await loadGroups();

    final groupIndex = groups.indexWhere(
      (e) => e.id == groupId,
    );

    if (groupIndex < 0) return;

    final group = groups[groupIndex];

    group.references.removeWhere(
      (e) => e.id == referenceId,
    );

    group.updatedAt = DateTime.now().toIso8601String();

    if (group.references.isEmpty) {
      groups.removeAt(groupIndex);
    } else {
      groups[groupIndex] = group;
    }

    await saveGroups(groups);
  }

  static Future<void> deleteGroup(
    String groupId,
  ) async {
    final groups = await loadGroups();

    groups.removeWhere(
      (e) => e.id == groupId,
    );

    await saveGroups(groups);
  }

  static int nextReferenceNumber(
    ReferenceGroup group,
  ) {
    var maxNumber = 0;

    for (final reference in group.references) {
      if (reference.referenceNumber > maxNumber) {
        maxNumber = reference.referenceNumber;
      }
    }

    return maxNumber + 1;
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
    final groups = await ReferenceStorage.loadGroups();

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
                      'แต่ละกลุ่มสามารถมีองค์อ้างอิงได้หลายองค์ '
                      'และสามารถเพิ่มต่อไปได้เรื่อย ๆ',
                    ),
                    SizedBox(height: 6),
                    Text(
                      'ครบ 5 องค์เป็นเพียงตัวช่วยดูสถานะ '
                      'ไม่ใช่จำนวนสูงสุด',
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
  State<SavedDataPage> createState() =>
      _SavedDataPageState();
}

class _SavedDataPageState
    extends State<SavedDataPage> {
  List<ReferenceGroup> groups = [];
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

    final data = await ReferenceStorage.loadGroups();

    data.sort(
      (a, b) => a.createdAt.compareTo(b.createdAt),
    );

    if (!mounted) return;

    setState(() {
      groups = data;
      loading = false;
    });
  }

  Future<void> openGroup(
    ReferenceGroup group,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReferenceListPage(
          cameras: widget.cameras,
          groupId: group.id,
        ),
      ),
    );

    await loadData();
  }

  Future<void> editGroup(
    ReferenceGroup group,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditGroupPage(
          group: group,
        ),
      ),
    );

    await loadData();
  }

  Future<void> deleteGroup(
    ReferenceGroup group,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบข้อมูลหลัก?'),
        content: Text(
          'ต้องการลบกลุ่มนี้ทั้งหมดหรือไม่?\n\n'
          'ชื่อพระ: ${group.name}\n'
          '${group.model.isEmpty ? '' : 'รุ่น: ${group.model}\n'}'
          '${group.type.isEmpty ? '' : 'ประเภท: ${group.type}\n'}'
          '${group.pim.isEmpty ? '' : 'พิมพ์: ${group.pim}\n'}'
          '${group.temple.isEmpty ? '' : 'วัด / สำนัก: ${group.temple}\n'}'
          '\nจะลบองค์อ้างอิงทั้งหมด '
          '${group.references.length} องค์',
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

    await ReferenceStorage.deleteGroup(group.id);

    await loadData();
  }

  @override
  Widget build(BuildContext context) {
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
                      for (final group in groups)
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

  Widget _groupCard(ReferenceGroup group) {
    final scanCount = group.references.fold<int>(
      0,
      (sum, item) => sum + item.scans.length,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              group.name.isEmpty
                  ? 'ไม่ระบุชื่อ'
                  : group.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (group.model.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('รุ่น: ${group.model}'),
              ),
            if (group.type.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('ประเภท: ${group.type}'),
              ),
            if (group.pim.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('พิมพ์: ${group.pim}'),
              ),
            if (group.temple.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'วัด / สำนัก: ${group.temple}',
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'มี ${group.references.length} องค์อ้างอิง',
            ),
            Text(
              'มีข้อมูลการสแกน $scanCount รายการ',
            ),
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
                IconButton(
                  tooltip: 'แก้ไขข้อมูลหลัก',
                  onPressed: () => editGroup(group),
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  tooltip: 'ลบข้อมูลหลัก',
                  onPressed: () => deleteGroup(group),
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
// CREATE REFERENCE
// =====================================================

class CreateReferencePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CreateReferencePage({
    super.key,
    required this.cameras,
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
                'หลังจากเริ่มสแกน ระบบจะเก็บเฉพาะข้อมูล '
                'สำหรับการวิเคราะห์อ้างอิง '
                'โดยไม่เก็บไฟล์รูปภาพไว้ถาวร',
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
// EDIT GROUP
// =====================================================

class EditGroupPage extends StatefulWidget {
  final ReferenceGroup group;

  const EditGroupPage({
    super.key,
    required this.group,
  });

  @override
  State<EditGroupPage> createState() =>
      _EditGroupPageState();
}

class _EditGroupPageState
    extends State<EditGroupPage> {
  late TextEditingController nameController;
  late TextEditingController modelController;
  late TextEditingController pimController;
  late TextEditingController templeController;

  String? selectedType;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.group.name,
    );
    modelController = TextEditingController(
      text: widget.group.model,
    );
    pimController = TextEditingController(
      text: widget.group.pim,
    );
    templeController = TextEditingController(
      text: widget.group.temple,
    );

    selectedType = widget.group.type;
  }

  @override
  void dispose() {
    nameController.dispose();
    modelController.dispose();
    pimController.dispose();
    templeController.dispose();
    super.dispose();
  }

  Future<void> save() async {
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

    final updated = ReferenceGroup(
      id: widget.group.id,
      createdAt: widget.group.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      name: name,
      model: model,
      pim: pim,
      type: selectedType!,
      temple: temple,
      references: widget.group.references,
    );

    await ReferenceStorage.updateGroup(updated);

    if (!mounted) return;

    Navigator.pop(context, true);
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
        title: const Text('แก้ไขข้อมูลหลัก'),
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
              onPressed: save,
              icon: const Icon(Icons.save),
              label: const Text('บันทึกข้อมูลหลัก'),
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
  final String groupId;

  const ReferenceListPage({
    super.key,
    required this.cameras,
    required this.groupId,
  });

  @override
  State<ReferenceListPage> createState() =>
      _ReferenceListPageState();
}

class _ReferenceListPageState
    extends State<ReferenceListPage> {
  ReferenceGroup? group;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadGroup();
  }

  Future<void> loadGroup() async {
    final data = await ReferenceStorage.findGroup(
      widget.groupId,
    );

    if (!mounted) return;

    if (data != null) {
      data.references.sort(
        (a, b) =>
            a.referenceNumber.compareTo(b.referenceNumber),
      );
    }

    setState(() {
      group = data;
      loading = false;
    });
  }

  Future<void> addNewReference() async {
    final currentGroup = group;

    if (currentGroup == null) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          groupId: currentGroup.id,
          name: currentGroup.name,
          model: currentGroup.model,
          pim: currentGroup.pim,
          type: currentGroup.type,
          temple: currentGroup.temple,
        ),
      ),
    );

    if (saved == true) {
      await loadGroup();
    }
  }

  Future<void> openEdit(
    ReferenceData reference,
  ) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditReferencePage(
          cameras: widget.cameras,
          groupId: widget.groupId,
          reference: reference,
        ),
      ),
    );

    if (saved == true) {
      await loadGroup();
    }
  }

  Future<void> deleteReference(
    ReferenceData reference,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'ลบองค์อ้างอิงที่ ${reference.referenceNumber}?',
        ),
        content: const Text(
          'ข้อมูลการสแกนทั้งหมดขององค์นี้จะถูกลบ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              false,
            ),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              true,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ReferenceStorage.deleteReference(
      widget.groupId,
      reference.id,
    );

    await loadGroup();
  }

  @override
  Widget build(BuildContext context) {
    final currentGroup = group;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentGroup?.name.isNotEmpty == true
              ? currentGroup!.name
              : 'รายการอ้างอิง',
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : currentGroup == null
              ? const Center(
                  child: Text('ไม่พบข้อมูลกลุ่ม'),
                )
              : currentGroup.references.isEmpty
                  ? const Center(
                      child: Text(
                        'ยังไม่มีองค์อ้างอิง',
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount:
                          currentGroup.references.length,
                      itemBuilder: (context, index) {
                        return _referenceCard(
                          currentGroup.references[index],
                        );
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
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    item.referenceNumber.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'องค์อ้างอิง',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'ลำดับอ้างอิงที่ ${item.referenceNumber}',
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
                            group: group!,
                            reference: item,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('ดูข้อมูล'),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'แก้ไขและสแกน',
                  onPressed: () => openEdit(item),
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  tooltip: 'ลบองค์นี้',
                  onPressed: () =>
                      deleteReference(item),
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
  final ReferenceGroup group;
  final ReferenceData reference;

  const ReferenceDetailPage({
    super.key,
    required this.group,
    required this.reference,
  });

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
              'องค์อ้างอิงที่ ${reference.referenceNumber}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('ชื่อพระ: ${group.name}'),
            Text('รุ่น: ${group.model}'),
            Text('ประเภท: ${group.type}'),
            Text('พิมพ์: ${group.pim}'),
            Text('วัด / สำนัก: ${group.temple}'),
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
            Text('คุณภาพ: ${scan.quality}'),
            const SizedBox(height: 6),
            Text(scan.details),
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
// EDIT REFERENCE
// =====================================================

class EditReferencePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String groupId;
  final ReferenceData reference;

  const EditReferencePage({
    super.key,
    required this.cameras,
    required this.groupId,
    required this.reference,
  });

  @override
  State<EditReferencePage> createState() =>
      _EditReferencePageState();
}

class _EditReferencePageState
    extends State<EditReferencePage> {
  Future<void> editAndScan() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          groupId: widget.groupId,
          existingReference: widget.reference,
        ),
      ),
    );

    if (saved == true && mounted) {
      Navigator.pop(context, true);
    }
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'องค์อ้างอิงที่ '
                    '${widget.reference.referenceNumber}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ข้อมูลหลักของกลุ่มจะไม่ถูกแก้จากหน้านี้',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ใช้ปุ่มด้านล่างเพื่อเพิ่มหรือแก้ไข '
                    'ข้อมูลการสแกนขององค์นี้',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'มีข้อมูลสแกนแล้ว '
            '${widget.reference.scans.length} ด้าน',
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: editAndScan,
              icon: const Icon(Icons.camera_alt),
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

  final String? groupId;

  final String? name;
  final String? model;
  final String? pim;
  final String? type;
  final String? temple;

  final ReferenceData? existingReference;

  const ScanPage({
    super.key,
    required this.cameras,
    this.groupId,
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

class _ScanPageState
    extends State<ScanPage> {
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

  Future<void> startCamera() async {
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

  Future<void> takePhoto() async {
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
      final XFile? file =
          await picker.pickImage(
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

    msg('บันทึกข้อมูล $area แล้ว');
  }

  Future<void> exitScan() async {
    if (results.isEmpty) {
      final leave =
          await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            'ออกจากการสแกน?',
          ),
          content: const Text(
            'ยังไม่มีข้อมูลการสแกน',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child: const Text('อยู่ต่อ'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
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

    setState(() {
      saving = true;
    });

    try {
      final scanList =
          results.values.toList();

      // =================================================
      // แก้ไของค์อ้างอิงเดิม
      // =================================================

      if (isEditMode) {
        final old =
            widget.existingReference!;

        final updated =
            ReferenceData(
          id: old.id,
          referenceNumber:
              old.referenceNumber,
          createdAt: old.createdAt,
          updatedAt:
              DateTime.now()
                  .toIso8601String(),
          scans: scanList,
        );

        await ReferenceStorage
            .updateReference(
          widget.groupId!,
          updated,
        );

        if (!mounted) return;

        msg(
          'บันทึกการแก้ไขข้อมูลแล้ว',
        );

        Navigator.pop(context, true);

        return;
      }

      // =================================================
      // สร้างองค์อ้างอิงใหม่
      // =================================================

      final now =
          DateTime.now()
              .toIso8601String();

      // กรณีเพิ่มองค์ในกลุ่มเดิม
      if (widget.groupId != null) {
        final group =
            await ReferenceStorage
                .findGroup(
          widget.groupId!,
        );

        if (group == null) {
          msg('ไม่พบกลุ่มข้อมูล');
          return;
        }

        final number =
            ReferenceStorage
                .nextReferenceNumber(
          group,
        );

        final reference =
            ReferenceData(
          id:
              'reference_${DateTime.now().microsecondsSinceEpoch}',
          referenceNumber: number,
          createdAt: now,
          updatedAt: now,
          scans: scanList,
        );

        await ReferenceStorage
            .addReference(
          group.id,
          reference,
        );

        if (!mounted) return;

        msg(
          'บันทึกองค์อ้างอิงที่ $number แล้ว',
        );

        Navigator.pop(context, true);

        return;
      }

      // =================================================
      // สร้างกลุ่มใหม่พร้อมองค์แรก
      // =================================================

      final groupId =
          'group_${DateTime.now().microsecondsSinceEpoch}';

      final reference =
          ReferenceData(
        id:
            'reference_${DateTime.now().microsecondsSinceEpoch}',
        referenceNumber: 1,
        createdAt: now,
        updatedAt: now,
        scans: scanList,
      );

      final group =
          ReferenceGroup(
        id: groupId,
        createdAt: now,
        updatedAt: now,
        name: widget.name ?? '',
        model: widget.model ?? '',
        pim: widget.pim ?? '',
        type: widget.type ?? '',
        temple: widget.temple ?? '',
        references: [reference],
      );

      await ReferenceStorage
          .createGroupWithReference(
        group,
        reference,
      );

      if (!mounted) return;

      msg(
        'บันทึกองค์อ้างอิงที่ 1 แล้ว',
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        msg(
          'เกิดข้อผิดพลาดในการบันทึกข้อมูล',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  void msg(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  Widget areaButton(String area) {
    final selected =
        currentArea == area;

    final hasData =
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
                ? Colors.brown
                    .withOpacity(0.12)
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal,
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
            padding:
                const EdgeInsets.fromLTRB(
              6,
              8,
              6,
              6,
            ),
            child: Row(
              children: [
                for (final area in areas)
                  areaButton(area),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(
              vertical: 4,
            ),
            child: Text(
              'กำลังเก็บข้อมูล: $currentArea',
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: loadingCamera
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : cameraReady
                      ? CameraPreview(
                          controller!,
                        )
                      : const Center(
                          child: Text(
                            'ไม่พบกล้อง',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize:
                                  18,
                            ),
                          ),
                        ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          FilledButton.icon(
                        onPressed:
                            loadingCamera ||
                                    saving
                                ? null
                                : takePhoto,
                        icon: const Icon(
                          Icons.camera_alt,
                        ),
                        label:
                            const Text(
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
                        onPressed: saving
                            ? null
                            : chooseGallery,
                        icon: const Icon(
                          Icons
                              .photo_library,
                        ),
                        label:
                            const Text(
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
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        saving
                            ? null
                            : exitScan,
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
