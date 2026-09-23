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

// =====================================================
// CONSTANTS
// =====================================================

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
    return [
      'ด้านหน้า',
      'ด้านหลัง',
      'ด้านข้าง',
    ];
  }

  return allAreas;
}

// =====================================================
// HELPERS
// =====================================================

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

String now() => DateTime.now().toIso8601String();

List<T> mapList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) builder,
) {
  if (value is! List) return [];

  return value
      .whereType<Map>()
      .map((e) => builder(Map<String, dynamic>.from(e)))
      .toList();
}

T? firstWhereOrNull<T>(
  Iterable<T> list,
  bool Function(T) test,
) {
  for (final item in list) {
    if (test(item)) return item;
  }
  return null;
}

// =====================================================
// DIALOGS
// =====================================================

Future<String?> textDialog(
  BuildContext context,
  String title,
  String value,
  Future<void> Function(String) save,
) async {
  final controller = TextEditingController(text: value);

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;

              await save(text);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      );
    },
  );

  final valueResult = result == true ? controller.text.trim() : null;
  controller.dispose();

  return valueResult;
}

Future<bool> confirmDelete(
  BuildContext context,
  String name,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('ยืนยันการลบ'),
            content: Text(
              'ต้องการลบ "$name" หรือไม่?\n'
              'ข้อมูล AI ที่เกี่ยวข้องจะถูกลบด้วย',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('ลบ'),
              ),
            ],
          );
        },
      ) ??
      false;
}

// =====================================================
// SCAN RESULT
// =====================================================

class ScanResult {
  String area;
  String details;

  ScanResult({
    required this.area,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'details': details,
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      area: map['area']?.toString() ?? '',
      details: map['details']?.toString() ?? '',
    );
  }
}

// =====================================================
// REFERENCE
// =====================================================

class ReferenceData {
  String id;
  String createdAt;
  String updatedAt;
  int referenceNumber;
  List<ScanResult> scans;

  ReferenceData({
    required this.id,
    required this.referenceNumber,
    required this.createdAt,
    required this.updatedAt,
    List<ScanResult>? scans,
  }) : scans = scans ?? [];

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
    return ReferenceData(
      id: map['id']?.toString() ?? newId(),
      referenceNumber: map['referenceNumber'] is int
          ? map['referenceNumber']
          : int.tryParse(
                map['referenceNumber']?.toString() ?? '',
              ) ??
              1,
      createdAt: map['createdAt']?.toString() ?? now(),
      updatedAt: map['updatedAt']?.toString() ?? now(),
      scans: mapList(
        map['scans'],
        ScanResult.fromMap,
      ),
    );
  }
}

// =====================================================
// PRINT
// =====================================================

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
    List<ReferenceData>? references,
  }) : references = references ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'references': references.map((e) => e.toMap()).toList(),
    };
  }

  factory PrintData.fromMap(Map<String, dynamic> map) {
    return PrintData(
      id: map['id']?.toString() ?? newId(),
      name: map['name']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? now(),
      updatedAt: map['updatedAt']?.toString() ?? now(),
      references: mapList(
        map['references'],
        ReferenceData.fromMap,
      ),
    );
  }
}

// =====================================================
// TYPE
// =====================================================

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
    List<PrintData>? prints,
  }) : prints = prints ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'prints': prints.map((e) => e.toMap()).toList(),
    };
  }

  factory TypeData.fromMap(Map<String, dynamic> map) {
    return TypeData(
      id: map['id']?.toString() ?? newId(),
      name: map['name']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? now(),
      updatedAt: map['updatedAt']?.toString() ?? now(),
      prints: mapList(
        map['prints'],
        PrintData.fromMap,
      ),
    );
  }
}

// =====================================================
// MODEL
// =====================================================

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
    List<TypeData>? types,
  }) : types = types ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'types': types.map((e) => e.toMap()).toList(),
    };
  }

  factory ModelData.fromMap(Map<String, dynamic> map) {
    return ModelData(
      id: map['id']?.toString() ?? newId(),
      name: map['name']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? now(),
      updatedAt: map['updatedAt']?.toString() ?? now(),
      types: mapList(
        map['types'],
        TypeData.fromMap,
      ),
    );
  }
}

// =====================================================
// GROUP
// =====================================================

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
    List<ModelData>? models,
  }) : models = models ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'temple': temple,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'models': models.map((e) => e.toMap()).toList(),
    };
  }

  factory GroupData.fromMap(Map<String, dynamic> map) {
    return GroupData(
      id: map['id']?.toString() ?? newId(),
      name: map['name']?.toString() ?? '',
      temple: map['temple']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? now(),
      updatedAt: map['updatedAt']?.toString() ?? now(),
      models: mapList(
        map['models'],
        ModelData.fromMap,
      ),
    );
  }
}

// =====================================================
// AI KNOWLEDGE
// =====================================================

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

  Map<String, dynamic> toMap() {
    return {
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
  }

  factory AiKnowledge.fromMap(Map<String, dynamic> map) {
    return AiKnowledge(
      id: map['id']?.toString() ?? newId(),
      groupId: map['groupId']?.toString() ?? '',
      modelId: map['modelId']?.toString() ?? '',
      typeId: map['typeId']?.toString() ?? '',
      printId: map['printId']?.toString() ?? '',
      referenceId: map['referenceId']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? now(),
      updatedAt: map['updatedAt']?.toString() ?? now(),
    );
  }
}

// =====================================================
// AI HISTORY
// =====================================================

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

  Map<String, dynamic> toMap() {
    return {
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
  }

  factory AiLearningHistory.fromMap(Map<String, dynamic> map) {
    return AiLearningHistory(
      id: map['id']?.toString() ?? newId(),
      groupId: map['groupId']?.toString() ?? '',
      modelId: map['modelId']?.toString() ?? '',
      typeId: map['typeId']?.toString() ?? '',
      printId: map['printId']?.toString() ?? '',
      referenceId: map['referenceId']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      learnedAt: map['learnedAt']?.toString() ?? now(),
    );
  }
}

