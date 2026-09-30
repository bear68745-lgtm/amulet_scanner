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
  }) {
    final reference = ReferenceData(
      id: id,
      referenceNumber: referenceNumber,
      createdAt: createdAt,
      updatedAt: createdAt,

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

    return reference;
  }
}
