import 'dart:io';

import 'package:image/image.dart' as img;

/// ผลการตรวจหาพื้นที่วัตถุหลักจากภาพ
///
/// ข้อมูลนี้ใช้สำหรับให้ Core รู้ว่า
/// องค์พระ/เหรียญน่าจะอยู่บริเวณใดของภาพ
///
/// ไม่เก็บภาพ
/// ไม่สร้างภาพใหม่
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
      throw Exception('ไม่พบไฟล์ภาพชั่วคราว');
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('ไฟล์ภาพว่าง');
    }

    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('ไม่สามารถอ่านภาพได้');
    }

    // ทำงานกับสำเนาในหน่วยความจำเท่านั้น
    // ไม่มีการเขียนภาพนี้กลับลงไฟล์
    final working = _resizeForAnalysis(decoded);

    final width = working.width;
    final height = working.height;

    if (width < 10 || height < 10) {
      throw Exception('ภาพมีขนาดเล็กเกินไปสำหรับการตรวจ');
    }

    final borderColor = _estimateBorderColor(
      working,
    );

    final threshold =
        _calculateThreshold(working, borderColor);

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

    // ถ้าหาองค์ประกอบหลักไม่ได้
    // ให้ใช้พื้นที่ภาพทั้งหมดเป็น fallback
    if (maxX < 0 || maxY < 0) {
      return const ImageObjectDetectionResult(
        area: '',
        left: 0.0,
        top: 0.0,
        right: 1.0,
        bottom: 1.0,
        objectRatio: 1.0,
      ).withArea(area);
    }

    // เพิ่มขอบเล็กน้อยเพื่อไม่ให้รายละเอียดขอบวัตถุถูกตัด
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

  img.Pixel _estimateBorderColor(
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

      r += pixel.r;
      g += pixel.g;
      b += pixel.b;
    }

    final count = points.length;

    return img.PixelRgb8(
      (r / count).round().clamp(0, 255),
      (g / count).round().clamp(0, 255),
      (b / count).round().clamp(0, 255),
    );
  }

  double _calculateThreshold(
    img.Image image,
    img.Pixel borderColor,
  ) {
    double total = 0;
    int count = 0;

    final width = image.width;
    final height = image.height;

    for (int y = 0; y < height; y += 4) {
      for (int x = 0; x < width; x += 4) {
        final pixel = image.getPixel(x, y);

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

    final average = total / count;

    final threshold = average * 1.35;

    if (threshold < 20) {
      return 20.0;
    }

    if (threshold > 90) {
      return 90.0;
    }

    return threshold;
  }

  double _colorDistance(
    img.Pixel a,
    img.Pixel b,
  ) {
    final dr = a.r - b.r;
    final dg = a.g - b.g;
    final db = a.b - b.b;

    return (dr * dr +
            dg * dg +
            db * db)
        .sqrt();
  }

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

extension _DoubleSqrt on double {
  double sqrt() {
    if (this <= 0) {
      return 0.0;
    }

    double x = this;

    for (int i = 0; i < 12; i++) {
      x = 0.5 * (x + this / x);
    }

    return x;
  }
}

extension _ResultArea
    on ImageObjectDetectionResult {
  ImageObjectDetectionResult withArea(
    String value,
  ) {
    return ImageObjectDetectionResult(
      area: value,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      objectRatio: objectRatio,
    );
  }
}
