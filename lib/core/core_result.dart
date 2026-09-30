// =====================================================
// CORE RESULT
// =====================================================
// ผลข้อมูลที่ Core อ่านได้จากการสแกน
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
  });

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
    };
  }

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
    );
  }
}
