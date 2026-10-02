// =====================================================
// CORE PIPELINE
// =====================================================
// ตัวกลางการทำงานของ Core
//
// ScanResult
//     ↓
// CoreEngine
//     ↓
// CoreResult
//     ↓
// CoreValidator
//     ↓
// CoreReferenceMapper
//     ↓
// ReferenceData
//
// รองรับการรับ CoreResult ที่ผ่านการแก้ไขแล้ว
// รองรับข้อมูลโครงร่างจาก ShapeAnalyzer
//
// ยังไม่บันทึกลง Storage
// ไม่เก็บไฟล์รูปภาพ
// ไม่ตัดสินแท้ / เก๊
// =====================================================

import 'core_engine.dart';
import 'core/core_result.dart';
import 'core/core_reference_mapper.dart';
import 'core_validator.dart';
import 'models.dart';
import 'scan_data.dart';
import 'core/shape_analyzer.dart';

class CorePipelineResult {
  final CoreResult coreResult;
  final CoreValidationResult validation;
  final ReferenceData reference;

  const CorePipelineResult({
    required this.coreResult,
    required this.validation,
    required this.reference,
  });
}

class CorePipeline {
  const CorePipeline();

  // ===================================================
  // ประมวลผลจาก ScanResult
  // ===================================================
  // ใช้เมื่อข้อมูลเริ่มต้นมาจากการสแกนหลายด้าน
  // ===================================================

  CorePipelineResult process({
    required List<ScanResult> scans,
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
    // OUTLINE
    // ข้อมูลโครงร่างที่ได้จาก ShapeAnalyzer
    // -------------------------------------------------

    List<ShapeContourPoint> outlineContour = const [],
    List<double> outlineProfile = const [],
    String outlineName = '',
  }) {
    const engine = CoreEngine();

    final coreResult = engine.fromScans(scans);

    return processCoreResult(
      coreResult: coreResult,
      id: id,
      referenceNumber: referenceNumber,
      createdAt: createdAt,
      width: width,
      height: height,
      thickness: thickness,
      unit: unit,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      outlineContour: outlineContour,
      outlineProfile: outlineProfile,
      outlineName: outlineName,
    );
  }

  // ===================================================
  // ประมวลผลจาก CoreResult โดยตรง
  // ===================================================
  // ใช้หลังจาก AI / ผู้ใช้ตรวจสอบและแก้ไขข้อมูลแล้ว
  //
  // ข้อมูลใน CoreResult จะถูกนำไปตรวจสอบ
  // และส่งต่อให้ ReferenceData โดยไม่หายไป
  // ===================================================

  CorePipelineResult processCoreResult({
    required CoreResult coreResult,
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
    // OUTLINE
    // ข้อมูลโครงร่างที่ได้จาก ShapeAnalyzer
    // -------------------------------------------------

    List<ShapeContourPoint> outlineContour = const [],
    List<double> outlineProfile = const [],
    String outlineName = '',
  }) {
    // =================================================
    // Validator
    // =================================================

    const validator = CoreValidator();

    final validation = validator.validate(
      coreResult,
    );

    // =================================================
    // Mapper
    // =================================================

    const mapper = CoreReferenceMapper();

    final reference = mapper.toReferenceData(
      result: coreResult,
      id: id,
      referenceNumber: referenceNumber,
      createdAt: createdAt,
      width: width,
      height: height,
      thickness: thickness,
      unit: unit,
      sourceName: sourceName,
      sourceUrl: sourceUrl,

      // ------------------------------------------------
      // ส่งข้อมูลโครงร่างต่อไปยัง ReferenceData
      // ------------------------------------------------

      outlineContour: outlineContour,
      outlineProfile: outlineProfile,
      outlineName: outlineName,
    );

    // =================================================
    // ผลลัพธ์
    // =================================================

    return CorePipelineResult(
      coreResult: coreResult,
      validation: validation,
      reference: reference,
    );
  }
}

