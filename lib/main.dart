import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (_) {}
  runApp(App(cameras));
}

/* ========================= RULES ========================= */

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
  'พระนางพญา',
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

const aiHeads = [
  'พิมพ์ทรง',
  'องค์ประกอบ',
  'ลวดลาย',
  'ตำหนิที่มองเห็น',
  'ผิว',
  'ลักษณะเนื้อที่มองเห็น',
  'ขอบ/ด้านข้าง',
  'จุดสังเกต',
  'รายละเอียดอื่น',
  'สิ่งที่อ่านไม่ได้',
];

List<String> scanAreasForType(String type) {
  if ([
    'เหรียญ',
    'เหรียญหล่อ',
    'พระขุนแผน',
  ].contains(type)) {
    return ['ด้านหน้า', 'ด้านหลัง', 'ด้านข้าง'];
  }
  return areas;
}

/* ========================= HELPERS ========================= */

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

Future<String?> textDialog(
  BuildContext context,
  String title, {
  String value = '',
  String hint = '',
}) async {
  final c = TextEditingController(text: value);

  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () {
            final v = c.text.trim();
            if (v.isNotEmpty) Navigator.pop(context, v);
          },
          child: const Text('บันทึก'),
        ),
      ],
    ),
  );
}

Future<bool> confirmDelete(BuildContext context, String title) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('ลบ$title'),
      content: Text('ต้องการลบ$titleนี้หรือไม่?\nข้อมูลย่อยภายในจะถูกลบด้วย'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('ลบ'),
        ),
      ],
    ),
  );
  return r == true;
}

/* ========================= BREADCRUMB ========================= */

class PathBar extends StatelessWidget {
  final List<String> items;

