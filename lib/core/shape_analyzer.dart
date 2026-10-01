import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// ============================================================
/// รูปทรงเหรียญมาตรฐานของ Core
/// ============================================================
///
/// รายการนี้เป็นโครงสร้างกลางสำหรับรูปทรงเหรียญ
/// ตอนนี้ยังไม่กำหนดกฎการจำแนกของแต่ละรูปทรง
/// และยังไม่ใช้เป็นตัวตัดสินผลการวิเคราะห์
///
/// ภายหลังจะเพิ่ม "สัญลักษณ์โครงร่างภายนอก"
/// ให้แต่ละรูปทรงทีละรูป หลังจากทดสอบกับภาพจริง
const List<String> coinShapeNames = [
  'กลม',
  'รูปไข่',
  'เสมา',
  'อาร์ม',
  'ห้าเหลี่ยม',
  'หกเหลี่ยม',
  'เม็ดแตง',
  'ใบสาเก',
  'ซุ้มกอ',
  'น้ำเต้า',
  'หยดน้ำ',
  'นั่งพาน',
  'สี่เหลี่ยม',
  'สี่เหลี่ยมข้าวหลามตัด',
  'จอบ',
];

/// ============================================================
/// สัญลักษณ์โครงร่างของรูปทรง
/// ============================================================
///
/// โครงสร้างพื้นฐานของชื่อรูปทรง
///
/// ตอนนี้ยังไม่ใส่กฎการจำแนก
/// และยังไม่ผูกกับผลการวิเคราะห์
class CoinShapeSymbol {
  final String name;

  const CoinShapeSymbol({
    required this.name,
  });
}

/// ตารางสัญลักษณ์รูปทรงเหรียญมาตรฐาน
const List<CoinShapeSymbol> coinShapeSymbols = [
  CoinShapeSymbol(name: 'กลม'),
  CoinShapeSymbol(name: 'รูปไข่'),
  CoinShapeSymbol(name: 'เสมา'),
  CoinShapeSymbol(name: 'อาร์ม'),
  CoinShapeSymbol(name: 'ห้าเหลี่ยม'),
  CoinShapeSymbol(name: 'หกเหลี่ยม'),
  CoinShapeSymbol(name: 'เม็ดแตง'),
  CoinShapeSymbol(name: 'ใบสาเก'),
  CoinShapeSymbol(name: 'ซุ้มกอ'),
  CoinShapeSymbol(name: 'น้ำเต้า'),
  CoinShapeSymbol(name: 'หยดน้ำ'),
  CoinShapeSymbol(name: 'นั่งพาน'),
  CoinShapeSymbol(name: 'สี่เหลี่ยม'),
  CoinShapeSymbol(name: 'สี่เหลี่ยมข้าวหลามตัด'),
  CoinShapeSymbol(name: 'จอบ'),
];

/// ============================================================
/// สัญลักษณ์โครงร่างภายนอก
/// ============================================================
///
/// radialProfile คือข้อมูลของเส้นรอบนอก
/// ที่สกัดจากภาพตัวอย่างจริง
///
/// แต่ละค่าจะเป็นระยะจากจุดศูนย์กลาง
/// ไปยังเส้นรอบนอกตามมุมต่าง ๆ
///
/// ข้อมูลนี้เป็น "โครงร่างเชิงตัวเลข"
/// ไม่ใช่ภาพ
///
/// ไม่เก็บภาพต้นฉบับ
/// ไม่สร้างภาพใหม่
/// ไม่บันทึกสำเนาภาพ
class ShapeOutlineSymbol {
  final String name;

  /// ค่าระยะเส้นรอบนอกที่ทำให้เป็นสัดส่วนแล้ว
  ///
  /// ตัวอย่างในอนาคต:
  /// [
  ///   1.00,
  ///   0.98,
  ///   0.96,
  ///   ...
  /// ]
  ///
  /// จำนวนและวิธีสร้างค่าจะมาจากภาพตัวอย่างจริง
  final List<double> radialProfile;

  const ShapeOutlineSymbol({
    required this.name,
    required this.radialProfile,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'radialProfile': radialProfile,
    };
  }
}

/// ============================================================
/// ต้นแบบโครงร่างรูปไข่
/// ============================================================
///
/// ตอนนี้ยังไม่มีค่าจากภาพจริง
///
/// จึงยังไม่กำหนด radialProfile เอง
/// เพื่อไม่ให้ Core เรียนจากค่าที่เราสมมติขึ้น
///
/// ขั้นต่อไปจะนำภาพเหรียญรูปไข่จริงมา
/// สกัดเส้นรอบนอก แล้วสร้าง radialProfile
/// ให้กับสัญลักษณ์นี้
ShapeOutlineSymbol ovalOutlineSymbol =
    const ShapeOutlineSymbol(
  name: 'รูปไข่',
  radialProfile: [],
);

