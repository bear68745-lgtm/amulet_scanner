// =====================================================
// MODELS
// =====================================================

import 'scan_data.dart';

// =====================================================
// HELPERS
// =====================================================

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

String now() => DateTime.now().toIso8601String();

List<T> mapList<T>(
  dynamic v,
  T Function(Map<String, dynamic>) f,
) =>
    v is List
        ? v
            .whereType<Map>()
            .map((e) => f(Map<String, dynamic>.from(e)))
            .toList()
        : <T>[];

// =====================================================
// REFERENCE DATA
// =====================================================

class ReferenceData {
  // ---------------------------------------------------
  // ID / NUMBER / TIME
  // ---------------------------------------------------

  String id;
  int referenceNumber;
  String createdAt;
  String updatedAt;

  // ---------------------------------------------------
  // SCAN DATA
  // ---------------------------------------------------

  List<ScanResult> scans;

  // ---------------------------------------------------
  // REFERENCE SIZE
  // ขนาดจริงจากแหล่งอ้างอิง
  // ---------------------------------------------------

  double width;
  double height;
  double thickness;
  String unit;

  // ---------------------------------------------------
  // SIZE RATIO
  // อัตราส่วน กว้าง : สูง
  // ---------------------------------------------------

  double widthHeightRatio;

  // ---------------------------------------------------
  // REFERENCE SOURCE
  // แหล่งข้อมูลอ้างอิง
  // ---------------------------------------------------

  String sourceName;
  String sourceUrl;

  // ---------------------------------------------------
  // PHYSICAL DETAILS
  // รายละเอียดลักษณะองค์พระ/วัตถุ
  // ---------------------------------------------------

  String frontDetails;
  String backDetails;
  String edgeDetails;
  String bottomDetails;
  String surfaceDetails;
  String shapeDetails;
  String materialDetails;

  // ---------------------------------------------------
  // DISTINCTIVE / DEFECT POINTS
  // จุดสังเกตและตำหนิที่มองเห็น
  // ---------------------------------------------------

  String distinctivePoints;
  String defectPoints;

  // ---------------------------------------------------
  // OUTLINE REFERENCE
  // โครงร่างภายนอกจากภาพอ้างอิง
  //
  // outlineProfile:
  // ค่ารัศมีของจุดรอบวัตถุที่สกัดจากภาพ
  //
  // outlineName:
  // ชื่อโครงร่างที่ระบบวิเคราะห์ได้
  //
  // ใช้สำหรับเปรียบเทียบโครงร่างเท่านั้น
  // ไม่ใช้ตัดสินแท้ / เก๊
  // ---------------------------------------------------

  List<double> outlineProfile;
  String outlineName;

  ReferenceData({
    required this.id,
    required this.referenceNumber,
    required this.createdAt,
    required this.updatedAt,

    List<ScanResult>? scans,

    this.width = 0.0,
    this.height = 0.0,
    this.thickness = 0.0,
    this.unit = 'mm',

    this.widthHeightRatio = 0.0,

    this.sourceName = '',
    this.sourceUrl = '',

    this.frontDetails = '',
    this.backDetails = '',
    this.edgeDetails = '',
    this.bottomDetails = '',
    this.surfaceDetails = '',
    this.shapeDetails = '',
    this.materialDetails = '',

    this.distinctivePoints = '',
    this.defectPoints = '',

    // Outline
    List<double>? outlineProfile,
    this.outlineName = '',
  })  : scans = scans ?? [],
        outlineProfile = outlineProfile ?? [];

  // ---------------------------------------------------
  // CALCULATE RATIO
  // ---------------------------------------------------

  void calculateRatio() {
    if (width > 0 && height > 0) {
      widthHeightRatio = width / height;
    } else {
      widthHeightRatio = 0.0;
    }
  }

  // ---------------------------------------------------
  // TO MAP
  // ---------------------------------------------------