// =====================================================
// AI MEMORY TEST
// =====================================================

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'knowledgeId': knowledgeId,
      'referenceId': referenceId,
      'area': area,
      'question': question,
      'answer': answer,
      'testedAt': testedAt,
    };
  }

  factory AiMemoryTest.fromMap(Map<String, dynamic> map) {
    return AiMemoryTest(
      id: map['id']?.toString() ?? newId(),
      knowledgeId: map['knowledgeId']?.toString() ?? '',
      referenceId: map['referenceId']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      question: map['question']?.toString() ?? '',
      answer: map['answer']?.toString() ?? '',
      testedAt: map['testedAt']?.toString() ?? now(),
    );
  }
}

// =====================================================
// AI TEST RESULT
// =====================================================

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

  Map<String, dynamic> toMap() {
    return {
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
  }

  factory AiTestResult.fromMap(Map<String, dynamic> map) {
    return AiTestResult(
      id: map['id']?.toString() ?? newId(),
      testId: map['testId']?.toString() ?? '',
      knowledgeId: map['knowledgeId']?.toString() ?? '',
      referenceId: map['referenceId']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      mode: map['mode']?.toString() ?? '',
      result: map['result']?.toString() ?? '',
      answer: map['answer']?.toString() ?? '',
      referenceAnswer: map['referenceAnswer']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      checkedAt: map['checkedAt']?.toString() ?? now(),
    );
  }
}

// =====================================================
// REFERENCE LINK
// =====================================================

class _RefLink {
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;

  _RefLink(
    this.group,
    this.model,
    this.type,
    this.print,
    this.reference,
  );
}

// =====================================================
// STORAGE
// =====================================================

class Storage {
  static const groupsKey = 'reference_groups';
  static const knowledgeKey = 'ai_knowledge';
  static const historyKey = 'ai_learning_history';
  static const testsKey = 'ai_memory_tests';
  static const resultsKey = 'ai_test_results';

  static Future<List<T>> _get<T>(
    String key,
    T Function(Map<String, dynamic>) builder,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key);

    if (value == null || value.isEmpty) return [];

    try {
      return mapList(
        jsonDecode(value),
        builder,
      );
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save<T>(
    String key,
    List<T> list,
    Map<String, dynamic> Function(T) mapper,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      key,
      jsonEncode(
        list.map(mapper).toList(),
      ),
    );
  }

  static Future<List<GroupData>> groups() {
    return _get(
      groupsKey,
      GroupData.fromMap,
    );
  }

  static Future<void> saveGroups(
    List<GroupData> groups,
  ) {
    return _save(
      groupsKey,
      groups,
      (e) => e.toMap(),
    );
  }

  static Future<void> saveGroup(GroupData group) async {
    final groups = await Storage.groups();

    final index = groups.indexWhere(
      (e) => e.id == group.id,
    );

    if (index < 0) {
      groups.add(group);
    } else {
      groups[index] = group;
    }

    await saveGroups(groups);
  }

  static Future<List<AiKnowledge>> knowledge() {
    return _get(
      knowledgeKey,
      AiKnowledge.fromMap,
    );
  }

  static Future<void> saveKnowledge(
    List<AiKnowledge> value,
  ) {
    return _save(
      knowledgeKey,
      value,
      (e) => e.toMap(),
    );
  }

  static Future<List<AiLearningHistory>> history() {
    return _get(
      historyKey,
      AiLearningHistory.fromMap,
    );
  }

  static Future<void> saveHistory(
    List<AiLearningHistory> value,
  ) {
    return _save(
      historyKey,
      value,
      (e) => e.toMap(),
    );
  }

  static Future<List<AiMemoryTest>> tests() {
    return _get(
      testsKey,
      AiMemoryTest.fromMap,
    );
  }

  static Future<void> saveTests(
    List<AiMemoryTest> value,
  ) {
    return _save(
      testsKey,
      value,
      (e) => e.toMap(),
    );
  }

  static Future<List<AiTestResult>> results() {
    return _get(
      resultsKey,
      AiTestResult.fromMap,
    );
  }

  static Future<void> saveResults(
    List<AiTestResult> value,
  ) {
    return _save(
      resultsKey,
      value,
      (e) => e.toMap(),
    );
  }

  static Iterable<_RefLink> links(GroupData group) sync* {
    for (final model in group.models) {
      for (final type in model.types) {
        for (final print in type.prints) {
          for (final reference in print.references) {
            yield _RefLink(
              group,
              model,
              type,
              print,
              reference,
            );
          }
        }
      }
    }
  }

  static Set<String> refIds(
    Iterable<_RefLink> links,
  ) {
    return links
        .map((e) => e.reference.id)
        .toSet();
  }

  // ---------------------------------------------------
  // CLEAR AI BY SCOPE
  // ---------------------------------------------------

