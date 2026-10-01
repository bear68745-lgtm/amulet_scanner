import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// ผลการทดลองวิเคราะห์รูปทรงของวัตถุ
///
/// หมายเหตุ:
/// - ยังไม่ใช่การจำแนกว่าเป็นพระหรือเหรียญ
/// - ยังไม่ตัดสินแท้/เก๊
/// - ใช้เฉพาะข้อมูลภาพชั่วคราว
/// - ไม่สร้างหรือบันทึกภาพใหม่
class ShapeAnalysisResult {
  final String shape;
  final double widthRatio;
  final double heightRatio;
  final double aspectRatio;
  final double fillRatio;
  final double edgeIrregularity;
  final String observation;

  const ShapeAnalysisResult({
    required this.shape,
    required this.widthRatio,
    required this.heightRatio,
    required this.aspectRatio,
    required this.fillRatio,
    required this.edgeIrregularity,
    required this.observation,
  });

  Map<String, dynamic> toMap() {
    return {
      'shape': shape,
      'widthRatio': widthRatio,
      'heightRatio': heightRatio,
      'aspectRatio': aspectRatio,
      'fillRatio': fillRatio,
      'edgeIrregularity': edgeIrregularity,
      'observation': observation,
    };
  }
}

/// Core ทดลองวิเคราะห์รูปทรง
class ShapeAnalyzer {
  const ShapeAnalyzer();