  Map<String, dynamic> toMap() => {
        'id': id,
        'referenceNumber': referenceNumber,
        'createdAt': createdAt,
        'updatedAt': updatedAt,

        // Scan data
        'scans': scans.map((e) => e.toMap()).toList(),

        // Reference size
        'width': width,
        'height': height,
        'thickness': thickness,
        'unit': unit,

        // Ratio
        'widthHeightRatio': widthHeightRatio,

        // Source
        'sourceName': sourceName,
        'sourceUrl': sourceUrl,

        // Physical details
        'frontDetails': frontDetails,
        'backDetails': backDetails,
        'edgeDetails': edgeDetails,
        'bottomDetails': bottomDetails,
        'surfaceDetails': surfaceDetails,
        'shapeDetails': shapeDetails,
        'materialDetails': materialDetails,

        // Distinctive points
        'distinctivePoints': distinctivePoints,
        'defectPoints': defectPoints,

        // Outline reference
        'outlineProfile': outlineProfile,
        'outlineName': outlineName,
      };

  // ---------------------------------------------------
  // FROM MAP
  // รองรับข้อมูล ReferenceData รุ่นเก่า
  // ---------------------------------------------------

  factory ReferenceData.fromMap(Map<String, dynamic> m) {
    final rawOutline = m['outlineProfile'];

    final data = ReferenceData(
      id: m['id'] ?? '',
      referenceNumber: _toInt(
        m['referenceNumber'],
        1,
      ),
      createdAt: m['createdAt'] ?? '',
      updatedAt: m['updatedAt'] ?? '',

      scans: mapList<ScanResult>(
        m['scans'],
        ScanResult.fromMap,
      ),

      width: _toDouble(m['width']),
      height: _toDouble(m['height']),
      thickness: _toDouble(m['thickness']),
      unit: m['unit'] ?? 'mm',

      widthHeightRatio: _toDouble(
        m['widthHeightRatio'],
      ),

      sourceName: m['sourceName'] ?? '',
      sourceUrl: m['sourceUrl'] ?? '',

      frontDetails: m['frontDetails'] ?? '',
      backDetails: m['backDetails'] ?? '',
      edgeDetails: m['edgeDetails'] ?? '',
      bottomDetails: m['bottomDetails'] ?? '',
      surfaceDetails: m['surfaceDetails'] ?? '',
      shapeDetails: m['shapeDetails'] ?? '',
      materialDetails: m['materialDetails'] ?? '',

      distinctivePoints: m['distinctivePoints'] ?? '',
      defectPoints: m['defectPoints'] ?? '',

      // Outline reference
      outlineProfile: rawOutline is List
          ? rawOutline
              .whereType<num>()
              .map((e) => e.toDouble())
              .toList()
          : <double>[],

      outlineName: m['outlineName'] ?? '',
    );

    // ถ้ามีขนาดแต่ไม่มี ratio ให้คำนวณใหม่
    if (data.widthHeightRatio <= 0 &&
        data.width > 0 &&
        data.height > 0) {
      data.calculateRatio();
    }

    return data;
  }
}

// =====================================================
// NUMBER HELPERS
// =====================================================

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
        '${value ?? ''}',
      ) ??
      0.0;
}

int _toInt(dynamic value, int defaultValue) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
        '${value ?? ''}',
      ) ??
      defaultValue;
}

// =====================================================
// PRINT DATA
// =====================================================

class PrintData {
  String id, name, createdAt, updatedAt;

  // ---------------------------------------------------
  // COIN STRUCTURE
  // โครงสร้างเหรียญ
  // ---------------------------------------------------

  String coinShape;
  String earType;

  List<ReferenceData> references;

  PrintData({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,

    this.coinShape = '',
    this.earType = '',

    List<ReferenceData>? references,
  }) : references = references ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,

        // Coin structure
        'coinShape': coinShape,
        'earType': earType,

        'references':
            references.map((e) => e.toMap()).toList(),
      };

  factory PrintData.fromMap(
    Map<String, dynamic> m,
  ) =>
      PrintData(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        createdAt: m['createdAt'] ?? '',
        updatedAt: m['updatedAt'] ?? '',

        // รองรับข้อมูลเดิมที่ยังไม่มีข้อมูลโครงสร้างเหรียญ
        coinShape: m['coinShape'] ?? '',
        earType: m['earType'] ?? '',

        references: mapList<ReferenceData>(
          m['references'],
          ReferenceData.fromMap,
        ),
      );
}

// =====================================================
// TYPE DATA
// =====================================================

class TypeData {
  String id, name, createdAt, updatedAt;
  List<PrintData> prints;

