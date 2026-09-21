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

const areas = ['ด้านหน้า', 'ด้านหลัง', 'ด้านข้าง', 'ก้นพระ'];

const typeOptions = [
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

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

class ScanResult {
  String area;
  String details;

  ScanResult({
    required this.area,
    this.details = '',
  });

  Map<String, dynamic> toMap() => {
        'area': area,
        'details': details,
      };

  factory ScanResult.fromMap(Map<String, dynamic> m) => ScanResult(
        area: m['area'] ?? '',
        details: m['details'] ?? '',
      );
}

class ReferenceData {
  String id;
  int referenceNumber;
  DateTime createdAt;
  DateTime updatedAt;
  List<ScanResult> scans;

  ReferenceData({
    required this.id,
    required this.referenceNumber,
    required this.createdAt,
    DateTime? updatedAt,
    List<ScanResult>? scans,
  })  : updatedAt = updatedAt ?? createdAt,
        scans = scans ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'referenceNumber': referenceNumber,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'scans': scans.map((e) => e.toMap()).toList(),
      };

  factory ReferenceData.fromMap(Map<String, dynamic> m) => ReferenceData(
        id: m['id'] ?? newId(),
        referenceNumber: m['referenceNumber'] ?? 1,
        createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
        scans: (m['scans'] as List? ?? [])
            .map((e) => ScanResult.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );

  ReferenceData copyWith({
    int? referenceNumber,
    List<ScanResult>? scans,
  }) =>
      ReferenceData(
        id: id,
        referenceNumber: referenceNumber ?? this.referenceNumber,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        scans: scans ?? this.scans,
      );
}

class PrintData {
  String id;
  String name;
  DateTime createdAt;
  DateTime updatedAt;
  List<ReferenceData> references;

  PrintData({
    required this.id,
    required this.name,
    required this.createdAt,
    DateTime? updatedAt,
    List<ReferenceData>? references,
  })  : updatedAt = updatedAt ?? createdAt,
        references = references ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'references': references.map((e) => e.toMap()).toList(),
      };

  factory PrintData.fromMap(Map<String, dynamic> m) => PrintData(
        id: m['id'] ?? newId(),
        name: m['name'] ?? 'พิมพ์เดียว',
        createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
        references: (m['references'] as List? ?? [])
            .map((e) => ReferenceData.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class TypeData {
  String id;
  String name;
  DateTime createdAt;
  DateTime updatedAt;
  List<PrintData> prints;

  TypeData({
    required this.id,
    required this.name,
    required this.createdAt,
    DateTime? updatedAt,
    List<PrintData>? prints,
  })  : updatedAt = updatedAt ?? createdAt,
        prints = prints ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'prints': prints.map((e) => e.toMap()).toList(),
      };

  factory TypeData.fromMap(Map<String, dynamic> m) => TypeData(
        id: m['id'] ?? newId(),
        name: m['name'] ?? '',
        createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
        prints: (m['prints'] as List? ?? [])
            .map((e) => PrintData.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class ModelData {
  String id;
  String name;
  DateTime createdAt;
  DateTime updatedAt;
  List<TypeData> types;

  ModelData({
    required this.id,
    required this.name,
    required this.createdAt,
    DateTime? updatedAt,
    List<TypeData>? types,
  })  : updatedAt = updatedAt ?? createdAt,
        types = types ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'types': types.map((e) => e.toMap()).toList(),
      };

  factory ModelData.fromMap(Map<String, dynamic> m) => ModelData(
        id: m['id'] ?? newId(),
        name: m['name'] ?? '',
        createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
        types: (m['types'] as List? ?? [])
            .map((e) => TypeData.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class GroupData {
  String id;
  String name;
  String temple;
  DateTime createdAt;
  DateTime updatedAt;
  List<ModelData> models;

  GroupData({
    required this.id,
    required this.name,
    required this.temple,
    required this.createdAt,
    DateTime? updatedAt,
    List<ModelData>? models,
  })  : updatedAt = updatedAt ?? createdAt,
        models = models ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'temple': temple,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'models': models.map((e) => e.toMap()).toList(),
      };

  factory GroupData.fromMap(Map<String, dynamic> m) => GroupData(
        id: m['id'] ?? newId(),
        name: m['name'] ?? '',
        temple: m['temple'] ?? '',
        createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
        models: (m['models'] as List? ?? [])
            .map((e) => ModelData.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class Storage {
  static const key = 'reference_groups';

  static Future<List<GroupData>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return [];

    try {
      return (jsonDecode(raw) as List)
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

  static Future<void> renumber(PrintData print) async {
    for (int i = 0; i < print.references.length; i++) {
      print.references[i] =
          print.references[i].copyWith(referenceNumber: i + 1);
    }
  }
}

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

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage(this.cameras, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<GroupData> groups = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    groups = await Storage.load();
    if (mounted) setState(() {});
  }

  Future<void> createGroup() async {
    final r = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => FormDialog(
        title: 'สร้างองค์อ้างอิง',
        fields: const ['ชื่อพระ', 'วัด / สำนัก'],
      ),
    );

    if (r == null || r['ชื่อพระ']!.trim().isEmpty) return;

    groups.add(
      GroupData(
        id: newId(),
        name: r['ชื่อพระ']!.trim(),
        temple: r['วัด / สำนัก']!.trim(),
        createdAt: DateTime.now(),
      ),
    );

    await Storage.save(groups);
    setState(() {});
  }

  Future<void> openGroup(GroupData g) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupPage(g, groups, widget.cameras),
      ),
    );
    await load();
  }

  Future<void> deleteGroup(GroupData g) async {
    if (!await confirm(context, 'ลบองค์อ้างอิง "${g.name}" ?')) return;
    groups.removeWhere((e) => e.id == g.id);
    await Storage.save(groups);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('กล้องสแกนพระ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: createGroup,
                icon: const Icon(Icons.add),
                label: const Text('สร้าง / เพิ่มองค์อ้างอิง'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: groups.isEmpty
                  ? const Center(child: Text('ยังไม่มีข้อมูลอ้างอิง'))
                  : ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (_, i) {
                        final g = groups[i];
                        return Card(
                          child: ListTile(
                            title: Text(g.name),
                            subtitle: Text(
                              g.temple.isEmpty
                                  ? 'ยังไม่ได้ระบุวัด / สำนัก'
                                  : g.temple,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => deleteGroup(g),
                            ),
                            onTap: () => openGroup(g),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupPage extends StatefulWidget {
  final GroupData group;
  final List<GroupData> groups;
  final List<CameraDescription> cameras;

  const GroupPage(this.group, this.groups, this.cameras, {super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  Future<void> save() => Storage.save(widget.groups);

  Future<void> addModel() async {
    final name = await textDialog(context, 'ชื่อรุ่น');
    if (name == null || name.trim().isEmpty) return;

    widget.group.models.add(
      ModelData(
        id: newId(),
        name: name.trim(),
        createdAt: DateTime.now(),
      ),
    );

    widget.group.updatedAt = DateTime.now();
    await save();
    setState(() {});
  }

  Future<void> deleteModel(ModelData m) async {
    if (!await confirm(context, 'ลบรุ่น "${m.name}" ?')) return;
    widget.group.models.removeWhere((e) => e.id == m.id);
    await save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: addModel,
        child: const Icon(Icons.add),
      ),
      body: widget.group.models.isEmpty
          ? const Center(child: Text('ยังไม่มีรุ่น'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.group.models.length,
              itemBuilder: (_, i) {
                final m = widget.group.models[i];
                return Card(
                  child: ListTile(
                    title: Text(m.name),
                    subtitle: Text('${m.types.length} ประเภท'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => deleteModel(m),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ModelPage(
                            widget.group,
                            m,
                            widget.groups,
                            widget.cameras,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }
}

class ModelPage extends StatefulWidget {
  final GroupData group;
  final ModelData model;
  final List<GroupData> groups;
  final List<CameraDescription> cameras;

  const ModelPage(
    this.group,
    this.model,
    this.groups,
    this.cameras, {
    super.key,
  });

  @override
  State<ModelPage> createState() => _ModelPageState();
}

class _ModelPageState extends State<ModelPage> {
  Future<void> save() => Storage.save(widget.groups);

  Future<void> addType() async {
    String? type = await showDialog<String>(
      context: context,
      builder: (_) => TypeDialog(),
    );

    if (type == null || type.trim().isEmpty) return;

    widget.model.types.add(
      TypeData(
        id: newId(),
        name: type.trim(),
        createdAt: DateTime.now(),
      ),
    );

    await save();
    setState(() {});
  }

  Future<void> deleteType(TypeData t) async {
    if (!await confirm(context, 'ลบประเภท "${t.name}" ?')) return;
    widget.model.types.removeWhere((e) => e.id == t.id);
    await save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.model.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: addType,
        child: const Icon(Icons.add),
      ),
      body: widget.model.types.isEmpty
          ? const Center(child: Text('ยังไม่มีประเภท'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.model.types.length,
              itemBuilder: (_, i) {
                final t = widget.model.types[i];
                return Card(
                  child: ListTile(
                    title: Text(t.name),
                    subtitle: Text('${t.prints.length} พิมพ์'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => deleteType(t),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TypePage(
                            widget.group,
                            widget.model,
                            t,
                            widget.groups,
                            widget.cameras,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }
}

class TypePage extends StatefulWidget {
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final List<GroupData> groups;
  final List<CameraDescription> cameras;

  const TypePage(
    this.group,
    this.model,
    this.type,
    this.groups,
    this.cameras, {
    super.key,
  });

  @override
  State<TypePage> createState() => _TypePageState();
}

class _TypePageState extends State<TypePage> {
  Future<void> save() => Storage.save(widget.groups);

  Future<void> addPrint() async {
    final name = await textDialog(
      context,
      'ชื่อพิมพ์',
      hint: 'เว้นว่างได้',
    );

    if (name == null) return;

    final printName =
        name.trim().isEmpty ? 'พิมพ์เดียว' : name.trim();

    widget.type.prints.add(
      PrintData(
        id: newId(),
        name: printName,
        createdAt: DateTime.now(),
      ),
    );

    await save();
    setState(() {});
  }

  Future<void> deletePrint(PrintData p) async {
    if (!await confirm(context, 'ลบพิมพ์ "${p.name}" ?')) return;
    widget.type.prints.removeWhere((e) => e.id == p.id);
    await save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.type.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: addPrint,
        child: const Icon(Icons.add),
      ),
      body: widget.type.prints.isEmpty
          ? const Center(child: Text('ยังไม่มีพิมพ์'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.type.prints.length,
              itemBuilder: (_, i) {
                final p = widget.type.prints[i];
                return Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      'มีองค์อ้างอิง ${p.references.length} องค์',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => deletePrint(p),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrintPage(
                            widget.group,
                            widget.model,
                            widget.type,
                            p,
                            widget.groups,
                            widget.cameras,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }
}

class PrintPage extends StatefulWidget {
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final List<GroupData> groups;
  final List<CameraDescription> cameras;

  const PrintPage(
    this.group,
    this.model,
    this.type,
    this.print,
    this.groups,
    this.cameras, {
    super.key,
  });

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  Future<void> save() => Storage.save(widget.groups);

  Future<void> addReference() async {
    final r = ReferenceData(
      id: newId(),
      referenceNumber: widget.print.references.length + 1,
      createdAt: DateTime.now(),
    );

    widget.print.references.add(r);
    await save();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReferencePage(
          widget.group,
          widget.model,
          widget.type,
          widget.print,
          r,
          widget.groups,
          widget.cameras,
        ),
      ),
    );

    await Storage.renumber(widget.print);
    await save();
    setState(() {});
  }

  Future<void> deleteReference(ReferenceData r) async {
    if (!await confirm(
      context,
      'ลบองค์อ้างอิงที่ ${r.referenceNumber} ?',
    )) return;

    widget.print.references.removeWhere((e) => e.id == r.id);
    await Storage.renumber(widget.print);
    await save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.print.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: addReference,
        child: const Icon(Icons.add),
      ),
      body: widget.print.references.isEmpty
          ? const Center(child: Text('ยังไม่มีองค์อ้างอิง'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.print.references.length,
              itemBuilder: (_, i) {
                final r = widget.print.references[i];
                return Card(
                  child: ListTile(
                    title: Text('องค์อ้างอิงที่ ${r.referenceNumber}'),
                    subtitle: Text(
                      'มีข้อมูล ${r.scans.length}/4 ด้าน',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => deleteReference(r),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReferencePage(
                            widget.group,
                            widget.model,
                            widget.type,
                            widget.print,
                            r,
                            widget.groups,
                            widget.cameras,
                          ),
                        ),
                      );
                      await save();
                      setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }
}

class ReferencePage extends StatefulWidget {
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;
  final List<GroupData> groups;
  final List<CameraDescription> cameras;

  const ReferencePage(
    this.group,
    this.model,
    this.type,
    this.print,
    this.reference,
    this.groups,
    this.cameras, {
    super.key,
  });

  @override
  State<ReferencePage> createState() => _ReferencePageState();
}

class _ReferencePageState extends State<ReferencePage> {
  Future<void> save() => Storage.save(widget.groups);

  ScanResult? getScan(String area) {
    for (final s in widget.reference.scans) {
      if (s.area == area) return s;
    }
    return null;
  }

  Future<void> scan(String area) async {
    final result = await Navigator.push<ScanResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          area: area,
          cameras: widget.cameras,
        ),
      ),
    );

    if (result == null) return;

    widget.reference.scans.removeWhere((e) => e.area == area);
    widget.reference.scans.add(result);
    widget.reference.updatedAt = DateTime.now();

    await save();
    setState(() {});
  }

  Future<void> deleteScan(String area) async {
    if (!await confirm(context, 'ลบข้อมูลด้าน$area ?')) return;
    widget.reference.scans.removeWhere((e) => e.area == area);
    await save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('องค์อ้างอิงที่ ${widget.reference.referenceNumber}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final area in areas)
            Card(
              child: ListTile(
                title: Text(area),
                subtitle: Text(
                  getScan(area) == null
                      ? 'ยังไม่ได้ระบุข้อมูล'
                      : 'มีข้อมูล\n${getScan(area)!.details}',
                ),
                isThreeLine: true,
                trailing: getScan(area) == null
                    ? const Icon(Icons.camera_alt_outlined)
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => deleteScan(area),
                      ),
                onTap: () => scan(area),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'ระบบเก็บข้อมูลวิเคราะห์ ไม่ได้เก็บรูปภาพถาวร',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ScanPage extends StatelessWidget {
  final String area;
  final List<CameraDescription> cameras;

  const ScanPage({
    required this.area,
    required this.cameras,
    super.key,
  });

  Future<void> scanCamera(BuildContext context) async {
    if (cameras.isEmpty) return;

    final back = cameras.where(
      (c) => c.lensDirection == CameraLensDirection.back,
    );

    final camera = back.isNotEmpty ? back.first : cameras.first;

    final file = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScanPage(camera),
      ),
    );

    if (file == null) return;

    try {
      await File(file.path).delete();
    } catch (_) {}

    if (!context.mounted) return;

    Navigator.pop(
      context,
      ScanResult(
        area: area,
        details: 'รอระบบ AI วิเคราะห์สิ่งที่มองเห็นจากภาพ',
      ),
    );
  }

  Future<void> scanGallery(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (file == null || !context.mounted) return;

    Navigator.pop(
      context,
      ScanResult(
        area: area,
        details: 'รอระบบ AI วิเคราะห์สิ่งที่มองเห็นจากภาพ',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('สแกน$area')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => scanCamera(context),
                icon: const Icon(Icons.camera_alt),
                label: const Text('เปิดกล้อง'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => scanGallery(context),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('เลือกจากแกลเลอรี'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraScanPage extends StatefulWidget {
  final CameraDescription camera;

  const CameraScanPage(this.camera, {super.key});

  @override
  State<CameraScanPage> createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  late CameraController controller;
  Future<void>? initialize;

  @override
  void initState() {
    super.initState();

    controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    initialize = controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> capture() async {
    if (!controller.value.isInitialized ||
        controller.value.isTakingPicture) return;

    final file = await controller.takePicture();

    if (!mounted) return;
    Navigator.pop(context, file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('กล้อง')),
      body: FutureBuilder(
        future: initialize,
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton.large(
                    onPressed: capture,
                    child: const Icon(Icons.camera),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FormDialog extends StatefulWidget {
  final String title;
  final List<String> fields;

  const FormDialog({
    required this.title,
    required this.fields,
    super.key,
  });

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  late final Map<String, TextEditingController> c;

  @override
  void initState() {
    super.initState();
    c = {
      for (final f in widget.fields) f: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final x in c.values) {
      x.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in widget.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: c[f],
                  decoration: InputDecoration(
                    labelText: f,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              {
                for (final f in widget.fields: f: c[f]!.text),
              },
            );
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}

class TypeDialog extends StatefulWidget {
  const TypeDialog({super.key});

  @override
  State<TypeDialog> createState() => _TypeDialogState();
}

class _TypeDialogState extends State<TypeDialog> {
  String? selected;
  final other = TextEditingController();

  @override
  void dispose() {
    other.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เลือกประเภท'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: selected,
            isExpanded: true,
            items: typeOptions
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => selected = v),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'ประเภท',
            ),
          ),
          if (selected == 'อื่น ๆ') ...[
            const SizedBox(height: 10),
            TextField(
              controller: other,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'ระบุประเภท',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            if (selected == null) return;

            if (selected == 'อื่น ๆ') {
              if (other.text.trim().isEmpty) return;
              Navigator.pop(context, other.text.trim());
            } else {
              Navigator.pop(context, selected);
            }
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}

Future<String?> textDialog(
  BuildContext context,
  String title, {
  String? hint,
}) async {
  final c = TextEditingController();

  final r = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: hint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, c.text),
          child: const Text('บันทึก'),
        ),
      ],
    ),
  );

  c.dispose();
  return r;
}

Future<bool> confirm(
  BuildContext context,
  String message,
) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      content: Text(message),
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

  return r == true;
}
