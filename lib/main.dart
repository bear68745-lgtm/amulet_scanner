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

/* ===================== SCAN RULES ===================== */

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

const allAreas = [
  'ด้านหน้า',
  'ด้านหลัง',
  'ด้านข้าง',
  'ก้นพระ',
];

List<String> scanAreasForType(String type) {
  if (type == 'เหรียญ' ||
      type == 'เหรียญหล่อ' ||
      type == 'พระขุนแผน') {
    return [
      'ด้านหน้า',
      'ด้านหลัง',
      'ด้านข้าง',
    ];
  }

  return allAreas;
}

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

/* ===================== HELPERS ===================== */

String newId() {
  return '${DateTime.now().microsecondsSinceEpoch}_${UniqueKey().hashCode}';
}

Future<void> textDialog(
  BuildContext context,
  String title,
  String value,
  void Function(String) onSave,
) async {
  final c = TextEditingController(text: value);

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
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

            if (v.isNotEmpty) {
              onSave(v);
            }

            Navigator.pop(context);
          },
          child: const Text('บันทึก'),
        ),
      ],
    ),
  );

  c.dispose();
}

Future<bool> confirmDelete(
  BuildContext context,
  String title,
  String message,
) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('ลบ'),
        ),
      ],
    ),
  );

  return r == true;
}

/* ===================== SCAN DATA ===================== */

class ScanResult {
  String area;
  String details;

