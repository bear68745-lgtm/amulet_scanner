import 'package:flutter/material.dart';

class OvalOutline extends StatelessWidget {
  const OvalOutline({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
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

    final rect = Rect.fromCenter(
      center: Offset(
        size.width / 2,
        size.height / 2,
      ),
      width: 110,
      height: 150,
    );

    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// =====================================================
// รูปไข่ + หูในตัว
// =====================================================

class IntegratedEarOvalOutline extends StatelessWidget {
  const IntegratedEarOvalOutline({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
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
      ..strokeWidth = 3;

    final centerX = size.width / 2;

    // ตัวเหรียญรูปไข่
    final coinRect = Rect.fromCenter(
      center: Offset(centerX, 125),
      width: 110,
      height: 150,
    );

    // โครงร่างหูในตัว
    //
    // จุดสำคัญ:
    // หูเป็นส่วนต่อเนื่องกับตัวเหรียญ
    // ไม่วาดเป็นวงแหวนแยกออกจากตัวเหรียญ
    final path = Path();

    path.moveTo(centerX - 24, 54);

    path.cubicTo(
      centerX - 23,
      38,
      centerX - 14,
      27,
      centerX,
      27,
    );

    path.cubicTo(
      centerX + 14,
      27,
      centerX + 23,
      38,
      centerX + 24,
      54,
    );

    // เชื่อมเข้ากับตัวเหรียญด้านซ้าย
    path.lineTo(
      centerX + 55,
      100,
    );

    // ด้านขวาของตัวเหรียญ
    path.cubicTo(
      centerX + 55,
      150,
      centerX + 40,
      200,
      centerX,
      200,
    );

    // ด้านซ้ายของตัวเหรียญ
    path.cubicTo(
      centerX - 40,
      200,
      centerX - 55,
      150,
      centerX - 55,
      100,
    );

    path.close();

    canvas.drawPath(path, paint);

    // เส้นแบ่งตำแหน่งฐานของหู
    // ใช้เป็นข้อมูลโครงสร้างสำหรับการพัฒนาระบบ
    final earBasePaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, 62),
        width: 48,
        height: 28,
      ),
      0.15,
      2.84,
      false,
      earBasePaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}