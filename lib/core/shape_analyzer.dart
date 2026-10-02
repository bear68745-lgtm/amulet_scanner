import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

// ============================================================
// รูปทรงที่ระบบรองรับ
// ============================================================

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

// ============================================================
// สัญลักษณ์รูปทรง
//
// ใช้บอก "ประเภทโครงสร้าง" ที่ผู้ใช้กำหนดไว้
// ไม่ใช่ผลการตัดสินแท้ / เก๊
// ============================================================

class CoinShapeSymbol {
  final String name;

  const CoinShapeSymbol({
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  factory CoinShapeSymbol.fromMap(
    Map<String, dynamic> map,
  ) {
    return CoinShapeSymbol(
      name: map['name']?.toString() ?? '',
    );
  }
}

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

// ============================================================
// โครงร่างของรุ่น
//
// radialProfile
// = ระยะจากจุดศูนย์กลางไปยังขอบนอกของวัตถุ
//
// ข้อมูลนี้เป็น "ลักษณะโครงสร้าง"
// ไม่ใช่ตำหนิ
// ไม่ใช่ข้อมูลผิว
// ไม่ใช่ข้อมูลพระ
// ไม่ใช่การตัดสินแท้ / เก๊
// ============================================================

class ShapeOutlineSymbol {
  final String name;

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

  factory ShapeOutlineSymbol.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawProfile = map['radialProfile'];

    final profile = rawProfile is List
        ? rawProfile
            .whereType<num>()
            .map((value) => value.toDouble())
            .toList()
        : <double>[];

    return ShapeOutlineSymbol(
      name: map['name']?.toString() ?? '',
      radialProfile: profile,
    );
  }
}

// ============================================================
// ผลการเปรียบเทียบโครงร่าง
//
// ใช้บอกความสัมพันธ์ของโครงร่างที่สแกน
// กับโครงร่างอ้างอิงของรุ่น
//
// ไม่ใช่คะแนนความแท้
// ============================================================

class ShapeOutlineComparison {
  final bool hasReference;
  final double difference;
  final String result;

  const ShapeOutlineComparison({
    required this.hasReference,
    required this.difference,
    required this.result,
  });

  Map<String, dynamic> toMap() {
    return {
      'hasReference': hasReference,
      'difference': difference,
      'result': result,
    };
  }
}

// ============================================================
// Shape Analyzer
//
// หน้าที่:
//
// 1. อ่านภาพชั่วคราว
// 2. ใช้กรอบวัตถุที่ตรวจพบ
// 3. แยกวัตถุออกจากพื้นหลัง
// 4. หาจุดศูนย์กลาง
// 5. เดินรัศมีรอบวัตถุ
// 6. หา "ขอบนอกสุด"
// 7. normalize เป็น radialProfile
// 8. เปรียบเทียบกับโครงร่างอ้างอิงได้
//
// ไม่มี:
//
// - การตัดสินแท้
// - การตัดสินเก๊
// - คะแนนความแท้
// - การวิเคราะห์องค์พระ
// - การวิเคราะห์ตำหนิ
// - การวิเคราะห์ผิว
// - การวิเคราะห์ตัวอักษร
// ============================================================

class ShapeAnalyzer {
  const ShapeAnalyzer();

  // ==========================================================
  // สกัดโครงร่างจากภาพจริง
  // ==========================================================