  ScanResult({
    required this.area,
    required this.details,
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

/* ===================== MAIN DATA ===================== */

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
    required this.updatedAt,
    required this.scans,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'referenceNumber': referenceNumber,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'scans': scans.map((e) => e.toMap()).toList(),
      };

  factory ReferenceData.fromMap(Map<String, dynamic> m) {
    return ReferenceData(
      id: m['id'] ?? newId(),
      referenceNumber: m['referenceNumber'] ?? 1,
      createdAt:
          m['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt:
          m['updatedAt'] ?? DateTime.now().toIso8601String(),
      scans: (m['scans'] as List? ?? [])
          .map(
            (e) => ScanResult.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
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
    required this.updatedAt,
    required this.references,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'references':
            references.map((e) => e.toMap()).toList(),
      };

  factory PrintData.fromMap(Map<String, dynamic> m) {
    return PrintData(
      id: m['id'] ?? newId(),
      name: m['name'] ?? '',
      createdAt:
          m['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt:
          m['updatedAt'] ?? DateTime.now().toIso8601String(),
      references: (m['references'] as List? ?? [])
          .map(
            (e) => ReferenceData.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
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
    required this.updatedAt,
    required this.prints,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'prints':
            prints.map((e) => e.toMap()).toList(),
      };

  factory TypeData.fromMap(Map<String, dynamic> m) {
    return TypeData(
      id: m['id'] ?? newId(),
      name: m['name'] ?? '',
      createdAt:
          m['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt:
          m['updatedAt'] ?? DateTime.now().toIso8601String(),
      prints: (m['prints'] as List? ?? [])
          .map(
            (e) => PrintData.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
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
    required this.updatedAt,
    required this.types,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'types':
            types.map((e) => e.toMap()).toList(),
      };

  factory ModelData.fromMap(Map<String, dynamic> m) {
    return ModelData(
      id: m['id'] ?? newId(),
      name: m['name'] ?? '',
      createdAt:
          m['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt:
          m['updatedAt'] ?? DateTime.now().toIso8601String(),
      types: (m['types'] as List? ?? [])
          .map(
            (e) => TypeData.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
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
    required this.updatedAt,
    required this.models,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'temple': temple,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'models':
            models.map((e) => e.toMap()).toList(),
      };

  factory GroupData.fromMap(Map<String, dynamic> m) {
    return GroupData(
      id: m['id'] ?? newId(),
      name: m['name'] ?? '',
      temple: m['temple'] ?? '',
      createdAt:
          m['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt:
          m['updatedAt'] ?? DateTime.now().toIso8601String(),
      models: (m['models'] as List? ?? [])
          .map(
            (e) => ModelData.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

/* ===================== AI MEMORY ===================== */

class AiKnowledge {
  String id;
  String groupId;
  String modelId;
  String typeId;
  String printId;
  String referenceId;
  String area;
  String content;
  String createdAt;
  String updatedAt;

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

  Map<String, dynamic> toMap() => {
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
      createdAt: m['createdAt'] ?? '',
      updatedAt: m['updatedAt'] ?? '',
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

  Map<String, dynamic> toMap() => {
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

  factory AiLearningHistory.fromMap(
    Map<String, dynamic> m,
  ) {
    return AiLearningHistory(
      id: m['id'] ?? newId(),
      groupId: m['groupId'] ?? '',
      modelId: m['modelId'] ?? '',
      typeId: m['typeId'] ?? '',
      printId: m['printId'] ?? '',
      referenceId: m['referenceId'] ?? '',
      area: m['area'] ?? '',
      content: m['content'] ?? '',
      learnedAt: m['learnedAt'] ?? '',
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
  String testedAt;

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
        'testedAt': testedAt,
      };

  factory AiMemoryTest.fromMap(Map<String, dynamic> m) {
    return AiMemoryTest(
      id: m['id'] ?? newId(),
      knowledgeId: m['knowledgeId'] ?? '',
      referenceId: m['referenceId'] ?? '',
      area: m['area'] ?? '',
      question: m['question'] ?? '',
      answer: m['answer'] ?? '',
      testedAt: m['testedAt'] ?? '',
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
  String checkedAt;

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
        'checkedAt': checkedAt,
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
      checkedAt: m['checkedAt'] ?? '',
    );
  }
}

/* ===================== STORAGE ===================== */

class Storage {
  static const groupsKey = 'reference_groups';
  static const knowledgeKey = 'ai_knowledge';
  static const historyKey = 'ai_learning_history';
  static const testsKey = 'ai_memory_tests';
  static const resultsKey = 'ai_test_results';

  static Future<List<GroupData>> groups() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(groupsKey);

    if (s == null || s.isEmpty) {
      return [];
    }

    try {
      return (jsonDecode(s) as List)
          .map(
            (e) => GroupData.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveGroups(
    List<GroupData> list,
  ) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      groupsKey,
      jsonEncode(
        list.map((e) => e.toMap()).toList(),
      ),
    );
  }

  static Future<void> saveGroup(
    GroupData group,
  ) async {
    final list = await groups();

    final i = list.indexWhere(
      (e) => e.id == group.id,
    );

    group.updatedAt =
        DateTime.now().toIso8601String();

    if (i >= 0) {
      list[i] = group;
    } else {
      list.add(group);
    }

    await saveGroups(list);
  }

  static Future<List<AiKnowledge>> knowledge() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(knowledgeKey);

    if (s == null || s.isEmpty) {
      return [];
    }

    try {
      return (jsonDecode(s) as List)
          .map(
            (e) => AiKnowledge.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveKnowledge(
    List<AiKnowledge> list,
  ) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      knowledgeKey,
      jsonEncode(
        list.map((e) => e.toMap()).toList(),
      ),
    );
  }

  static Future<List<AiLearningHistory>> history() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(historyKey);

    if (s == null || s.isEmpty) {
      return [];
    }

    try {
      return (jsonDecode(s) as List)
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
    List<AiLearningHistory> list,
  ) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      historyKey,
      jsonEncode(
        list.map((e) => e.toMap()).toList(),
      ),
    );
  }

  static Future<List<AiMemoryTest>> tests() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(testsKey);

    if (s == null || s.isEmpty) {
      return [];
    }

    try {
      return (jsonDecode(s) as List)
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
    List<AiMemoryTest> list,
  ) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      testsKey,
      jsonEncode(
        list.map((e) => e.toMap()).toList(),
      ),
    );
  }

  static Future<List<AiTestResult>> results() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(resultsKey);

    if (s == null || s.isEmpty) {
      return [];
    }

    try {
      return (jsonDecode(s) as List)
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
    List<AiTestResult> list,
  ) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      resultsKey,
      jsonEncode(
        list.map((e) => e.toMap()).toList(),
      ),
    );
  }

  /* ===== ลบความจำ AI ทั้งกลุ่ม ===== */

  static Future<void> deleteAiByGroup(
    String groupId,
  ) async {
    final k = await knowledge();
    final h = await history();
    final t = await tests();
    final r = await results();

    final groupKnowledgeIds = k
        .where((e) => e.groupId == groupId)
        .map((e) => e.id)
        .toSet();

    final groupReferenceIds = <String>{};

    final gs = await groups();

    for (final g in gs) {
      if (g.id != groupId) continue;

      for (final m in g.models) {
        for (final type in m.types) {
          for (final print in type.prints) {
            for (final ref in print.references) {
              groupReferenceIds.add(ref.id);
            }
          }
        }
      }
    }

    await saveKnowledge(
      k.where((e) => e.groupId != groupId).toList(),
    );

    await saveHistory(
      h.where((e) => e.groupId != groupId).toList(),
    );

    await saveTests(
      t.where(
        (e) =>
            !groupReferenceIds.contains(e.referenceId) &&
            !groupKnowledgeIds.contains(e.knowledgeId),
      ).toList(),
    );

    await saveResults(
      r.where(
        (e) =>
            !groupReferenceIds.contains(e.referenceId) &&
            !groupKnowledgeIds.contains(e.knowledgeId),
      ).toList(),
    );
  }

  /* ===== ลบความจำตามองค์อ้างอิง ===== */

  static Future<void> deleteAiByReference(
    String referenceId,
  ) async {
    final k = await knowledge();
    final h = await history();
    final t = await tests();
    final r = await results();

    final ids = k
        .where((e) => e.referenceId == referenceId)
        .map((e) => e.id)
        .toSet();

    await saveKnowledge(
      k.where(
        (e) => e.referenceId != referenceId,
      ).toList(),
    );

    await saveHistory(
      h.where(
        (e) => e.referenceId != referenceId,
      ).toList(),
    );

    await saveTests(
      t.where(
        (e) =>
            e.referenceId != referenceId &&
            !ids.contains(e.knowledgeId),
      ).toList(),
    );

    await saveResults(
      r.where(
        (e) =>
            e.referenceId != referenceId &&
            !ids.contains(e.knowledgeId),
      ).toList(),
    );
  }

  static Future<void> deleteAiByPrint(
    String printId,
  ) async {
    final gs = await groups();
    final ids = <String>{};

    for (final g in gs) {
      for (final m in g.models) {
        for (final type in m.types) {
          for (final p in type.prints) {
            if (p.id == printId) {
              for (final ref in p.references) {
                ids.add(ref.id);
              }
            }
          }
        }
      }
    }

    for (final id in ids) {
      await deleteAiByReference(id);
    }
  }

  static Future<void> deleteAiByType(
    String typeId,
  ) async {
    final gs = await groups();
    final ids = <String>{};

    for (final g in gs) {
      for (final m in g.models) {
        for (final type in m.types) {
          if (type.id == typeId) {
            for (final p in type.prints) {
              for (final ref in p.references) {
                ids.add(ref.id);
              }
            }
          }
        }
      }
    }

    for (final id in ids) {
      await deleteAiByReference(id);
    }
  }

  static Future<void> deleteAiByModel(
    String modelId,
  ) async {
    final gs = await groups();
    final ids = <String>{};

    for (final g in gs) {
      for (final m in g.models) {
        if (m.id == modelId) {
          for (final type in m.types) {
            for (final p in type.prints) {
              for (final ref in p.references) {
                ids.add(ref.id);
              }
            }
          }
        }
      }
    }

    for (final id in ids) {
      await deleteAiByReference(id);
    }
  }
}

/* ===================== APP ===================== */

class App extends StatelessWidget {
  final List<CameraDescription> cameras;

  const App(
    this.cameras, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'กล้องสแกนพระและเหรียญ',
      theme: ThemeData(
        colorSchemeSeed: Colors.brown,
        useMaterial3: true,
      ),
      home: HomePage(
        cameras: cameras,
      ),
    );
  }
}

/* ===================== PATH BAR ===================== */

class PathBar extends StatelessWidget {
  final List<String> items;

  const PathBar(
    this.items, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: Colors.brown.shade50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          items.join('  >  '),
          style: const TextStyle(
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/* ===================== HOME ===================== */

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
    groups = await Storage.groups();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> addGroup() async {
    final name = TextEditingController();
    final temple = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('สร้างกลุ่มพระ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'ชื่อพระ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: temple,
              decoration: const InputDecoration(
                labelText: 'วัด / เกจิ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (name.text.trim().isEmpty) {
                return;
              }

              Navigator.pop(context, true);
            },
            child: const Text('สร้าง'),
          ),
        ],
      ),
    );

    if (ok != true) {
      name.dispose();
      temple.dispose();
      return;
    }

    final now =
        DateTime.now().toIso8601String();

    groups.add(
      GroupData(
        id: newId(),
        name: name.text.trim(),
        temple: temple.text.trim(),
        createdAt: now,
        updatedAt: now,
        models: [],
      ),
    );

    await Storage.saveGroups(groups);

    name.dispose();
    temple.dispose();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> editGroup(
    GroupData g,
  ) async {
    final name =
        TextEditingController(text: g.name);

    final temple =
        TextEditingController(text: g.temple);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('แก้ไขกลุ่ม'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'ชื่อพระ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: temple,
              decoration: const InputDecoration(
                labelText: 'วัด / เกจิ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (ok == true) {
      g.name = name.text.trim();
      g.temple = temple.text.trim();

      await Storage.saveGroup(g);
      await load();
    }

    name.dispose();
    temple.dispose();
  }

  Future<void> deleteGroup(
    GroupData g,
  ) async {
    final ok = await confirmDelete(
      context,
      'ลบทั้งกลุ่ม?',
      'ข้อมูลรุ่น ชนิด พิมพ์ องค์อ้างอิง ข้อมูลสแกน และความจำ AI ของกลุ่มนี้จะถูกลบทั้งหมด',
    );

    if (!ok) return;

    await Storage.deleteAiByGroup(g.id);

    groups.removeWhere(
      (e) => e.id == g.id,
    );

    await Storage.saveGroups(groups);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ฐานข้อมูลส่วนตัว'),
      ),
      body: groups.isEmpty
          ? const Center(
              child: Text('ยังไม่มีข้อมูลกลุ่มพระ'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: groups.length,
              itemBuilder: (_, i) {
                final g = groups[i];

                return Card(
                  child: ListTile(
                    title: Text(
                      g.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      g.temple.isEmpty
                          ? 'ยังไม่ได้ระบุวัด'
                          : g.temple,
                    ),
                    trailing:
                        PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          editGroup(g);
                        }

                        if (v == 'delete') {
                          deleteGroup(g);
                        }
                      },
                      itemBuilder: (_) =>
                          const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('แก้ไข'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('ลบ'),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ModelPage(
                            group: g,
                            cameras:
                                widget.cameras,
                            autoCreate: false,
                          ),
                        ),
                      );

                      await load();
                    },
                  ),
                );
              },
            ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addGroup,
        icon: const Icon(Icons.add),
        label: const Text('สร้างกลุ่ม'),
      ),
    );
  }
}

/* ===================== MODEL PAGE ===================== */

class ModelPage extends StatefulWidget {
  final GroupData group;
  final List<CameraDescription> cameras;
  final bool autoCreate;

  const ModelPage({
    required this.group,
    required this.cameras,
    this.autoCreate = false,
    super.key,
  });

  @override
  State<ModelPage> createState() =>
      _ModelPageState();
}

class _ModelPageState
    extends State<ModelPage> {
  bool openedAutoCreate = false;

  @override
  void initState() {
    super.initState();

    if (widget.autoCreate) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!openedAutoCreate) {
          openedAutoCreate = true;
          add();
        }
      });
    }
  }

  Future<void> add() async {
    await textDialog(
      context,
      'สร้างรุ่น',
      '',
      (v) async {
        final now =
            DateTime.now().toIso8601String();

        widget.group.models.add(
          ModelData(
            id: newId(),
            name: v,
            createdAt: now,
            updatedAt: now,
            types: [],
          ),
        );

        await Storage.saveGroup(
          widget.group,
        );

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<void> edit(
    ModelData m,
  ) async {
    await textDialog(
      context,
      'แก้ไขรุ่น',
      m.name,
      (v) async {
        m.name = v;

        await Storage.saveGroup(
          widget.group,
        );

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<void> remove(
    ModelData m,
  ) async {
    final ok = await confirmDelete(
      context,
      'ลบรุ่น?',
      'ข้อมูลชนิด พิมพ์ องค์อ้างอิง และความจำ AI ของรุ่นนี้จะถูกลบ',
    );

    if (!ok) return;

    await Storage.deleteAiByModel(
      m.id,
    );

    widget.group.models.removeWhere(
      (e) => e.id == m.id,
    );

    await Storage.saveGroup(
      widget.group,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รุ่น'),
      ),
      body: Column(
        children: [
          PathBar([
            widget.group.name,
            'รุ่น',
          ]),
          Expanded(
            child: widget.group.models.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีรุ่น',
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.all(8),
                    itemCount:
                        widget.group.models.length,
                    itemBuilder: (_, i) {
                      final m =
                          widget.group.models[i];

                      return Card(
                        child: ListTile(
                          title: Text(
                            m.name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'แก้ไข',
                                onPressed: () =>
                                    edit(m),
                                icon: const Icon(
                                  Icons.edit,
                                ),
                              ),
                              IconButton(
                                tooltip: 'ลบ',
                                onPressed: () =>
                                    remove(m),
                                icon: const Icon(
                                  Icons.delete,
                                ),
                              ),
                            ],
                          ),

                          // แตะชื่อรุ่น
                          // ไปหน้าชนิดและสร้างชนิดทันที
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TypePage(
                                  group:
                                      widget.group,
                                  model: m,
                                  cameras:
                                      widget.cameras,
                                  autoCreate: true,
                                ),
                              ),
                            );

                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add),
        label: const Text('สร้างรุ่น'),
      ),
    );
  }
}

/* ===================== TYPE PAGE ===================== */

class TypePage extends StatefulWidget {
  final GroupData group;
  final ModelData model;
  final List<CameraDescription> cameras;
  final bool autoCreate;

  const TypePage({
    required this.group,
    required this.model,
    required this.cameras,
    this.autoCreate = false,
    super.key,
  });

  @override
  State<TypePage> createState() =>
      _TypePageState();
}

class _TypePageState
    extends State<TypePage> {
  bool openedAutoCreate = false;

  @override
  void initState() {
    super.initState();

    if (widget.autoCreate) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!openedAutoCreate) {
          openedAutoCreate = true;
          add();
        }
      });
    }
  }

  Future<void> add() async {
    String? selected;

    selected = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('สร้างชนิด'),
        content:
            DropdownButtonFormField<String>(
          items: typeOptions
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),
          onChanged: (v) {
            selected = v;
          },
          decoration:
              const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'ชนิดพระ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selected != null) {
                Navigator.pop(
                  context,
                  selected,
                );
              }
            },
            child: const Text('สร้าง'),
          ),
        ],
      ),
    );

    if (selected == null) return;

    final now =
        DateTime.now().toIso8601String();

    widget.model.types.add(
      TypeData(
        id: newId(),
        name: selected!,
        createdAt: now,
        updatedAt: now,
        prints: [],
      ),
    );

    await Storage.saveGroup(
      widget.group,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> edit(
    TypeData t,
  ) async {
    await textDialog(
      context,
      'แก้ไขชนิด',
      t.name,
      (v) async {
        t.name = v;

        await Storage.saveGroup(
          widget.group,
        );

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<void> remove(
    TypeData t,
  ) async {
    final ok = await confirmDelete(
      context,
      'ลบชนิด?',
      'ข้อมูลพิมพ์ องค์อ้างอิง และความจำ AI ของชนิดนี้จะถูกลบ',
    );

    if (!ok) return;

    await Storage.deleteAiByType(
      t.id,
    );

    widget.model.types.removeWhere(
      (e) => e.id == t.id,
    );

    await Storage.saveGroup(
      widget.group,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ชนิด'),
      ),
      body: Column(
        children: [
          PathBar([
            widget.group.name,
            widget.model.name,
            'ชนิด',
          ]),
          Expanded(
            child: widget.model.types.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีชนิด',
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.all(8),
                    itemCount:
                        widget.model.types.length,
                    itemBuilder: (_, i) {
                      final t =
                          widget.model.types[i];

                      return Card(
                        child: ListTile(
                          title: Text(
                            t.name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'แก้ไข',
                                onPressed: () =>
                                    edit(t),
                                icon: const Icon(
                                  Icons.edit,
                                ),
                              ),
                              IconButton(
                                tooltip: 'ลบ',
                                onPressed: () =>
                                    remove(t),
                                icon: const Icon(
                                  Icons.delete,
                                ),
                              ),
                            ],
                          ),

                          // แตะชื่อชนิด
                          // ไปหน้าพิมพ์และสร้างพิมพ์ทันที
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PrintPage(
                                  group:
                                      widget.group,
                                  model:
                                      widget.model,
                                  type: t,
                                  cameras:
                                      widget.cameras,
                                  autoCreate: true,
                                ),
                              ),
                            );

                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add),
        label: const Text('สร้างชนิด'),
      ),
    );
  }
}

/* ===================== PRINT PAGE ===================== */

class PrintPage extends StatefulWidget {
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final List<CameraDescription> cameras;
  final bool autoCreate;

  const PrintPage({
    required this.group,
    required this.model,
    required this.type,
    required this.cameras,
    this.autoCreate = false,
    super.key,
  });

  @override
  State<PrintPage> createState() =>
      _PrintPageState();
}

class _PrintPageState
    extends State<PrintPage> {
  bool openedAutoCreate = false;

  @override
  void initState() {
    super.initState();

    if (widget.autoCreate) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!openedAutoCreate) {
          openedAutoCreate = true;
          add();
        }
      });
    }
  }

