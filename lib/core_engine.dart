// =====================================================
// CORE ENGINE
// =====================================================
// ตัวกลางของ Core
//
// ScanResult หลายด้าน
//        ↓
//    CoreEngine
//        ↓
//    CoreResult
//
// Core ยังไม่ตัดสินแท้ / เก๊
// Core ไม่เก็บไฟล์รูปภาพ
// =====================================================

import 'ai_engine.dart';
import 'scan_data.dart';
import 'core/core_result.dart';

class CoreEngine {
  const CoreEngine();

  // ===================================================
  // แปลงข้อมูล ScanResult 1 ด้าน
  // ===================================================

  CoreResult fromScanResult(ScanResult scan) {
    return CoreResult(
      area: scan.area,
      observation: scan.details,
    );
  }

  // ===================================================
  // รวม ScanResult หลายด้านขององค์เดียวกัน
  // ===================================================

  CoreResult fromScans(List<ScanResult> scans) {
    final result = CoreResult(
      area: '',
    );

    for (final scan in scans) {
      final area = scan.area.trim();
      final details = scan.details.trim();

      if (details.isEmpty) {
        continue;
      }

      switch (area) {
        case 'ด้านหน้า':
          result.frontDetails = details;
          break;

        case 'ด้านหลัง':
          result.backDetails = details;
          break;

        case 'ด้านข้าง':
          result.edge = details;
          break;

        case 'ก้นพระ':
          result.bottomDetails = details;
          break;

        default:
          result.other = details;
      }
    }

    return result;
  }

  // ===================================================
  // แปลงผลจาก AI เป็นข้อมูลของ Core
  // ===================================================

  CoreResult fromAiAnalysis(AiAnalysis analysis) {
    return CoreResult(
      area: analysis.area,
      printShape: analysis.printShape,
      composition: analysis.composition,
      pattern: analysis.patterns,
      visibleMarks: analysis.visibleMarks,
      surface: analysis.surface,
      material: analysis.material,
      edge: analysis.edge,
      observation: analysis.observation,
      other: analysis.otherDetails,
      unreadable: analysis.unreadable,
    );
  }

  // ===================================================
  // แปลง CoreResult กลับเป็น AiAnalysis
  // ===================================================

  AiAnalysis toAiAnalysis(CoreResult result) {
    return AiAnalysis(
      area: result.area,
      printShape: result.printShape,
      composition: result.composition,
      patterns: result.pattern,
      visibleMarks: result.visibleMarks,
      surface: result.surface,
      material: result.material,
      edge: result.edge,
      observation: result.observation,
      otherDetails: result.other,
      unreadable: result.unreadable,
    );
  }
}