/// ผลการวิเคราะห์รูปทรงของวัตถุ
///
/// หมายเหตุ:
/// - เป็นการวิเคราะห์รูปทรงจากภาพเท่านั้น
/// - ยังไม่จำแนกว่าเป็นพระหรือเหรียญ
/// - ยังไม่ตัดสินแท้/เก๊
/// - ไม่สร้างหรือบันทึกภาพใหม่
class ShapeAnalysisResult {
  final String shape;
  final double widthRatio;
  final double heightRatio;
  final double aspectRatio;
  final double fillRatio;
  final double edgeIrregularity;
  final double circularity;
  final double radialConsistency;
  final String observation;

  const ShapeAnalysisResult({
    required this.shape,
    required this.widthRatio,
    required this.heightRatio,
    required this.aspectRatio,
    required this.fillRatio,
    required this.edgeIrregularity,
    required this.circularity,
    required this.radialConsistency,
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
      'circularity': circularity,
      'radialConsistency': radialConsistency,
      'observation': observation,
    };
  }
}

/// Core ทดลองวิเคราะห์รูปทรง
class ShapeAnalyzer {
  const ShapeAnalyzer();

  /// ============================================================
  /// สกัดสัญลักษณ์โครงร่างจากภาพตัวอย่างจริง
  /// ============================================================
  ///
  /// ใช้ภาพชั่วคราวเป็นแหล่งข้อมูล
  ///
  /// ภาพจะถูกอ่านเพื่อหาข้อมูลโครงร่างเท่านั้น
  ///
  /// ไม่สร้างภาพใหม่
  /// ไม่บันทึกภาพ
  /// ไม่เก็บสำเนาภาพ
  ///
  /// ผลลัพธ์คือ ShapeOutlineSymbol
  /// ซึ่งเก็บเฉพาะตัวเลขของเส้นรอบนอก
  Future<ShapeOutlineSymbol> extractOutlineSymbol({
    required String imagePath,
    required String shapeName,
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
      throw Exception(
        'พื้นที่ตัวอย่างเล็กเกินไปสำหรับสร้างโครงร่าง',
      );
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

    final mask = <bool>[
      for (int i = 0; i < objectWidth * objectHeight; i++)
        false,
    ];

    int detectedPixels = 0;

    for (int y = cropTop; y < cropBottom; y++) {
      for (int x = cropLeft; x < cropRight; x++) {
        final pixel = image.getPixel(x, y);

        final distance = _colorDistance(
          pixel,
          borderColor,
        );

        if (distance >= threshold) {
          final localX = x - cropLeft;
          final localY = y - cropTop;

          mask[
            localY * objectWidth + localX
          ] = true;

          detectedPixels++;
        }
      }
    }

    if (detectedPixels == 0) {
      throw Exception(
        'ไม่สามารถแยกวัตถุตัวอย่างออกจากพื้นหลังได้',
      );
    }

    final centroid = _calculateCentroid(
      image,
      mask,
      objectWidth,
      objectHeight,
      cropLeft,
      cropTop,
    );

    const sampleCount = 72;

    final radialProfile = <double>[];

    final maxRadius = math.sqrt(
      objectWidth * objectWidth +
          objectHeight * objectHeight,
    );

    /// ----------------------------------------------------------
    /// หาเส้นรอบนอกสุด
    /// ----------------------------------------------------------
    ///
    /// จุดสำคัญ:
    /// ไม่หยุดเมื่อเจอช่องว่างเล็ก ๆ จากลวดลายด้านใน
    ///
    /// จะเดินต่อไปจนสุดแนวรัศมี
    /// แล้วเก็บจุดที่เป็นวัตถุที่อยู่ไกลที่สุด
    ///
    /// จึงเน้น "โครงร่างภายนอก"
    /// มากกว่ารายละเอียดภายในเหรียญ
    for (int i = 0; i < sampleCount; i++) {
      final angle =
          (2 * math.pi * i) / sampleCount;

      double outerRadius = 0;

      for (
        double radius = 1;
        radius <= maxRadius;
        radius += 1
      ) {
        final x =
            (centroid.x +
                    math.cos(angle) * radius)
                .round();

        final y =
            (centroid.y +
                    math.sin(angle) * radius)
                .round();

        final localX =
            x - cropLeft;

        final localY =
            y - cropTop;

        if (localX < 0 ||
            localX >= objectWidth ||
            localY < 0 ||
            localY >= objectHeight) {
          break;
        }

        if (mask[
            localY * objectWidth + localX]) {
          outerRadius = radius;
        }
      }

      radialProfile.add(outerRadius);
    }

    final validRadii =
        radialProfile.where((value) => value > 0).toList();

    if (validRadii.length < sampleCount * 0.80) {
      throw Exception(
        'เส้นรอบนอกของตัวอย่างไม่สมบูรณ์พอสำหรับสร้างสัญลักษณ์',
      );
    }

    final maximum =
        validRadii.reduce(math.max);

    if (maximum <= 0) {
      throw Exception(
        'ไม่พบระยะเส้นรอบนอกของตัวอย่าง',
      );
    }

    /// ----------------------------------------------------------
    /// ทำให้ค่ามีสเกลมาตรฐาน
    /// ----------------------------------------------------------
    ///
    /// ค่าสูงสุด = 1.0
    /// ค่าที่เหลือเป็นสัดส่วนของรัศมี
    ///
    /// ทำให้ไม่ผูกกับขนาดภาพ
    /// และไม่ผูกกับขนาดเหรียญจริง
    final normalizedProfile =
        radialProfile.map((radius) {
      if (radius <= 0) {
        return 0.0;
      }

      return radius / maximum;
    }).toList();

    return ShapeOutlineSymbol(
      name: shapeName,
      radialProfile: normalizedProfile,
    );
  }

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
      throw Exception(
        'พื้นที่วัตถุเล็กเกินไปสำหรับวิเคราะห์รูปทรง',
      );
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

    final mask = <bool>[
      for (int i = 0; i < objectWidth * objectHeight; i++)
        false,
    ];

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
          final localX = x - cropLeft;
          final localY = y - cropTop;

          mask[
            localY * objectWidth + localX
          ] = true;

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
        circularity: 0,
        radialConsistency: 0,
        observation:
            'Core ไม่สามารถแยกพื้นที่วัตถุออกจากพื้นหลังได้ชัดเจน',
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

    final centroid = _calculateCentroid(
      image,
      mask,
      objectWidth,
      objectHeight,
      cropLeft,
      cropTop,
    );

    final radial = _analyzeRadialShape(
      image,
      mask,
      objectWidth,
      objectHeight,
      cropLeft,
      cropTop,
      centroid,
      threshold,
    );

    final edgeIrregularity =
        radial.edgeIrregularity;

    final circularity =
        radial.circularity;

    final radialConsistency =
        radial.radialConsistency;

    final shape = _classifyShape(
      aspectRatio: aspectRatio,
      fillRatio: fillRatio,
      edgeIrregularity: edgeIrregularity,
      circularity: circularity,
      radialConsistency: radialConsistency,
    );

    final observation = _buildObservation(
      aspectRatio: aspectRatio,
      fillRatio: fillRatio,
      edgeIrregularity: edgeIrregularity,
      circularity: circularity,
      radialConsistency: radialConsistency,
    );

    return ShapeAnalysisResult(
      shape: shape,
      widthRatio: widthRatio,
      heightRatio: heightRatio,
      aspectRatio: aspectRatio,
      fillRatio: fillRatio,
      edgeIrregularity: edgeIrregularity,
      circularity: circularity,
      radialConsistency: radialConsistency,
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

  _Centroid _calculateCentroid(
    img.Image image,
    List<bool> mask,
    int width,
    int height,
    int cropLeft,
    int cropTop,
  ) {
    double totalX = 0;
    double totalY = 0;
    int count = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (!mask[y * width + x]) {
          continue;
        }

        totalX += cropLeft + x;
        totalY += cropTop + y;
        count++;
      }
    }

    if (count == 0) {
      return _Centroid(
        x: cropLeft + width / 2,
        y: cropTop + height / 2,
      );
    }

    return _Centroid(
      x: totalX / count,
      y: totalY / count,
    );
  }

