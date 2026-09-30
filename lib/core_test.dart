// =====================================================
// CORE TEST
// =====================================================
// ทดสอบ CorePipeline
//
// ScanResult
//     ↓
// CorePipeline
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

import 'core_pipeline.dart';
import 'models.dart';
import 'scan_data.dart';

class CoreTest {
  const CoreTest();

  CoreTestReport run() {
    // ===================================================
    // ข้อมูล ScanResult จำลอง
    // ===================================================

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

    // ===================================================
    // ใช้ CorePipeline ตัวจริง
    // ===================================================

    const pipeline = CorePipeline();

    final result = pipeline.process(
      scans: scans,
      id: 'TEST-001',
      referenceNumber: 1,
      createdAt: '2026-09-30T00:00:00.000Z',
      width: 30.0,
      height: 40.0,
      thickness: 2.5,
      unit: 'mm',
      sourceName: 'ข้อมูลทดสอบ',
      sourceUrl: '',
    );

    // ===================================================
    // เติมข้อมูลที่เป็นข้อมูลจาก AI / การอ่านเพิ่มเติม
    // ===================================================
    //
    // CorePipeline ตอนนี้รับข้อมูล ScanResult
    // เป็นหลัก ส่วนข้อมูลเหล่านี้จำลองการเติมข้อมูล
    // ก่อนเข้าสู่ขั้น Reference
    //
    // ไม่ใช่การตัดสินแท้ / เก๊
    // ===================================================

    result.coreResult.printShape = 'พิมพ์ทรงตัวอย่าง';
    result.coreResult.material = 'ลักษณะเนื้อตัวอย่าง';
    result.coreResult.visibleMarks = 'จุดสังเกตตัวอย่าง';
    result.coreResult.unreadable = 'ไม่มีข้อมูลที่อ่านไม่ได้';

    return CoreTestReport(
      coreResult: result.coreResult,
      validation: result.validation,
      reference: result.reference,
    );
  }
}

// =====================================================
// CORE TEST REPORT
// =====================================================

class CoreTestReport {
  final dynamic coreResult;
  final dynamic validation;
  final ReferenceData reference;

  const CoreTestReport({
    required this.coreResult,
    required this.validation,
    required this.reference,
  });
}