  TypeData({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    List<PrintData>? prints,
  }) : prints = prints ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'prints': prints.map((e) => e.toMap()).toList(),
      };

  factory TypeData.fromMap(Map<String, dynamic> m) => TypeData(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        createdAt: m['createdAt'] ?? '',
        updatedAt: m['updatedAt'] ?? '',
        prints: mapList<PrintData>(
          m['prints'],
          PrintData.fromMap,
        ),
      );
}

// =====================================================
// MODEL DATA
// =====================================================

class ModelData {
  String id, name, createdAt, updatedAt;
  List<TypeData> types;

  ModelData({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    List<TypeData>? types,
  }) : types = types ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'types': types.map((e) => e.toMap()).toList(),
      };

  factory ModelData.fromMap(Map<String, dynamic> m) => ModelData(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        createdAt: m['createdAt'] ?? '',
        updatedAt: m['updatedAt'] ?? '',
        types: mapList<TypeData>(
          m['types'],
          TypeData.fromMap,
        ),
      );
}

// =====================================================
// GROUP DATA
// =====================================================

class GroupData {
  String id, name, temple, createdAt, updatedAt;
  List<ModelData> models;

  GroupData({
    required this.id,
    required this.name,
    required this.temple,
    required this.createdAt,
    required this.updatedAt,
    List<ModelData>? models,
  }) : models = models ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'temple': temple,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'models': models.map((e) => e.toMap()).toList(),
      };

  factory GroupData.fromMap(Map<String, dynamic> m) => GroupData(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        temple: m['temple'] ?? '',
        createdAt: m['createdAt'] ?? '',
        updatedAt: m['updatedAt'] ?? '',
        models: mapList<ModelData>(
          m['models'],
          ModelData.fromMap,
        ),
      );
}

// =====================================================
// AI KNOWLEDGE
// =====================================================

class AiKnowledge {
  String id,
      groupId,
      modelId,
      typeId,
      printId,
      referenceId,
      area,
      content,
      createdAt,
      updatedAt;

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

  factory AiKnowledge.fromMap(Map<String, dynamic> m) => AiKnowledge(
        id: m['id'] ?? '',
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

// =====================================================
// AI LEARNING HISTORY
// =====================================================

class AiLearningHistory {
  String id,
      groupId,
      modelId,
      typeId,
      printId,
      referenceId,
      area,
      content,
      learnedAt;

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
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'learnedAt': learnedAt,
      };

  factory AiLearningHistory.fromMap(Map<String, dynamic> m) =>
      AiLearningHistory(
        id: m['id'] ?? '',
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

// =====================================================
// AI MEMORY TEST
// =====================================================

class AiMemoryTest {
  String id,
      knowledgeId,
      referenceId,
      area,
      question,
      answer,
      testedAt;

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

  factory AiMemoryTest.fromMap(Map<String, dynamic> m) => AiMemoryTest(
        id: m['id'] ?? '',
        knowledgeId: m['knowledgeId'] ?? '',
        referenceId: m['referenceId'] ?? '',
        area: m['area'] ?? '',
        question: m['question'] ?? '',
        answer: m['answer'] ?? '',
        testedAt: m['testedAt'] ?? '',
      );
}

// =====================================================
// AI TEST RESULT
// =====================================================

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

  // ---------------------------------------------------
  // เลของค์อ้างอิงของ Memory ที่นำมาเปรียบเทียบ
  // ---------------------------------------------------

  int referenceNumber;

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
    this.referenceNumber = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'testId': testId,
        'knowledgeId': knowledgeId,
        'referenceId': referenceId,
        'referenceNumber': referenceNumber,
        'area': area,
        'mode': mode,
        'result': result,
        'answer': answer,
        'referenceAnswer': referenceAnswer,
        'reason': reason,
        'checkedAt': checkedAt,
      };

  factory AiTestResult.fromMap(Map<String, dynamic> m) => AiTestResult(
        id: m['id'] ?? '',
        testId: m['testId'] ?? '',
        knowledgeId: m['knowledgeId'] ?? '',
        referenceId: m['referenceId'] ?? '',
        referenceNumber: _toInt(
          m['referenceNumber'],
          0,
        ),
        area: m['area'] ?? '',
        mode: m['mode'] ?? '',
        result: m['result'] ?? '',
        answer: m['answer'] ?? '',
        referenceAnswer: m['referenceAnswer'] ?? '',
        reason: m['reason'] ?? '',
        checkedAt: m['checkedAt'] ?? '',
      );
}

// =====================================================
// END MODELS
// =====================================================