import 'package:flutter/material.dart';

class OvalOutline extends StatelessWidget {
  const OvalOutline({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
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

    final path = Path();

    // รูปไข่ทั่วไป
    path.moveTo(centerX, 35);

    path.cubicTo(
      centerX - 42,
      35,
      centerX - 68,
      75,
      centerX - 68,
      130,
    );

    path.cubicTo(
      centerX - 68,
      190,
      centerX - 43,
      230,
      centerX,
      230,
    );

    path.cubicTo(
      centerX + 43,
      230,
      centerX + 68,
      190,
      centerX + 68,
      130,
    );

    path.cubicTo(
      centerX + 68,
      75,
      centerX + 42,
      35,
      centerX,
      35,
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class IntegratedEarOvalOutline extends StatelessWidget {
  const IntegratedEarOvalOutline({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
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

    // ============================================================
    // โครงร่างเหรียญหลวงปู่ฝั้น รุ่นแรก
    //
    // ใช้เป็นข้อมูลโครงสร้างประจำรุ่น
    // ไม่ใช่ภาพพระ
    // ไม่ใช่ข้อมูลตำหนิ
    // ไม่ใช้ตัดสินแท้ / ปลอม
    // ============================================================

    final path = Path();

    // ------------------------------------------------------------
    // จุดเริ่มต้นด้านบนของหูในตัว
    // ------------------------------------------------------------
    path.moveTo(centerX, 25);

    // ด้านซ้ายของส่วนหู
    path.cubicTo(
      centerX - 10,
      27,
      centerX - 21,
      33,
      centerX - 31,
      43,
    );

    // ไหล่หูด้านซ้ายเข้าสู่ตัวเหรียญ
    path.cubicTo(
      centerX - 40,
      52,
      centerX - 53,
      61,
      centerX - 60,
      78,
    );

    // ------------------------------------------------------------
    // ขอบซ้ายของตัวเหรียญ
    // ------------------------------------------------------------
    path.cubicTo(
      centerX - 69,
      98,
      centerX - 72,
      121,
      centerX - 71,
      145,
    );

    path.cubicTo(
      centerX - 70,
      174,
      centerX - 64,
      199,
      centerX - 53,
      217,
    );

    // ------------------------------------------------------------
    // ส่วนล่างโค้งมน
    // ------------------------------------------------------------
    path.cubicTo(
      centerX - 42,
      235,
      centerX - 24,
      244,
      centerX,
      245,
    );

    path.cubicTo(
      centerX + 24,
      244,
      centerX + 42,
      235,
      centerX + 53,
      217,
    );

    // ------------------------------------------------------------
    // ขอบขวาของตัวเหรียญ
    // ------------------------------------------------------------
    path.cubicTo(
      centerX + 64,
      199,
      centerX + 70,
      174,
      centerX + 71,
      145,
    );

    path.cubicTo(
      centerX + 72,
      121,
      centerX + 69,
      98,
      centerX + 60,
      78,
    );

    // ไหล่หูด้านขวา
    path.cubicTo(
      centerX + 53,
      61,
      centerX + 40,
      52,
      centerX + 31,
      43,
    );

    // ด้านขวาของหู
    path.cubicTo(
      centerX + 21,
      33,
      centerX + 10,
      27,
      centerX,
      25,
    );

    path.close();

    canvas.drawPath(path, paint);

    // ============================================================
    // รูหู
    // ============================================================

    final holePaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, 45),
        width: 22,
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