  _RadialShapeResult _analyzeRadialShape(
    img.Image image,
    List<bool> mask,
    int width,
    int height,
    int cropLeft,
    int cropTop,
    _Centroid centroid,
    double threshold,
  ) {
    const sampleCount = 72;

    final radii = <double>[];

    for (int i = 0; i < sampleCount; i++) {
      final angle =
          (2 * math.pi * i) / sampleCount;

      double radius = 0;

      final maxRadius =
          math.sqrt(
            width * width +
                height * height,
          );

      for (double r = 1; r <= maxRadius; r += 1) {
        final x =
            (centroid.x +
                    math.cos(angle) * r)
                .round();

        final y =
            (centroid.y +
                    math.sin(angle) * r)
                .round();

        final localX =
            x - cropLeft;

        final localY =
            y - cropTop;

        if (localX < 0 ||
            localX >= width ||
            localY < 0 ||
            localY >= height) {
          break;
        }

        if (!mask[
            localY * width + localX]) {
          break;
        }

        radius = r;
      }

      radii.add(radius);
    }

    final validRadii =
        radii.where((value) => value > 0).toList();

    if (validRadii.length < sampleCount * 0.50) {
      return const _RadialShapeResult(
        circularity: 0,
        radialConsistency: 0,
        edgeIrregularity: 1,
      );
    }

    final averageRadius =
        validRadii.reduce((a, b) => a + b) /
            validRadii.length;

    if (averageRadius <= 0) {
      return const _RadialShapeResult(
        circularity: 0,
        radialConsistency: 0,
        edgeIrregularity: 1,
      );
    }

    double variance = 0;

    for (final radius in validRadii) {
      final difference =
          radius - averageRadius;

      variance +=
          difference * difference;
    }

    variance /= validRadii.length;

    final standardDeviation =
        math.sqrt(variance);

    final coefficient =
        standardDeviation / averageRadius;

    final radialConsistency =
        (1 - coefficient)
            .clamp(0.0, 1.0);

    final minRadius =
        validRadii.reduce(math.min);

    final maxRadius =
        validRadii.reduce(math.max);

    final radiusRatio =
        minRadius / maxRadius;

    final circularity =
        radiusRatio
            .clamp(0.0, 1.0);

    double changes = 0;

    for (int i = 0;
        i < validRadii.length;
        i++) {
      final current =
          validRadii[i];

      final next =
          validRadii[
              (i + 1) %
                  validRadii.length];

      final difference =
          (current - next).abs();

      if (difference >
          averageRadius * 0.18) {
        changes++;
      }
    }

    final edgeIrregularity =
        (changes / validRadii.length)
            .clamp(0.0, 1.0);

    return _RadialShapeResult(
      circularity: circularity,
      radialConsistency: radialConsistency,
      edgeIrregularity: edgeIrregularity,
    );
  }