  Future<ShapeAnalysisResult> analyze({
    required String imagePath,
    required double left,
    required double top,
    required double right,
    required double bottom,
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

    final image = _resizeForAnalysis(decoded);

    final cropLeft = _clampInt(
      (left * image.width).floor(),
      0,
      image.width - 1,
    );

    final cropTop = _clampInt(
      (top * image.height).floor(),
      0,
      image.height - 1,
    );

    final cropRight = _clampInt(
      (right * image.width).ceil(),
      cropLeft + 1,
      image.width,
    );

    final cropBottom = _clampInt(
      (bottom * image.height).ceil(),
      cropTop + 1,
      image.height,
    );

    final objectWidth = cropRight - cropLeft;
    final objectHeight = cropBottom - cropTop;

    if (objectWidth < 5 || objectHeight < 5) {
      throw Exception('พื้นที่วัตถุเล็กเกินไปสำหรับวิเคราะห์รูปทรง');
    }

    final borderColor = _estimateLocalBorderColor(
      image,
      cropLeft,
      cropTop,
      cropRight,
      cropBottom,
    );

    final threshold = _calculateThreshold(
      image,
      cropLeft,
      cropTop,
      cropRight,
      cropBottom,
      borderColor,
    );

    int detectedPixels = 0;

    int minX = cropRight;
    int minY = cropBottom;
    int maxX = cropLeft;
    int maxY = cropTop;

    for (int y = cropTop; y < cropBottom; y++) {
      for (int x = cropLeft; x < cropRight; x++) {
        final pixel = image.getPixel(x, y);

        final distance = _colorDistance(
          pixel,
          borderColor,
        );

        if (distance >= threshold) {
          detectedPixels++;

          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (detectedPixels == 0) {
      return const ShapeAnalysisResult(
        shape: 'ไม่ชัดเจน',
        widthRatio: 0,
        heightRatio: 0,
        aspectRatio: 0,
        fillRatio: 0,
        edgeIrregularity: 1,
        observation: 'Core ไม่สามารถแยกพื้นที่วัตถุออกจากพื้นหลังได้ชัดเจน',
      );
    }

    final detectedWidth = maxX - minX + 1;
    final detectedHeight = maxY - minY + 1;

    final detectedArea =
        detectedWidth * detectedHeight;

    final fillRatio =
        detectedPixels / detectedArea;

    final aspectRatio =
        detectedWidth / detectedHeight;

    final widthRatio =
        detectedWidth / image.width;

    final heightRatio =
        detectedHeight / image.height;

    final edgeIrregularity = _estimateEdgeIrregularity(
      image,
      minX,
      minY,
      maxX,
      maxY,
      borderColor,
      threshold,
    );

    final shape = _classifyShape(
      aspectRatio,
      fillRatio,
      edgeIrregularity,
    );

    final observation = _buildObservation(
      aspectRatio,
      fillRatio,
      edgeIrregularity,
    );

    return ShapeAnalysisResult(
      shape: shape,
      widthRatio: widthRatio,
      heightRatio: heightRatio,
      aspectRatio: aspectRatio,
      fillRatio: fillRatio,
      edgeIrregularity: edgeIrregularity,
      observation: observation,
    );
  }

  img.Image _resizeForAnalysis(img.Image source) {
    const maxWidth = 320;

    if (source.width <= maxWidth) {
      return source;
    }

    return img.copyResize(
      source,
      width: maxWidth,
    );
  }

  List<double> _estimateLocalBorderColor(
    img.Image image,
    int left,
    int top,
    int right,
    int bottom,
  ) {
    final points = <List<int>>[
      [left, top],
      [right - 1, top],
      [left, bottom - 1],
      [right - 1, bottom - 1],
      [(left + right) ~/ 2, top],
      [(left + right) ~/ 2, bottom - 1],
      [left, (top + bottom) ~/ 2],
      [right - 1, (top + bottom) ~/ 2],
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

  double _calculateThreshold(
    img.Image image,
    int left,
    int top,
    int right,
    int bottom,
    List<double> borderColor,
  ) {
    double total = 0;
    int count = 0;

    for (int y = top; y < bottom; y += 4) {
      for (int x = left; x < right; x += 4) {
        final pixel = image.getPixel(x, y);

        total += _colorDistance(
          pixel,
          borderColor,
        );

        count++;
      }
    }

    if (count == 0) {
      return 30;
    }

    final average = total / count;

    final threshold = average * 1.35;

    if (threshold < 20) {
      return 20;
    }

    if (threshold > 90) {
      return 90;
    }

    return threshold;
  }

  double _colorDistance(
    img.Pixel pixel,
    List<double> borderColor,
  ) {
    final dr =
        pixel.r.toDouble() - borderColor[0];

    final dg =
        pixel.g.toDouble() - borderColor[1];

    final db =
        pixel.b.toDouble() - borderColor[2];

    return math.sqrt(
      dr * dr +
          dg * dg +
          db * db,
    );
  }

  double _estimateEdgeIrregularity(
    img.Image image,
    int left,
    int top,
    int right,
    int bottom,
    List<double> borderColor,
    double threshold,
  ) {
    final width = right - left + 1;
    final height = bottom - top + 1;

    if (width < 5 || height < 5) {
      return 1;
    }

    final samples = <double>[];

    const sampleCount = 24;

    for (int i = 0; i < sampleCount; i++) {
      final angle =
          (2 * math.pi * i) / sampleCount;

      final cx =
          (left + right) / 2;

      final cy =
          (top + bottom) / 2;

      final radius =
          math.min(width, height) / 2;

      final x =
          (cx + math.cos(angle) * radius)
              .round();

      final y =
          (cy + math.sin(angle) * radius)
              .round();

      final px = _clampInt(
        x,
        left,
        right,
      );

      final py = _clampInt(
        y,
        top,
        bottom,
      );

      final pixel =
          image.getPixel(px, py);

      final distance =
          _colorDistance(
        pixel,
        borderColor,
      );

      samples.add(
        distance >= threshold
            ? 1.0
            : 0.0,
      );
    }

    if (samples.isEmpty) {
      return 1;
    }

    double changes = 0;

    for (int i = 0; i < samples.length; i++) {
      final next =
          samples[(i + 1) % samples.length];

      if (samples[i] != next) {
        changes++;
      }
    }

    return (changes / samples.length)
        .clamp(0.0, 1.0);
  }

  String _classifyShape(
    double aspectRatio,
    double fillRatio,
    double edgeIrregularity,
  ) {
    final ratio =
        aspectRatio < 1
            ? 1 / aspectRatio
            : aspectRatio;

    // ยังไม่พยายามจำแนกรูปร่างเฉพาะทาง
    // เช่น เสมา / ใบโพธิ์ / เหรียญ
    // เพราะต้องมีข้อมูลตัวอย่างจริงก่อน

    if (ratio >= 0.90 &&
        ratio <= 1.10 &&
        fillRatio >= 0.65 &&
        fillRatio <= 0.88 &&
        edgeIrregularity < 0.30) {
      return 'ใกล้เคียงวงกลม';
    }

    if (ratio >= 1.15 &&
        fillRatio >= 0.55 &&
        fillRatio <= 0.90 &&
        edgeIrregularity < 0.35) {
      return 'ใกล้เคียงวงรี';
    }

    if (fillRatio >= 0.85 &&
        edgeIrregularity < 0.25) {
      return 'ใกล้เคียงสี่เหลี่ยม';
    }

    if (edgeIrregularity >= 0.30) {
      return 'รูปทรงไม่สม่ำเสมอ';
    }

    return 'รูปทรงอื่น/ยังไม่ชัดเจน';
  }

  String _buildObservation(
    double aspectRatio,
    double fillRatio,
    double edgeIrregularity,
  ) {
    final ratioText =
        aspectRatio.toStringAsFixed(2);

    final fillText =
        (fillRatio * 100)
            .toStringAsFixed(1);

    final edgeText =
        edgeIrregularity
            .toStringAsFixed(2);

    return 'อัตราส่วนกว้าง/สูง $ratioText, '
        'พื้นที่วัตถุภายในกรอบประมาณ $fillText%, '
        'ความไม่สม่ำเสมอของขอบ $edgeText';
  }

  int _clampInt(
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