  Future<ShapeOutlineSymbol?> extractOutlineSymbol({
    required String imagePath,
    required String shapeName,
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) async {
    final file = File(imagePath);

    if (!await file.exists()) {
      return null;
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      return null;
    }

    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return null;
    }

    final image = _resizeForAnalysis(decoded);

    final crop = _cropByNormalizedBox(
      image,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );

    if (crop == null ||
        crop.width < 10 ||
        crop.height < 10) {
      return null;
    }

    // --------------------------------------------------------
    // สร้าง mask ของวัตถุ
    // --------------------------------------------------------

    final borderColor =
        _estimateLocalBorderColor(crop);

    final threshold = _calculateThreshold(
      crop,
      borderColor,
    );

    final mask = _buildMask(
      crop,
      borderColor,
      threshold,
    );

    final cleanedMask = _removeSmallNoise(mask);

    final centroid =
        _calculateCentroid(cleanedMask);

    if (centroid == null) {
      return null;
    }

    // --------------------------------------------------------
    // สกัดขอบนอก
    //
    // ใช้หลายทิศทางรอบวัตถุ
    // และเลือกจุดที่ไกลที่สุดจากศูนย์กลาง
    //
    // จึงไม่หยุดเมื่อเจอรายละเอียดภายในเหรียญ
    // --------------------------------------------------------

    const sampleCount = 72;

    final profile = <double>[];

    final maxRadius = math.sqrt(
      math.pow(crop.width, 2) +
          math.pow(crop.height, 2),
    );

    for (int i = 0; i < sampleCount; i++) {
      final angle =
          (2 * math.pi * i) / sampleCount;

      final dx = math.cos(angle);
      final dy = math.sin(angle);

      double? farthestRadius;

      for (
        double radius = 0;
        radius <= maxRadius;
        radius += 1
      ) {
        final x =
            centroid.x + (dx * radius);

        final y =
            centroid.y + (dy * radius);

        final ix = x.round();
        final iy = y.round();

        if (ix < 0 ||
            iy < 0 ||
            ix >= crop.width ||
            iy >= crop.height) {
          break;
        }

        if (cleanedMask[iy][ix]) {
          farthestRadius = radius;
        }
      }

      profile.add(
        farthestRadius ?? 0,
      );
    }

    // --------------------------------------------------------
    // ตรวจสอบว่ามีข้อมูลขอบเพียงพอ
    // --------------------------------------------------------

    final validCount =
        profile.where((value) => value > 0).length;

    if (validCount < sampleCount * 0.80) {
      return null;
    }

    // --------------------------------------------------------
    // เติมค่าที่หายไปจากค่าข้างเคียง
    // --------------------------------------------------------

    final completedProfile =
        _fillMissingProfileValues(profile);

    // --------------------------------------------------------
    // ทำให้ค่าทั้งหมดอยู่ในมาตรฐานเดียวกัน
    // --------------------------------------------------------

    final maxProfile =
        completedProfile.reduce(math.max);

    if (maxProfile <= 0) {
      return null;
    }

    final normalized = completedProfile
        .map(
          (value) => value / maxProfile,
        )
        .toList();

    return ShapeOutlineSymbol(
      name: shapeName,
      radialProfile: normalized,
    );
  }

  // ==========================================================
  // เปรียบเทียบโครงร่างที่สแกนกับโครงร่างอ้างอิง
  //
  // ผลลัพธ์มีเพียง:
  //
  // - ตรงกับโครงร่างอ้างอิง
  // - ใกล้เคียงโครงร่างอ้างอิง
  // - แตกต่างจากโครงร่างอ้างอิง
  // - ยังไม่มีโครงร่างอ้างอิง
  //
  // ไม่ใช่ผลแท้ / เก๊
  // ==========================================================

  ShapeOutlineComparison compareOutline(
    ShapeOutlineSymbol scanned,
    ShapeOutlineSymbol reference,
  ) {
    if (scanned.radialProfile.isEmpty ||
        reference.radialProfile.isEmpty) {
      return const ShapeOutlineComparison(
        hasReference: false,
        difference: 0,
        result: 'ยังไม่มีโครงร่างอ้างอิง',
      );
    }

    final count = math.min(
      scanned.radialProfile.length,
      reference.radialProfile.length,
    );

    if (count == 0) {
      return const ShapeOutlineComparison(
        hasReference: false,
        difference: 0,
        result: 'ยังไม่มีโครงร่างอ้างอิง',
      );
    }

    double totalDifference = 0;

    for (int i = 0; i < count; i++) {
      final a = scanned.radialProfile[i];
      final b = reference.radialProfile[i];

      totalDifference += (a - b).abs();
    }

    final averageDifference =
        totalDifference / count;

    String result;

    if (averageDifference <= 0.035) {
      result = 'ตรงกับโครงร่างอ้างอิง';
    } else if (averageDifference <= 0.080) {
      result = 'ใกล้เคียงโครงร่างอ้างอิง';
    } else {
      result = 'แตกต่างจากโครงร่างอ้างอิง';
    }

    return ShapeOutlineComparison(
      hasReference: true,
      difference: averageDifference,
      result: result,
    );
  }

