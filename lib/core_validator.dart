// =====================================================
// CORE VALIDATOR
// =====================================================
// ตรวจความครบถ้วนของข้อมูลก่อนบันทึก
//
// ไม่ตัดสินแท้ / เก๊
// ไม่แก้ข้อมูลของผู้ใช้
// ไม่บันทึกรูปภาพ
// =====================================================

import 'core/core_result.dart';

class CoreValidationResult {
  final bool isValid;
  final List<String> warnings;

  const CoreValidationResult({
    required this.isValid,
    required this.warnings,
  });
}

class CoreValidator {
  const CoreValidator();

  // ===================================================
  // ตรวจ CoreResult
  // ===================================================

  CoreValidationResult validate(CoreResult result) {
    final warnings = <String>[];

    // -----------------------------------------------
    // ตรวจข้อมูลด้านต่าง ๆ
    // -----------------------------------------------

    if (result.frontDetails.trim().isEmpty) {
      warnings.add('ยังไม่มีรายละเอียดด้านหน้า');
    }

    if (result.backDetails.trim().isEmpty) {
      warnings.add('ยังไม่มีรายละเอียดด้านหลัง');
    }

    if (result.edgeDetails.trim().isEmpty) {
      warnings.add('ยังไม่มีรายละเอียดด้านข้าง');
    }

    // -----------------------------------------------
    // ตรวจพิมพ์ทรง
    // -----------------------------------------------

    if (result.printShape.trim().isEmpty) {
      warnings.add('ยังไม่มีข้อมูลพิมพ์ทรง');
    }

    // -----------------------------------------------
    // ตรวจข้อมูลเนื้อ
    // -----------------------------------------------

    if (result.material.trim().isEmpty) {
      warnings.add('ยังไม่มีข้อมูลลักษณะเนื้อ');
    }

    // -----------------------------------------------
    // ตรวจจุดสังเกต
    // -----------------------------------------------

    if (result.visibleMarks.trim().isEmpty) {
      warnings.add('ยังไม่มีจุดสังเกต');
    }

    // -----------------------------------------------
    // ตรวจสิ่งที่อ่านไม่ได้
    // -----------------------------------------------

    if (result.unreadable.trim().isEmpty) {
      warnings.add('ยังไม่ได้ระบุสิ่งที่อ่านไม่ได้');
    }

    // -----------------------------------------------
    // warnings เป็นเพียงคำเตือน
    // ไม่ได้หมายความว่าข้อมูลใช้ไม่ได้
    // -----------------------------------------------

    return CoreValidationResult(
      isValid: true,
      warnings: warnings,
    );
  }
}
