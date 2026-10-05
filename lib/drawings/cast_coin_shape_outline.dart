import 'dart:math';

import 'package:flutter/material.dart';

const double _castOutlineStrokeWidth = 3.0;
const Color _castOutlineColor = Colors.brown;

class CastCoinShapeOutline extends StatelessWidget {
  final String shapeName;

  const CastCoinShapeOutline({
    super.key,
    required this.shapeName,
  });

  @override
  Widget build(BuildContext context) {
    switch (shapeName) {
      case 'จอบใหญ่':
        return const _CastShapeFrame(
          painter: CastJorbLargeOutlinePainter(),
        );

      case 'จอบเล็ก':
        return const _CastShapeFrame(
          painter: CastJorbSmallOutlinePainter(),
        );

      case 'รูปไข่':
        return const _CastShapeFrame(
          painter: CastOvalOutlinePainter(),
        );

      case 'เสมา':
        return const _CastShapeFrame(
          painter: CastSemaOutlinePainter(),
        );

      case 'ห้าเหลี่ยม':
        return const _CastShapeFrame(
          painter: CastPentagonOutlinePainter(),
        );

      case 'กลม':
        return const _CastShapeFrame(
          painter: CastCircleOutlinePainter(),
        );

      case 'หยดน้ำ':
        return const _CastShapeFrame(
          painter: CastTeardropOutlinePainter(),
        );

      case 'ทรงอื่น ๆ':
        return const _CastShapeFrame(
          painter: CastOtherOutlinePainter(),
        );

      default:
        return const _CastShapeFrame(
          painter: CastOtherOutlinePainter(),
        );
    }
  }
}

class _CastShapeFrame extends StatelessWidget {
  final CustomPainter painter;

  const _CastShapeFrame({
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

Paint _castPaint() {
  return Paint()
    ..color = _castOutlineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = _castOutlineStrokeWidth
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
}

class CastCircleOutlinePainter extends CustomPainter {
  const CastCircleOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 150);
    canvas.drawCircle(center, 105, _castPaint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CastOvalOutlinePainter extends CustomPainter {
  const CastOvalOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, 150),
        width: 150,
        height: 230,
      ),
      _castPaint(),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, 35),
        width: 22,
        height: 16,
      ),
      _castPaint(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CastSemaOutlinePainter extends CustomPainter {
  const CastSemaOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final path = Path();

    path.moveTo(centerX, 25);
    path.cubicTo(
      centerX - 65,
      45,
      centerX - 80,
      95,
      centerX - 72,
      155,
    );
    path.cubicTo(
      centerX - 65,
      215,
      centerX - 35,
      255,
      centerX,
      270,
    );
    path.cubicTo(
      centerX + 35,
      255,
      centerX + 65,
      215,
      centerX + 72,
      155,
    );
    path.cubicTo(
      centerX + 80,
      95,
      centerX + 65,
      45,
      centerX,
      25,
    );
    path.close();

    canvas.drawPath(path, _castPaint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CastPentagonOutlinePainter extends CustomPainter {
  const CastPentagonOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 150);
    final radius = 110.0;
    final path = Path();

    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (2 * pi * i / 5);
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
    canvas.drawPath(path, _castPaint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CastTeardropOutlinePainter extends CustomPainter {
  const CastTeardropOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final path = Path();

    path.moveTo(centerX, 25);

    path.cubicTo(
      centerX - 18,
      55,
      centerX - 80,
      115,
      centerX - 78,
      175,
    );

    path.cubicTo(
      centerX - 76,
      235,
      centerX - 35,
      270,
      centerX,
      270,
    );

    path.cubicTo(
      centerX + 35,
      270,
      centerX + 76,
      235,
      centerX + 78,
      175,
    );

    path.cubicTo(
      centerX + 80,
      115,
      centerX + 18,
      55,
      centerX,
      25,
    );

    path.close();

    canvas.drawPath(path, _castPaint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CastJorbLargeOutlinePainter extends CustomPainter {
  const CastJorbLargeOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final path = Path();

    path.moveTo(centerX, 35);

    path.cubicTo(
      centerX - 35,
      38,
      centerX - 70,
      60,
      centerX - 82,
      105,
    );

    path.cubicTo(
      centerX - 92,
      145,
      centerX - 88,
      190,
      centerX - 62,
      225,
    );

    path.cubicTo(
      centerX - 42,
      252,
      centerX - 18,
      265,
      centerX,
      270,
    );

    path.cubicTo(
      centerX + 18,
      265,
      centerX + 42,
      252,
      centerX + 62,
      225,
    );

    path.cubicTo(
      centerX + 88,
      190,
      centerX + 92,
      145,
      centerX + 82,
      105,
    );

    path.cubicTo(
      centerX + 70,
      60,
      centerX + 35,
      38,
      centerX,
      35,
    );

    path.close();

    canvas.drawPath(path, _castPaint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CastJorbSmallOutlinePainter extends CustomPainter {
  const CastJorbSmallOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final path = Path();

    path.moveTo(centerX, 55);

    path.cubicTo(
      centerX - 30,
      58,
      centerX - 58,
      82,
      centerX - 65,
      125,
    );

    path.cubicTo(
      centerX - 70,
      170,
      centerX - 50,
      215,
      centerX,
      250,
    );

    path.cubicTo(
      centerX + 50,
      215,
      centerX + 70,
      170,
      centerX + 65,
      125,
    );

    path.cubicTo(
      centerX + 58,
      82,
      centerX + 30,
      58,
      centerX,
      55,
    );

    path.close();

    canvas.drawPath(path, _castPaint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CastOtherOutlinePainter extends CustomPainter {
  const CastOtherOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 150);

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: 150,
        height: 210,
      ),
      _castPaint(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
