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

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

/* =========================================================
DATA
========================================================= */

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

  factory ScanResult.fromMap(Map<String, dynamic> m) {
    return ScanResult(
      area: m['area'] ?? '',
      details: m['details'] ?? '',
    );
  }
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

  factory ReferenceData.fromMap(Map<String, dynamic> m) {
    return ReferenceData(
      id: m['id'] ?? newId(),
      referenceNumber: m['referenceNumber'] ?? 1,
      createdAt:
          DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
      scans: (m['scans'] as List? ?? [])
          .map((e) => ScanResult.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  ReferenceData copyWith({
    int? referenceNumber,
    List<ScanResult>? scans,
  }) {
    return ReferenceData(
      id: id,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      scans: scans ?? this.scans,
    );
  }
}

/* =========================================================
AI DATA
========================================================= */

class AiKnowledge {
  String id;
  String groupId;
  String modelId;
  String typeId;
  String printId;
  String referenceId;
  String area;
  String content;
  DateTime createdAt;
  DateTime updatedAt;

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
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'groupId': groupId,
        'modelId': modelId,
        'typeId': typeId,
        'printId': printId,
        'referenceId': referenceId,
        'area': area,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AiKnowledge.fromMap(Map<String, dynamic> m) {
    return AiKnowledge(
      id: m['id'] ?? newId(),
      groupId: m['groupId'] ?? '',
      modelId: m['modelId'] ?? '',
      typeId: m['typeId'] ?? '',
      printId: m['printId'] ?? '',
      referenceId: m['referenceId'] ?? '',
      area: m['area'] ?? '',
      content: m['content'] ?? '',
      createdAt:
          DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class AiLearningHistory {
  String id;
  String groupId;
  String modelId;
  String typeId;
  String printId;
  String referenceId;
  String area;
  String content;
  DateTime learnedAt;

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

  Map<String, dynamic> toMap() => {
        'id': id,
        'groupId': groupId,
        'modelId': modelId,
        'typeId': typeId,
        'printId': printId,
        'referenceId': referenceId,
        'area': area,
        'content': content,
        'learnedAt': learnedAt.toIso8601String(),
      };

  factory AiLearningHistory.fromMap(Map<String, dynamic> m) {
    return AiLearningHistory(
      id: m['id'] ?? newId(),
      groupId: m['groupId'] ?? '',
      modelId: m['modelId'] ?? '',
      typeId: m['typeId'] ?? '',
      printId: m['printId'] ?? '',
      referenceId: m['referenceId'] ?? '',
      area: m['area'] ?? '',
      content: m['content'] ?? '',
      learnedAt:
          DateTime.tryParse(m['learnedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class AiMemoryTest {
  String id;
  String knowledgeId;
  String referenceId;
  String area;
  String question;
  String answer;
  DateTime testedAt;

  AiMemoryTest({
    required this.id,
    required this.knowledgeId,
    required this.referenceId,
    required this.area,
    required this.question,
    required this.answer,
    required this.testedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'knowledgeId': knowledgeId,
        'referenceId': referenceId,
        'area': area,
        'question': question,
        'answer': answer,
        'testedAt': testedAt.toIso8601String(),
      };

  factory AiMemoryTest.fromMap(Map<String, dynamic> m) {
    return AiMemoryTest(
      id: m['id'] ?? newId(),
      knowledgeId: m['knowledgeId'] ?? '',
      referenceId: m['referenceId'] ?? '',
      area: m['area'] ?? '',
      question: m['question'] ?? '',
      answer: m['answer'] ?? '',
      testedAt:
          DateTime.tryParse(m['testedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class AiTestResult {
  String id;
  String testId;
  String knowledgeId;
  String referenceId;
  String area;
  String mode;
  String result;
  String answer;
  String referenceAnswer;
  String reason;
  DateTime checkedAt;

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

  Map<String, dynamic> toMap() => {
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
        'checkedAt': checkedAt.toIso8601String(),
      };

  factory AiTestResult.fromMap(Map<String, dynamic> m) {
    return AiTestResult(
      id: m['id'] ?? newId(),
      testId: m['testId'] ?? '',
      knowledgeId: m['knowledgeId'] ?? '',
      referenceId: m['referenceId'] ?? '',
      area: m['area'] ?? '',
      mode: m['mode'] ?? '',
      result: m['result'] ?? '',
      answer: m['answer'] ?? '',
      referenceAnswer: m['referenceAnswer'] ?? '',
      reason: m['reason'] ?? '',
      checkedAt:
          DateTime.tryParse(m['checkedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/* =========================================================
HIERARCHY
========================================================= */

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

  factory PrintData.fromMap(Map<String, dynamic> m) {
    return PrintData(
      id: m['id'] ?? newId(),
      name: m['name'] ?? 'พิมพ์เดียว',
      createdAt:
          DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
      references: (m['references'] as List? ?? [])
          .map((e) => ReferenceData.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
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

  factory TypeData.fromMap(Map<String, dynamic> m) {
    return TypeData(
      id: m['id'] ?? newId(),
      name: m['name'] ?? '',
      createdAt:
          DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
      prints: (m['prints'] as List? ?? [])
          .map((e) => PrintData.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
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

  factory ModelData.fromMap(Map<String, dynamic> m) {
    return ModelData(
      id: m['id'] ?? newId(),
      name: m['name'] ?? '',
      createdAt:
          DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
      types: (m['types'] as List? ?? [])
          .map((e) => TypeData.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
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

  factory GroupData.fromMap(Map<String, dynamic> m) {
    return GroupData(
      id: m['id'] ?? newId(),
      name: m['name'] ?? '',
      temple: m['temple'] ?? '',
      createdAt:
          DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
      models: (m['models'] as List? ?? [])
          .map((e) => ModelData.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/* =========================================================
STORAGE
========================================================= */

class Storage {
  static const key = 'reference_groups';
  static const aiKey = 'ai_knowledge';
  static const historyKey = 'ai_learning_history';
  static const testKey = 'ai_memory_tests';
  static const resultKey = 'ai_test_results';

  static Future<List<GroupData>> load() async {
    final p = await SharedPreferences.getInstance();
    final r = p.getString(key);

    if (r == null || r.isEmpty) return [];

    try {
      return (jsonDecode(r) as List)
          .map((e) => GroupData.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<GroupData> data) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      key,
      jsonEncode(data.map((e) => e.toMap()).toList()),
    );
  }

  static Future<List<AiKnowledge>> loadAi() async {
    final p = await SharedPreferences.getInstance();
    final r = p.getString(aiKey);

    if (r == null || r.isEmpty) return [];

    try {
      return (jsonDecode(r) as List)
          .map((e) => AiKnowledge.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAi(List<AiKnowledge> data) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      aiKey,
      jsonEncode(data.map((e) => e.toMap()).toList()),
    );
  }

  static Future<void> addAi({
    required GroupData group,
    required ModelData model,
    required TypeData type,
    required PrintData print,
    required ReferenceData reference,
    required ScanResult scan,
  }) async {
    final content = scan.details.trim();
    if (content.isEmpty) return;

    final list = await loadAi();

    final index = list.indexWhere(
      (e) =>
          e.referenceId == reference.id &&
          e.area == scan.area,
    );

    final now = DateTime.now();

    final item = AiKnowledge(
      id: index >= 0 ? list[index].id : newId(),
      groupId: group.id,
      modelId: model.id,
      typeId: type.id,
      printId: print.id,
      referenceId: reference.id,
      area: scan.area,
      content: content,
      createdAt: index >= 0 ? list[index].createdAt : now,
      updatedAt: now,
    );

    if (index >= 0) {
      list[index] = item;
    } else {
      list.add(item);
    }

    await saveAi(list);
  }

  static Future<void> deleteAi({
    required String referenceId,
    required String area,
  }) async {
    final list = await loadAi();

    list.removeWhere(
      (e) => e.referenceId == referenceId && e.area == area,
    );

    await saveAi(list);
  }

  static Future<List<AiLearningHistory>> loadHistory() async {
    final p = await SharedPreferences.getInstance();
    final r = p.getString(historyKey);

    if (r == null || r.isEmpty) return [];

    try {
      return (jsonDecode(r) as List)
          .map(
            (e) => AiLearningHistory.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveHistory(
    List<AiLearningHistory> data,
  ) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      historyKey,
      jsonEncode(data.map((e) => e.toMap()).toList()),
    );
  }

  static Future<void> addHistory(AiLearningHistory item) async {
    final list = await loadHistory();
    list.add(item);
    await saveHistory(list);
  }

  static Future<List<AiMemoryTest>> loadTests() async {
    final p = await SharedPreferences.getInstance();
    final r = p.getString(testKey);

    if (r == null || r.isEmpty) return [];

    try {
      return (jsonDecode(r) as List)
          .map(
            (e) => AiMemoryTest.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTests(
    List<AiMemoryTest> data,
  ) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      testKey,
      jsonEncode(data.map((e) => e.toMap()).toList()),
    );
  }

  static Future<void> addTest(AiMemoryTest item) async {
    final list = await loadTests();
    list.add(item);
    await saveTests(list);
  }

  static Future<List<AiTestResult>> loadResults() async {
    final p = await SharedPreferences.getInstance();
    final r = p.getString(resultKey);

    if (r == null || r.isEmpty) return [];

    try {
      return (jsonDecode(r) as List)
          .map(
            (e) => AiTestResult.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveResults(
    List<AiTestResult> data,
  ) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      resultKey,
      jsonEncode(data.map((e) => e.toMap()).toList()),
    );
  }

  static Future<void> addResult(AiTestResult item) async {
    final list = await loadResults();
    list.add(item);
    await saveResults(list);
  }
}

/* =========================================================
APP
========================================================= */

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
      home: HomePage(cameras: cameras),
    );
  }
}

/* =========================================================
HOME
========================================================= */

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage({
    required this.cameras,
    super.key,
  });

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
    final data = await Storage.load();

    if (!mounted) return;

    setState(() => groups = data);
  }

  Future<void> createGroup() async {
    final name = TextEditingController();
    final temple = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('สร้างข้อมูลชุดพระ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'ชื่อพระ',
                ),
              ),
              TextField(
                controller: temple,
                decoration: const InputDecoration(
                  labelText: 'วัด/พระเกจิ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('สร้าง'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    if (name.text.trim().isEmpty) return;

    final now = DateTime.now();

    final group = GroupData(
      id: newId(),
      name: name.text.trim(),
      temple: temple.text.trim(),
      createdAt: now,
    );

    groups.add(group);

    await Storage.save(groups);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('กล้องสแกนพระ'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createGroup,
        icon: const Icon(Icons.add),
        label: const Text('สร้างข้อมูล'),
      ),
      body: groups.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีข้อมูล\nกด "สร้างข้อมูล" เพื่อเริ่มต้น',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: groups.length,
              itemBuilder: (_, i) {
                final g = groups[i];

                return Card(
                  child: ListTile(
                    title: Text(g.name),
                    subtitle: Text(
                      g.temple.isEmpty
                          ? 'ยังไม่ได้ระบุวัด'
                          : g.temple,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ModelPage(
                            cameras: widget.cameras,
                            groups: groups,
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
    );
  }
}

/* =========================================================
MODEL PAGE
========================================================= */

class ModelPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final List<GroupData> groups;
  final GroupData group;

  const ModelPage({
    required this.cameras,
    required this.groups,
    required this.group,
    super.key,
  });

  @override
  State<ModelPage> createState() => _ModelPageState();
}

class _ModelPageState extends State<ModelPage> {
  Future<void> addModel() async {
    final c = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เพิ่มรุ่น'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            labelText: 'ชื่อรุ่น',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );

    if (ok != true || c.text.trim().isEmpty) return;

    widget.group.models.add(
      ModelData(
        id: newId(),
        name: c.text.trim(),
        createdAt: DateTime.now(),
      ),
    );

    await Storage.save(widget.groups);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addModel,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรุ่น'),
      ),
      body: widget.group.models.isEmpty
          ? const Center(
              child: Text('ยังไม่มีรุ่น'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.group.models.length,
              itemBuilder: (_, i) {
                final model = widget.group.models[i];

                return Card(
                  child: ListTile(
                    title: Text(model.name),
                    trailing:
                        const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TypePage(
                            cameras: widget.cameras,
                            groups: widget.groups,
                            group: widget.group,
                            model: model,
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

/* =========================================================
TYPE PAGE
========================================================= */

class TypePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final List<GroupData> groups;
  final GroupData group;
  final ModelData model;

  const TypePage({
    required this.cameras,
    required this.groups,
    required this.group,
    required this.model,
    super.key,
  });

  @override
  State<TypePage> createState() => _TypePageState();
}

class _TypePageState extends State<TypePage> {
  Future<void> addType() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: const Text('เลือกประเภทพระ'),
          children: typeOptions
              .map(
                (e) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, e),
                  child: Text(e),
                ),
              )
              .toList(),
        );
      },
    );

    if (selected == null) return;

    widget.model.types.add(
      TypeData(
        id: newId(),
        name: selected,
        createdAt: DateTime.now(),
      ),
    );

    await Storage.save(widget.groups);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.model.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addType,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มประเภท'),
      ),
      body: widget.model.types.isEmpty
          ? const Center(
              child: Text('ยังไม่มีประเภท'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.model.types.length,
              itemBuilder: (_, i) {
                final type = widget.model.types[i];

                return Card(
                  child: ListTile(
                    title: Text(type.name),
                    trailing:
                        const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrintPage(
                            cameras: widget.cameras,
                            groups: widget.groups,
                            group: widget.group,
                            model: widget.model,
                            type: type,
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

/* =========================================================
PRINT PAGE
========================================================= */

class PrintPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final List<GroupData> groups;
  final GroupData group;
  final ModelData model;
  final TypeData type;

  const PrintPage({
    required this.cameras,
    required this.groups,
    required this.group,
    required this.model,
    required this.type,
    super.key,
  });

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  Future<void> addPrint() async {
    final c = TextEditingController(
      text: 'พิมพ์ที่ ${widget.type.prints.length + 1}',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เพิ่มพิมพ์'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            labelText: 'ชื่อพิมพ์',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );

    if (ok != true || c.text.trim().isEmpty) return;

    widget.type.prints.add(
      PrintData(
        id: newId(),
        name: c.text.trim(),
        createdAt: DateTime.now(),
      ),
    );

    await Storage.save(widget.groups);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addPrint,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มพิมพ์'),
      ),
      body: widget.type.prints.isEmpty
          ? const Center(
              child: Text('ยังไม่มีพิมพ์'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.type.prints.length,
              itemBuilder: (_, i) {
                final print = widget.type.prints[i];

                return Card(
                  child: ListTile(
                    title: Text(print.name),
                    trailing:
                        const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReferencePage(
                            cameras: widget.cameras,
                            groups: widget.groups,
                            group: widget.group,
                            model: widget.model,
                            type: widget.type,
                            print: print,
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

/* =========================================================
REFERENCE PAGE
========================================================= */

class ReferencePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final List<GroupData> groups;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;

  const ReferencePage({
    required this.cameras,
    required this.groups,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    super.key,
  });

  @override
  State<ReferencePage> createState() => _ReferencePageState();
}

class _ReferencePageState extends State<ReferencePage> {
  Future<void> addReference() async {
    final number = widget.print.references.length + 1;

    widget.print.references.add(
      ReferenceData(
        id: newId(),
        referenceNumber: number,
        createdAt: DateTime.now(),
      ),
    );

    await Storage.save(widget.groups);

    if (mounted) setState(() {});
  }

  Future<void> scan(
    ReferenceData reference,
    String area,
  ) async {
    final result = await Navigator.push<ScanResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          area: area,
        ),
      ),
    );

    if (result == null) return;

    final oldIndex =
        reference.scans.indexWhere((e) => e.area == area);

    if (oldIndex >= 0) {
      reference.scans[oldIndex] = result;
    } else {
      reference.scans.add(result);
    }

    await Storage.deleteAi(
      referenceId: reference.id,
      area: area,
    );

    await Storage.addAi(
      group: widget.group,
      model: widget.model,
      type: widget.type,
      print: widget.print,
      reference: reference,
      scan: result,
    );

    await Storage.save(widget.groups);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.print.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addReference,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มองค์ตัวอย่าง'),
      ),
      body: widget.print.references.isEmpty
          ? const Center(
              child: Text('ยังไม่มีองค์ตัวอย่าง'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.print.references.length,
              itemBuilder: (_, i) {
                final ref = widget.print.references[i];

                return Card(
                  child: ExpansionTile(
                    title: Text(
                      'องค์ตัวอย่าง ${ref.referenceNumber}',
                    ),
                    children: [
                      ...areas.map(
                        (area) {
                          final scan = ref.scans
                              .where((e) => e.area == area)
                              .cast<ScanResult?>()
                              .firstOrNull;

                          return ListTile(
                            title: Text(area),
                            subtitle: Text(
                              scan == null ||
                                      scan.details.trim().isEmpty
                                  ? 'ยังไม่มีข้อมูล'
                                  : 'มีข้อมูลแล้ว',
                            ),
                            trailing: const Icon(
                              Icons.camera_alt,
                            ),
                            onTap: () =>
                                scan == null ||
                                        scan.details.trim().isEmpty
                                    ? scanArea(ref, area)
                                    : editArea(ref, area),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> scanArea(
    ReferenceData ref,
    String area,
  ) async {
    await scan(ref, area);
  }

  Future<void> editArea(
    ReferenceData ref,
    String area,
  ) async {
    final old = ref.scans.firstWhere(
      (e) => e.area == area,
    );

    final c = TextEditingController(
      text: old.details,
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('แก้ไข $area'),
        content: TextField(
          controller: c,
          maxLines: 12,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final result = ScanResult(
      area: area,
      details: c.text.trim(),
    );

    final index =
        ref.scans.indexWhere((e) => e.area == area);

    if (index >= 0) {
      ref.scans[index] = result;
    }

    await Storage.deleteAi(
      referenceId: ref.id,
      area: area,
    );

    await Storage.addAi(
      group: widget.group,
      model: widget.model,
      type: widget.type,
      print: widget.print,
      reference: ref,
      scan: result,
    );

    await Storage.save(widget.groups);

    if (mounted) setState(() {});
  }
}

/* =========================================================
SCAN PAGE
========================================================= */

class ScanPage extends StatelessWidget {
  final List<CameraDescription> cameras;
  final String area;

  const ScanPage({
    required this.cameras,
    required this.area,
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

    if (file == null || !context.mounted) return;

    try {
      final result = await Navigator.push<ScanResult>(
        context,
        MaterialPageRoute(
          builder: (_) => AiVisionPage(
            area: area,
            imageFile: File(file.path),
          ),
        ),
      );

      if (result != null && context.mounted) {
        Navigator.pop(context, result);
      }
    } finally {
      try {
        await File(file.path).delete();
      } catch (_) {}
    }
  }

  Future<void> scanGallery(BuildContext context) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (file == null || !context.mounted) return;

    final result = await Navigator.push<ScanResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AiVisionPage(
          area: area,
          imageFile: File(file.path),
        ),
      ),
    );

    if (result != null && context.mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สแกน $area'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.document_scanner,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                area,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => scanCamera(context),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('ถ่ายภาพ'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => scanGallery(context),
                  icon: const Icon(Icons.photo),
                  label: const Text('เลือกภาพ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================================================
CAMERA
========================================================= */

class CameraScanPage extends StatefulWidget {
  final CameraDescription camera;

  const CameraScanPage(
    this.camera, {
    super.key,
  });

  @override
  State<CameraScanPage> createState() =>
      _CameraScanPageState();
}

class _CameraScanPageState
    extends State<CameraScanPage> {
  CameraController? controller;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    final c = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    controller = c;

    try {
      await c.initialize();

      if (mounted) {
        setState(() => ready = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> takePicture() async {
    final c = controller;

    if (c == null || !c.value.isInitialized) return;

    try {
      final file = await c.takePicture();

      if (mounted) {
        Navigator.pop(context, file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ถ่ายภาพไม่สำเร็จ: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ถ่ายภาพ'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: !ready || controller == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller!),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: FloatingActionButton.large(
                      onPressed: takePicture,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/* =========================================================
AI VISION PAGE
========================================================= */

class AiVisionPage extends StatefulWidget {
  final String area;
  final File imageFile;

  const AiVisionPage({
    required this.area,
    required this.imageFile,
    super.key,
  });

  @override
  State<AiVisionPage> createState() =>
      _AiVisionPageState();
}

class _AiVisionPageState extends State<AiVisionPage> {
  final Map<String, TextEditingController> controllers = {};
  final Map<String, bool> selected = {};

  @override
  void initState() {
    super.initState();

    for (final head in aiHeads) {
      controllers[head] = TextEditingController();
      selected[head] = true;
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }

    super.dispose();
  }

  void selectAll(bool value) {
    setState(() {
      for (final head in aiHeads) {
        selected[head] = value;
      }
    });
  }

  void saveSelected() {
    final out = StringBuffer();

    for (final head in aiHeads) {
      final text =
          controllers[head]!.text.trim();

      if (selected[head] == true && text.isNotEmpty) {
        out.writeln('$head:');
        out.writeln(text);
        out.writeln();
      }
    }

    final result = out.toString().trim();

    if (result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยังไม่ได้เลือกข้อมูล'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      ScanResult(
        area: widget.area,
        details: result,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI วิเคราะห์ ${widget.area}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              widget.imageFile,
              height: 240,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'ภาพถูกใช้ชั่วคราวเท่านั้น\n'
                'ยังไม่มีการบันทึกรูปลงฐานข้อมูล\n\n'
                'AI ควรวิเคราะห์เฉพาะสิ่งที่มองเห็นจากภาพ '
                'และไม่ควรเดารุ่น ปี หรือความแท้จากสิ่งที่มองไม่เห็น',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => selectAll(true),
                  child: const Text('เลือกทั้งหมด'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => selectAll(false),
                  child: const Text('ไม่เลือกทั้งหมด'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...aiHeads.map(
            (head) => Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selected[head],
                      title: Text(
                        head,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onChanged: (v) {
                        setState(() {
                          selected[head] = v ?? false;
                        });
                      },
                    ),
                    TextField(
                      controller: controllers[head],
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'ข้อมูลจาก AI ในหัวข้อ $head',
                        border:
                            const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: saveSelected,
            icon: const Icon(Icons.save),
            label: const Text(
              'บันทึกข้อมูลที่เลือก',
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

/* =========================================================
EXTENSION
========================================================= */

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;

    if (iterator.moveNext()) {
      return iterator.current;
    }

    return null;
  }
}
