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
  static const String key = 'reference_data';
  static const String legacyKey = 'amulet_data';
  static const String counterKey = 'last_reference_number';

  // ===================================================
  // AI MEMORY KEYS
  // ===================================================

  static const String aiKnowledgeKey = 'ai_knowledge';
  static const String aiHistoryKey = 'ai_learning_history';

  // ---------------------------------------------------
  // AI MEMORY TEST KEYS
  // ---------------------------------------------------

  static const String aiMemoryTestsKey = 'ai_memory_tests';
  static const String aiTestResultsKey = 'ai_test_results';

  // ===================================================
  // LOAD GROUPS
  // ===================================================

  static Future<List<GroupData>> groups() async {
    final prefs = await SharedPreferences.getInstance();

    // -------------------------------------------------
    // ข้อมูลรูปแบบใหม่
    // -------------------------------------------------

    final raw = prefs.getString(key);

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map(
                (e) => GroupData.fromMap(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList();
        }
      } catch (_) {
        // ถ้าอ่านไม่ได้ ให้ลองข้อมูลเก่า
      }
    }

    // -------------------------------------------------
    // ข้อมูลรูปแบบเก่า
    // -------------------------------------------------

    final legacy = prefs.getString(legacyKey);

    if (legacy != null && legacy.isNotEmpty) {
      try {
        final decoded = jsonDecode(legacy);

        if (decoded is List) {
          final result = <GroupData>[];

          for (final item in decoded) {
            if (item is! Map) continue;

            final map = Map<String, dynamic>.from(item);

            final group = _legacyToGroup(map);

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

  // ===================================================
  // SAVE GROUPS
  // ===================================================

  static Future<bool> saveGroups(
    List<GroupData> groups,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final data = groups
          .map(
            (e) => e.toMap(),
          )
          .toList();

      return await prefs.setString(
        key,
        jsonEncode(data),
      );
    } catch (_) {
      return false;
    }
  }

  // ===================================================
  // ADD GROUP
  // ===================================================

  static Future<bool> addGroup(
    GroupData group,
  ) async {
    final list = await groups();

    list.add(group);

    return saveGroups(list);
  }

  // ===================================================
  // UPDATE GROUP
  // ===================================================

  static Future<bool> updateGroup(
    GroupData group,
  ) async {
    final list = await groups();

    final index = list.indexWhere(
      (e) => e.id == group.id,
    );

    if (index < 0) {
      return false;
    }

    list[index] = group;

    return saveGroups(list);
  }

  // ===================================================
  // DELETE GROUP
  // ===================================================

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
  // NEXT REFERENCE NUMBER
  // ===================================================

  static Future<int> nextReferenceNumber() async {
    final prefs = await SharedPreferences.getInstance();

    final last = prefs.getInt(counterKey) ?? 0;

    final next = last + 1;

    await prefs.setInt(
      counterKey,
      next,
    );

    return next;
  }

  // ===================================================
  // CURRENT REFERENCE NUMBER
  // ===================================================

  static Future<int> currentReferenceNumber() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(counterKey) ?? 0;
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

    if (group == null) {
      return false;
    }

    final model = _findModel(
      group,
      modelId,
    );

    if (model == null) {
      return false;
    }

    final type = _findType(
      model,
      typeId,
    );

    if (type == null) {
      return false;
    }

    final print = _findPrint(
      type,
      printId,
    );

    if (print == null) {
      return false;
    }

    final index = print.references.indexWhere(
      (e) => e.id == reference.id,
    );

    if (index >= 0) {
      print.references[index] = reference;
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

    if (group == null) {
      return false;
    }

    final model = _findModel(
      group,
      modelId,
    );

    if (model == null) {
      return false;
    }

    final type = _findType(
      model,
      typeId,
    );

    if (type == null) {
      return false;
    }

    final print = _findPrint(
      type,
      printId,
    );

    if (print == null) {
      return false;
    }

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

    if (group == null) {
      return false;
    }

    final model = _findModel(
      group,
      modelId,
    );

    if (model == null) {
      return false;
    }

    final type = _findType(
      model,
      typeId,
    );

    if (type == null) {
      return false;
    }

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

    if (group == null) {
      return false;
    }

    final model = _findModel(
      group,
      modelId,
    );

    if (model == null) {
      return false;
    }

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

    if (group == null) {
      return false;
    }

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
  ) {
    return _copyGroup(source);
  }

  // ===================================================
  // AI MEMORY
  // ===================================================

  // ---------------------------------------------------
  // LOAD AI KNOWLEDGE
  // ---------------------------------------------------

  static Future<List<AiKnowledge>> aiKnowledge() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(aiKnowledgeKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        return decoded
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

  // ---------------------------------------------------
  // SAVE AI KNOWLEDGE
  // ---------------------------------------------------

  static Future<bool> saveAiKnowledge(
    AiKnowledge item,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final list = await aiKnowledge();

      final index = list.indexWhere(
        (e) =>
            e.groupId == item.groupId &&
            e.modelId == item.modelId &&
            e.typeId == item.typeId &&
            e.printId == item.printId &&
            e.referenceId == item.referenceId &&
            e.area == item.area,
      );

      if (index >= 0) {
        list[index] = item;
      } else {
        list.add(item);
      }

      return await prefs.setString(
        aiKnowledgeKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------
  // DELETE AI KNOWLEDGE
  // ---------------------------------------------------

  static Future<bool> deleteAiKnowledge({
    required String groupId,
    required String modelId,
    required String typeId,
    required String printId,
    required String referenceId,
    required String area,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final list = await aiKnowledge();

      list.removeWhere(
        (e) =>
            e.groupId == groupId &&
            e.modelId == modelId &&
            e.typeId == typeId &&
            e.printId == printId &&
            e.referenceId == referenceId &&
            e.area == area,
      );

      return await prefs.setString(
        aiKnowledgeKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------
  // LOAD AI LEARNING HISTORY
  // ---------------------------------------------------

  static Future<List<AiLearningHistory>> aiLearningHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(aiHistoryKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        return decoded
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

  // ---------------------------------------------------
  // SAVE AI LEARNING HISTORY
  // ---------------------------------------------------

  static Future<bool> saveAiLearningHistory(
    AiLearningHistory item,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final list = await aiLearningHistory();

      list.add(item);

      return await prefs.setString(
        aiHistoryKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------
  // LEARN FROM SCAN
  // ---------------------------------------------------

  static Future<bool> learnFromScan({
    required String groupId,
    required String modelId,
    required String typeId,
    required String printId,
    required String referenceId,
    required String area,
    required String content,
  }) async {
    final cleanContent = content.trim();

    // -----------------------------------------------
    // ถ้าไม่มีข้อความ
    // ให้ลบความจำของด้านนั้นออก
    // -----------------------------------------------

    if (cleanContent.isEmpty) {
      return deleteAiKnowledge(
        groupId: groupId,
        modelId: modelId,
        typeId: typeId,
        printId: printId,
        referenceId: referenceId,
        area: area,
      );
    }

    final existing = await aiKnowledge();

    final oldIndex = existing.indexWhere(
      (e) =>
          e.groupId == groupId &&
          e.modelId == modelId &&
          e.typeId == typeId &&
          e.printId == printId &&
          e.referenceId == referenceId &&
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
      content: cleanContent,
      createdAt: oldIndex >= 0
          ? existing[oldIndex].createdAt
          : time,
      updatedAt: time,
    );

    final saved = await saveAiKnowledge(
      knowledge,
    );

    if (!saved) {
      return false;
    }

    // -----------------------------------------------
    // บันทึกประวัติการเรียนรู้เฉพาะเมื่อข้อมูลเปลี่ยน
    // -----------------------------------------------

    final changed =
        oldIndex < 0 ||
        existing[oldIndex].content.trim() != cleanContent;

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
          content: cleanContent,
          learnedAt: time,
        ),
      );
    }

    return true;
  }

  // ===================================================
  // FIND AI KNOWLEDGE
  // ===================================================

  static Future<List<AiKnowledge>> findAiKnowledge({
    String? groupId,
    String? modelId,
    String? typeId,
    String? printId,
    String? area,
  }) async {
    final list = await aiKnowledge();

    return list.where((e) {
      if (groupId != null && e.groupId != groupId) {
        return false;
      }

      if (modelId != null && e.modelId != modelId) {
        return false;
      }

      if (typeId != null && e.typeId != typeId) {
        return false;
      }

      if (printId != null && e.printId != printId) {
        return false;
      }

      if (area != null && e.area != area) {
        return false;
      }

      return true;
    }).toList();
  }

  // ===================================================
  // FIND AI MEMORY FOR COMPARISON
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
    final list = await findAiKnowledge(
      groupId: groupId,
      modelId: modelId,
      typeId: typeId,
      printId: printId,
      area: area,
    );

    // -----------------------------------------------
    // ไม่เอาความจำขององค์ปัจจุบันมาเปรียบเทียบกับตัวเอง
    // -----------------------------------------------

    return list
        .where(
          (e) =>
              e.referenceId != referenceId &&
              e.content.trim().isNotEmpty,
        )
        .toList();
  }

  // ===================================================
  // AI MEMORY TEST
  // ===================================================

  // ---------------------------------------------------
  // LOAD AI MEMORY TESTS
  // ---------------------------------------------------

  static Future<List<AiMemoryTest>> aiMemoryTests() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(aiMemoryTestsKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        return decoded
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

  // ---------------------------------------------------
  // SAVE AI MEMORY TEST
  // ---------------------------------------------------

  static Future<bool> saveAiMemoryTest(
    AiMemoryTest item,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final list = await aiMemoryTests();

      final index = list.indexWhere(
        (e) => e.id == item.id,
      );

      if (index >= 0) {
        list[index] = item;
      } else {
        list.add(item);
      }

      return await prefs.setString(
        aiMemoryTestsKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------
  // DELETE AI MEMORY TEST
  // ---------------------------------------------------

  static Future<bool> deleteAiMemoryTest(
    String testId,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final list = await aiMemoryTests();

      list.removeWhere(
        (e) => e.id == testId,
      );

      return await prefs.setString(
        aiMemoryTestsKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------
  // FIND AI MEMORY TEST BY REFERENCE
  // ---------------------------------------------------

  static Future<List<AiMemoryTest>>
      findAiMemoryTestsByReference(
    String referenceId,
  ) async {
    final list = await aiMemoryTests();

    return list
        .where(
          (e) => e.referenceId == referenceId,
        )
        .toList();
  }

  // ===================================================
  // AI TEST RESULT
  // ===================================================

  // ---------------------------------------------------
  // LOAD AI TEST RESULTS
  // ---------------------------------------------------

  static Future<List<AiTestResult>> aiTestResults() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(aiTestResultsKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        return decoded
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

  // ---------------------------------------------------
  // SAVE AI TEST RESULT
  // ---------------------------------------------------

  static Future<bool> saveAiTestResult(
    AiTestResult item,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final list = await aiTestResults();

      final index = list.indexWhere(
        (e) => e.id == item.id,
      );

      if (index >= 0) {
        list[index] = item;
      } else {
        list.add(item);
      }

      return await prefs.setString(
        aiTestResultsKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------
  // DELETE AI TEST RESULT
  // ---------------------------------------------------

  static Future<bool> deleteAiTestResult(
    String resultId,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final list = await aiTestResults();

      list.removeWhere(
        (e) => e.id == resultId,
      );

      return await prefs.setString(
        aiTestResultsKey,
        jsonEncode(
          list.map((e) => e.toMap()).toList(),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------
  // FIND AI TEST RESULTS BY TEST
  // ---------------------------------------------------

  static Future<List<AiTestResult>>
      findAiTestResultsByTest(
    String testId,
  ) async {
    final list = await aiTestResults();

    return list
        .where(
          (e) => e.testId == testId,
        )
        .toList();
  }

  // ---------------------------------------------------
  // FIND AI TEST RESULTS BY REFERENCE
  // ---------------------------------------------------

  static Future<List<AiTestResult>>
      findAiTestResultsByReference(
    String referenceId,
  ) async {
    final list = await aiTestResults();

    return list
        .where(
          (e) => e.referenceId == referenceId,
        )
        .toList();
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
  // LEGACY DATA CONVERTER
  // ===================================================

  static GroupData? _legacyToGroup(
    Map<String, dynamic> m,
  ) {
    try {
      final created =
          m['createdAt']?.toString() ?? now();

      final group = GroupData(
        id: newId(),
        name: m['name']?.toString() ?? '',
        temple: m['temple']?.toString() ?? '',
        createdAt: created,
        updatedAt: now(),
      );

      final model = ModelData(
        id: newId(),
        name: m['model']?.toString() ?? '',
        createdAt: created,
        updatedAt: now(),
      );

      final type = TypeData(
        id: newId(),
        name: m['type']?.toString() ?? '',
        createdAt: created,
        updatedAt: now(),
      );

      final print = PrintData(
        id: newId(),
        name: m['pim']?.toString() ?? '',
        createdAt: created,
        updatedAt: now(),
      );

      final reference = ReferenceData(
        id: m['id']?.toString() ?? newId(),
        referenceNumber:
            m['referenceNumber'] is int
                ? m['referenceNumber'] as int
                : 1,
        createdAt: created,
        updatedAt: now(),
        scans: mapList<ScanResult>(
          m['scans'],
          ScanResult.fromMap,
        ),
      );

      print.references.add(reference);
      type.prints.add(print);
      model.types.add(type);
      group.models.add(model);

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

  for (final sourceModel in source.models) {
    final model = ModelData(
      id: newId(),
      name: sourceModel.name,
      createdAt: now(),
      updatedAt: now(),
    );

    for (final sourceType in sourceModel.types) {
      final type = TypeData(
        id: newId(),
        name: sourceType.name,
        createdAt: now(),
        updatedAt: now(),
      );

      for (final sourcePrint in sourceType.prints) {
        final print = PrintData(
          id: newId(),
          name: sourcePrint.name,
          createdAt: now(),
          updatedAt: now(),
        );

        for (final sourceReference
            in sourcePrint.references) {
          final reference = ReferenceData(
            id: newId(),
            referenceNumber:
                sourceReference.referenceNumber,
            createdAt: now(),
            updatedAt: now(),
            scans: sourceReference.scans
                .map(
                  (scan) => ScanResult(
                    area: scan.area,
                    details: scan.details,
                  ),
                )
                .toList(),
          );

          print.references.add(reference);
        }

        type.prints.add(print);
      }

      model.types.add(type);
    }

    group.models.add(model);
  }

  return group;
}

// =====================================================
// END STORAGE
// =====================================================
