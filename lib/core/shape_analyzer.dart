// ==========================================================
// ทำความสะอาด contour
//
// เป้าหมาย:
// - ลดจุดที่เกิดจาก pixel
// - ทำให้เส้นดูเป็นรูปวาด 2D
// - ไม่ทำให้รูปทรงกลมเกินจริง
// - ไม่ลบมุมสำคัญ
// - ไม่กำหนดจำนวนจุดตายตัว
// ==========================================================

List<_Pixel> _cleanContour(
  List<_Pixel> contour,
) {
  if (contour.length < 10) {
    return contour;
  }

  final unique =
      _removeConsecutiveDuplicatePoints(
    contour,
  );

  if (unique.length < 10) {
    return unique;
  }

  // --------------------------------------------------------
  // ลดจุดแบบ RDP เพียงขั้นเดียว
  //
  // ไม่ทำ smoothing ซ้ำหลายชั้น
  // เพื่อรักษารูปทรงจริงของเหรียญ
  // --------------------------------------------------------

  final simplified =
      _simplifyClosedContour(
    unique,
    epsilon: 1.10,
  );

  if (simplified.length < 10) {
    return unique;
  }

  return simplified;
}