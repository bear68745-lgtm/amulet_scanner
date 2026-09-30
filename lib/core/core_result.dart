// =====================================================
// CORE RESULT
// =====================================================
// ผลข้อมูลที่ Core อ่านและรวบรวมได้
//
// ไม่เก็บไฟล์รูปภาพ
// ไม่ตัดสินแท้ / เก๊
// =====================================================

class CoreResult {
  String area;

  String printShape;
  String composition;
  String pattern;
  String visibleMarks;
  String surface;
  String material;
  String edge;
  String observation;
  String other;
  String unreadable;

  // ===================================================
  // รายละเอียดแยกตามด้าน
  // ===================================================

  String frontDetails;
  String backDetails;
  String edgeDetails;
  String bottomDetails;

  CoreResult({
    required this.area,

    this.printShape = '',
    this.composition = '',
    this.pattern = '',
    this.visibleMarks = '',
    this.surface = '',
    this.material = '',
    this.edge = '',
    this.observation = '',
    this.other = '',
    this.unreadable = '',

    this.frontDetails = '',
    this.backDetails = '',
    this.edgeDetails = '',
    this.bottomDetails = '',
  });

  // ===================================================
  // แปลงเป็น Map
  // ===================================================

  Map<String, dynamic> toMap() {
    return {
      'area': area,

      'printShape': printShape,
      'composition': composition,
      'pattern': pattern,
      'visibleMarks': visibleMarks,
      'surface': surface,
      'material': material,
      'edge': edge,
      'observation': observation,
      'other': other,
      'unreadable': unreadable,

      'frontDetails': frontDetails,
      'backDetails': backDetails,
      'edgeDetails': edgeDetails,
      'bottomDetails': bottomDetails,
    };
  }

  // ===================================================
  // อ่านจาก Map
  // ===================================================

  factory CoreResult.fromMap(Map<String, dynamic> map) {
    return CoreResult(
      area: map['area'] ?? '',

      printShape: map['printShape'] ?? '',
      composition: map['composition'] ?? '',
      pattern: map['pattern'] ?? '',
      visibleMarks: map['visibleMarks'] ?? '',
      surface: map['surface'] ?? '',
      material: map['material'] ?? '',
      edge: map['edge'] ?? '',
      observation: map['observation'] ?? '',
      other: map['other'] ?? '',
      unreadable: map['unreadable'] ?? '',

      frontDetails: map['frontDetails'] ?? '',
      backDetails: map['backDetails'] ?? '',
      edgeDetails: map['edgeDetails'] ?? '',
      bottomDetails: map['bottomDetails'] ?? '',
    );
  }
}
