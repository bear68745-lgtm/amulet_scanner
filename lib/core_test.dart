// =====================================================
// CORE TEST
// =====================================================
// ทดสอบการไหลของข้อมูล Core
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
// ไฟล์นี้ใช้สำหรับทดสอบเท่านั้น
// ไม่บันทึกข้อมูล
// ไม่บันทึกรูปภาพ
// ไม่แตะกล้อง
// ไม่ตัดสินแท้ / เก๊
// =====================================================

import 'core_engine.dart';
import 'core/core_reference_mapper.dart';
import 'core_validator.dart';
import 'models.dart';
import 'scan_data.dart';

class CoreTest {
  const CoreTest();

  // ===================================================
  // ทดสอบ Core ด้วยข้อมูลจำลอง
  // ===================================================

  CoreTestReport run() {
    // -------------------------------------------------
    // 1. สร้างข้อมูล ScanResult จำลอง
    // -------------------------------------------------

    final scans = [
      ScanResult(
        area: 'ด้านหน้า',
        details: 'องค์พระอยู่กึ่งกลาง มีรายละเอียดพิมพ์ทรงที่มองเห็นได้',
      ),
      ScanResult(
        area: 'ด้านหลัง',
        details: 'ด้านหลังมีรายละเอียดพื้นผิวและลวดลายที่มองเห็นได้',
      ),
      ScanResult(
        area: 'ด้านข้าง',
        details: 'ขอบด้านข้างมีรายละเอียดและร่องรอยที่มองเห็นได้',
      ),
      ScanResult(
        area: 'ก้นพระ',
        details: 'ก้นพระมีรายละเอียดที่สามารถสังเกตได้',
      ),
    ];

    // -------------------------------------------------
    // 2. ส่งเข้า CoreEngine
    // -------------------------------------------------

    const engine = CoreEngine();

    final coreResult = engine.fromScans(scans);

    // -------------------------------------------------
    // 3. เติมข้อมูลทั่วไปสำหรับทดสอบ
    // -------------------------------------------------

    coreResult.printShape = 'พิมพ์ทรงตัวอย่าง';

    coreResult.material = 'ลักษณะเนื้อตัวอย่าง';

    coreResult.visibleMarks = 'จุดสังเกตตัวอย่าง';

    coreResult.unreadable = 'ไม่มีข้อมูลที่อ่านไม่ได้';

    // -------------------------------------------------
    // 4. ตรวจข้อมูลด้วย CoreValidator
    // -------------------------------------------------

    const validator = CoreValidator();

    final validation = validator.validate(coreResult);

    // -------------------------------------------------
    // 5. แปลงเป็น ReferenceData
    // -------------------------------------------------

    const mapper = CoreReferenceMapper();

    final reference = mapper.toReferenceData(
      result: coreResult,
      id: 'TEST-001',
      referenceNumber: 1,
      createdAt: DateTime.now().toIso8601String(),
      width: 30.0,
      height: 40.0,
      thickness: 2.5,
      unit: 'mm',
      sourceName: 'ข้อมูลทดสอบ',
      sourceUrl: '',
    );

    // -------------------------------------------------
    // 6. ส่งผลการทดสอบกลับ
    // -------------------------------------------------

    return CoreTestReport(
      coreResult: coreResult,
      validation: validation,
      reference: reference,
    );
  }
}

// =====================================================
// ผลการทดสอบ
// =====================================================

class CoreTestReport {
  final CoreResult coreResult;
  final CoreValidationResult validation;
  final ReferenceData reference;

  const CoreTestReport({
    required this.coreResult,
    required this.validation,
    required this.reference,
  });
}