  static Future<void> clearAiByScope({
    String? groupId,
    String? modelId,
    String? typeId,
    String? printId,
    Set<String>? referenceIds,
  }) async {
    final refs = referenceIds ?? <String>{};

    final knowledgeList = await knowledge();
    final historyList = await history();
    final testList = await tests();
    final resultList = await results();

    bool matchKnowledge(AiKnowledge e) {
      return refs.contains(e.referenceId) ||
          (groupId != null && e.groupId == groupId) ||
          (modelId != null && e.modelId == modelId) ||
          (typeId != null && e.typeId == typeId) ||
          (printId != null && e.printId == printId);
    }

    bool matchHistory(AiLearningHistory e) {
      return refs.contains(e.referenceId) ||
          (groupId != null && e.groupId == groupId) ||
          (modelId != null && e.modelId == modelId) ||
          (typeId != null && e.typeId == typeId) ||
          (printId != null && e.printId == printId);
    }

    final matchedKnowledge =
        knowledgeList.where(matchKnowledge).toList();

    final knowledgeIds =
        matchedKnowledge.map((e) => e.id).toSet();

    final allReferenceIds = {
      ...refs,
      ...matchedKnowledge.map((e) => e.referenceId),
    };

    final matchedTests = testList.where(
      (e) =>
          allReferenceIds.contains(e.referenceId) ||
          knowledgeIds.contains(e.knowledgeId),
    );

    final testIds =
        matchedTests.map((e) => e.id).toSet();

    knowledgeList.removeWhere(matchKnowledge);
    historyList.removeWhere(matchHistory);

    testList.removeWhere(
      (e) =>
          allReferenceIds.contains(e.referenceId) ||
          knowledgeIds.contains(e.knowledgeId),
    );

    resultList.removeWhere(
      (e) =>
          allReferenceIds.contains(e.referenceId) ||
          knowledgeIds.contains(e.knowledgeId) ||
          testIds.contains(e.testId),
    );

    await Future.wait([
      saveKnowledge(knowledgeList),
      saveHistory(historyList),
      saveTests(testList),
      saveResults(resultList),
    ]);
  }

  // ---------------------------------------------------
  // CLEAR ONE SCAN AREA
  // ---------------------------------------------------

  static Future<void> clearAiByArea(
    String referenceId,
    String area,
  ) async {
    final knowledgeList = await knowledge();
    final historyList = await history();
    final testList = await tests();
    final resultList = await results();

    final knowledgeIds = knowledgeList
        .where(
          (e) =>
              e.referenceId == referenceId &&
              e.area == area,
        )
        .map((e) => e.id)
        .toSet();

    final testIds = testList
        .where(
          (e) =>
              e.referenceId == referenceId &&
              e.area == area,
        )
        .map((e) => e.id)
        .toSet();

    knowledgeList.removeWhere(
      (e) =>
          e.referenceId == referenceId &&
          e.area == area,
    );

    historyList.removeWhere(
      (e) =>
          e.referenceId == referenceId &&
          e.area == area,
    );

    testList.removeWhere(
      (e) =>
          (e.referenceId == referenceId &&
              e.area == area) ||
          knowledgeIds.contains(e.knowledgeId),
    );

    resultList.removeWhere(
      (e) =>
          (e.referenceId == referenceId &&
              e.area == area) ||
          knowledgeIds.contains(e.knowledgeId) ||
          testIds.contains(e.testId),
    );

    await Future.wait([
      saveKnowledge(knowledgeList),
      saveHistory(historyList),
      saveTests(testList),
      saveResults(resultList),
    ]);
  }

  // ---------------------------------------------------
  // REBUILD AI
  // ---------------------------------------------------

  static Future<void> rebuildAi(
    Iterable<_RefLink> source, {
    String? groupId,
    String? modelId,
    String? typeId,
    String? printId,
  }) async {
    final list = source.toList();

    await clearAiByScope(
      groupId: groupId,
      modelId: modelId,
      typeId: typeId,
      printId: printId,
      referenceIds: refIds(list),
    );

    if (list.isEmpty) return;

    final knowledgeList = await knowledge();
    final historyList = await history();

    final date = now();

    for (final item in list) {
      for (final scan in item.reference.scans) {
        final content = scan.details.trim();

        if (content.isEmpty) continue;

        final knowledgeId = newId();

        knowledgeList.add(
          AiKnowledge(
            id: knowledgeId,
            groupId: item.group.id,
            modelId: item.model.id,
            typeId: item.type.id,
            printId: item.print.id,
            referenceId: item.reference.id,
            area: scan.area,
            content: content,
            createdAt: date,
            updatedAt: date,
          ),
        );

        historyList.add(
          AiLearningHistory(
            id: newId(),
            groupId: item.group.id,
            modelId: item.model.id,
            typeId: item.type.id,
            printId: item.print.id,
            referenceId: item.reference.id,
            area: scan.area,
            content: content,
            learnedAt: date,
          ),
        );
      }
    }

    await Future.wait([
      saveKnowledge(knowledgeList),
      saveHistory(historyList),
    ]);
  }

  static Future<void> syncGroup(
    GroupData group,
  ) {
    return rebuildAi(
      links(group),
      groupId: group.id,
    );
  }

  static Future<void> syncModel(
    GroupData group,
    ModelData model,
  ) {
    return rebuildAi(
      links(
        _copyGroup(
          group,
          [model],
        ),
      ),
      modelId: model.id,
    );
  }

  static Future<void> syncType(
    GroupData group,
    ModelData model,
    TypeData type,
  ) {
    final copyModel = ModelData(
      id: model.id,
      name: model.name,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      types: [type],
    );

    return rebuildAi(
      links(
        _copyGroup(
          group,
          [copyModel],
        ),
      ),
      typeId: type.id,
    );
  }

  static Future<void> syncPrint(
    GroupData group,
    ModelData model,
    TypeData type,
    PrintData print,
  ) {
    final copyType = TypeData(
      id: type.id,
      name: type.name,
      createdAt: type.createdAt,
      updatedAt: type.updatedAt,
      prints: [print],
    );

    final copyModel = ModelData(
      id: model.id,
      name: model.name,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      types: [copyType],
    );

    return rebuildAi(
      links(
        _copyGroup(
          group,
          [copyModel],
        ),
      ),
      printId: print.id,
    );
  }

  // ---------------------------------------------------
  // SYNC ONE SCAN
  // ---------------------------------------------------

