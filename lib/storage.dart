// =====================================================
// STORAGE
// =====================================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'scan_data.dart';

// =====================================================
// STORAGE
// =====================================================

class Storage {
  static const key = 'reference_data';
  static const legacyKey = 'amulet_data';

  // ตัวเดิมเก็บเลขรวมทั้งระบบ
  // จะไม่ใช้กับระบบเลของค์อ้างอิงแบบใหม่แล้ว
  static const counterKey = 'last_reference_number';

  // AI MEMORY
  static const aiKnowledgeKey = 'ai_knowledge';
  static const aiHistoryKey = 'ai_learning_history';
  static const aiMemoryTestsKey = 'ai_memory_tests';
  static const aiTestResultsKey = 'ai_test_results';

  // ===================================================
  // GROUPS
  // ===================================================

  static Future<List<GroupData>> groups() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);

    if (raw != null && raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw);

        if (data is List) {
          return data
              .whereType<Map>()
              .map(
                (e) => GroupData.fromMap(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList();
        }
      } catch (_) {}
    }

    final legacy = prefs.getString(legacyKey);

    if (legacy != null && legacy.isNotEmpty) {
      try {
        final data = jsonDecode(legacy);

        if (data is List) {
          final result = <GroupData>[];

          for (final item in data) {
            if (item is! Map) continue;

            final group = _legacyToGroup(
              Map<String, dynamic>.from(item),
            );

            if (group != null) {
              result.add(group);
            }
          }

          if (result.isNotEmpty) {
            await saveGroups(result);
          }

          return result;
        }
      } catch (_) {}
    }

    return [];
  }

  static Future<bool> saveGroups(
    List<GroupData> groups,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return prefs.setString(
        key,
        jsonEncode(
          groups.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> addGroup(
    GroupData group,
  ) async {
    final list = await groups();

    list.add(group);

    return saveGroups(list);
  }

  static Future<bool> updateGroup(
    GroupData group,
  ) async {
    final list = await groups();

    final i = list.indexWhere(
      (e) => e.id == group.id,
    );

    if (i < 0) return false;

    list[i] = group;

    return saveGroups(list);
  }

  static Future<bool> deleteGroup(
    String groupId,
  ) async {
    final list = await groups();

    list.removeWhere(
      (e) => e.id == groupId,
    );

    return saveGroups(list);
  }

  // ===================================================
  // REFERENCE NUMBER
  // ===================================================
  //
  // ระบบใหม่:
  // เลของค์อ้างอิงแยกตาม GROUP
  //
  // กลุ่ม A -> #1 #2 #3
  // กลุ่ม B -> #1 #2
  //
  // ลบ #2 ของกลุ่ม A
  // แล้วสร้างใหม่ -> #4
  //
  // ไม่ใช้เลขร่วมกันระหว่างกลุ่ม
  // ===================================================

  static String _groupCounterKey(
    String groupId,
  ) {
    return 'last_reference_number_group_$groupId';
  }

  static Future<int> nextReferenceNumber({
    required String groupId,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final counterKey =
        _groupCounterKey(groupId);

    // -------------------------------------------------
    // อ่านตัวนับเดิมของกลุ่ม
    // -------------------------------------------------

    final stored =
        prefs.getInt(counterKey);

    // -------------------------------------------------
    // ถ้ายังไม่เคยมีตัวนับ
    // ให้ตรวจเลขที่มีอยู่จริงในกลุ่มก่อน
    //
    // เพื่อรองรับข้อมูลเก่าที่สร้างไว้ก่อนระบบนี้
    // -------------------------------------------------

    int current = stored ?? 0;

    if (stored == null) {
      final list = await groups();

      final group = _findGroup(
        list,
        groupId,
      );

      if (group != null) {
        for (final model in group.models) {
          for (final type in model.types) {
            for (final print in type.prints) {
              for (final reference
                  in print.references) {
                if (reference.referenceNumber >
                    current) {
                  current =
                      reference.referenceNumber;
                }
              }
            }
          }
        }
      }
    }

    final next = current + 1;

    await prefs.setInt(
      counterKey,
      next,
    );

    return next;
  }

  static Future<int> currentReferenceNumber({
    required String groupId,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getInt(
          _groupCounterKey(groupId),
        ) ??
        0;
  }

  // ===================================================
  // SAVE REFERENCE
  // ===================================================

  static Future<bool> saveReference({
    required String groupId,
    required String modelId,
    required String typeId,
    required String printId,
    required ReferenceData reference,
  }) async {
    final list = await groups();

    final group = _findGroup(
      list,
      groupId,
    );

    if (group == null) return false;

    final model = _findModel(
      group,
      modelId,
    );

    if (model == null) return false;

    final type = _findType(
      model,
      typeId,
    );

    if (type == null) return false;

    final print = _findPrint(
      type,
      printId,
    );

    if (print == null) return false;

    final i = print.references.indexWhere(
      (e) => e.id == reference.id,
    );

    if (i >= 0) {
      print.references[i] = reference;
    } else {
      print.references.add(reference);
    }

    final time = now();

    print.updatedAt = time;
    type.updatedAt = time;
    model.updatedAt = time;
    group.updatedAt = time;

    return saveGroups(list);
  }

  // ===================================================
  // DELETE REFERENCE
  // ===================================================

  static Future<bool> deleteReference({
    required String groupId,
    required String modelId,
    required String typeId,
    required String printId,
    required String referenceId,
  }) async {
    final list = await groups();

    final group = _findGroup(
      list,
      groupId,
    );

    if (group == null) return false;

    final model = _findModel(
      group,
      modelId,
    );

    if (model == null) return false;

    final type = _findType(
      model,
      typeId,
    );

    if (type == null) return false;

    final print = _findPrint(
      type,
      printId,
    );

    if (print == null) return false;

    print.references.removeWhere(
      (e) => e.id == referenceId,
    );

    final time = now();

    print.updatedAt = time;
    type.updatedAt = time;
    model.updatedAt = time;
    group.updatedAt = time;

    return saveGroups(list);
  }

  // ===================================================
  // DELETE PRINT
  // ===================================================

  static Future<bool> deletePrint({
    required String groupId,
    required String modelId,
    required String typeId,
    required String printId,
  }) async {
    final list = await groups();

    final group = _findGroup(
      list,
      groupId,
    );

    if (group == null) return false;

    final model = _findModel(
      group,
      modelId,
    );

    if (model == null) return false;

    final type = _findType(
      model,
      typeId,
    );

    if (type == null) return false;

    type.prints.removeWhere(
      (e) => e.id == printId,
    );

    final time = now();

    type.updatedAt = time;
    model.updatedAt = time;
    group.updatedAt = time;

    return saveGroups(list);
  }

  // ===================================================
  // DELETE TYPE
  // ===================================================

  static Future<bool> deleteType({
    required String groupId,
    required String modelId,
    required String typeId,
  }) async {
    final list = await groups();

    final group = _findGroup(
      list,
      groupId,
    );

    if (group == null) return false;

    final model = _findModel(
      group,
      modelId,
    );

    if (model == null) return false;

    model.types.removeWhere(
      (e) => e.id == typeId,
    );

    final time = now();

    model.updatedAt = time;
    group.updatedAt = time;

    return saveGroups(list);
  }

  // ===================================================
  // DELETE MODEL
  // ===================================================

  static Future<bool> deleteModel({
    required String groupId,
    required String modelId,
  }) async {
    final list = await groups();

    final group = _findGroup(
      list,
      groupId,
    );

    if (group == null) return false;

    group.models.removeWhere(
      (e) => e.id == modelId,
    );

    group.updatedAt = now();

    return saveGroups(list);
  }

  // ===================================================
  // COPY GROUP
  // ===================================================

  static GroupData copyGroup(
    GroupData source,
  ) =>
      _copyGroup(source);

  // ===================================================
  // AI KNOWLEDGE
  // ===================================================

  static Future<List<AiKnowledge>>
      aiKnowledge() async {
    final prefs =
        await SharedPreferences.getInstance();

    final raw =
        prefs.getString(aiKnowledgeKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final data = jsonDecode(raw);

      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (e) => AiKnowledge.fromMap(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }
    } catch (_) {}

    return [];
  }

  static Future<bool> saveAiKnowledge(
    AiKnowledge item,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final list =
          await aiKnowledge();

      final i = list.indexWhere(
        (e) =>
            e.groupId == item.groupId &&
            e.modelId == item.modelId &&
            e.typeId == item.typeId &&
            e.printId == item.printId &&
            e.referenceId ==
                item.referenceId &&
            e.area == item.area,
      );

      if (i >= 0) {
        list[i] = item;
      } else {
        list.add(item);
      }

      return prefs.setString(
        aiKnowledgeKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteAiKnowledge({
    required String groupId,
    required String modelId,
    required String typeId,
    required String printId,
    required String referenceId,
    required String area,
  }) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final list =
          await aiKnowledge();

      list.removeWhere(
        (e) =>
            e.groupId == groupId &&
            e.modelId == modelId &&
            e.typeId == typeId &&
            e.printId == printId &&
            e.referenceId ==
                referenceId &&
            e.area == area,
      );

      return prefs.setString(
        aiKnowledgeKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ===================================================
  // AI LEARNING HISTORY
  // ===================================================

  static Future<List<AiLearningHistory>>
      aiLearningHistory() async {
    final prefs =
        await SharedPreferences.getInstance();

    final raw =
        prefs.getString(aiHistoryKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final data = jsonDecode(raw);

      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (e) => AiLearningHistory.fromMap(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }
    } catch (_) {}

    return [];
  }

  static Future<bool> saveAiLearningHistory(
    AiLearningHistory item,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final list =
          await aiLearningHistory();

      list.add(item);

      return prefs.setString(
        aiHistoryKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ===================================================
  // LEARN FROM SCAN
  // ===================================================

  static Future<bool> learnFromScan({
    required String groupId,
    required String modelId,
    required String typeId,
    required String printId,
    required String referenceId,
    required String area,
    required String content,
  }) async {
    final clean = content.trim();

    if (clean.isEmpty) {
      return deleteAiKnowledge(
        groupId: groupId,
        modelId: modelId,
        typeId: typeId,
        printId: printId,
        referenceId: referenceId,
        area: area,
      );
    }

    final existing =
        await aiKnowledge();

    final oldIndex =
        existing.indexWhere(
      (e) =>
          e.groupId == groupId &&
          e.modelId == modelId &&
          e.typeId == typeId &&
          e.printId == printId &&
          e.referenceId ==
              referenceId &&
          e.area == area,
    );

    final time = now();

    final knowledge = AiKnowledge(
      id: oldIndex >= 0
          ? existing[oldIndex].id
          : newId(),
      groupId: groupId,
      modelId: modelId,
      typeId: typeId,
      printId: printId,
      referenceId: referenceId,
      area: area,
      content: clean,
      createdAt: oldIndex >= 0
          ? existing[oldIndex].createdAt
          : time,
      updatedAt: time,
    );

    if (!await saveAiKnowledge(
      knowledge,
    )) {
      return false;
    }

    final changed =
        oldIndex < 0 ||
        existing[oldIndex].content.trim() !=
            clean;

    if (changed) {
      await saveAiLearningHistory(
        AiLearningHistory(
          id: newId(),
          groupId: groupId,
          modelId: modelId,
          typeId: typeId,
          printId: printId,
          referenceId: referenceId,
          area: area,
          content: clean,
          learnedAt: time,
        ),
      );
    }

    return true;
  }

  // ===================================================
  // FIND AI KNOWLEDGE
  // ===================================================

  static Future<List<AiKnowledge>>
      findAiKnowledge({
    String? groupId,
    String? modelId,
    String? typeId,
    String? printId,
    String? area,
  }) async {
    final list =
        await aiKnowledge();

    return list.where((e) {
      if (groupId != null &&
          e.groupId != groupId) {
        return false;
      }

      if (modelId != null &&
          e.modelId != modelId) {
        return false;
      }

      if (typeId != null &&
          e.typeId != typeId) {
        return false;
      }

      if (printId != null &&
          e.printId != printId) {
        return false;
      }

      if (area != null &&
          e.area != area) {
        return false;
      }

      return true;
    }).toList();
  }

  // ===================================================
  // FIND COMPARABLE AI MEMORY
  // ===================================================

  static Future<List<AiKnowledge>>
      findComparableAiMemory({
    required String groupId,
    required String modelId,
    required String typeId,
    required String printId,
    required String referenceId,
    String? area,
  }) async {
    final list =
        await findAiKnowledge(
      groupId: groupId,
      modelId: modelId,
      typeId: typeId,
      printId: printId,
      area: area,
    );

    return list
        .where(
          (e) =>
              e.referenceId !=
                  referenceId &&
              e.content.trim().isNotEmpty,
        )
        .toList();
  }

  // ===================================================
  // AI MEMORY TESTS
  // ===================================================

  static Future<List<AiMemoryTest>>
      aiMemoryTests() async {
    final prefs =
        await SharedPreferences.getInstance();

    final raw =
        prefs.getString(aiMemoryTestsKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final data = jsonDecode(raw);

      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (e) => AiMemoryTest.fromMap(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }
    } catch (_) {}

    return [];
  }

  static Future<bool> saveAiMemoryTest(
    AiMemoryTest item,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final list =
          await aiMemoryTests();

      final i = list.indexWhere(
        (e) => e.id == item.id,
      );

      if (i >= 0) {
        list[i] = item;
      } else {
        list.add(item);
      }

      return prefs.setString(
        aiMemoryTestsKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteAiMemoryTest(
    String testId,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final list =
          await aiMemoryTests();

      list.removeWhere(
        (e) => e.id == testId,
      );

      return prefs.setString(
        aiMemoryTestsKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<List<AiMemoryTest>>
      findAiMemoryTestsByReference(
    String referenceId,
  ) async {
    final list =
        await aiMemoryTests();

    return list
        .where(
          (e) => e.referenceId == referenceId,
        )
        .toList();
  }

  // ===================================================
  // AI TEST RESULTS
  // ===================================================

  static Future<List<AiTestResult>>
      aiTestResults() async {
    final prefs =
        await SharedPreferences.getInstance();

    final raw =
        prefs.getString(aiTestResultsKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final data = jsonDecode(raw);

      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (e) => AiTestResult.fromMap(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }
    } catch (_) {}

    return [];
  }

  static Future<bool> saveAiTestResult(
    AiTestResult item,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final list =
          await aiTestResults();

      final i = list.indexWhere(
        (e) => e.id == item.id,
      );

      if (i >= 0) {
        list[i] = item;
      } else {
        list.add(item);
      }

      return prefs.setString(
        aiTestResultsKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteAiTestResult(
    String resultId,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final list =
          await aiTestResults();

      list.removeWhere(
        (e) => e.id == resultId,
      );

      return prefs.setString(
        aiTestResultsKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<List<AiTestResult>>
      findAiTestResultsByTest(
    String testId,
  ) async {
    final list =
        await aiTestResults();

    return list
        .where(
          (e) => e.testId == testId,
        )
        .toList();
  }

  static Future<List<AiTestResult>>
      findAiTestResultsByReference(
    String referenceId,
  ) async {
    final list =
        await aiTestResults();

    return list
        .where(
          (e) => e.referenceId == referenceId,
        )
        .toList();
  }

  // ===================================================
  // COMPARE AI MEMORY
  // ===================================================

  static Future<List<AiTestResult>>
      compareAiMemory({
    required String groupId,
    required String modelId,
    required String typeId,
    required String printId,
    required String referenceId,
    required String area,
    required String currentContent,
  }) async {
    final current =
        currentContent.trim();

    if (current.isEmpty) {
      return [];
    }

    final memories =
        await findComparableAiMemory(
      groupId: groupId,
      modelId: modelId,
      typeId: typeId,
      printId: printId,
      referenceId: referenceId,
      area: area,
    );

    if (memories.isEmpty) {
      return [];
    }

    final results =
        <AiTestResult>[];

    for (final memory in memories) {
      final testId = newId();
      final time = now();

      final comparison =
          _compareText(
        current,
        memory.content,
      );

      await saveAiMemoryTest(
        AiMemoryTest(
          id: testId,
          knowledgeId: memory.id,
          referenceId: referenceId,
          area: area,
          question:
              'เปรียบเทียบข้อมูลด้าน $area '
              'กับข้อมูลอ้างอิง '
              '${memory.referenceId}',
          answer: current,
          testedAt: time,
        ),
      );

      final result = AiTestResult(
        id: newId(),
        testId: testId,
        knowledgeId: memory.id,
        referenceId: referenceId,
        area: area,
        mode: 'text_compare',
        result:
            comparison['result'] ?? '',
        answer: current,
        referenceAnswer:
            memory.content,
        reason:
            comparison['reason'] ?? '',
        checkedAt: time,
      );

      await saveAiTestResult(
        result,
      );

      results.add(result);
    }

    return results;
  }

  // ===================================================
  // BASIC TEXT COMPARISON
  // ===================================================

  static Map<String, String> _compareText(
    String current,
    String reference,
  ) {
    final a = _textWords(current);
    final b = _textWords(reference);

    if (a.isEmpty || b.isEmpty) {
      return {
        'result': 'ไม่เพียงพอ',
        'reason':
            'ข้อมูลที่ใช้เปรียบเทียบไม่เพียงพอ',
      };
    }

    final common =
        a.intersection(b);

    final all = {...a, ...b};

    if (all.isEmpty) {
      return {
        'result': 'ไม่พบข้อมูลร่วม',
        'reason':
            'ไม่พบข้อมูลร่วมกัน',
      };
    }

    final score =
        common.length / all.length;

    final percent =
        (score * 100).round();

    String result;

    if (score >= 0.70) {
      result =
          'ข้อมูลใกล้เคียงกัน';
    } else if (score >= 0.40) {
      result =
          'มีข้อมูลบางส่วนตรงกัน';
    } else {
      result =
          'ข้อมูลแตกต่างกัน';
    }

    return {
      'result': result,
      'reason':
          'พบข้อมูลร่วมกันประมาณ '
          '$percent%',
    };
  }

  // ===================================================
  // TEXT WORDS
  // ===================================================

  static Set<String> _textWords(
    String text,
  ) {
    final cleaned = text
        .toLowerCase()
        .replaceAll(
          RegExp(
            r'[^\u0E00-\u0E7Fa-zA-Z0-9]+',
          ),
          ' ',
        )
        .trim();

    if (cleaned.isEmpty) {
      return {};
    }

    return cleaned
        .split(RegExp(r'\s+'))
        .where(
          (e) => e.trim().isNotEmpty,
        )
        .toSet();
  }

  // ===================================================
  // FIND GROUP
  // ===================================================

  static GroupData? _findGroup(
    List<GroupData> list,
    String id,
  ) {
    for (final group in list) {
      if (group.id == id) {
        return group;
      }
    }

    return null;
  }

  // ===================================================
  // FIND MODEL
  // ===================================================

  static ModelData? _findModel(
    GroupData group,
    String id,
  ) {
    for (final model in group.models) {
      if (model.id == id) {
        return model;
      }
    }

    return null;
  }

  // ===================================================
  // FIND TYPE
  // ===================================================

  static TypeData? _findType(
    ModelData model,
    String id,
  ) {
    for (final type in model.types) {
      if (type.id == id) {
        return type;
      }
    }

    return null;
  }

  // ===================================================
  // FIND PRINT
  // ===================================================

  static PrintData? _findPrint(
    TypeData type,
    String id,
  ) {
    for (final print in type.prints) {
      if (print.id == id) {
        return print;
      }
    }

    return null;
  }

  // ===================================================
  // LEGACY CONVERTER
  // ===================================================

  static GroupData? _legacyToGroup(
    Map<String, dynamic> m,
  ) {
    try {
      final created =
          m['createdAt']?.toString() ??
              now();

      final group = GroupData(
        id: newId(),
        name:
            m['name']?.toString() ?? '',
        temple:
            m['temple']?.toString() ?? '',
        createdAt: created,
        updatedAt: now(),
      );

      final model = ModelData(
        id: newId(),
        name:
            m['model']?.toString() ?? '',
        createdAt: created,
        updatedAt: now(),
      );

      final type = TypeData(
        id: newId(),
        name:
            m['type']?.toString() ?? '',
        createdAt: created,
        updatedAt: now(),
      );

      final print = PrintData(
        id: newId(),
        name:
            m['pim']?.toString() ?? '',
        createdAt: created,
        updatedAt: now(),
      );

      final reference = ReferenceData(
        id:
            m['id']?.toString() ??
                newId(),
        referenceNumber:
            m['referenceNumber']
                    is int
                ? m['referenceNumber']
                    as int
                : 1,
        createdAt: created,
        updatedAt: now(),
        scans: mapList<ScanResult>(
          m['scans'],
          ScanResult.fromMap,
        ),
      );

      print.references.add(
        reference,
      );

      type.prints.add(
        print,
      );

      model.types.add(
        type,
      );

      group.models.add(
        model,
      );

      return group;
    } catch (_) {
      return null;
    }
  }
}

// =====================================================
// COPY GROUP
// =====================================================

GroupData _copyGroup(
  GroupData source,
) {
  final group = GroupData(
    id: newId(),
    name: source.name,
    temple: source.temple,
    createdAt: now(),
    updatedAt: now(),
  );

  for (final sourceModel
      in source.models) {
    final model = ModelData(
      id: newId(),
      name: sourceModel.name,
      createdAt: now(),
      updatedAt: now(),
    );

    for (final sourceType
        in sourceModel.types) {
      final type = TypeData(
        id: newId(),
        name: sourceType.name,
        createdAt: now(),
        updatedAt: now(),
      );

      for (final sourcePrint
          in sourceType.prints) {
        final print = PrintData(
          id: newId(),
          name: sourcePrint.name,
          createdAt: now(),
          updatedAt: now(),
        );

        for (final sourceReference
            in sourcePrint.references) {
          final reference =
              ReferenceData(
            id: newId(),
            referenceNumber:
                sourceReference
                    .referenceNumber,
            createdAt: now(),
            updatedAt: now(),
            scans: sourceReference.scans
                .map(
                  (scan) => ScanResult(
                    area: scan.area,
                    details:
                        scan.details,
                  ),
                )
                .toList(),
          );

          print.references.add(
            reference,
          );
        }

        type.prints.add(
          print,
        );
      }

      model.types.add(
        type,
      );
    }

    group.models.add(
      model,
    );
  }

  return group;
}

// =====================================================
// END STORAGE
// =====================================================
