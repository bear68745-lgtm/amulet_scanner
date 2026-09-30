import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// ผลการตรวจหาพื้นที่วัตถุหลักจากภาพ
///
/// ใช้สำหรับให้ Core รู้ว่า
/// องค์พระ/เหรียญน่าจะอยู่บริเวณใดของภาพ
///
/// ไม่เก็บภาพ
/// ไม่สร้างไฟล์ภาพใหม่
/// ไม่บันทึกสำเนาภาพ
/// ไม่ตัดสินแท้/เก๊
class ImageObjectDetectionResult {
  final String area;

  /// ตำแหน่ง normalized 0.0 - 1.0
  final double left;
  final double top;
  final double right;
  final double bottom;

  final double objectRatio;

  const ImageObjectDetectionResult({
    required this.area,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.objectRatio,
  });

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
      'objectRatio': objectRatio,
    };
  }
}

/// Core สำหรับค้นหาวัตถุหลักจากภาพ
///
/// อ่านภาพชั่วคราวในหน่วยความจำเท่านั้น
/// ไม่สร้างไฟล์ผลลัพธ์
class ImageObjectDetector {
  const ImageObjectDetector();

  Future<ImageObjectDetectionResult> detect({
    required String imagePath,
    required String area,
  }) async {
    final file = File(imagePath);

    if (!await file.exists()) {
      throw Exception(
        'ไม่พบไฟล์ภาพชั่วคราว',
      );
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception(
        'ไฟล์ภาพว่าง',
      );
    }

    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception(
        'ไม่สามารถอ่านภาพได้',
      );
    }

    // ทำงานกับข้อมูลภาพในหน่วยความจำเท่านั้น
    // ไม่มีการเขียนภาพกลับลงไฟล์
    final working = _resizeForAnalysis(decoded);

    final width = working.width;
    final height = working.height;

    if (width < 10 || height < 10) {
      throw Exception(
        'ภาพมีขนาดเล็กเกินไปสำหรับการตรวจ',
      );
    }

    final borderColor =
        _estimateBorderColor(working);

    final threshold = _calculateThreshold(
      working,
      borderColor,
    );

    int minX = width;
    int minY = height;
    int maxX = -1;
    int maxY = -1;

    int detectedPixels = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = working.getPixel(x, y);

        final distance = _colorDistance(
          pixel,
          borderColor,
        );

        if (distance >= threshold) {
          detectedPixels++;

          if (x < minX) {
            minX = x;
          }

          if (y < minY) {
            minY = y;
          }

          if (x > maxX) {
            maxX = x;
          }

          if (y > maxY) {
            maxY = y;
          }
        }
      }
    }

    // กันกรณีที่ไม่พบวัตถุ
    if (detectedPixels == 0 ||
        maxX < 0 ||
        maxY < 0) {
      return ImageObjectDetectionResult(
        area: area,
        left: 0.0,
        top: 0.0,
        right: 1.0,
        bottom: 1.0,
        objectRatio: 1.0,
      );
    }

    // เพิ่มขอบเล็กน้อย
    // เพื่อไม่ให้รายละเอียดบริเวณขอบวัตถุถูกตัด
    final paddingX =
        ((maxX - minX + 1) * 0.05).round();

    final paddingY =
        ((maxY - minY + 1) * 0.05).round();

    minX = _clamp(
      minX - paddingX,
      0,
      width - 1,
    );

    minY = _clamp(
      minY - paddingY,
      0,
      height - 1,
    );

    maxX = _clamp(
      maxX + paddingX,
      0,
      width - 1,
    );

    maxY = _clamp(
      maxY + paddingY,
      0,
      height - 1,
    );

    final objectWidth =
        maxX - minX + 1;

    final objectHeight =
        maxY - minY + 1;

    final objectRatio =
        (objectWidth * objectHeight) /
            (width * height);

    return ImageObjectDetectionResult(
      area: area,
      left: minX / width,
      top: minY / height,
      right: (maxX + 1) / width,
      bottom: (maxY + 1) / height,
      objectRatio: objectRatio,
    );
  }

  // ===================================================
  // RESIZE
  // ===================================================

  img.Image _resizeForAnalysis(
    img.Image source,
  ) {
    const maxWidth = 320;

    if (source.width <= maxWidth) {
      return source;
    }

    return img.copyResize(
      source,
      width: maxWidth,
    );
  }

  // ===================================================
  // ESTIMATE BORDER COLOR
  // ===================================================

  List<double> _estimateBorderColor(
    img.Image image,
  ) {
    final width = image.width;
    final height = image.height;

    final points = <List<int>>[
      [0, 0],
      [width - 1, 0],
      [0, height - 1],
      [width - 1, height - 1],
      [width ~/ 2, 0],
      [width ~/ 2, height - 1],
      [0, height ~/ 2],
      [width - 1, height ~/ 2],
    ];

    double r = 0;
    double g = 0;
    double b = 0;

    for (final point in points) {
      final pixel = image.getPixel(
        point[0],
        point[1],
      );

      r += pixel.r.toDouble();
      g += pixel.g.toDouble();
      b += pixel.b.toDouble();
    }

    final count = points.length.toDouble();

    return [
      r / count,
      g / count,
      b / count,
    ];
  }

  // ===================================================
  // THRESHOLD
  // ===================================================

  double _calculateThreshold(
    img.Image image,
    List<double> borderColor,
  ) {
    double total = 0;
    int count = 0;

    final width = image.width;
    final height = image.height;

    for (int y = 0; y < height; y += 4) {
      for (int x = 0; x < width; x += 4) {
        final pixel = image.getPixel(
          x,
          y,
        );

        total += _colorDistance(
          pixel,
          borderColor,
        );

        count++;
      }
    }

    if (count == 0) {
      return 30.0;
    }

    final average =
        total / count;

    final threshold =
        average * 1.35;

    if (threshold < 20) {
      return 20.0;
    }

    if (threshold > 90) {
      return 90.0;
    }

    return threshold;
  }

  // ===================================================
  // COLOR DISTANCE
  // ===================================================

  double _colorDistance(
    img.Pixel pixel,
    List<double> borderColor,
  ) {
    final dr =
        pixel.r.toDouble() -
        borderColor[0];

    final dg =
        pixel.g.toDouble() -
        borderColor[1];

    final db =
        pixel.b.toDouble() -
        borderColor[2];

    return math.sqrt(
      dr * dr +
          dg * dg +
          db * db,
    );
  }

  // ===================================================
  // CLAMP
  // ===================================================

  int _clamp(
    int value,
    int min,
    int max,
  ) {
    if (value < min) {
      return min;
    }

    if (value > max) {
      return max;
    }

    return value;
  }
}
