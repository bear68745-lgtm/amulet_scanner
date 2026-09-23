// =====================================================
// SCAN DATA
// =====================================================

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

// =====================================================
// SCAN AREAS
// =====================================================

const allAreas = [
  'ด้านหน้า',
  'ด้านหลัง',
  'ด้านข้าง',
  'ก้นพระ',
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
// AI DETAIL HEADS
// =====================================================

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