  static Future<void> syncScan({
    required GroupData group,
    required ModelData model,
    required TypeData type,
    required PrintData print,
    required ReferenceData reference,
    required ScanResult scan,
  }) async {
    await clearAiByArea(
      reference.id,
      scan.area,
    );

    final content = scan.details.trim();

    if (content.isEmpty) return;

    final date = now();
    final knowledgeList = await knowledge();
    final historyList = await history();

    final knowledgeId = newId();

    knowledgeList.add(
      AiKnowledge(
        id: knowledgeId,
        groupId: group.id,
        modelId: model.id,
        typeId: type.id,
        printId: print.id,
        referenceId: reference.id,
        area: scan.area,
        content: content,
        createdAt: date,
        updatedAt: date,
      ),
    );

    historyList.add(
      AiLearningHistory(
        id: newId(),
        groupId: group.id,
        modelId: model.id,
        typeId: type.id,
        printId: print.id,
        referenceId: reference.id,
        area: scan.area,
        content: content,
        learnedAt: date,
      ),
    );

    await Future.wait([
      saveKnowledge(knowledgeList),
      saveHistory(historyList),
    ]);
  }

  // ---------------------------------------------------
  // DELETE
  // ---------------------------------------------------

  static Future<void> deleteReference(
    ReferenceData reference,
  ) {
    return clearAiByScope(
      referenceIds: {reference.id},
    );
  }

  static Future<void> deletePrint(
    PrintData print,
  ) {
    return clearAiByScope(
      printId: print.id,
      referenceIds: _refsFromPrint(print),
    );
  }

  static Future<void> deleteType(
    TypeData type,
  ) {
    return clearAiByScope(
      typeId: type.id,
      referenceIds: _refsFromType(type),
    );
  }

  static Future<void> deleteModel(
    ModelData model,
  ) {
    return clearAiByScope(
      modelId: model.id,
      referenceIds: _refsFromModel(model),
    );
  }

  static Future<void> deleteGroup(
    GroupData group,
  ) {
    return clearAiByScope(
      groupId: group.id,
      referenceIds: refIds(links(group)),
    );
  }

  static Set<String> _refsFromPrint(
    PrintData print,
  ) {
    return print.references
        .map((e) => e.id)
        .toSet();
  }

  static Set<String> _refsFromType(
    TypeData type,
  ) {
    return type.prints
        .expand((p) => p.references)
        .map((r) => r.id)
        .toSet();
  }

  static Set<String> _refsFromModel(
    ModelData model,
  ) {
    return model.types
        .expand((t) => t.prints)
        .expand((p) => p.references)
        .map((r) => r.id)
        .toSet();
  }
}

GroupData _copyGroup(
  GroupData group,
  List<ModelData> models,
) {
  return GroupData(
    id: group.id,
    name: group.name,
    temple: group.temple,
    createdAt: group.createdAt,
    updatedAt: group.updatedAt,
    models: models,
  );
}

// =====================================================
// APP
// =====================================================

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
        ),
        useMaterial3: true,
      ),
      home: HomePage(
        cameras: cameras,
      ),
    );
  }
}

// =====================================================
// PATH BAR
// =====================================================

class PathBar extends StatelessWidget {
  final String text;

  const PathBar(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: Colors.brown.shade50,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
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
  final groupController = TextEditingController();
  final templeController = TextEditingController();
  final modelController = TextEditingController();
  final printController = TextEditingController();

  String selectedType = typeOptions.first;
  bool saving = false;

  @override
  void dispose() {
    groupController.dispose();
    templeController.dispose();
    modelController.dispose();
    printController.dispose();
    super.dispose();
  }

  Future<int> nextNumber(
    List<GroupData> groups,
  ) async {
    var max = 0;

    for (final group in groups) {
      for (final link in Storage.links(group)) {
        if (link.reference.referenceNumber > max) {
          max = link.reference.referenceNumber;
        }
      }
    }

    return max + 1;
  }

  Future<void> create() async {
    if (saving) return;

    final groupName =
        groupController.text.trim();
    final temple =
        templeController.text.trim();
    final modelName =
        modelController.text.trim();
    final printName =
        printController.text.trim();

    if ([
      groupName,
      temple,
      modelName,
      printName,
    ].any((e) => e.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณากรอกข้อมูลให้ครบทุกช่อง',
          ),
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final groups = await Storage.groups();
      final date = now();

      GroupData? group = firstWhereOrNull(
        groups,
        (g) =>
            g.name.trim() == groupName &&
            g.temple.trim() == temple,
      );

      if (group == null) {
        group = GroupData(
          id: newId(),
          name: groupName,
          temple: temple,
          createdAt: date,
          updatedAt: date,
        );

        groups.add(group);
      }

      ModelData? model = firstWhereOrNull(
        group.models,
        (m) => m.name.trim() == modelName,
      );

      if (model == null) {
        model = ModelData(
          id: newId(),
          name: modelName,
          createdAt: date,
          updatedAt: date,
        );

        group.models.add(model);
      }

      TypeData? type = firstWhereOrNull(
        model.types,
        (t) => t.name.trim() == selectedType,
      );

      if (type == null) {
        type = TypeData(
          id: newId(),
          name: selectedType,
          createdAt: date,
          updatedAt: date,
        );

        model.types.add(type);
      }

      PrintData? print = firstWhereOrNull(
        type.prints,
        (p) => p.name.trim() == printName,
      );

      if (print == null) {
        print = PrintData(
          id: newId(),
          name: printName,
          createdAt: date,
          updatedAt: date,
        );

        type.prints.add(print);
      }

      final reference = ReferenceData(
        id: newId(),
        referenceNumber:
            await nextNumber(groups),
        createdAt: date,
        updatedAt: date,
      );

      print.references.add(reference);

      group.updatedAt = date;
      model.updatedAt = date;
      type.updatedAt = date;
      print.updatedAt = date;

      await Storage.saveGroups(groups);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReferenceEditPage(
            cameras: widget.cameras,
            group: group!,
            model: model!,
            type: type!,
            print: print!,
            reference: reference,
          ),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถสร้างข้อมูลได้: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'สร้างองค์อ้างอิง',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const PathBar(
            'กรอกข้อมูลเพื่อสร้างองค์อ้างอิง',
          ),
          const SizedBox(height: 12),

          TextField(
            controller: groupController,
            decoration: const InputDecoration(
              labelText: 'ชื่อกลุ่ม',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: templeController,
            decoration: const InputDecoration(
              labelText: 'วัด',
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

          DropdownButtonFormField<String>(
            value: selectedType,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'ชนิด',
              border: OutlineInputBorder(),
            ),
            items: typeOptions
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(
                  () => selectedType = value,
                );
              }
            },
          ),

          const SizedBox(height: 12),

          TextField(
            controller: printController,
            decoration: const InputDecoration(
              labelText: 'พิมพ์',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: saving ? null : create,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(
                saving
                    ? 'กำลังสร้าง...'
                    : 'สร้างองค์อ้างอิง',
              ),
            ),
          ),
        ],
      ),
    );
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
  List<GroupData> data = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final groups = await Storage.groups();

