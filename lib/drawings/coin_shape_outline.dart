import 'package:flutter/material.dart';

/// ===============================================================
/// โครงร่างเหรียญ
///
/// หลักการ
/// - แสดงเฉพาะโครงร่างภายนอก
/// - แสดงห่วงและรูหูในแบบที่เหมาะสม
/// - ไม่ใส่รูปพระ
/// - ไม่ใส่ตัวหนังสือ
/// - ไม่ใส่ลวดลาย
/// - ไม่ใส่ตำหนิ
/// - ไม่ใช้ตัดสินแท้ / เก๊
/// ===============================================================

const double _outlineStrokeWidth = 3.0;
const Color _outlineColor = Colors.brown;

/// ===============================================================
/// ตัวกลางสำหรับแสดงโครงร่างตามชื่อรูปทรง
/// ===============================================================

class CoinShapeOutline extends StatelessWidget {
  final String shapeName;

  const CoinShapeOutline({
    super.key,
    required this.shapeName,
  });

  @override
  Widget build(BuildContext context) {
    switch (shapeName) {
      case 'กลม':
        return const _ShapeFrame(
          painter: CircleOutlinePainter(),
        );

      case 'รูปไข่':
        return const _ShapeFrame(
          painter: OvalOutlinePainter(),
        );

      case 'เสมา':
        return const _ShapeFrame(
          painter: SemaOutlinePainter(),
        );

      case 'อาร์ม':
        return const _ShapeFrame(
          painter: ArmOutlinePainter(),
        );

      case 'ห้าเหลี่ยม':
        return const _ShapeFrame(
          painter: PentagonOutlinePainter(),
        );

      case 'หกเหลี่ยม':
        return const _ShapeFrame(
          painter: HexagonOutlinePainter(),
        );

      case 'เม็ดแตง':
        return const _ShapeFrame(
          painter: MelonSeedOutlinePainter(),
        );

      case 'ใบสาเก':
        return const _ShapeFrame(
          painter: BreadfruitLeafOutlinePainter(),
        );

      case 'ซุ้มกอ':
        return const _ShapeFrame(
          painter: SumkorOutlinePainter(),
        );

      case 'น้ำเต้า':
        return const _ShapeFrame(
          painter: GourdOutlinePainter(),
        );

      case 'หยดน้ำ':
        return const _ShapeFrame(
          painter: TeardropOutlinePainter(),
        );

      case 'นั่งพาน':
        return const _ShapeFrame(
          painter: NangPhanOutlinePainter(),
        );

      case 'สี่เหลี่ยม':
        return const _ShapeFrame(
          painter: RectangleOutlinePainter(),
        );

      case 'สี่เหลี่ยมข้าวหลามตัด':
        return const _ShapeFrame(
          painter: DiamondOutlinePainter(),
        );

      case 'จอบ':
        return const _ShapeFrame(
          painter: JorbOutlinePainter(),
        );

      default:
        return const _ShapeFrame(
          painter: CircleOutlinePainter(),
        );
    }
  }
}

class _ShapeFrame extends StatelessWidget {
  final CustomPainter painter;

  const _ShapeFrame({
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: CustomPaint(
        painter: painter,
      ),
    );
  }
}

/// ===============================================================
/// รูปที่ 1 : กลม
/// ===============================================================

class CircleOutlinePainter extends CustomPainter {
  const CircleOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 150);
    final radius = 105.0;

    final paint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineStrokeWidth;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 2 : รูปไข่ทั่วไป + ห่วง
/// ===============================================================

class OvalOutlinePainter extends CustomPainter {
  const OvalOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final paint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineStrokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final holePaint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final earPath = Path()
      ..moveTo(centerX - 12, 38)
      ..cubicTo(
        centerX - 12,
        20,
        centerX - 7,
        10,
        centerX,
        10,
      )
      ..cubicTo(
        centerX + 7,
        10,
        centerX + 12,
        20,
        centerX + 12,
        38,
      );

