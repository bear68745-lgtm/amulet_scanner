import 'package:flutter/material.dart';

// =====================================================
// รูปไข่ทั่วไป
// =====================================================

class OvalOutline extends StatelessWidget {
  const OvalOutline({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      width: double.infinity,
      child: CustomPaint(
        painter: OvalOutlinePainter(),
      ),
    );
  }
}

class OvalOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final centerX = size.width / 2;

    final rect = Rect.fromCenter(
      center: Offset(centerX, 180),
      width: 145,
      height: 250,
    );

    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// =====================================================
// หลวงปู่ฝั้น อาจาโร รุ่นแรก ปี 2507
//
// โครงร่างโครงสร้างเท่านั้น
//
// รูปทรง : รูปไข่
// หู     : หูในตัว
//
// ไม่ใส่รายละเอียดพระ
// ไม่ใส่ตัวหนังสือ
// ไม่ใส่ลวดลาย
// =====================================================

class IntegratedEarOvalOutline extends StatelessWidget {
  const IntegratedEarOvalOutline({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380,
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
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;

    // =================================================
    // โครงร่างภายนอก
    //
    // ถอดจากลักษณะเหรียญรุ่นแรก:
    // - หูด้านบน
    // - ฐานใต้หูโค้งมน
    // - ไหล่เหรียญต่อเนื่อง
    // - ตัวเหรียญวงรีสูง
    // - ก้นเหรียญมน
    // =================================================

    final path = Path();

    // จุดเริ่มต้นด้านบนของหู
    path.moveTo(cx, 20);

    // -----------------------------------------------
    // หูด้านซ้าย
    // -----------------------------------------------

    path.cubicTo(
      cx - 9,
      20,
      cx - 19,
      24,
      cx - 28,
      32,
    );

    path.cubicTo(
      cx - 34,
      38,
      cx - 38,
      47,
      cx - 39,
      57,
    );

    // -----------------------------------------------
    // ฐานหูด้านซ้าย
    //
    // สำคัญ: ไม่ทำเป็นมุมแหลม
    // ให้โค้งมนลงไปหาตัวเหรียญ
    // -----------------------------------------------

    path.cubicTo(
      cx - 39,
      66,
      cx - 35,
      72,
      cx - 28,
      76,
    );

    path.cubicTo(
      cx - 22,
      80,
      cx - 15,
      82,
      cx - 9,
      83,
    );

    // -----------------------------------------------
    // ไหล่ซ้ายของตัวเหรียญ
    // -----------------------------------------------

    path.cubicTo(
      cx - 31,
      87,
      cx - 49,
      99,
      cx - 61,
      116,
    );

    path.cubicTo(
      cx - 75,
      136,
      cx - 82,
      164,
      cx - 83,
      195,
    );

    path.cubicTo(
      cx - 84,
      230,
      cx - 78,
      264,
      cx - 65,
      291,
    );

    path.cubicTo(
      cx - 54,
      315,
      cx - 39,
      333,
      cx - 21,
      344,
    );

    // -----------------------------------------------
    // ก้นเหรียญ
    // -----------------------------------------------

    path.cubicTo(
      cx - 13,
      349,
      cx - 6,
      352,
      cx,
      353,
    );

    path.cubicTo(
      cx + 6,
      352,
      cx + 13,
      349,
      cx + 21,
      344,
    );

    // -----------------------------------------------
    // ตัวเหรียญด้านขวา
    // -----------------------------------------------

    path.cubicTo(
      cx + 39,
      333,
      cx + 54,
      315,
      cx + 65,
      291,
    );

    path.cubicTo(
      cx + 78,
      264,
      cx + 84,
      230,
      cx + 83,
      195,
    );

    path.cubicTo(
      cx + 82,
      164,
      cx + 75,
      136,
      cx + 61,
      116,
    );

    path.cubicTo(
      cx + 49,
      99,
      cx + 31,
      87,
      cx + 9,
      83,
    );

    // -----------------------------------------------
    // ฐานหูด้านขวา
    //
    // ต้องมนเหมือนด้านซ้าย
    // -----------------------------------------------

    path.cubicTo(
      cx + 15,
      82,
      cx + 22,
      80,
      cx + 28,
      76,
    );

    path.cubicTo(
      cx + 35,
      72,
      cx + 39,
      66,
      cx + 39,
      57,
    );

    // -----------------------------------------------
    // หูด้านขวา
    // -----------------------------------------------

    path.cubicTo(
      cx + 38,
      47,
      cx + 34,
      38,
      cx + 28,
      32,
    );

    path.cubicTo(
      cx + 19,
      24,
      cx + 9,
      20,
      cx,
      20,
    );

    path.close();

    canvas.drawPath(path, paint);

    // =================================================
    // ช่องหู
    //
    // เป็นช่องกลมมน ไม่ใช่สี่เหลี่ยม
    // =================================================

    final holePaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final hole = Path();

    hole.moveTo(cx, 31);

    hole.cubicTo(
      cx - 8,
      31,
      cx - 14,
      37,
      cx - 14,
      44,
    );

    hole.cubicTo(
      cx - 14,
      51,
      cx - 8,
      56,
      cx,
      56,
    );

    hole.cubicTo(
      cx + 8,
      56,
      cx + 14,
      51,
      cx + 14,
      44,
    );

    hole.cubicTo(
      cx + 14,
      37,
      cx + 8,
      31,
      cx,
      31,
    );

    hole.close();

    canvas.drawPath(hole, holePaint);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}