    if (!mounted) return;

    setState(() {
      data = groups;
    });
  }

  Future<void> createGroup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReferencePage(
          cameras: widget.cameras,
        ),
      ),
    );

    if (mounted) {
      await load();
    }
  }

  Future<void> editGroup(
    GroupData group,
  ) async {
    final name =
        TextEditingController(text: group.name);
    final temple =
        TextEditingController(text: group.temple);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('แก้ไขกลุ่ม'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'ชื่อกลุ่ม',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: temple,
                decoration: const InputDecoration(
                  labelText: 'วัด',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );

    if (ok == true &&
        name.text.trim().isNotEmpty) {
      group.name = name.text.trim();
      group.temple = temple.text.trim();
      group.updatedAt = now();

      await Storage.saveGroup(group);
      await Storage.syncGroup(group);
      await load();
    }

    name.dispose();
    temple.dispose();
  }

  Future<void> deleteGroup(
    GroupData group,
  ) async {
    if (!await confirmDelete(
      context,
      group.name,
    )) {
      return;
    }

    final ids =
        Storage.refIds(Storage.links(group));

    data.removeWhere(
      (e) => e.id == group.id,
    );

    await Storage.saveGroups(data);

    await Storage.clearAiByScope(
      groupId: group.id,
      referenceIds: ids,
    );

    await load();
  }

  int countReferences(
    GroupData group,
  ) {
    return group.models.fold(
      0,
      (total, model) =>
          total +
          model.types.fold(
            0,
            (typeTotal, type) =>
                typeTotal +
                type.prints.fold(
                  0,
                  (printTotal, print) =>
                      printTotal +
                      print.references.length,
                ),
          ),
    );
  }

  int countScans(
    GroupData group,
  ) {
    return group.models.fold(
      0,
      (total, model) =>
          total +
          model.types.fold(
            0,
            (typeTotal, type) =>
                typeTotal +
                type.prints.fold(
                  0,
                  (printTotal, print) =>
                      printTotal +
                      print.references.fold(
                        0,
                        (refTotal, reference) =>
                            refTotal +
                            reference.scans.length,
                      ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'กล้องสแกนพระและเหรียญ',
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: createGroup,
        icon: const Icon(Icons.add),
        label: const Text(
          'สร้างองค์อ้างอิง',
        ),
      ),
      body: Column(
        children: [
          const PathBar(
            'ฐานข้อมูลส่วนตัว',
          ),
          Expanded(
            child: data.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีข้อมูล',
                    ),
                  )
                : ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (_, index) {
                      final group = data[index];

                      return Card(
                        margin:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          title: Text(
                            group.name,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${group.temple.isEmpty ? '' : 'วัด ${group.temple}\n'}'
                            'องค์อ้างอิง ${countReferences(group)} • '
                            'สแกน ${countScans(group)}',
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ModelPage(
                                  cameras:
                                      widget.cameras,
                                  group: group,
                                ),
                              ),
                            );

                            if (mounted) {
                              await load();
                            }
                          },
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    editGroup(group),
                                icon:
                                    const Icon(Icons.edit),
                              ),
                              IconButton(
                                onPressed: () =>
                                    deleteGroup(group),
                                icon: const Icon(
                                  Icons.delete,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// MODEL PAGE
// =====================================================

class ModelPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final GroupData group;

  const ModelPage({
    super.key,
    required this.cameras,
    required this.group,
  });

  @override
  State<ModelPage> createState() =>
      _ModelPageState();
}

class _ModelPageState extends State<ModelPage> {
  Future<void> add() async {
    await textDialog(
      context,
      'เพิ่มรุ่น',
      '',
      (value) async {
        final date = now();

        widget.group.models.add(
          ModelData(
            id: newId(),
            name: value,
            createdAt: date,
            updatedAt: date,
          ),
        );

        widget.group.updatedAt = date;

        await Storage.saveGroup(
          widget.group,
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> edit(
    ModelData model,
  ) async {
    await textDialog(
      context,
      'แก้ไขรุ่น',
      model.name,
      (value) async {
        model.name = value;
        model.updatedAt = now();
        widget.group.updatedAt = now();

        await Storage.saveGroup(
          widget.group,
        );

        await Storage.syncModel(
          widget.group,
          model,
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> delete(
    ModelData model,
  ) async {
    if (!await confirmDelete(
      context,
      model.name,
    )) {
      return;
    }

    final ids = model.types
        .expand((t) => t.prints)
        .expand((p) => p.references)
        .map((r) => r.id)
        .toSet();

    widget.group.models.removeWhere(
      (e) => e.id == model.id,
    );

    widget.group.updatedAt = now();

    await Storage.saveGroup(
      widget.group,
    );

    await Storage.clearAiByScope(
      modelId: model.id,
      referenceIds: ids,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรุ่น'),
      ),
      body: Column(
        children: [
          PathBar(
            '${widget.group.name} > รุ่น',
          ),
          Expanded(
            child: widget.group.models.isEmpty
                ? const Center(
                    child: Text('ยังไม่มีรุ่น'),
                  )
                : ListView.builder(
                    itemCount:
                        widget.group.models.length,
                    itemBuilder: (_, index) {
                      final model =
                          widget.group.models[index];

                      return Card(
                        child: ListTile(
                          title: Text(model.name),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TypePage(
                                  cameras:
                                      widget.cameras,
                                  group: widget.group,
                                  model: model,
                                ),
                              ),
                            );

                            if (mounted) {
                              setState(() {});
                            }
                          },
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    edit(model),
                                icon: const Icon(
                                  Icons.edit,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    delete(model),
                                icon: const Icon(
                                  Icons.delete,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// TYPE PAGE
// =====================================================

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
  State<TypePage> createState() =>
      _TypePageState();
}

class _TypePageState extends State<TypePage> {
  Future<void> add() async {
    String selected = typeOptions.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('เพิ่มชนิด'),
              content:
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
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(
                      () => selected = value,
                    );
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    true,
                  ),
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      final date = now();

      widget.model.types.add(
        TypeData(
          id: newId(),
          name: selected,
          createdAt: date,
          updatedAt: date,
        ),
      );

      widget.group.updatedAt = date;

      await Storage.saveGroup(
        widget.group,
      );

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> edit(
    TypeData type,
  ) async {
    String selected = type.name;

    if (!typeOptions.contains(selected)) {
      selected = typeOptions.first;
    }

    final oldName = type.name;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('แก้ไขชนิด'),
              content:
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
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(
                      () => selected = value,
                    );
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    true,
                  ),
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true &&
        selected != oldName) {
      type.name = selected;
      type.updatedAt = now();
      widget.group.updatedAt = now();

      await Storage.saveGroup(
        widget.group,
      );

      await Storage.syncType(
        widget.group,
        widget.model,
        type,
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> delete(
    TypeData type,
  ) async {
    if (!await confirmDelete(
      context,
      type.name,
    )) {
      return;
    }

    final ids = type.prints
        .expand((p) => p.references)
        .map((r) => r.id)
        .toSet();

    widget.model.types.removeWhere(
      (e) => e.id == type.id,
    );

    widget.group.updatedAt = now();

    await Storage.saveGroup(
      widget.group,
    );

    await Storage.clearAiByScope(
      typeId: type.id,
      referenceIds: ids,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.model.name),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มชนิด'),
      ),
      body: Column(
        children: [
          PathBar(
            '${widget.group.name} > '
            '${widget.model.name} > ชนิด',
          ),
          Expanded(
            child: widget.model.types.isEmpty
                ? const Center(
                    child: Text('ยังไม่มีชนิด'),
                  )
                : ListView.builder(
                    itemCount:
                        widget.model.types.length,
                    itemBuilder: (_, index) {
                      final type =
                          widget.model.types[index];

                      return Card(
                        child: ListTile(
                          title: Text(type.name),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PrintPage(
                                  cameras:
                                      widget.cameras,
                                  group: widget.group,
                                  model: widget.model,
                                  type: type,
                                ),
                              ),
                            );

                            if (mounted) {
                              setState(() {});
                            }
                          },
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    edit(type),
                                icon: const Icon(
                                  Icons.edit,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    delete(type),
                                icon: const Icon(
                                  Icons.delete,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// PRINT PAGE
// =====================================================

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
  State<PrintPage> createState() =>
      _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  Future<void> add() async {
    await textDialog(
      context,
      'เพิ่มพิมพ์',
      '',
      (value) async {
        final date = now();

        widget.type.prints.add(
          PrintData(
            id: newId(),
            name: value,
            createdAt: date,
            updatedAt: date,
          ),
        );

        widget.type.updatedAt = date;
        widget.group.updatedAt = date;

        await Storage.saveGroup(
          widget.group,
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> edit(
    PrintData print,
  ) async {
    await textDialog(
      context,
      'แก้ไขพิมพ์',
      print.name,
      (value) async {
        print.name = value;
        print.updatedAt = now();
        widget.type.updatedAt = now();
        widget.group.updatedAt = now();

        await Storage.saveGroup(
          widget.group,
        );

        await Storage.syncPrint(
          widget.group,
          widget.model,
          widget.type,
          print,
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> delete(
    PrintData print,
  ) async {
    if (!await confirmDelete(
      context,
      print.name,
    )) {
      return;
    }

    final ids = print.references
        .map((r) => r.id)
        .toSet();

    widget.type.prints.removeWhere(
      (e) => e.id == print.id,
    );

    widget.type.updatedAt = now();
    widget.group.updatedAt = now();

    await Storage.saveGroup(
      widget.group,
    );

    await Storage.clearAiByScope(
      printId: print.id,
      referenceIds: ids,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.name),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มพิมพ์'),
      ),
      body: Column(
        children: [
          PathBar(
            '${widget.group.name} > '
            '${widget.model.name} > '
            '${widget.type.name} > พิมพ์',
          ),
          Expanded(
            child: widget.type.prints.isEmpty
                ? const Center(
                    child: Text('ยังไม่มีพิมพ์'),
                  )
                : ListView.builder(
                    itemCount:
                        widget.type.prints.length,
                    itemBuilder: (_, index) {
                      final print =
                          widget.type.prints[index];

                      return Card(
                        child: ListTile(
                          title: Text(print.name),
                          subtitle: Text(
                            'องค์อ้างอิง '
                            '${print.references.length}',
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReferencePage(
                                  cameras:
                                      widget.cameras,
                                  group: widget.group,
                                  model: widget.model,
                                  type: widget.type,
                                  print: print,
                                ),
                              ),
                            );

                            if (mounted) {
                              setState(() {});
                            }
                          },
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    edit(print),
                                icon: const Icon(
                                  Icons.edit,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    delete(print),
                                icon: const Icon(
                                  Icons.delete,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// REFERENCE PAGE
// =====================================================

class ReferencePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;

  const ReferencePage({
    super.key,
    required this.cameras,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
  });

  @override
  State<ReferencePage> createState() =>
      _ReferencePageState();
}

class _ReferencePageState
    extends State<ReferencePage> {
  Future<int> nextNumber() async {
    final groups = await Storage.groups();

    var max = 0;

    for (final group in groups) {
      for (final link in Storage.links(group)) {
        if (link.reference.referenceNumber > max) {
          max = link.reference.referenceNumber;
        }
      }
    }

    return max + 1;
  }

  Future<void> addReference() async {
    final number = await nextNumber();
    final date = now();

    widget.print.references.add(
      ReferenceData(
        id: newId(),
        referenceNumber: number,
        createdAt: date,
        updatedAt: date,
      ),
    );

    widget.print.updatedAt = date;
    widget.type.updatedAt = date;
    widget.model.updatedAt = date;
    widget.group.updatedAt = date;

    await Storage.saveGroup(
      widget.group,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> editReference(
    ReferenceData reference,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReferenceEditPage(
          cameras: widget.cameras,
          group: widget.group,
          model: widget.model,
          type: widget.type,
          print: widget.print,
          reference: reference,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> deleteReference(
    ReferenceData reference,
  ) async {
    if (!await confirmDelete(
      context,
      'องค์อ้างอิง #'
          '${reference.referenceNumber}',
    )) {
      return;
    }

    widget.print.references.removeWhere(
      (e) => e.id == reference.id,
    );

    widget.print.updatedAt = now();
    widget.group.updatedAt = now();

    await Storage.saveGroup(
      widget.group,
    );

    await Storage.deleteReference(
      reference,
    );

    if (mounted) {
      setState(() {});
    }
  }

  String status(
    ReferenceData reference,
  ) {
    final areas =
        scanAreasForType(widget.type.name);

    final done = areas.where(
      (area) {
        return reference.scans.any(
          (scan) =>
              scan.area == area &&
              scan.details.trim().isNotEmpty,
        );
      },
    ).length;

    return '$done/${areas.length} ด้าน';
  }

  @override
  Widget build(BuildContext context) {
    final areas =
        scanAreasForType(widget.type.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.print.name),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addReference,
        icon: const Icon(Icons.add),
        label: const Text(
          'เพิ่มองค์อ้างอิง',
        ),
      ),
      body: Column(
        children: [
          PathBar(
            '${widget.group.name} > '
            '${widget.model.name} > '
            '${widget.type.name} > '
            '${widget.print.name}',
          ),

          Expanded(
            child: widget.print.references.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีองค์อ้างอิง',
                    ),
                  )
                : ListView.builder(
                    itemCount:
                        widget.print.references.length,
                    itemBuilder: (_, index) {
                      final reference =
                          widget.print.references[
                              index];

                      return Card(
                        margin:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ExpansionTile(
                          title: Text(
                            'องค์อ้างอิง #'
                            '${reference.referenceNumber}',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle:
                              Text(status(reference)),
                          children: [
                            ...areas.map(
                              (area) {
                                final scan =
                                    firstWhereOrNull(
                                  reference.scans,
                                  (e) =>
                                      e.area == area,
                                );

                                return ListTile(
                                  title:
                                      Text(area),
                                  subtitle: Text(
                                    scan == null ||
                                            scan.details
                                                .trim()
                                                .isEmpty
                                        ? 'ยังไม่มีข้อมูล'
                                        : 'มีข้อมูลแล้ว',
                                  ),
                                );
                              },
                            ),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      editReference(
                                    reference,
                                  ),
                                  icon: const Icon(
                                    Icons.edit,
                                  ),
                                  label: const Text(
                                    'แก้ไข',
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                IconButton(
                                  onPressed: () =>
                                      deleteReference(
                                    reference,
                                  ),
                                  icon: const Icon(
                                    Icons.delete,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 8,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                ),
                child: const Text(
                  'กลับหน้ากลุ่ม',
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
// REFERENCE EDIT
// =====================================================

class ReferenceEditPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;

  const ReferenceEditPage({
    super.key,
    required this.cameras,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
  });

  @override
  State<ReferenceEditPage> createState() =>
      _ReferenceEditPageState();
}

class _ReferenceEditPageState
    extends State<ReferenceEditPage> {
  ScanResult? getScan(String area) {
    return firstWhereOrNull(
      widget.reference.scans,
      (scan) => scan.area == area,
    );
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

    widget.reference.updatedAt = now();
    widget.group.updatedAt = now();

    await Storage.saveGroup(
      widget.group,
    );

    await Storage.syncScan(
      group: widget.group,
      model: widget.model,
      type: widget.type,
      print: widget.print,
      reference: widget.reference,
      scan: result,
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
          'องค์อ้างอิง #'
          '${widget.reference.referenceNumber}',
        ),
      ),
      body: Column(
        children: [
          PathBar(
            '${widget.group.name} > '
            '${widget.model.name} > '
            '${widget.type.name} > '
            '${widget.print.name}',
          ),

          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.all(10),
              children: [
                Text(
                  'องค์อ้างอิง #'
                  '${widget.reference.referenceNumber}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                ...areas.map(
                  (area) {
                    final scan =
                        getScan(area);

                    final hasData =
                        scan != null &&
                        scan.details
                            .trim()
                            .isNotEmpty;

                    return Card(
                      child: ListTile(
                        title: Text(area),
                        subtitle: Text(
                          hasData
                              ? 'มีข้อมูลสแกนแล้ว'
                              : 'ยังไม่มีข้อมูล',
                        ),
                        trailing:
                            ElevatedButton(
                          onPressed: () =>
                              scanArea(area),
                          child: Text(
                            hasData
                                ? 'แก้ไข'
                                : 'สแกน',
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

// =====================================================
// SCAN PAGE
// =====================================================

class ScanPage extends StatelessWidget {
  final List<CameraDescription> cameras;
  final String area;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;

  const ScanPage({
    super.key,
    required this.cameras,
    required this.area,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
  });

  Future<void> gallery(
    BuildContext context,
  ) async {
    final file =
        await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (file == null) return;

    File? temp;

    try {
      temp = File(
        '${Directory.systemTemp.path}/'
        'amulet_scan_${newId()}.jpg',
      );

      await File(file.path).copy(
        temp.path,
      );

      final result =
          await Navigator.push<ScanResult>(
        context,
        MaterialPageRoute(
          builder: (_) => AiVisionPage(
            imageFile: XFile(temp!.path),
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
        if (temp != null &&
            await temp.exists()) {
          await temp.delete();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สแกน $area'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 70,
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: cameras.isEmpty
                  ? null
                  : () async {
                      final result =
                          await Navigator.push<
                              ScanResult>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CameraScanPage(
                            cameras: cameras,
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
                    },
              icon: const Icon(
                Icons.camera,
              ),
              label: const Text(
                'เปิดกล้อง',
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: () =>
                  gallery(context),
              icon: const Icon(
                Icons.photo_library,
              ),
              label: const Text(
                'เลือกจาก Gallery',
              ),
            ),

            const SizedBox(height: 20),

            const Padding(
              padding:
                  EdgeInsets.all(20),
              child: Text(
                'ภาพใช้ชั่วคราวเพื่อวิเคราะห์เท่านั้น\n'
                'แอปจะไม่เก็บรูปไว้ในฐานข้อมูล',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// CAMERA SCAN
// =====================================================

class CameraScanPage
    extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String area;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;

  const CameraScanPage({
    super.key,
    required this.cameras,
    required this.area,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
  });

  @override
  State<CameraScanPage> createState() =>
      _CameraScanPageState();
}

class _CameraScanPageState
    extends State<CameraScanPage> {
  CameraController? controller;
  Future<void>? initializeFuture;
  bool busy = false;

  @override
  void initState() {
    super.initState();

    if (widget.cameras.isEmpty) {
      return;
    }

    controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    initializeFuture =
        controller!.initialize();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> take() async {
    final camera = controller;

    if (busy ||
        camera == null ||
        !camera.value.isInitialized) {
      return;
    }

    setState(() => busy = true);

    XFile? file;

    try {
      file = await camera.takePicture();

      final result =
          await Navigator.push<ScanResult>(
        context,
        MaterialPageRoute(
          builder: (_) => AiVisionPage(
            imageFile: file!,
            area: widget.area,
            group: widget.group,
            model: widget.model,
            type: widget.type,
            print: widget.print,
            reference: widget.reference,
          ),
        ),
      );

      if (result != null &&
          mounted) {
        Navigator.pop(
          context,
          result,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถถ่ายภาพได้: $e',
            ),
          ),
        );
      }
    } finally {
      try {
        if (file != null) {
          final temp =
              File(file.path);

          if (await temp.exists()) {
            await temp.delete();
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = controller;

    if (camera == null ||
        initializeFuture == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'ไม่พบกล้อง',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'กล้อง - ${widget.area}',
        ),
      ),
      body: FutureBuilder<void>(
        future: initializeFuture,
        builder: (_, snapshot) {
          if (snapshot.connectionState !=
                  ConnectionState.done ||
              !camera.value.isInitialized) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(camera),

              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton(
                    onPressed:
                        busy ? null : take,
                    child: busy
                        ? const CircularProgressIndicator()
                        : const Icon(
                            Icons.camera,
                          ),
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

// =====================================================
// AI VISION / DETAIL
// =====================================================

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
    super.key,
    required this.imageFile,
    required this.area,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
  });

  @override
  State<AiVisionPage> createState() =>
      _AiVisionPageState();
}

class _AiVisionPageState
    extends State<AiVisionPage> {
  final Map<String, TextEditingController>
      controllers = {};

  @override
  void initState() {
    super.initState();

    for (final head in aiHeads) {
      controllers[head] =
          TextEditingController();
    }

    final old = firstWhereOrNull(
      widget.reference.scans,
      (scan) =>
          scan.area == widget.area,
    );

    if (old != null) {
      final lines =
          old.details.split('\n');

      for (final head in aiHeads) {
        final line = firstWhereOrNull(
          lines,
          (value) =>
              value.startsWith('$head:'),
        );

        if (line != null) {
          controllers[head]!.text =
              line.substring(
            head.length + 1,
          ).trim();
        }
      }

      if (lines.isNotEmpty &&
          controllers.values.every(
            (controller) =>
                controller.text
                    .trim()
                    .isEmpty,
          )) {
        controllers[aiHeads.first]!.text =
            old.details;
      }
    }
  }

  @override
  void dispose() {
    for (final controller
        in controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  String buildDetails() {
    final output = <String>[];

    for (final head in aiHeads) {
      final value =
          controllers[head]!.text.trim();

      if (value.isNotEmpty) {
        output.add(
          '$head: $value',
        );
      }
    }

    return output.join('\n');
  }

  void save() {
    final details =
        buildDetails().trim();

    if (details.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณากรอกรายละเอียดอย่างน้อย 1 ช่อง',
          ),
        ),
      );
      return;
    }

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
        title: Text(
          'รายละเอียด ${widget.area}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Image.file(
            File(widget.imageFile.path),
            height: 260,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 10),

          ...aiHeads.map(
            (head) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: TextField(
                controller:
                    controllers[head],
                maxLines: 3,
                decoration:
                    InputDecoration(
                  labelText: head,
                  border:
                      const OutlineInputBorder(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: save,
              icon: const Icon(
                Icons.save,
              ),
              label: const Text(
                'บันทึกข้อมูล',
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