    canvas.drawPath(earPath, paint);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, 22),
        width: 10,
        height: 12,
      ),
      holePaint,
    );

    final body = Path()
      ..moveTo(centerX, 36)
      ..cubicTo(
        centerX - 35,
        36,
        centerX - 68,
        58,
        centerX - 78,
        105,
      )
      ..cubicTo(
        centerX - 84,
        140,
        centerX - 81,
        190,
        centerX - 67,
        225,
      )
      ..cubicTo(
        centerX - 55,
        255,
        centerX - 30,
        270,
        centerX,
        272,
      )
      ..cubicTo(
        centerX + 30,
        270,
        centerX + 55,
        255,
        centerX + 67,
        225,
      )
      ..cubicTo(
        centerX + 81,
        190,
        centerX + 84,
        140,
        centerX + 78,
        105,
      )
      ..cubicTo(
        centerX + 68,
        58,
        centerX + 35,
        36,
        centerX,
        36,
      )
      ..close();

    canvas.drawPath(body, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 3 : เสมา
/// ===============================================================

class SemaOutlinePainter extends CustomPainter {
  const SemaOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final paint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineStrokeWidth
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(cx, 25)
      ..cubicTo(cx - 28, 34, cx - 55, 58, cx - 72, 92)
      ..cubicTo(cx - 86, 122, cx - 88, 174, cx - 72, 216)
      ..cubicTo(cx - 58, 252, cx - 30, 270, cx, 275)
      ..cubicTo(cx + 30, 270, cx + 58, 252, cx + 72, 216)
      ..cubicTo(cx + 88, 174, cx + 86, 122, cx + 72, 92)
      ..cubicTo(cx + 55, 58, cx + 28, 34, cx, 25)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 4 : อาร์ม
/// ===============================================================

class ArmOutlinePainter extends CustomPainter {
  const ArmOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final paint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineStrokeWidth
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(cx, 25)
      ..cubicTo(cx - 32, 30, cx - 66, 48, cx - 78, 82)
      ..cubicTo(cx - 88, 112, cx - 84, 188, cx - 68, 225)
      ..cubicTo(cx - 55, 255, cx - 28, 270, cx, 275)
      ..cubicTo(cx + 28, 270, cx + 55, 255, cx + 68, 225)
      ..cubicTo(cx + 84, 188, cx + 88, 112, cx + 78, 82)
      ..cubicTo(cx + 66, 48, cx + 32, 30, cx, 25)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 5 : ห้าเหลี่ยม
/// ===============================================================

class PentagonOutlinePainter extends CustomPainter {
  const PentagonOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    _drawPolygon(
      canvas,
      size,
      sides: 5,
      radius: 105,
      rotation: -90,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 6 : หกเหลี่ยม
/// ===============================================================

class HexagonOutlinePainter extends CustomPainter {
  const HexagonOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    _drawPolygon(
      canvas,
      size,
      sides: 6,
      radius: 105,
      rotation: -90,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 7 : เม็ดแตง
/// ===============================================================

class MelonSeedOutlinePainter extends CustomPainter {
  const MelonSeedOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final paint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineStrokeWidth;

    final path = Path()
      ..moveTo(cx, 22)
      ..cubicTo(
        cx - 38,
        55,
        cx - 55,
        105,
        cx - 48,
        160,
      )
      ..cubicTo(
        cx - 42,
        215,
        cx - 20,
        255,
        cx,
        275,
      )
      ..cubicTo(
        cx + 20,
        255,
        cx + 42,
        215,
        cx + 48,
        160,
      )
      ..cubicTo(
        cx + 55,
        105,
        cx + 38,
        55,
        cx,
        22,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 8 : ใบสาเก
/// ===============================================================

class BreadfruitLeafOutlinePainter extends CustomPainter {
  const BreadfruitLeafOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final paint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineStrokeWidth;

    final path = Path()
      ..moveTo(cx, 20)
      ..cubicTo(cx - 45, 45, cx - 78, 95, cx - 76, 155)
      ..cubicTo(cx - 74, 215, cx - 38, 260, cx, 278)
      ..cubicTo(cx + 38, 260, cx + 74, 215, cx + 76, 155)
      ..cubicTo(cx + 78, 95, cx + 45, 45, cx, 20)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 9 : ซุ้มกอ
/// ===============================================================

class SumkorOutlinePainter extends CustomPainter {
  const SumkorOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final paint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineStrokeWidth
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(cx, 22)
      ..cubicTo(cx - 45, 35, cx - 76, 72, cx - 84, 120)
      ..cubicTo(cx - 90, 170, cx - 75, 220, cx - 50, 252)
      ..cubicTo(cx - 28, 274, cx + 28, 274, cx + 50, 252)
      ..cubicTo(cx + 75, 220, cx + 90, 170, cx + 84, 120)
      ..cubicTo(cx + 76, 72, cx + 45, 35, cx, 22)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 10 : น้ำเต้า
/// ===============================================================

class GourdOutlinePainter extends CustomPainter {
  const GourdOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final paint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineStrokeWidth;

    final path = Path()
      ..moveTo(cx, 25)
      ..cubicTo(cx - 30, 25, cx - 42, 48, cx - 30, 78)
      ..cubicTo(cx - 20, 100, cx - 50, 105, cx - 62, 135)
      ..cubicTo(cx - 80, 180, cx - 65, 230, cx - 35, 255)
      ..cubicTo(cx - 15, 272, cx + 15, 272, cx + 35, 255)
      ..cubicTo(cx + 65, 230, cx + 80, 180, cx + 62, 135)
      ..cubicTo(cx + 50, 105, cx + 20, 100, cx + 30, 78)
      ..cubicTo(cx + 42, 48, cx + 30, 25, cx, 25)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 11 : หยดน้ำ
/// ===============================================================

class TeardropOutlinePainter extends CustomPainter {
  const TeardropOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final paint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineStrokeWidth;

    final path = Path()
      ..moveTo(cx, 20)
      ..cubicTo(cx - 18, 48, cx - 70, 100, cx - 70, 160)
      ..cubicTo(cx - 70, 225, cx - 35, 270, cx, 275)
      ..cubicTo(cx + 35, 270, cx + 70, 225, cx + 70, 160)
      ..cubicTo(cx + 70, 100, cx + 18, 48, cx, 20)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 12 : นั่งพาน
/// ===============================================================

class NangPhanOutlinePainter extends CustomPainter {
  const NangPhanOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final paint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineStrokeWidth
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(cx, 28)
      ..cubicTo(cx - 35, 32, cx - 62, 58, cx - 70, 95)
      ..lineTo(cx - 82, 205)
      ..cubicTo(cx - 65, 220, cx - 45, 225, cx - 30, 230)
      ..lineTo(cx - 55, 260)
      ..lineTo(cx + 55, 260)
      ..lineTo(cx + 30, 230)
      ..cubicTo(cx + 45, 225, cx + 65, 220, cx + 82, 205)
      ..lineTo(cx + 70, 95)
      ..cubicTo(cx + 62, 58, cx + 35, 32, cx, 28)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 13 : สี่เหลี่ยม
/// ===============================================================

class RectangleOutlinePainter extends CustomPainter {
  const RectangleOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineStrokeWidth;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, 150),
      width: 150,
      height: 220,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 14 : สี่เหลี่ยมข้าวหลามตัด
/// ===============================================================

class DiamondOutlinePainter extends CustomPainter {
  const DiamondOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final paint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineStrokeWidth
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(cx, 30)
      ..lineTo(cx + 78, 150)
      ..lineTo(cx, 270)
      ..lineTo(cx - 78, 150)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// รูปที่ 15 : จอบ
/// ===============================================================

class JorbOutlinePainter extends CustomPainter {
  const JorbOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final paint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineStrokeWidth
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(cx, 25)
      ..cubicTo(cx - 35, 35, cx - 65, 62, cx - 78, 105)
      ..cubicTo(cx - 90, 145, cx - 86, 205, cx - 65, 235)
      ..cubicTo(cx - 45, 262, cx - 20, 275, cx, 278)
      ..cubicTo(cx + 20, 275, cx + 45, 262, cx + 65, 235)
      ..cubicTo(cx + 86, 205, cx + 90, 145, cx + 78, 105)
      ..cubicTo(cx + 65, 62, cx + 35, 35, cx, 25)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================================
/// ตัวช่วยวาดรูปหลายเหลี่ยม
/// ===============================================================

void _drawPolygon(
  Canvas canvas,
  Size size, {
  required int sides,
  required double radius,
  required double rotation,
}) {
  final paint = Paint()
    ..color = _outlineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = _outlineStrokeWidth
    ..strokeJoin = StrokeJoin.round;

  final center = Offset(size.width / 2, 150);
  final path = Path();

  for (int i = 0; i < sides; i++) {
    final angle =
        (rotation + (360 / sides) * i) * 3.141592653589793 / 180;

    final point = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );

    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }

  path.close();
  canvas.drawPath(path, paint);
}

/// ===============================================================
/// โครงร่างเฉพาะเหรียญหลวงปู่ฝั้น รุ่นแรก
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
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();

    path.moveTo(centerX, 18);

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

    path.cubicTo(
      centerX + 32,
      254,
      centerX + 47,
      242,
      centerX + 56,
      225,
    );

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

    path.cubicTo(
      centerX + 68,
      91,
      centerX + 63,
      76,
      centerX + 56,
      64,
    );

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

    final holePaint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, 38),
        width: 20,
        height: 16,
      ),
      holePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}