// =====================================================
// AI ENGINE
// ตัวกลางสำหรับระบบ AI ของแอป
//
// หน้าที่:
// กล้อง/ScanPage
//      ↓
//   AiEngine
//      ↓
// ผลวิเคราะห์แบบข้อมูล
//
// ยังไม่ผูกกับ AI รุ่นใดโดยเฉพาะ
// ภายหลังสามารถเปลี่ยนเครื่องยนต์ AI ได้
// โดยไม่ต้องรื้อระบบฐานข้อมูล
// =====================================================

class AiAnalysis {
  final String area;

  final String printShape;
  final String composition;
  final String patterns;
  final String visibleMarks;
  final String surface;
  final String material;
  final String edge;
  final String observation;
  final String otherDetails;
  final String unreadable;

  const AiAnalysis({
    required this.area,
    this.printShape = '',
    this.composition = '',
    this.patterns = '',
    this.visibleMarks = '',
    this.surface = '',
    this.material = '',
    this.edge = '',
    this.observation = '',
    this.otherDetails = '',
    this.unreadable = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'printShape': printShape,
      'composition': composition,
      'patterns': patterns,
      'visibleMarks': visibleMarks,
      'surface': surface,
      'material': material,
      'edge': edge,
      'observation': observation,
      'otherDetails': otherDetails,
      'unreadable': unreadable,
    };
  }

  factory AiAnalysis.fromMap(
    Map<String, dynamic> map,
  ) {
    return AiAnalysis(
      area: map['area']?.toString() ?? '',
      printShape: map['printShape']?.toString() ?? '',
      composition: map['composition']?.toString() ?? '',
      patterns: map['patterns']?.toString() ?? '',
      visibleMarks: map['visibleMarks']?.toString() ?? '',
      surface: map['surface']?.toString() ?? '',
      material: map['material']?.toString() ?? '',
      edge: map['edge']?.toString() ?? '',
      observation: map['observation']?.toString() ?? '',
      otherDetails: map['otherDetails']?.toString() ?? '',
      unreadable: map['unreadable']?.toString() ?? '',
    );
  }

  String toText() {
    final parts = <String>[];

    void add(
      String label,
      String value,
    ) {
      if (value.trim().isNotEmpty) {
        parts.add('$label: $value');
      }
    }

    add('พิมพ์ทรง', printShape);
    add('องค์ประกอบ', composition);
    add('ลวดลาย', patterns);
    add('ตำหนิที่มองเห็น', visibleMarks);
    add('ผิว', surface);
    add('ลักษณะเนื้อที่มองเห็น', material);
    add('ขอบ/ด้านข้าง', edge);
    add('จุดสังเกต', observation);
    add('รายละเอียดอื่น', otherDetails);
    add('สิ่งที่อ่านไม่ได้', unreadable);

    return parts.join('\n');
  }
}

// =====================================================
// AI ENGINE
// =====================================================

class AiEngine {
  const AiEngine();

  // ---------------------------------------------------
  // วิเคราะห์ภาพ
  //
  // ตอนนี้ยังไม่เรียก AI จริง
  // จะใส่เครื่องยนต์ AI ในส่วนนี้ภายหลัง
  // ---------------------------------------------------

  Future<AiAnalysis> analyzeImage({
    required String area,
    required String imagePath,
  }) async {
    // -------------------------------------------------
    // จุดนี้จะเชื่อม AI จริงในขั้นต่อไป
    // -------------------------------------------------

    return AiAnalysis(
      area: area,
    );
  }

  // ---------------------------------------------------
  // วิเคราะห์จากข้อความที่มีอยู่แล้ว
  //
  // ใช้สำหรับระบบ AI Memory ปัจจุบัน
  // ---------------------------------------------------

  Future<AiAnalysis> analyzeText({
    required String area,
    required String text,
  }) async {
    return AiAnalysis(
      area: area,
      otherDetails: text,
    );
  }
}