  String _classifyShape({
    required double aspectRatio,
    required double fillRatio,
    required double edgeIrregularity,
    required double circularity,
    required double radialConsistency,
  }) {
    final ratio =
        aspectRatio < 1
            ? 1 / aspectRatio
            : aspectRatio;

    // ระบบจำแนกรูปทรงเดิมยังคงไว้ก่อน
    // ยังไม่ผูกเข้ากับสัญลักษณ์ 15 รูป
    // จนกว่าจะทดสอบโครงร่างจริง

    if (ratio >= 0.90 &&
        ratio <= 1.10 &&
        circularity >= 0.78 &&
        radialConsistency >= 0.72 &&
        edgeIrregularity < 0.25) {
      return 'ใกล้เคียงวงกลม';
    }

    if (ratio >= 1.15 &&
        ratio <= 2.20 &&
        radialConsistency >= 0.55 &&
        edgeIrregularity < 0.30) {
      return 'ใกล้เคียงวงรี';
    }

    if (ratio >= 0.90 &&
        ratio <= 1.10 &&
        fillRatio >= 0.75 &&
        edgeIrregularity < 0.20 &&
        radialConsistency < 0.72) {
      return 'ใกล้เคียงทรงหลายเหลี่ยม/สี่เหลี่ยม';
    }

    if (edgeIrregularity >= 0.35 ||
        radialConsistency < 0.45) {
      return 'รูปทรงไม่สม่ำเสมอ';
    }

    return 'รูปทรงอื่น/ยังไม่ชัดเจน';
  }

  String _buildObservation({
    required double aspectRatio,
    required double fillRatio,
    required double edgeIrregularity,
    required double circularity,
    required double radialConsistency,
  }) {
    final ratioText =
        aspectRatio.toStringAsFixed(2);

    final fillText =
        (fillRatio * 100)
            .toStringAsFixed(1);

    final edgeText =
        edgeIrregularity
            .toStringAsFixed(2);

    final circularityText =
        circularity
            .toStringAsFixed(2);

    final radialText =
        radialConsistency
            .toStringAsFixed(2);

    return 'อัตราส่วนกว้าง/สูง $ratioText, '
        'พื้นที่วัตถุภายในกรอบประมาณ $fillText%, '
        'ความไม่สม่ำเสมอของขอบ $edgeText, '
        'ความสม่ำเสมอรอบศูนย์กลาง $radialText, '
        'ความใกล้เคียงวงกลม $circularityText';
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

class _Centroid {
  final double x;
  final double y;

  const _Centroid({
    required this.x,
    required this.y,
  });
}

class _RadialShapeResult {
  final double circularity;
  final double radialConsistency;
  final double edgeIrregularity;

  const _RadialShapeResult({
    required this.circularity,
    required this.radialConsistency,
    required this.edgeIrregularity,
  });
}