  const PathBar(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.folder_open, size: 18),
            const SizedBox(width: 6),
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(Icons.chevron_right, size: 18),
                ),
              Text(
                items[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      i == items.length - 1 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PageBody extends StatelessWidget {
  final List<String> path;
  final Widget child;

  const PageBody({
    super.key,
    required this.path,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PathBar(path),
        Expanded(child: child),
      ],
    );
  }
}

/* ========================= DATA ========================= */

class ScanResult {
  String area;
  Map<String, String> details;

  ScanResult({
    required this.area,
    Map<String, String>? details,
  }) : details = details ?? {};

  Map<String, dynamic> toJson() => {
        'area': area,
        'details': details,
      };

  factory ScanResult.fromJson(Map<String, dynamic> j) => ScanResult(
        area: j['area'] ?? '',
        details: Map<String, String>.from(j['details'] ?? {}),
      );
}

class ReferenceData {
  String id;
  int referenceNumber;
  String createdAt;
  String updatedAt;
  List<ScanResult> scans;

  ReferenceData({
    required this.id,
    required this.referenceNumber,
    required this.createdAt,
    String? updatedAt,
    List<ScanResult>? scans,
  })  : updatedAt = updatedAt ?? createdAt,
        scans = scans ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'referenceNumber': referenceNumber,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'scans': scans.map((e) => e.toJson()).toList(),
      };

  factory ReferenceData.fromJson(Map<String, dynamic> j) => ReferenceData(
        id: j['id'] ?? newId(),
        referenceNumber: j['referenceNumber'] ?? 1,
        createdAt: j['createdAt'] ?? '',
        updatedAt: j['updatedAt'],
        scans: (j['scans'] as List? ?? [])
            .map((e) => ScanResult.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class PrintData {
  String id;
  String name;
  String createdAt;
  String updatedAt;
  List<ReferenceData> references;

  PrintData({
    required this.id,
    required this.name,
    required this.createdAt,
    String? updatedAt,
    List<ReferenceData>? references,
  })  : updatedAt = updatedAt ?? createdAt,
        references = references ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'references': references.map((e) => e.toJson()).toList(),
      };

  factory PrintData.fromJson(Map<String, dynamic> j) => PrintData(
        id: j['id'] ?? newId(),
        name: j['name'] ?? '',
        createdAt: j['createdAt'] ?? '',
        updatedAt: j['updatedAt'],
        references: (j['references'] as List? ?? [])
            .map((e) => ReferenceData.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class TypeData {
  String id;
  String name;
  String createdAt;
  String updatedAt;
  List<PrintData> prints;

  TypeData({
    required this.id,
    required this.name,
    required this.createdAt,
    String? updatedAt,
    List<PrintData>? prints,
  })  : updatedAt = updatedAt ?? createdAt,
        prints = prints ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'prints': prints.map((e) => e.toJson()).toList(),
      };

  factory TypeData.fromJson(Map<String, dynamic> j) => TypeData(
        id: j['id'] ?? newId(),
        name: j['name'] ?? '',
        createdAt: j['createdAt'] ?? '',
        updatedAt: j['updatedAt'],
        prints: (j['prints'] as List? ?? [])
            .map((e) => PrintData.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class ModelData {
  String id;
  String name;
  String createdAt;
  String updatedAt;
  List<TypeData> types;

  ModelData({
    required this.id,
    required this.name,
    required this.createdAt,
    String? updatedAt,
    List<TypeData>? types,
  })  : updatedAt = updatedAt ?? createdAt,
        types = types ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'types': types.map((e) => e.toJson()).toList(),
      };

  factory ModelData.fromJson(Map<String, dynamic> j) => ModelData(
        id: j['id'] ?? newId(),
        name: j['name'] ?? '',
        createdAt: j['createdAt'] ?? '',
        updatedAt: j['updatedAt'],
        types: (j['types'] as List? ?? [])
            .map((e) => TypeData.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class GroupData {
  String id;
  String name;
  String temple;
  String createdAt;
  String updatedAt;
  List<ModelData> models;

  GroupData({
    required this.id,
    required this.name,
    required this.temple,
    required this.createdAt,
    String? updatedAt,
    List<ModelData>? models,
  })  : updatedAt = updatedAt ?? createdAt,
        models = models ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'temple': temple,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'models': models.map((e) => e.toJson()).toList(),
      };

  factory GroupData.fromJson(Map<String, dynamic> j) => GroupData(
        id: j['id'] ?? newId(),
        name: j['name'] ?? '',
        temple: j['temple'] ?? '',
        createdAt: j['createdAt'] ?? '',
        updatedAt: j['updatedAt'],
        models: (j['models'] as List? ?? [])
            .map((e) => ModelData.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/* ========================= AI DATA ========================= */

class AiKnowledge {
  String id, groupId, modelId, typeId, printId, referenceId, area, content;
  String createdAt, updatedAt;

  AiKnowledge({
    required this.id,
    required this.groupId,
    required this.modelId,
    required this.typeId,
    required this.printId,
    required this.referenceId,
    required this.area,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'modelId': modelId,
        'typeId': typeId,
        'printId': printId,
        'referenceId': referenceId,
        'area': area,
        'content': content,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory AiKnowledge.fromJson(Map<String, dynamic> j) => AiKnowledge(
        id: j['id'] ?? newId(),
        groupId: j['groupId'] ?? '',
        modelId: j['modelId'] ?? '',
        typeId: j['typeId'] ?? '',
        printId: j['printId'] ?? '',
        referenceId: j['referenceId'] ?? '',
        area: j['area'] ?? '',
        content: j['content'] ?? '',
        createdAt: j['createdAt'] ?? '',
        updatedAt: j['updatedAt'] ?? '',
      );
}

class AiLearningHistory {
  String id, groupId, modelId, typeId, printId, referenceId, area, content;
  String learnedAt;

  AiLearningHistory({
    required this.id,
    required this.groupId,
    required this.modelId,
    required this.typeId,
    required this.printId,
    required this.referenceId,
    required this.area,
    required this.content,
    required this.learnedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'modelId': modelId,
        'typeId': typeId,
        'printId': printId,
        'referenceId': referenceId,
        'area': area,
        'content': content,
        'learnedAt': learnedAt,
      };

  factory AiLearningHistory.fromJson(Map<String, dynamic> j) =>
      AiLearningHistory(
        id: j['id'] ?? newId(),
        groupId: j['groupId'] ?? '',
        modelId: j['modelId'] ?? '',
        typeId: j['typeId'] ?? '',
        printId: j['printId'] ?? '',
        referenceId: j['referenceId'] ?? '',
        area: j['area'] ?? '',
        content: j['content'] ?? '',
        learnedAt: j['learnedAt'] ?? '',
      );
}

class AiMemoryTest {
  String id, knowledgeId, referenceId, area, question, answer, testedAt;

  AiMemoryTest({
    required this.id,
    required this.knowledgeId,
    required this.referenceId,
    required this.area,
    required this.question,
    required this.answer,
    required this.testedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'knowledgeId': knowledgeId,
        'referenceId': referenceId,
        'area': area,
        'question': question,
        'answer': answer,
        'testedAt': testedAt,
      };

  factory AiMemoryTest.fromJson(Map<String, dynamic> j) => AiMemoryTest(
        id: j['id'] ?? newId(),
        knowledgeId: j['knowledgeId'] ?? '',
        referenceId: j['referenceId'] ?? '',
        area: j['area'] ?? '',
        question: j['question'] ?? '',
        answer: j['answer'] ?? '',
        testedAt: j['testedAt'] ?? '',
      );
}

class AiTestResult {
  String id,
      testId,
      knowledgeId,
      referenceId,
      area,
      mode,
      result,
      answer,
      referenceAnswer,
      reason,
      checkedAt;

  AiTestResult({
    required this.id,
    required this.testId,
    required this.knowledgeId,
    required this.referenceId,
    required this.area,
    required this.mode,
    required this.result,
    required this.answer,
    required this.referenceAnswer,
    required this.reason,
    required this.checkedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'testId': testId,
        'knowledgeId': knowledgeId,
        'referenceId': referenceId,
        'area': area,
        'mode': mode,
        'result': result,
        'answer': answer,
        'referenceAnswer': referenceAnswer,
        'reason': reason,
        'checkedAt': checkedAt,
      };

  factory AiTestResult.fromJson(Map<String, dynamic> j) => AiTestResult(
        id: j['id'] ?? newId(),
        testId: j['testId'] ?? '',
        knowledgeId: j['knowledgeId'] ?? '',
        referenceId: j['referenceId'] ?? '',
        area: j['area'] ?? '',
        mode: j['mode'] ?? '',
        result: j['result'] ?? '',
        answer: j['answer'] ?? '',
        referenceAnswer: j['referenceAnswer'] ?? '',
        reason: j['reason'] ?? '',
        checkedAt: j['checkedAt'] ?? '',
      );
}

/* ========================= STORAGE ========================= */

class Storage {
  static const groupsKey = 'reference_groups';
  static const knowledgeKey = 'ai_knowledge';
  static const historyKey = 'ai_learning_history';
  static const testsKey = 'ai_memory_tests';
  static const resultsKey = 'ai_test_results';

  static Future<SharedPreferences> _p() => SharedPreferences.getInstance();

  static Future<List<dynamic>> _load(String key) async {
    final p = await _p();
    final s = p.getString(key);
    if (s == null || s.isEmpty) return [];
    try {
      return jsonDecode(s) as List;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(String key, List<dynamic> list) async {
    final p = await _p();
    await p.setString(key, jsonEncode(list));
  }

  static Future<List<GroupData>> groups() async => (await _load(groupsKey))
      .map((e) => GroupData.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  static Future<void> saveGroups(List<GroupData> x) =>
      _save(groupsKey, x.map((e) => e.toJson()).toList());

  static Future<List<AiKnowledge>> knowledge() async =>
      (await _load(knowledgeKey))
          .map((e) => AiKnowledge.fromJson(Map<String, dynamic>.from(e)))
          .toList();

  static Future<void> saveKnowledge(List<AiKnowledge> x) =>
      _save(knowledgeKey, x.map((e) => e.toJson()).toList());

  static Future<List<AiLearningHistory>> history() async =>
      (await _load(historyKey))
          .map((e) => AiLearningHistory.fromJson(Map<String, dynamic>.from(e)))
          .toList();

  static Future<void> saveHistory(List<AiLearningHistory> x) =>
      _save(historyKey, x.map((e) => e.toJson()).toList());

  static Future<List<AiMemoryTest>> tests() async => (await _load(testsKey))
      .map((e) => AiMemoryTest.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  static Future<void> saveTests(List<AiMemoryTest> x) =>
      _save(testsKey, x.map((e) => e.toJson()).toList());

  static Future<List<AiTestResult>> results() async =>
      (await _load(resultsKey))
          .map((e) => AiTestResult.fromJson(Map<String, dynamic>.from(e)))
          .toList();

  static Future<void> saveResults(List<AiTestResult> x) =>
      _save(resultsKey, x.map((e) => e.toJson()).toList());

  static Future<void> deleteAiByRef(String refId) async {
    final k = await knowledge();
    await saveKnowledge(k.where((e) => e.referenceId != refId).toList());

    final h = await history();
    await saveHistory(h.where((e) => e.referenceId != refId).toList());

    final t = await tests();
    await saveTests(t.where((e) => e.referenceId != refId).toList());

    final r = await results();
    await saveResults(r.where((e) => e.referenceId != refId).toList());
  }

  static Future<void> deleteAiByGroup(String groupId) async {
    final k = await knowledge();
    await saveKnowledge(k.where((e) => e.groupId != groupId).toList());

    final h = await history();
    await saveHistory(h.where((e) => e.groupId != groupId).toList());
  }
}

/* ========================= APP ========================= */

class App extends StatelessWidget {
  final List<CameraDescription> cameras;

  const App(this.cameras, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'กล้องสแกนพระและเหรียญ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: HomePage(cameras),
    );
  }
}

/* ========================= HOME ========================= */

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
    groups = await Storage.groups();
    if (mounted) setState(() {});
  }

  Future<void> createGroup() async {
    final name = await textDialog(context, 'สร้างกลุ่ม', hint: 'ชื่อพระ');
    if (name == null) return;

    final temple = await textDialog(context, 'วัด / สำนัก', hint: 'ชื่อวัด');
    if (temple == null) return;

    final now = DateTime.now().toIso8601String();

    groups.add(
      GroupData(
        id: newId(),
        name: name,
        temple: temple,
        createdAt: now,
        models: [],
      ),
    );

    await Storage.saveGroups(groups);
    setState(() {});
  }

  Future<void> editGroup(GroupData g) async {
    final name = await textDialog(
      context,
      'แก้ไขชื่อกลุ่ม',
      value: g.name,
    );
    if (name == null) return;

    final temple = await textDialog(
      context,
      'แก้ไขวัด / สำนัก',
      value: g.temple,
    );
    if (temple == null) return;

    g.name = name;
    g.temple = temple;
    g.updatedAt = DateTime.now().toIso8601String();

    await Storage.saveGroups(groups);
    setState(() {});
  }

  Future<void> deleteGroup(GroupData g) async {
    if (!await confirmDelete(context, 'กลุ่ม ${g.name}')) return;

    await Storage.deleteAiByGroup(g.id);
    groups.removeWhere((x) => x.id == g.id);
    await Storage.saveGroups(groups);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการกลุ่มพระ'),
      ),
      body: Column(
        children: [
          const PathBar(['ฐานข้อมูลส่วนตัว', 'กลุ่มพระ']),
          Expanded(
            child: groups.isEmpty
                ? const Center(
                    child: Text('ยังไม่มีข้อมูล\nกด + เพื่อสร้างกลุ่ม'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                      final g = groups[i];

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.folder),
                          ),
                          title: Text(
                            g.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text('วัด: ${g.temple}'),
                          trailing: PopupMenuButton(
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('แก้ไข'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('ลบ'),
                              ),
                            ],
                            onSelected: (v) {
                              if (v == 'edit') editGroup(g);
                              if (v == 'delete') deleteGroup(g);
                            },
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ModelPage(
                                  cameras: widget.cameras,
                                  group: g,
                                ),
                              ),
                            );
                            load();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createGroup,
        icon: const Icon(Icons.add),
        label: const Text('สร้างกลุ่ม'),
      ),
    );
  }
}

/* ========================= MODEL ========================= */

class ModelPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final GroupData group;

  const ModelPage({
    super.key,
    required this.cameras,
    required this.group,
  });

  @override
  State<ModelPage> createState() => _ModelPageState();
}

class _ModelPageState extends State<ModelPage> {
  Future<void> addModel() async {
    final name = await textDialog(
      context,
      'สร้างรุ่น',
      hint: 'ชื่อรุ่น',
    );
    if (name == null) return;

    final now = DateTime.now().toIso8601String();

    widget.group.models.add(
      ModelData(
        id: newId(),
        name: name,
        createdAt: now,
      ),
    );

    await Storage.saveGroups(await Storage.groups());
    setState(() {});
  }

  Future<void> edit(ModelData m) async {
    final name = await textDialog(
      context,
      'แก้ไขรุ่น',
      value: m.name,
    );
    if (name == null) return;

    m.name = name;
    m.updatedAt = DateTime.now().toIso8601String();

    await Storage.saveGroups(await Storage.groups());
    setState(() {});
  }

  Future<void> remove(ModelData m) async {
    if (!await confirmDelete(context, 'รุ่น ${m.name}')) return;

    for (final t in m.types) {
      for (final p in t.prints) {
        for (final r in p.references) {
          await Storage.deleteAiByRef(r.id);
        }
      }
    }

    widget.group.models.removeWhere((x) => x.id == m.id);
    await Storage.saveGroups(await Storage.groups());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างรุ่น')),
      body: PageBody(
        path: [
          widget.group.name,
          'สร้างรุ่น',
        ],
        child: widget.group.models.isEmpty
            ? const Center(child: Text('ยังไม่มีรุ่น'))
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: widget.group.models.length,
                itemBuilder: (_, i) {
                  final m = widget.group.models[i];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.layers),
                      title: Text(m.name),
                      subtitle: Text(
                        '${m.types.length} ชนิด',
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('แก้ไข'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('ลบ'),
                          ),
                        ],
                        onSelected: (v) {
                          if (v == 'edit') edit(m);
                          if (v == 'delete') remove(m);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TypePage(
                              cameras: widget.cameras,
                              group: widget.group,
                              model: m,
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addModel,
        icon: const Icon(Icons.add),
        label: const Text('สร้างรุ่น'),
      ),
    );
  }
}

/* ========================= TYPE ========================= */

class TypePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final GroupData group;
  final ModelData model;

  const TypePage({
    super.key,
    required this.cameras,
    required this.group,
    required this.model,
  });

  @override
  State<TypePage> createState() => _TypePageState();
}

class _TypePageState extends State<TypePage> {
  Future<void> addType() async {
    final type = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('สร้างชนิด'),
        children: typeOptions
            .map(
              (x) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, x),
                child: Text(x),
              ),
            )
            .toList(),
      ),
    );

    if (type == null) return;

    if (widget.model.types.any((x) => x.name == type)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('มีชนิดนี้อยู่แล้ว')),
      );
      return;
    }

    final now = DateTime.now().toIso8601String();

    widget.model.types.add(
      TypeData(
        id: newId(),
        name: type,
        createdAt: now,
      ),
    );

    await Storage.saveGroups(await Storage.groups());
    setState(() {});
  }

  Future<void> edit(TypeData t) async {
    final name = await textDialog(
      context,
      'แก้ไขชนิด',
      value: t.name,
    );
    if (name == null) return;

    t.name = name;
    t.updatedAt = DateTime.now().toIso8601String();

    await Storage.saveGroups(await Storage.groups());
    setState(() {});
  }

  Future<void> remove(TypeData t) async {
    if (!await confirmDelete(context, 'ชนิด ${t.name}')) return;

    for (final p in t.prints) {
      for (final r in p.references) {
        await Storage.deleteAiByRef(r.id);
      }
    }

    widget.model.types.removeWhere((x) => x.id == t.id);
    await Storage.saveGroups(await Storage.groups());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างชนิด')),
      body: PageBody(
        path: [
          widget.group.name,
          widget.model.name,
          'สร้างชนิด',
        ],
        child: widget.model.types.isEmpty
            ? const Center(child: Text('ยังไม่มีชนิด'))
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: widget.model.types.length,
                itemBuilder: (_, i) {
                  final t = widget.model.types[i];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.category),
                      title: Text(t.name),
                      subtitle: Text('${t.prints.length} พิมพ์'),
                      trailing: PopupMenuButton(
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('แก้ไข'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('ลบ'),
                          ),
                        ],
                        onSelected: (v) {
                          if (v == 'edit') edit(t);
                          if (v == 'delete') remove(t);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrintPage(
                              cameras: widget.cameras,
                              group: widget.group,
                              model: widget.model,
                              type: t,
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addType,
        icon: const Icon(Icons.add),
        label: const Text('สร้างชนิด'),
      ),
    );
  }
}

/* ========================= PRINT ========================= */

class PrintPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final GroupData group;
  final ModelData model;
  final TypeData type;

  const PrintPage({
    super.key,
    required this.cameras,
    required this.group,
    required this.model,
    required this.type,
  });

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  Future<void> addPrint() async {
    final name = await textDialog(
      context,
      'สร้างพิมพ์',
      hint: 'ชื่อพิมพ์',
    );
    if (name == null) return;

    if (widget.type.prints.any((x) => x.name == name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('มีพิมพ์นี้อยู่แล้ว')),
      );
      return;
    }

    final now = DateTime.now().toIso8601String();

    widget.type.prints.add(
      PrintData(
        id: newId(),
        name: name,
        createdAt: now,
      ),
    );

    await Storage.saveGroups(await Storage.groups());
    setState(() {});
  }

  Future<void> edit(PrintData p) async {
    final name = await textDialog(
      context,
      'แก้ไขพิมพ์',
      value: p.name,
    );
    if (name == null) return;

    p.name = name;
    p.updatedAt = DateTime.now().toIso8601String();

    await Storage.saveGroups(await Storage.groups());
    setState(() {});
  }

  Future<void> remove(PrintData p) async {
    if (!await confirmDelete(context, 'พิมพ์ ${p.name}')) return;

    for (final r in p.references) {
      await Storage.deleteAiByRef(r.id);
    }

    widget.type.prints.removeWhere((x) => x.id == p.id);
    await Storage.saveGroups(await Storage.groups());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างพิมพ์')),
      body: PageBody(
        path: [
          widget.group.name,
          widget.model.name,
          widget.type.name,
          'สร้างพิมพ์',
        ],
        child: widget.type.prints.isEmpty
            ? const Center(child: Text('ยังไม่มีพิมพ์'))
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: widget.type.prints.length,
                itemBuilder: (_, i) {
                  final p = widget.type.prints[i];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.view_module),
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.references.length} องค์ตัวอย่าง',
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('แก้ไข'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('ลบ'),
                          ),
                        ],
                        onSelected: (v) {
                          if (v == 'edit') edit(p);
                          if (v == 'delete') remove(p);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReferencePage(
                              cameras: widget.cameras,
                              group: widget.group,
                              model: widget.model,
                              type: widget.type,
                              printData: p,
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addPrint,
        icon: const Icon(Icons.add),
        label: const Text('สร้างพิมพ์'),
      ),
    );
  }
}

/* ========================= REFERENCES ========================= */

class ReferencePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData printData;

  const ReferencePage({
    super.key,
    required this.cameras,
    required this.model,
    required this.type,
    required this.printData,
    required this.group,
  });

  @override
  State<ReferencePage> createState() => _ReferencePageState();
}

class _ReferencePageState extends State<ReferencePage> {
  Future<void> addReference() async {
    final maxNo = widget.printData.references.isEmpty
        ? 0
        : widget.printData.references
            .map((e) => e.referenceNumber)
            .reduce((a, b) => a > b ? a : b);

    final now = DateTime.now().toIso8601String();

    widget.printData.references.add(
      ReferenceData(
        id: newId(),
        referenceNumber: maxNo + 1,
        createdAt: now,
      ),
    );

    await Storage.saveGroups(await Storage.groups());
    setState(() {});
  }

  Future<void> deleteReference(ReferenceData r) async {
    if (!await confirmDelete(
      context,
      'องค์ตัวอย่าง #${r.referenceNumber}',
    )) {
      return;
    }

    await Storage.deleteAiByRef(r.id);

    widget.printData.references.removeWhere((x) => x.id == r.id);
    await Storage.saveGroups(await Storage.groups());
    setState(() {});
  }

  Future<void> scan(ReferenceData r, String area) async {
    final scan = r.scans.cast<ScanResult?>().firstWhere(
          (x) => x!.area == area,
          orElse: () => null,
        );

    final path = [
      widget.group.name,
      widget.model.name,
      widget.type.name,
      widget.printData.name,
      'องค์ตัวอย่าง #${r.referenceNumber}',
      area,
    ];

    final result = await Navigator.push<ScanResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          area: area,
          path: path,
          oldResult: scan,
        ),
      ),
    );

    if (result == null) return;

    r.scans.removeWhere((x) => x.area == area);
    r.scans.add(result);
    r.updatedAt = DateTime.now().toIso8601String();

    await Storage.saveGroups(await Storage.groups());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scanAreas = scanAreasForType(widget.type.name);

    return Scaffold(
      appBar: AppBar(
        title: const Text('องค์ตัวอย่าง'),
      ),
      body: PageBody(
        path: [
          widget.group.name,
          widget.model.name,
          widget.type.name,
          widget.printData.name,
          'องค์ตัวอย่าง',
        ],
        child: widget.printData.references.isEmpty
            ? const Center(
                child: Text('ยังไม่มีองค์ตัวอย่าง\nกด + เพื่อสร้าง'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: widget.printData.references.length,
                itemBuilder: (_, i) {
                  final r = widget.printData.references[i];

                  return Card(
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        child: Text('${r.referenceNumber}'),
                      ),
                      title: Text(
                        'องค์ตัวอย่าง #${r.referenceNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'สแกนแล้ว ${r.scans.length}/${scanAreas.length} ด้าน',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteReference(r),
                      ),
                      children: scanAreas.map((area) {
                        final result = r.scans.cast<ScanResult?>().firstWhere(
                              (x) => x!.area == area,
                              orElse: () => null,
                            );

                        return ListTile(
                          leading: Icon(
                            result == null
                                ? Icons.camera_alt_outlined
                                : Icons.check_circle,
                          ),
                          title: Text(area),
                          subtitle: Text(
                            result == null
                                ? 'ยังไม่ได้สแกน'
                                : 'มีข้อมูลแล้ว กดเพื่อแก้ไข',
                          ),
                          onTap: () => scan(r, area),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addReference,
        icon: const Icon(Icons.add),
        label: const Text('สร้างองค์ตัวอย่าง'),
      ),
    );
  }
}

/* ========================= SCAN ========================= */

class ScanPage extends StatelessWidget {
  final List<CameraDescription> cameras;
  final String area;
  final List<String> path;
  final ScanResult? oldResult;

  const ScanPage({
    super.key,
    required this.cameras,
    required this.area,
    required this.path,
    this.oldResult,
  });

  Future<void> gallery(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (file == null) return;

    try {
      final result = await Navigator.push<ScanResult>(
        context,
        MaterialPageRoute(
          builder: (_) => AiVisionPage(
            imageFile: file,
            area: area,
            path: path,
            oldResult: oldResult,
          ),
        ),
      );

      if (result != null && context.mounted) {
        Navigator.pop(context, result);
      }
    } finally {
      try {
        final f = File(file.path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สแกน$area'),
      ),
      body: PageBody(
        path: path,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.document_scanner,
                size: 90,
              ),
              const SizedBox(height: 25),
              const Text(
                'เลือกรูปแบบการสแกน',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('เปิดกล้อง'),
                  onPressed: cameras.isEmpty
                      ? null
                      : () async {
                          final result =
                              await Navigator.push<ScanResult>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CameraScanPage(
                                cameras: cameras,
                                area: area,
                                path: path,
                                oldResult: oldResult,
                              ),
                            ),
                          );

                          if (result != null && context.mounted) {
                            Navigator.pop(context, result);
                          }
                        },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('เลือกรูปจากเครื่อง'),
                  onPressed: () => gallery(context),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'รูปภาพใช้สำหรับการวิเคราะห์ชั่วคราว\n'
                'ระบบจะไม่บันทึกรูปลงฐานข้อมูล',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ========================= CAMERA ========================= */

class CameraScanPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String area;
  final List<String> path;
  final ScanResult? oldResult;

  const CameraScanPage({
    super.key,
    required this.cameras,
    required this.area,
    required this.path,
    this.oldResult,
  });

  @override
  State<CameraScanPage> createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  CameraController? controller;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      controller = CameraController(
        widget.cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller!.initialize();

      if (mounted) setState(() => ready = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> takePicture() async {
    if (!ready || controller == null) return;

    try {
      final file = await controller!.takePicture();

      final result = await Navigator.push<ScanResult>(
        context,
        MaterialPageRoute(
          builder: (_) => AiVisionPage(
            imageFile: file,
            area: widget.area,
            path: widget.path,
            oldResult: widget.oldResult,
          ),
        ),
      );

      try {
        final f = File(file.path);
        if (await f.exists()) await f.delete();
      } catch (_) {}

      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ถ่ายภาพ${widget.area}'),
      ),
      body: Column(
        children: [
          PathBar(widget.path),
          Expanded(
            child: !ready
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : CameraPreview(controller!),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: takePicture,
        child: const Icon(Icons.camera),
      ),
    );
  }
}

/* ========================= AI VISION ========================= */

class AiVisionPage extends StatefulWidget {
  final XFile imageFile;
  final String area;
  final List<String> path;
  final ScanResult? oldResult;

  const AiVisionPage({
    super.key,
    required this.imageFile,
    required this.area,
    required this.path,
    this.oldResult,
  });

  @override
  State<AiVisionPage> createState() => _AiVisionPageState();
}

class _AiVisionPageState extends State<AiVisionPage> {
  final Map<String, TextEditingController> controllers = {};
  bool saving = false;

  @override
  void initState() {
    super.initState();

    for (final h in aiHeads) {
      controllers[h] = TextEditingController(
        text: widget.oldResult?.details[h] ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void save() {
    if (saving) return;

    saving = true;

    final data = <String, String>{};

    for (final h in aiHeads) {
      final value = controllers[h]!.text.trim();
      if (value.isNotEmpty) {
        data[h] = value;
      }
    }

    Navigator.pop(
      context,
      ScanResult(
        area: widget.area,
        details: data,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียด${widget.area}'),
      ),
      body: Column(
        children: [
          PathBar(widget.path),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.imageFile.path),
                    height: 240,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ภาพนี้ใช้ชั่วคราวเท่านั้น\n'
                  'เมื่อออกจากหน้านี้ระบบจะไม่เก็บรูปไว้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 15),
                ...aiHeads.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: controllers[h],
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: h,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: save,
                    icon: const Icon(Icons.save),
                    label: const Text('บันทึกข้อมูลการสแกน'),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