  // ==========================================================
  // แปลง radialProfile เป็นข้อความ
  //
  // ใช้สำหรับเก็บในฐานข้อมูลปัจจุบัน
  // ==========================================================

  String profileToText(
    List<double> profile,
  ) {
    return profile
        .map(
          (value) => value.toStringAsFixed(4),
        )
        .join(',');
  }

  // ==========================================================
  // Resize ภาพ
  // ==========================================================

  img.Image _resizeForAnalysis(
    img.Image source,
  ) {
    const maxWidth = 320;

    if (source.width <= maxWidth) {
      return source;
    }

    final newHeight =
        (source.height *
                maxWidth /
                source.width)
            .round();

    return img.copyResize(
      source,
      width: maxWidth,
      height: newHeight,
    );
  }

  // ==========================================================
  // Crop ตามกรอบวัตถุจาก Core
  // ==========================================================

  img.Image? _cropByNormalizedBox(
    img.Image image, {
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    final l = left.clamp(0.0, 1.0);
    final t = top.clamp(0.0, 1.0);
    final r = right.clamp(0.0, 1.0);
    final b = bottom.clamp(0.0, 1.0);

    if (r <= l || b <= t) {
      return null;
    }

    final x = (image.width * l)
        .round()
        .clamp(0, image.width - 1);

    final y = (image.height * t)
        .round()
        .clamp(0, image.height - 1);

    final x2 = (image.width * r)
        .round()
        .clamp(x + 1, image.width);

    final y2 = (image.height * b)
        .round()
        .clamp(y + 1, image.height);

    final width = x2 - x;
    final height = y2 - y;

    if (width <= 0 || height <= 0) {
      return null;
    }

    return img.copyCrop(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  // ==========================================================
  // ประมาณสีพื้นหลังบริเวณขอบภาพ
  // ==========================================================

  img.Color _estimateLocalBorderColor(
    img.Image image,
  ) {
    final points = <List<int>>[
      [0, 0],
      [image.width ~/ 2, 0],
      [image.width - 1, 0],
      [0, image.height ~/ 2],
      [image.width - 1, image.height ~/ 2],
      [0, image.height - 1],
      [image.width ~/ 2, image.height - 1],
      [image.width - 1, image.height - 1],
    ];

    double red = 0;
    double green = 0;
    double blue = 0;

    int count = 0;

    for (final point in points) {
      final x =
          point[0].clamp(0, image.width - 1);

      final y =
          point[1].clamp(0, image.height - 1);

      final pixel = image.getPixel(x, y);

      red += pixel.r;
      green += pixel.g;
      blue += pixel.b;

      count++;
    }

    if (count == 0) {
      return img.ColorRgb8(
        255,
        255,
        255,
      );
    }

    return img.ColorRgb8(
      (red / count).round().clamp(0, 255),
      (green / count).round().clamp(0, 255),
      (blue / count).round().clamp(0, 255),
    );
  }

  // ==========================================================
  // คำนวณ threshold จากภาพจริง
  // ==========================================================

  double _calculateThreshold(
    img.Image image,
    img.Color borderColor,
  ) {
    final distances = <double>[];

    for (
      int y = 0;
      y < image.height;
      y += 4
    ) {
      for (
        int x = 0;
        x < image.width;
        x += 4
      ) {
        final pixel = image.getPixel(x, y);

        distances.add(
          _colorDistance(
            pixel,
            borderColor,
          ),
        );
      }
    }

    if (distances.isEmpty) {
      return 30;
    }

    final average =
        distances.reduce((a, b) => a + b) /
            distances.length;

    return (average * 1.35)
        .clamp(20.0, 90.0);
  }

  // ==========================================================
  // สร้าง mask
  // ==========================================================

  List<List<bool>> _buildMask(
    img.Image image,
    img.Color borderColor,
    double threshold,
  ) {
    final mask = List.generate(
      image.height,
      (_) => List<bool>.filled(
        image.width,
        false,
      ),
    );

    for (
      int y = 0;
      y < image.height;
      y++
    ) {
      for (
        int x = 0;
        x < image.width;
        x++
      ) {
        final pixel =
            image.getPixel(x, y);

        final distance = _colorDistance(
          pixel,
          borderColor,
        );

        mask[y][x] =
            distance >= threshold;
      }
    }

    return mask;
  }

  // ==========================================================
  // ลดจุดรบกวนเล็ก ๆ
  //
  // ไม่สร้างรูปทรงใหม่
  // เพียงลดจุดที่เกิดจาก noise ของภาพ
  // ==========================================================

  List<List<bool>> _removeSmallNoise(
    List<List<bool>> source,
  ) {
    final height = source.length;

    if (height == 0) {
      return source;
    }

    final width = source.first.length;

    final result = List.generate(
      height,
      (y) => List<bool>.from(source[y]),
    );

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        if (!source[y][x]) {
          continue;
        }

        int neighbours = 0;

        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) {
              continue;
            }

            if (source[y + dy][x + dx]) {
              neighbours++;
            }
          }
        }

        if (neighbours <= 1) {
          result[y][x] = false;
        }
      }
    }

