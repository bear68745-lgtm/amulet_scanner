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

// =====================================================
// CONSTANTS
// =====================================================

const areas = [
  'ด้านหน้า',
  'ด้านหลัง',
  'ด้านข้าง',
  'ก้นพระ',
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
    this.quality = '',
    this.details = '',
    this.brightness = 0,
    this.sharpness = 0,
    this.fromGallery = false,
  });

  Map<String, dynamic> toMap() => {
        'area': area,
        'quality': quality,
        'details': details,
        'brightness': brightness,
        'sharpness': sharpness,
        'fromGallery': fromGallery,
      };

  factory ScanResult.fromMap(Map<String, dynamic> m) {
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
// REFERENCE
// =====================================================

class ReferenceData {
  final String id;
  final int referenceNumber;
  final String createdAt;
  final String updatedAt;
  final List<ScanResult> scans;

  ReferenceData({
    required this.id,
    required this.referenceNumber,
    required this.createdAt,
    required this.updatedAt,
    this.scans = const [],
  });

  ReferenceData copyWith({
    int? referenceNumber,
    String? updatedAt,
    List<ScanResult>? scans,
  }) {
    return ReferenceData(
      id: id,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scans: scans ?? this.scans,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'referenceNumber': referenceNumber,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'scans': scans.map((e) => e.toMap()).toList(),
      };

  factory ReferenceData.fromMap(Map<String, dynamic> m) {
    return ReferenceData(
      id: m['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
      referenceNumber: m['referenceNumber'] ?? 1,
      createdAt: m['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: m['updatedAt'] ?? DateTime.now().toIso8601String(),
      scans: (m['scans'] as List? ?? [])
          .map((e) => ScanResult.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

// =====================================================
// TYPE
// =====================================================

class TypeData {
  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final List<ReferenceData> references;

  TypeData({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.references = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'references': references.map((e) => e.toMap()).toList(),
      };

  factory TypeData.fromMap(Map<String, dynamic> m) {
    return TypeData(
      id: m['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: m['name'] ?? '',
      createdAt: m['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: m['updatedAt'] ?? DateTime.now().toIso8601String(),
      references: (m['references'] as List? ?? [])
          .map((e) => ReferenceData.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

// =====================================================
// MODEL / รุ่น
// =====================================================

class ModelData {
  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final List<TypeData> types;

  ModelData({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.types = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'types': types.map((e) => e.toMap()).toList(),
      };

  factory ModelData.fromMap(Map<String, dynamic> m) {
    return ModelData(
      id: m['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: m['name'] ?? '',
      createdAt: m['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: m['updatedAt'] ?? DateTime.now().toIso8601String(),
      types: (m['types'] as List? ?? [])
          .map((e) => TypeData.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

// =====================================================
// GROUP
// =====================================================

class GroupData {
  final String id;
  final String name;
  final String temple;
  final String createdAt;
  final String updatedAt;
  final List<ModelData> models;

  GroupData({
    required this.id,
    required this.name,
    required this.temple,
    required this.createdAt,
    required this.updatedAt,
    this.models = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'temple': temple,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'models': models.map((e) => e.toMap()).toList(),
      };

  factory GroupData.fromMap(Map<String, dynamic> m) {
    return GroupData(
      id: m['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: m['name'] ?? '',
      temple: m['temple'] ?? '',
      createdAt: m['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: m['updatedAt'] ?? DateTime.now().toIso8601String(),
      models: (m['models'] as List? ?? [])
          .map((e) => ModelData.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

// =====================================================
// STORAGE
// =====================================================

class Storage {
  static const key = 'reference_groups';

  static Future<List<GroupData>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key);

    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List;

      return list
          .map((e) => GroupData.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<GroupData> groups) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      key,
      jsonEncode(groups.map((e) => e.toMap()).toList()),
    );
  }

  static String id() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  static String now() => DateTime.now().toIso8601String();

  static int nextReferenceNumber(List<GroupData> groups) {
    var max = 0;

    for (final group in groups) {
      for (final model in group.models) {
        for (final type in model.types) {
          for (final ref in type.references) {
            if (ref.referenceNumber > max) {
              max = ref.referenceNumber;
            }
          }
        }
      }
    }

    return max + 1;
  }
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
      title: 'กล้องสแกนพระ',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.brown,
      ),
      home: HomePage(cameras),
    );
  }
}

// =====================================================
// HOME
// =====================================================

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage(this.cameras, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int groupCount = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final groups = await Storage.load();

    if (mounted) {
      setState(() {
        groupCount = groups.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('กล้องสแกนพระ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _button(
            context,
            'สร้างกลุ่มใหม่',
            Icons.create_new_folder,
            () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateGroupPage(widget.cameras),
                ),
              );
              load();
            },
          ),
          _button(
            context,
            'รายการข้อมูลอ้างอิง ($groupCount กลุ่ม)',
            Icons.folder,
            () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupListPage(widget.cameras),
                ),
              );
              load();
            },
          ),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'ระบบเก็บข้อมูลวิเคราะห์และข้อมูลอ้างอิง '
                'โดยไม่เก็บรูปภาพถาวร',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(text),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// =====================================================
// CREATE GROUP
// =====================================================

class CreateGroupPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CreateGroupPage(this.cameras, {super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final nameController = TextEditingController();
  final templeController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    templeController.dispose();
    super.dispose();
  }

  Future<void> create() async {
    final name = nameController.text.trim();
    final temple = templeController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาใส่ชื่อกลุ่ม')),
      );
      return;
    }

    final groups = await Storage.load();
    final now = Storage.now();

    final group = GroupData(
      id: Storage.id(),
      name: name,
      temple: temple,
      createdAt: now,
      updatedAt: now,
    );

    groups.add(group);
    await Storage.save(groups);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ModelListPage(
          cameras: widget.cameras,
          groupId: group.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างกลุ่ม')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'ชื่อกลุ่ม',
              hintText: 'เช่น สมเด็จบางขุนพรหม',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: templeController,
            decoration: const InputDecoration(
              labelText: 'วัด / สำนัก',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: create,
            child: const Text('สร้างกลุ่ม'),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// GROUP LIST
// =====================================================

class GroupListPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const GroupListPage(this.cameras, {super.key});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  List<GroupData> groups = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await Storage.load();

    if (mounted) {
      setState(() => groups = data);
    }
  }

  Future<void> deleteGroup(GroupData group) async {
    groups.removeWhere((e) => e.id == group.id);
    await Storage.save(groups);
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('กลุ่มข้อมูล')),
      body: groups.isEmpty
          ? const Center(child: Text('ยังไม่มีข้อมูล'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: groups.length,
              itemBuilder: (_, i) {
                final group = groups[i];
                final modelCount = group.models.length;

                return Card(
                  child: ListTile(
                    title: Text(group.name),
                    subtitle: Text(
                      '${group.temple.isEmpty ? 'ไม่ระบุวัด/สำนัก' : group.temple}'
                      '\nรุ่น $modelCount รายการ',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('ลบกลุ่ม'),
                        ),
                      ],
                      onSelected: (v) async {
                        if (v == 'delete') {
                          await deleteGroup(group);
                        }
                      },
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ModelListPage(
                            cameras: widget.cameras,
                            groupId: group.id,
                          ),
                        ),
                      );
                      load();
                    },
                  ),
                );
              },
            ),
    );
  }
}

// =====================================================
// MODEL LIST
// =====================================================

class ModelListPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String groupId;

  const ModelListPage({
    required this.cameras,
    required this.groupId,
    super.key,
  });

  @override
  State<ModelListPage> createState() => _ModelListPageState();
}

class _ModelListPageState extends State<ModelListPage> {
  GroupData? group;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final groups = await Storage.load();

    GroupData? found;

    for (final g in groups) {
      if (g.id == widget.groupId) {
        found = g;
        break;
      }
    }

    if (mounted) {
      setState(() => group = found);
    }
  }

  Future<void> addModel() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เพิ่มรุ่น'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'ชื่อรุ่น',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name == null) return;

    final groups = await Storage.load();
    final index = groups.indexWhere((e) => e.id == widget.groupId);

    if (index < 0) return;

    final now = Storage.now();

    groups[index].models.add(
          ModelData(
            id: Storage.id(),
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await Storage.save(groups);
    load();
  }

  @override
  Widget build(BuildContext context) {
    if (group == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(group!.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addModel,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรุ่น'),
      ),
      body: group!.models.isEmpty
          ? const Center(child: Text('ยังไม่มีรุ่น'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: group!.models.length,
              itemBuilder: (_, i) {
                final model = group!.models[i];

                return Card(
                  child: ListTile(
                    title: Text(model.name),
                    subtitle: Text(
                      'ชนิด ${model.types.length} รายการ',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TypeListPage(
                            cameras: widget.cameras,
                            groupId: widget.groupId,
                            modelId: model.id,
                          ),
                        ),
                      );
                      load();
                    },
                  ),
                );
              },
            ),
    );
  }
}

// =====================================================
// TYPE LIST
// =====================================================

class TypeListPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String groupId;
  final String modelId;

  const TypeListPage({
    required this.cameras,
    required this.groupId,
    required this.modelId,
    super.key,
  });

  @override
  State<TypeListPage> createState() => _TypeListPageState();
}

class _TypeListPageState extends State<TypeListPage> {
  ModelData? model;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final groups = await Storage.load();

    for (final group in groups) {
      if (group.id != widget.groupId) continue;

      for (final m in group.models) {
        if (m.id == widget.modelId) {
          if (mounted) setState(() => model = m);
          return;
        }
      }
    }
  }

  Future<void> addType() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เพิ่มชนิด'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'ชื่อชนิด',
            hintText: 'เช่น พระสมเด็จ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name == null) return;

    final groups = await Storage.load();

    for (final group in groups) {
      if (group.id != widget.groupId) continue;

      for (final m in group.models) {
        if (m.id != widget.modelId) continue;

        final now = Storage.now();

        m.types.add(
              TypeData(
                id: Storage.id(),
                name: name,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    }

    await Storage.save(groups);
    load();
  }

  @override
  Widget build(BuildContext context) {
    if (model == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('รุ่น ${model!.name}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addType,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มชนิด'),
      ),
      body: model!.types.isEmpty
          ? const Center(child: Text('ยังไม่มีชนิด'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: model!.types.length,
              itemBuilder: (_, i) {
                final type = model!.types[i];

                return Card(
                  child: ListTile(
                    title: Text(type.name),
                    subtitle: Text(
                      'อ้างอิง ${type.references.length} องค์',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReferenceListPage(
                            cameras: widget.cameras,
                            groupId: widget.groupId,
                            modelId: widget.modelId,
                            typeId: type.id,
                          ),
                        ),
                      );
                      load();
                    },
                  ),
                );
              },
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
  final String modelId;
  final String typeId;

  const ReferenceListPage({
    required this.cameras,
    required this.groupId,
    required this.modelId,
    required this.typeId,
    super.key,
  });

  @override
  State<ReferenceListPage> createState() => _ReferenceListPageState();
}

class _ReferenceListPageState extends State<ReferenceListPage> {
  TypeData? type;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final groups = await Storage.load();

    for (final group in groups) {
      if (group.id != widget.groupId) continue;

      for (final model in group.models) {
        if (model.id != widget.modelId) continue;

        for (final t in model.types) {
          if (t.id == widget.typeId) {
            if (mounted) setState(() => type = t);
            return;
          }
        }
      }
    }
  }

  Future<void> addReference() async {
    final number = Storage.nextReferenceNumber(await Storage.load());

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          groupId: widget.groupId,
          modelId: widget.modelId,
          typeId: widget.typeId,
          referenceId: null,
          referenceNumber: number,
        ),
      ),
    );

    load();
  }

  Future<void> deleteReference(String id) async {
    final groups = await Storage.load();

    for (final group in groups) {
      if (group.id != widget.groupId) continue;

      for (final model in group.models) {
        if (model.id != widget.modelId) continue;

        for (final t in model.types) {
          if (t.id != widget.typeId) continue;

          t.references.removeWhere((r) => r.id == id);
        }
      }
    }

    await Storage.save(groups);
    load();
  }

  @override
  Widget build(BuildContext context) {
    if (type == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(type!.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addReference,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มอ้างอิง'),
      ),
      body: type!.references.isEmpty
          ? const Center(child: Text('ยังไม่มีข้อมูลอ้างอิง'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: type!.references.length,
              itemBuilder: (_, i) {
                final ref = type!.references[i];

                return Card(
                  child: ListTile(
                    title: Text('อ้างอิงที่ ${ref.referenceNumber}'),
                    subtitle: Text(
                      'มีข้อมูล ${ref.scans.length}/4 ด้าน',
                    ),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('ลบ'),
                        ),
                      ],
                      onSelected: (v) async {
                        if (v == 'delete') {
                          await deleteReference(ref.id);
                        }
                      },
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScanPage(
                            cameras: widget.cameras,
                            groupId: widget.groupId,
                            modelId: widget.modelId,
                            typeId: widget.typeId,
                            referenceId: ref.id,
                            referenceNumber: ref.referenceNumber,
                          ),
                        ),
                      );
                      load();
                    },
                  ),
                );
              },
            ),
    );
  }
}

// =====================================================
// SCAN PAGE
// =====================================================

class ScanPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String groupId;
  final String modelId;
  final String typeId;
  final String? referenceId;
  final int referenceNumber;

  const ScanPage({
    required this.cameras,
    required this.groupId,
    required this.modelId,
    required this.typeId,
    required this.referenceId,
    required this.referenceNumber,
    super.key,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? controller;

  int currentIndex = 0;
  final Map<String, ScanResult> results = {};

  @override
  void initState() {
    super.initState();
    loadExisting();
    initCamera();
  }

  Future<void> loadExisting() async {
    if (widget.referenceId == null) return;

    final groups = await Storage.load();

    for (final group in groups) {
      if (group.id != widget.groupId) continue;

      for (final model in group.models) {
        if (model.id != widget.modelId) continue;

        for (final type in model.types) {
          if (type.id != widget.typeId) continue;

          for (final ref in type.references) {
            if (ref.id == widget.referenceId) {
              for (final scan in ref.scans) {
                results[scan.area] = scan;
              }
            }
          }
        }
      }
    }

    for (var i = 0; i < areas.length; i++) {
      if (!results.containsKey(areas[i])) {
        currentIndex = i;
        break;
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> initCamera() async {
    if (widget.cameras.isEmpty) return;

    CameraDescription selected = widget.cameras.first;

    for (final camera in widget.cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        selected = camera;
        break;
      }
    }

    controller = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller!.initialize();

      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> scanCamera() async {
    if (controller == null || !controller!.value.isInitialized) return;

    final file = await controller!.takePicture();

    await saveScan(
      area: areas[currentIndex],
      fromGallery: false,
      tempPath: file.path,
    );
  }

  Future<void> scanGallery() async {
    final picker = ImagePicker();

    final file = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (file == null) return;

    // อ่านเพื่อใช้วิเคราะห์เท่านั้น
    // ไม่มีการ copy และไม่มีการบันทึก path ลงฐานข้อมูล
    await saveScan(
      area: areas[currentIndex],
      fromGallery: true,
      tempPath: null,
    );
  }

  Future<void> saveScan({
    required String area,
    required bool fromGallery,
    String? tempPath,
  }) async {
    final result = ScanResult(
      area: area,
      quality: 'พร้อมสำหรับเก็บข้อมูลอ้างอิง',
      details: 'รอระบบ AI วิเคราะห์รายละเอียดทั้งหมดที่มองเห็นในองค์พระ',
      brightness: 0,
      sharpness: 0,
      fromGallery: fromGallery,
    );

    results[area] = result;

    // ลบไฟล์ภาพชั่วคราวจากกล้องทันที
    if (!fromGallery &&
        tempPath != null &&
        tempPath.isNotEmpty) {
      try {
        final f = File(tempPath);

        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }

    if (currentIndex < areas.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      setState(() {});
    }
  }

  Future<void> saveReference() async {
    final groups = await Storage.load();

    for (final group in groups) {
      if (group.id != widget.groupId) continue;

      for (final model in group.models) {
        if (model.id != widget.modelId) continue;

        for (final type in model.types) {
          if (type.id != widget.typeId) continue;

          final now = Storage.now();

          final scans = areas
              .where(results.containsKey)
              .map((area) => results[area]!)
              .toList();

          if (widget.referenceId == null) {
            type.references.add(
              ReferenceData(
                id: Storage.id(),
                referenceNumber: widget.referenceNumber,
                createdAt: now,
                updatedAt: now,
                scans: scans,
              ),
            );
          } else {
            final index = type.references.indexWhere(
              (r) => r.id == widget.referenceId,
            );

            if (index >= 0) {
              type.references[index] =
                  type.references[index].copyWith(
                updatedAt: now,
                scans: scans,
              );
            }
          }
        }
      }
    }

    await Storage.save(groups);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final area = areas[currentIndex];
    final hasCamera =
        controller != null && controller!.value.isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'อ้างอิงที่ ${widget.referenceNumber} • $area',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: hasCamera
                ? CameraPreview(controller!)
                : const Center(
                    child: Text('กำลังเปิดกล้อง...'),
                  ),
          ),

          SizedBox(
            height: 58,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: areas.length,
              itemBuilder: (_, i) {
                final selected = i == currentIndex;
                final hasData = results.containsKey(areas[i]);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      hasData
                          ? '${areas[i]} ✓'
                          : areas[i],
                    ),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        currentIndex = i;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: hasCamera ? scanCamera : null,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('สแกน'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: scanGallery,
                    icon: const Icon(Icons.photo),
                    label: const Text('เลือกรูป'),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saveReference,
                child: const Text('บันทึกข้อมูลอ้างอิง'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
