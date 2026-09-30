// =====================================================
// CORE ENGINE
// =====================================================
// ตัวกลางของ Core
//
// หน้าที่:
// AiAnalysis
//      ↓
// CoreEngine
//      ↓
// CoreResult
//
// Core ยังไม่ตัดสินแท้ / เก๊
// Core ไม่เก็บไฟล์รูปภาพ
// =====================================================

import 'ai_engine.dart';
import 'core/core_result.dart';

class CoreEngine {
  const CoreEngine();

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
  //
  // ใช้เพื่อให้ระบบเดิมยังสามารถทำงานร่วมกับ Core ได้
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
