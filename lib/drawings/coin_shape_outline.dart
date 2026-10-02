import 'package:flutter/material.dart';

/// ===============================================================
/// โครงร่างเหรียญ
///
/// หลักการ
/// - แสดงเฉพาะโครงร่างภายนอก
/// - แสดงส่วนหูในตัวและรูหู
/// - ไม่ใส่รูปพระ
/// - ไม่ใส่ตัวหนังสือ
/// - ไม่ใส่ลวดลาย
/// - ไม่ใส่ตำหนิ
/// - ไม่ใช้ตัดสินแท้ / เก๊
///
/// โครงร่างใช้สำหรับอธิบายลักษณะภายนอกของเหรียญเท่านั้น
/// ===============================================================

class OvalOutline extends StatelessWidget {
  const OvalOutline({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: CustomPaint(
        painter: OvalOutlinePainter(),
      ),
    );
  }
}

/// ===============================================================
/// รูปไข่ทั่วไป
///
/// ใช้เป็นสัญลักษณ์ประเภท "รูปไข่"
/// ไม่ใช่โครงร่างเฉพาะของรุ่นใด
/// ===============================================================

class OvalOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;

    final path = Path();

    path.moveTo(centerX, 25);

    path.cubicTo(
      centerX - 30,
      25,
      centerX - 58,
      45,
      centerX - 69,
      82,
    );

    path.cubicTo(
      centerX - 77,
      108,
      centerX - 77,
      151,
      centerX - 70,
      184,
    );

    path.cubicTo(
      centerX - 62,
      220,
      centerX - 38,
      250,
      centerX,
      253,
    );

    path.cubicTo(
      centerX + 38,
      250,
      centerX + 62,
      220,
      centerX + 70,
      184,
    );

    path.cubicTo(
      centerX + 77,
      151,
      centerX + 77,
      108,
      centerX + 69,
      82,
    );

    path.cubicTo(
      centerX + 58,
      45,
      centerX + 30,
      25,
      centerX,
      25,
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// ===============================================================
/// โครงร่างเหรียญหลวงปู่ฝั้น รุ่นแรก
///
/// ลักษณะหลักที่แสดง
/// - ตัวเหรียญทรงไข่
/// - ด้านบนต่อเนื่องขึ้นเป็นส่วนหู
/// - หูเป็นส่วนเดียวกับโครงร่างเหรียญ
/// - มีช่องรูหู
/// - ด้านข้างสอบเข้าสู่ด้านบนและด้านล่าง
/// - ด้านล่างโค้งมน
///
/// ไม่มีรายละเอียดด้านในเหรียญ
/// ===============================================================

class IntegratedEarOvalOutline extends StatelessWidget {
  const IntegratedEarOvalOutline({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: CustomPaint(
        painter: IntegratedEarOvalOutlinePainter(),
      ),
    );
  }
}

class IntegratedEarOvalOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // =============================================================
    // จุดเริ่มต้นบริเวณยอดหู
    // =============================================================

    path.moveTo(centerX, 18);

    // =============================================================
    // ด้านซ้ายของหู
    // =============================================================

    path.cubicTo(
      centerX - 8,
      19,
      centerX - 18,
      24,
      centerX - 28,
      32,
    );

    path.cubicTo(
      centerX - 39,
      40,
      centerX - 48,
      51,
      centerX - 56,
      64,
    );

    // =============================================================
    // ไหล่ซ้ายของเหรียญ
    // =============================================================

    path.cubicTo(
      centerX - 63,
      76,
      centerX - 68,
      91,
      centerX - 71,
      108,
    );

    path.cubicTo(
      centerX - 74,
      126,
      centerX - 75,
      146,
      centerX - 73,
      165,
    );

    // =============================================================
    // ขอบซ้ายของตัวเหรียญ
    // =============================================================

    path.cubicTo(
      centerX - 71,
      187,
      centerX - 65,
      208,
      centerX - 56,
      225,
    );

    path.cubicTo(
      centerX - 47,
      242,
      centerX - 32,
      254,
      centerX - 17,
      259,
    );

    // =============================================================
    // ก้นเหรียญ
    // =============================================================

    path.cubicTo(
      centerX - 11,
      261,
      centerX - 5,
      263,
      centerX,
      263,
    );

    path.cubicTo(
      centerX + 5,
      263,
      centerX + 11,
      261,
      centerX + 17,
      259,
    );

    // =============================================================
    // ด้านล่างขวา
    // =============================================================

    path.cubicTo(
      centerX + 32,
      254,
      centerX + 47,
      242,
      centerX + 56,
      225,
    );

    // =============================================================
    // ขอบขวาของตัวเหรียญ
    // =============================================================

    path.cubicTo(
      centerX + 65,
      208,
      centerX + 71,
      187,
      centerX + 73,
      165,
    );

    path.cubicTo(
      centerX + 75,
      146,
      centerX + 74,
      126,
      centerX + 71,
      108,
    );

    // =============================================================
    // ไหล่ขวาของเหรียญ
    // =============================================================

    path.cubicTo(
      centerX + 68,
      91,
      centerX + 63,
      76,
      centerX + 56,
      64,
    );

    // =============================================================
    // ด้านขวาของหู
    // =============================================================

    path.cubicTo(
      centerX + 48,
      51,
      centerX + 39,
      40,
      centerX + 28,
      32,
    );

    path.cubicTo(
      centerX + 18,
      24,
      centerX + 8,
      19,
      centerX,
      18,
    );

    path.close();

    canvas.drawPath(path, paint);

    // =============================================================
    // รูหู
    // =============================================================

    final holePaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          centerX,
          38,
        ),
        width: 20,
        height: 16,
      ),
      holePaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}