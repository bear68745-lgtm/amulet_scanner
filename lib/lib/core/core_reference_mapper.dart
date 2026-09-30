// =====================================================
// CORE REFERENCE MAPPER
// =====================================================
// แปลงข้อมูลจาก CoreResult
// ไปเป็น ReferenceData
//
// ยังไม่บันทึกฐานข้อมูล
// ยังไม่สร้างเลข Reference
// ยังไม่ตัดสินแท้ / เก๊
// =====================================================

import '../models.dart';
import 'core_result.dart';

class CoreReferenceMapper {
  const CoreReferenceMapper();

  // ===================================================
  // แปลง CoreResult → ReferenceData
  // ===================================================

  ReferenceData toReferenceData({
    required CoreResult result,
    required String id,
    required int referenceNumber,
    required String createdAt,

    double width = 0.0,
    double height = 0.0,
    double thickness = 0.0,
    String unit = 'mm',

    String sourceName = '',
    String sourceUrl = '',
  }) {
    final reference = ReferenceData(
      id: id,
      referenceNumber: referenceNumber,
      createdAt: createdAt,
      updatedAt: createdAt,

      // -----------------------------
      // ขนาดจริงจากแหล่งอ้างอิง
      // -----------------------------
      width: width,
      height: height,
      thickness: thickness,
      unit: unit,

      // -----------------------------
      // แหล่งอ้างอิง
      // -----------------------------
      sourceName: sourceName,
      sourceUrl: sourceUrl,

      // -----------------------------
      // รายละเอียดแต่ละด้าน
      // -----------------------------
      frontDetails: result.frontDetails,
      backDetails: result.backDetails,
      edgeDetails: result.edgeDetails,
      bottomDetails: result.bottomDetails,

      // -----------------------------
      // รายละเอียดทั่วไป
      // -----------------------------
      surfaceDetails: result.surface,
      shapeDetails: result.printShape,
      materialDetails: result.material,

      // -----------------------------
      // จุดสังเกต
      // -----------------------------
      distinctivePoints: result.visibleMarks,
      defectPoints: result.unreadable,
    );

    // คำนวณอัตราส่วน กว้าง : สูง
    reference.calculateRatio();

    return reference;
  }
}
