// =====================================================
// CORE ENGINE
// =====================================================
// ตัวกลางของ Core
//
// ScanResult
//      ↓
// CoreEngine
//      ↓
// CoreResult
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
  // แปลงข้อมูลจาก ScanResult เป็น CoreResult
  // ===================================================

  CoreResult fromScanResult(ScanResult scan) {
    return CoreResult(
      area: scan.area,
      observation: scan.details,
    );
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
