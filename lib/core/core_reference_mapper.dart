// =====================================================
// CORE REFERENCE MAPPER
// =====================================================
// แปลงข้อมูลจาก CoreResult
// ไปเป็น ReferenceData
//
// ยังไม่บันทึกฐานข้อมูล
// ยังไม่สร้างเลข Reference
// ยังไม่ตัดสินแท้ / เก๊
//
// รองรับข้อมูลโครงร่างจาก ShapeAnalyzer
// =====================================================

import '../models.dart';
import 'core_result.dart';
import 'shape_analyzer.dart';

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

    // -------------------------------------------------
    // OUTLINE REFERENCE
    // ข้อมูลโครงร่างที่ ShapeAnalyzer สกัดจากภาพ
    // -------------------------------------------------

    List<ShapeContourPoint> outlineContour = const [],
    List<double> outlineProfile = const [],
    String outlineName = '',
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

      // -----------------------------
      // โครงร่างภายนอก
      // -----------------------------
      outlineContour: outlineContour
          .map(
            (point) => ShapeContourPoint(
              x: point.x,
              y: point.y,
            ),
          )
          .toList(),

      // -----------------------------
      // ข้อมูลเดิมเพื่อรองรับย้อนหลัง
      // -----------------------------
      outlineProfile: List<double>.from(
        outlineProfile,
      ),

      outlineName: outlineName,
    );

    // =================================================
    // คำนวณอัตราส่วน กว้าง : สูง
    // =================================================

    reference.calculateRatio();

    return reference;
  }
}