    return result;
  }

  // ==========================================================
  // เติมค่าที่หายไปใน radialProfile
  // ==========================================================

  List<double> _fillMissingProfileValues(
    List<double> profile,
  ) {
    final result = List<double>.from(
      profile,
    );

    for (int i = 0; i < result.length; i++) {
      if (result[i] > 0) {
        continue;
      }

      double? previous;
      double? next;

      for (
        int step = 1;
        step <= result.length;
        step++
      ) {
        final index =
            (i - step + result.length) %
                result.length;

        if (result[index] > 0) {
          previous = result[index];
          break;
        }
      }

      for (
        int step = 1;
        step <= result.length;
        step++
      ) {
        final index =
            (i + step) %
                result.length;

        if (result[index] > 0) {
          next = result[index];
          break;
        }
      }

      if (previous != null &&
          next != null) {
        result[i] =
            (previous + next) / 2;
      } else if (previous != null) {
        result[i] = previous;
      } else if (next != null) {
        result[i] = next;
      }
    }

    return result;
  }

  // ==========================================================
  // ระยะห่างของสี
  // ==========================================================

  double _colorDistance(
    img.Color a,
    img.Color b,
  ) {
    final dr = a.r - b.r;
    final dg = a.g - b.g;
    final db = a.b - b.b;

    return math.sqrt(
      (dr * dr) +
          (dg * dg) +
          (db * db),
    );
  }

  // ==========================================================
  // จุดศูนย์กลางของ mask
  // ==========================================================

  _Point? _calculateCentroid(
    List<List<bool>> mask,
  ) {
    double sumX = 0;
    double sumY = 0;

    int count = 0;

    for (
      int y = 0;
      y < mask.length;
      y++
    ) {
      for (
        int x = 0;
        x < mask[y].length;
        x++
      ) {
        if (!mask[y][x]) {
          continue;
        }

        sumX += x;
        sumY += y;
        count++;
      }
    }

    if (count == 0) {
      return null;
    }

    return _Point(
      sumX / count,
      sumY / count,
    );
  }
}

// ============================================================
// จุด 2 มิติภายใน
// ============================================================

class _Point {
  final double x;
  final double y;

  const _Point(
    this.x,
    this.y,
  );
}