  Future<void> add() async {
    await textDialog(
      context,
      'สร้างพิมพ์',
      '',
      (v) async {
        final now =
            DateTime.now().toIso8601String();

        widget.type.prints.add(
          PrintData(
            id: newId(),
            name: v,
            createdAt: now,
            updatedAt: now,
            references: [],
          ),
        );

        await Storage.saveGroup(
          widget.group,
        );

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<void> edit(
    PrintData p,
  ) async {
    await textDialog(
      context,
      'แก้ไขพิมพ์',
      p.name,
      (v) async {
        p.name = v;

        await Storage.saveGroup(
          widget.group,
        );

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<void> remove(
    PrintData p,
  ) async {
    final ok = await confirmDelete(
      context,
      'ลบพิมพ์?',
      'องค์อ้างอิงและความจำ AI ของพิมพ์นี้จะถูกลบ',
    );

    if (!ok) return;

    await Storage.deleteAiByPrint(
      p.id,
    );

    widget.type.prints.removeWhere(
      (e) => e.id == p.id,
    );

    await Storage.saveGroup(
      widget.group,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('พิมพ์'),
      ),
      body: Column(
        children: [
          PathBar([
            widget.group.name,
            widget.model.name,
            widget.type.name,
            'พิมพ์',
          ]),
          Expanded(
            child: widget.type.prints.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีพิมพ์',
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.all(8),
                    itemCount:
                        widget.type.prints.length,
                    itemBuilder: (_, i) {
                      final p =
                          widget.type.prints[i];

                      return Card(
                        child: ListTile(
                          title: Text(
                            p.name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'องค์อ้างอิง ${p.references.length} องค์',
                          ),
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'แก้ไข',
                                onPressed: () =>
                                    edit(p),
                                icon: const Icon(
                                  Icons.edit,
                                ),
                              ),
                              IconButton(
                                tooltip: 'ลบ',
                                onPressed: () =>
                                    remove(p),
                                icon: const Icon(
                                  Icons.delete,
                                ),
                              ),
                            ],
                          ),

                          // แตะชื่อพิมพ์
                          // ไปหน้าองค์อ้างอิง
                          // และเพิ่มองค์อ้างอิงทันที
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReferencePage(
                                  group:
                                      widget.group,
                                  model:
                                      widget.model,
                                  type:
                                      widget.type,
                                  print: p,
                                  cameras:
                                      widget.cameras,
                                  autoCreate: true,
                                ),
                              ),
                            );

                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add),
        label: const Text('สร้างพิมพ์'),
      ),
    );
  }
}

/* ===================== REFERENCE PAGE ===================== */

class ReferencePage extends StatefulWidget {
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final List<CameraDescription> cameras;
  final bool autoCreate;

  const ReferencePage({
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.cameras,
    this.autoCreate = false,
    super.key,
  });

  @override
  State<ReferencePage> createState() =>
      _ReferencePageState();
}

class _ReferencePageState
    extends State<ReferencePage> {
  bool openedAutoCreate = false;

  @override
  void initState() {
    super.initState();

    if (widget.autoCreate) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!openedAutoCreate) {
          openedAutoCreate = true;
          addReference();
        }
      });
    }
  }

