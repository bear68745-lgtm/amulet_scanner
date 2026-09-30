import 'package:flutter_test/flutter_test.dart';

import '../lib/core_test.dart';

void main() {
  test('Core pipeline should process all scan areas correctly', () {
    const coreTest = CoreTest();

    final report = coreTest.run();

    // ตรวจด้านหน้า
    expect(
      report.coreResult.frontDetails,
      'องค์พระอยู่กึ่งกลาง มีรายละเอียดพิมพ์ทรงที่มองเห็นได้',
    );

    // ตรวจด้านหลัง
    expect(
      report.coreResult.backDetails,
      'ด้านหลังมีรายละเอียดพื้นผิวและลวดลายที่มองเห็นได้',
    );

    // ตรวจด้านข้าง
    expect(
      report.coreResult.edgeDetails,
      'ขอบด้านข้างมีรายละเอียดและร่องรอยที่มองเห็นได้',
    );

    // ตรวจก้นพระ
    expect(
      report.coreResult.bottomDetails,
      'ก้นพระมีรายละเอียดที่สามารถสังเกตได้',
    );

    // ตรวจข้อมูลทั่วไป
    expect(
      report.coreResult.printShape,
      'พิมพ์ทรงตัวอย่าง',
    );

    expect(
      report.coreResult.material,
      'ลักษณะเนื้อตัวอย่าง',
    );

    expect(
      report.coreResult.visibleMarks,
      'จุดสังเกตตัวอย่าง',
    );

    // ตรวจ ReferenceData
    expect(report.reference.id, 'TEST-001');
    expect(report.reference.referenceNumber, 1);
    expect(report.reference.width, 30.0);
    expect(report.reference.height, 40.0);
    expect(report.reference.thickness, 2.5);
    expect(report.reference.unit, 'mm');

    // ตรวจแหล่งอ้างอิง
    expect(report.reference.sourceName, 'ข้อมูลทดสอบ');

    // ตรวจว่าข้อมูลผ่าน Validator
    expect(report.validation.isValid, true);
  });
}
