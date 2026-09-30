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
// ยังไม่บันทึกลง Storage
// ไม่เก็บไฟล์รูปภาพ
// ไม่ตัดสินแท้ / เก๊
// =====================================================

import 'core_engine.dart';
import 'core/core_result.dart';
import 'core/core_reference_mapper.dart';
import 'core/core_validator.dart';
import 'models.dart';
import 'scan_data.dart';

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
  // ประมวลผล ScanResult → ReferenceData
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
  }) {
    // -----------------------------------------------
    // 1. รวมข้อมูลจาก ScanResult
    // -----------------------------------------------

    const engine = CoreEngine();

    final coreResult = engine.fromScans(scans);

    // -----------------------------------------------
    // 2. ตรวจความครบถ้วน
    // -----------------------------------------------

    const validator = CoreValidator();

    final validation = validator.validate(coreResult);

    // -----------------------------------------------
    // 3. แปลงเป็น ReferenceData
    // -----------------------------------------------

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
    );

    // -----------------------------------------------
    // 4. ส่งผลกลับ
    // -----------------------------------------------

    return CorePipelineResult(
      coreResult: coreResult,
      validation: validation,
      reference: reference,
    );
  }
}
