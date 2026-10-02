import 'package:flutter/material.dart';

// =====================================================
// โครงร่างรูปไข่ทั่วไป
// =====================================================

class OvalOutline extends StatelessWidget {
  const OvalOutline({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
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
      center: Offset(centerX, 150),
      width: 130,
      height: 190,
    );

    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// =====================================================
// หลวงปู่ฝั้น รุ่นแรก
// โครงสร้าง: รูปไข่ + หูในตัว
//
// ไม่มีรูปพระ
// ไม่มีตัวหนังสือ
// ไม่มีลวดลาย
// ไม่มีรายละเอียดผิว
//
// ใช้เพื่อเก็บ "ลักษณะโครงสร้าง" เท่านั้น
// =====================================================

class IntegratedEarOvalOutline extends StatelessWidget {
  const IntegratedEarOvalOutline({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
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

    final centerX = size.width / 2;

    // =================================================
    // โครงร่างภายนอกทั้งหมด
    //
    // หูและตัวเหรียญเป็นโครงสร้างเดียวกัน
    // =================================================

    final outerPath = Path();

    // -----------------------------
    // เริ่มจากด้านบนของช่องหู
    // -----------------------------

    outerPath.moveTo(centerX, 28);

    // ด้านซ้ายของหู
    outerPath.cubicTo(
      centerX - 16,
      28,
      centerX - 27,
      40,
      centerX - 27,
      56,
    );

    // คอหูด้านซ้าย
    outerPath.cubicTo(
      centerX - 27,
      67,
      centerX - 23,
      76,
      centerX - 19,
      84,
    );

    // ไหล่ด้านซ้าย
    outerPath.cubicTo(
      centerX - 37,
      96,
      centerX - 52,
      112,
      centerX - 60,
      132,
    );

    // ช่วงตัวเหรียญด้านซ้าย
    outerPath.cubicTo(
      centerX - 70,
      158,
      centerX - 70,
      193,
      centerX - 63,
      224,
    );

    outerPath.cubicTo(
      centerX - 56,
      255,
      centerX - 40,
      282,
      centerX - 20,
      297,
    );

    // ก้นเหรียญ
    outerPath.cubicTo(
      centerX - 9,
      305,
      centerX - 4,
      308,
      centerX,
      308,
    );

    outerPath.cubicTo(
      centerX + 4,
      308,
      centerX + 9,
      305,
      centerX + 20,
      297,
    );

    // ช่วงตัวเหรียญด้านขวา
    outerPath.cubicTo(
      centerX + 40,
      282,
      centerX + 56,
      255,
      centerX + 63,
      224,
    );

    outerPath.cubicTo(
      centerX + 70,
      193,
      centerX + 70,
      158,
      centerX + 60,
      132,
    );

    // ไหล่ด้านขวา
    outerPath.cubicTo(
      centerX + 52,
      112,
      centerX + 37,
      96,
      centerX + 19,
      84,
    );

    // คอหูด้านขวา
    outerPath.cubicTo(
      centerX + 23,
      76,
      centerX + 27,
      67,
      centerX + 27,
      56,
    );

    outerPath.cubicTo(
      centerX + 27,
      40,
      centerX + 16,
      28,
      centerX,
      28,
    );

    canvas.drawPath(outerPath, paint);

    // =================================================
    // ช่องหู
    //
    // เป็นข้อมูลโครงสร้างของหู
    // ไม่ใช่การวาดรายละเอียดเหรียญ
    // =================================================

    final earHolePaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final earHole = Path();

    earHole.moveTo(centerX, 39);

    earHole.cubicTo(
      centerX - 8,
      39,
      centerX - 13,
      46,
      centerX - 13,
      54,
    );

    earHole.cubicTo(
      centerX - 13,
      63,
      centerX - 8,
      69,
      centerX,
      69,
    );

    earHole.cubicTo(
      centerX + 8,
      69,
      centerX + 13,
      63,
      centerX + 13,
      54,
    );

    earHole.cubicTo(
      centerX + 13,
      46,
      centerX + 8,
      39,
      centerX,
      39,
    );

    earHole.close();

    canvas.drawPath(earHole, earHolePaint);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