  Future<void> addReference() async {
    final maxNumber =
        widget.print.references.isEmpty
            ? 0
            : widget.print.references
                .map(
                  (e) => e.referenceNumber,
                )
                .reduce(
                  (a, b) =>
                      a > b ? a : b,
                );

    final now =
        DateTime.now().toIso8601String();

    widget.print.references.add(
      ReferenceData(
        id: newId(),
        referenceNumber:
            maxNumber + 1,
        createdAt: now,
        updatedAt: now,
        scans: [],
      ),
    );

    await Storage.saveGroup(
      widget.group,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> deleteReference(
    ReferenceData ref,
  ) async {
    final ok = await confirmDelete(
      context,
      'ลบองค์อ้างอิง?',
      'ข้อมูลสแกนและความจำ AI ขององค์นี้จะถูกลบทั้งหมด',
    );

    if (!ok) return;

    await Storage.deleteAiByReference(
      ref.id,
    );

    widget.print.references.removeWhere(
      (e) => e.id == ref.id,
    );

    await Storage.saveGroup(
      widget.group,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> editReference(
    ReferenceData ref,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReferenceEditPage(
          group: widget.group,
          model: widget.model,
          type: widget.type,
          print: widget.print,
          reference: ref,
          cameras: widget.cameras,
        ),
      ),
    );

    await Storage.saveGroup(
      widget.group,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> backToGroup() async {
    await Storage.saveGroup(
      widget.group,
    );

    if (!mounted) return;

    Navigator.popUntil(
      context,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final areas =
        scanAreasForType(widget.type.name);

    return Scaffold(
      appBar: AppBar(
        title: const Text('องค์อ้างอิง'),
      ),
      body: Column(
        children: [
          PathBar([
            widget.group.name,
            widget.model.name,
            widget.type.name,
            widget.print.name,
            'องค์อ้างอิง',
          ]),
          Expanded(
            child: widget.print.references.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีองค์อ้างอิง',
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.all(8),
                    itemCount: widget
                        .print.references.length,
                    itemBuilder: (_, i) {
                      final ref = widget
                          .print.references[i];

                      return Card(
                        child: ExpansionTile(
                          title: Text(
                            'องค์อ้างอิง #${ref.referenceNumber}',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'บันทึกแล้ว ${ref.scans.length}/${areas.length} ด้าน',
                          ),
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'แก้ไข',
                                onPressed: () =>
                                    editReference(
                                  ref,
                                ),
                                icon: const Icon(
                                  Icons.edit,
                                ),
                              ),
                              IconButton(
                                tooltip: 'ลบ',
                                onPressed: () =>
                                    deleteReference(
                                  ref,
                                ),
                                icon: const Icon(
                                  Icons.delete,
                                ),
                              ),
                            ],
                          ),
                          children: [
                            ...areas.map(
                              (area) {
                                final scan = ref
                                    .scans
                                    .cast<
                                        ScanResult?>()
                                    .firstWhere(
                                      (e) =>
                                          e?.area ==
                                          area,
                                      orElse: () =>
                                          null,
                                    );

                                return ListTile(
                                  title:
                                      Text(area),
                                  subtitle:
                                      Text(
                                    scan == null ||
                                            scan.details
                                                .isEmpty
                                        ? 'ยังไม่มีข้อมูล'
                                        : 'มีข้อมูลแล้ว',
                                  ),
                                  trailing:
                                      const Icon(
                                    Icons
                                        .chevron_right,
                                  ),
                                  onTap: () async {
                                    await editReference(
                                      ref,
                                    );
                                  },
                                );
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets
                                      .all(10),
                              child: SizedBox(
                                width:
                                    double.infinity,
                                child:
                                    ElevatedButton
                                        .icon(
                                  onPressed: () =>
                                      editReference(
                                    ref,
                                  ),
                                  icon: const Icon(
                                    Icons.edit,
                                  ),
                                  label: const Text(
                                    'แก้ไขข้อมูลทุกด้าน',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ปุ่มสร้างยังอยู่ล่างขวา
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addReference,
        icon: const Icon(Icons.add),
        label: const Text(
          'เพิ่มองค์อ้างอิง',
        ),
      ),

      // ปุ่มกลับหน้ากลุ่ม
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            10,
            6,
            10,
            10,
          ),
          child: OutlinedButton.icon(
            onPressed: backToGroup,
            icon: const Icon(
              Icons.arrow_back,
            ),
            label: const Text(
              'กลับหน้ากลุ่ม',
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================== REFERENCE EDIT ===================== */

class ReferenceEditPage extends StatefulWidget {
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;
  final List<CameraDescription> cameras;

  const ReferenceEditPage({
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
    required this.cameras,
    super.key,
  });

  @override
  State<ReferenceEditPage> createState() =>
      _ReferenceEditPageState();
}

class _ReferenceEditPageState
    extends State<ReferenceEditPage> {
  ScanResult? getScan(
    String area,
  ) {
    for (final s in widget.reference.scans) {
      if (s.area == area) {
        return s;
      }
    }

    return null;
  }

  Future<void> scanArea(
    String area,
  ) async {
    final result =
        await Navigator.push<ScanResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          area: area,
          group: widget.group,
          model: widget.model,
          type: widget.type,
          print: widget.print,
          reference: widget.reference,
        ),
      ),
    );

    if (result == null) return;

    final old = getScan(area);

    if (old == null) {
      widget.reference.scans.add(result);
    } else {
      old.details = result.details;
    }

    widget.reference.updatedAt =
        DateTime.now().toIso8601String();

    await Storage.saveGroup(
      widget.group,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final areas =
        scanAreasForType(widget.type.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'แก้ไของค์อ้างอิง #${widget.reference.referenceNumber}',
        ),
      ),
      body: Column(
        children: [
          PathBar([
            widget.group.name,
            widget.model.name,
            widget.type.name,
            widget.print.name,
            'องค์อ้างอิง #${widget.reference.referenceNumber}',
            'แก้ไข',
          ]),
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.all(10),
              children: [
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'องค์อ้างอิง #${widget.reference.referenceNumber}',
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
                        const Text(
                          'แก้ไขและสแกนข้อมูลขององค์เดิมได้ทุกด้าน',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                ...areas.map(
                  (area) {
                    final scan =
                        getScan(area);

                    return Card(
                      child: ListTile(
                        title: Text(
                          area,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          scan == null ||
                                  scan.details
                                      .trim()
                                      .isEmpty
                              ? 'ยังไม่มีข้อมูล'
                              : scan.details,
                          maxLines: 3,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                        trailing:
                            ElevatedButton(
                          onPressed: () =>
                              scanArea(area),
                          child: Text(
                            scan == null
                                ? 'สแกน'
                                : 'แก้ไข',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== SCAN PAGE ===================== */

class ScanPage extends StatelessWidget {
  final List<CameraDescription> cameras;
  final String area;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;

  const ScanPage({
    required this.cameras,
    required this.area,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
    super.key,
  });

  Future<void> gallery(
    BuildContext context,
  ) async {
    final picker = ImagePicker();

    final file =
        await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (file == null) return;

    try {
      final result =
          await Navigator.push<ScanResult>(
        context,
        MaterialPageRoute(
          builder: (_) => AiVisionPage(
            imageFile: file,
            area: area,
            group: group,
            model: model,
            type: type,
            print: print,
            reference: reference,
          ),
        ),
      );

      if (result != null &&
          context.mounted) {
        Navigator.pop(
          context,
          result,
        );
      }
    } finally {
      try {
        final f = File(file.path);

        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> camera(
    BuildContext context,
  ) async {
    if (cameras.isEmpty) return;

    final file =
        await Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScanPage(
          cameras: cameras,
          area: area,
        ),
      ),
    );

    if (file == null) return;

    try {
      final result =
          await Navigator.push<ScanResult>(
        context,
        MaterialPageRoute(
          builder: (_) => AiVisionPage(
            imageFile: file,
            area: area,
            group: group,
            model: model,
            type: type,
            print: print,
            reference: reference,
          ),
        ),
      );

      if (result != null &&
          context.mounted) {
        Navigator.pop(
          context,
          result,
        );
      }
    } finally {
      try {
        final f = File(file.path);

        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สแกน$area'),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            PathBar([
              group.name,
              model.name,
              type.name,
              print.name,
              'องค์อ้างอิง #${reference.referenceNumber}',
              area,
            ]),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed: () =>
                    camera(context),
                icon: const Icon(
                  Icons.camera_alt,
                ),
                label:
                    const Text('เปิดกล้อง'),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed: () =>
                    gallery(context),
                icon: const Icon(
                  Icons.photo,
                ),
                label: const Text(
                  'เลือกภาพจากเครื่อง',
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'ภาพใช้ชั่วคราวสำหรับการวิเคราะห์เท่านั้น\n'
              'ไม่บันทึกรูปภาพลงฐานข้อมูล',
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== CAMERA ===================== */

class CameraScanPage
    extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String area;

  const CameraScanPage({
    required this.cameras,
    required this.area,
    super.key,
  });

  @override
  State<CameraScanPage> createState() =>
      _CameraScanPageState();
}

class _CameraScanPageState
    extends State<CameraScanPage> {
  CameraController? controller;
  bool busy = false;

  @override
  void initState() {
    super.initState();

    controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    controller!.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> capture() async {
    if (controller == null ||
        !controller!.value.isInitialized ||
        busy) {
      return;
    }

    setState(() {
      busy = true;
    });

    try {
      final file =
          await controller!.takePicture();

      if (mounted) {
        Navigator.pop(
          context,
          file,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content:
                Text('ไม่สามารถถ่ายภาพได้'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Scaffold(
      appBar: AppBar(
        title:
            Text('ถ่ายภาพ${widget.area}'),
      ),
      body: c == null ||
              !c.value.isInitialized
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child:
                      CameraPreview(c),
                ),
                Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child:
                      FloatingActionButton(
                    onPressed:
                        busy ? null : capture,
                    child: const Icon(
                      Icons.camera,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/* ===================== AI VISION / DETAILS ===================== */

class AiVisionPage
    extends StatefulWidget {
  final XFile imageFile;
  final String area;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;

  const AiVisionPage({
    required this.imageFile,
    required this.area,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
    super.key,
  });

  @override
  State<AiVisionPage> createState() =>
      _AiVisionPageState();
}

class _AiVisionPageState
    extends State<AiVisionPage> {
  final Map<String, TextEditingController>
      c = {};

  @override
  void initState() {
    super.initState();

    final old =
        widget.reference.scans.where(
      (e) => e.area == widget.area,
    );

    String oldText = '';

    if (old.isNotEmpty) {
      oldText = old.first.details;
    }

    for (final h in aiHeads) {
      c[h] =
          TextEditingController();
    }

    if (oldText.isNotEmpty) {
      final lines =
          oldText.split('\n');

      for (final line in lines) {
        for (final h in aiHeads) {
          if (line.startsWith('$h:')) {
            c[h]!.text =
                line.substring(
              h.length + 1,
            ).trim();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (final x in c.values) {
      x.dispose();
    }

    super.dispose();
  }

  String makeDetails() {
    final out = <String>[];

    for (final h in aiHeads) {
      final v =
          c[h]!.text.trim();

      if (v.isNotEmpty) {
        out.add('$h: $v');
      }
    }

    return out.join('\n');
  }

  void save() {
    final details =
        makeDetails();

    Navigator.pop(
      context,
      ScanResult(
        area: widget.area,
        details: details,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('รายละเอียด${widget.area}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.all(10),
              children: [
                SizedBox(
                  height: 240,
                  child: Image.file(
                    File(
                      widget.imageFile.path,
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'รายละเอียดการสแกน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                ...aiHeads.map(
                  (h) => Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: TextField(
                      controller: c[h],
                      maxLines: 3,
                      decoration:
                          InputDecoration(
                        labelText: h,
                        border:
                            const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed: save,
                  icon: const Icon(
                    Icons.save,
                  ),
                  label: const Text(
                    'บันทึกข้อมูล',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
