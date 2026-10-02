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
// radialProfile ไม่ใช่คำตัดสินแท้/ปลอม
// ใช้เก็บ "รูปร่างภายนอก" ของรุ่นเท่านั้น
// ============================================================

class ShapeOutlineSymbol {
  final String name;

  /// ระยะจากจุดศูนย์กลางไปยังขอบวัตถุ
  /// เก็บเป็นค่าที่ normalize แล้ว
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
    return ShapeOutlineSymbol(
      name: map['name']?.toString() ?? '',
      radialProfile: (map['radialProfile'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
    );
  }
}

// ============================================================
// โครงร่างรูปไข่
//
// ตอนนี้ยังไม่ใส่ค่าจากการเดา
// ต้องสร้างจากภาพอ้างอิงจริงของรุ่น
// ============================================================

const ShapeOutlineSymbol ovalOutlineSymbol =
    ShapeOutlineSymbol(
  name: 'รูปไข่',
  radialProfile: [],
);

// ============================================================
// Shape Analyzer
//
// หน้าที่ของคลาสนี้:
//
// 1. อ่านภาพชั่วคราว
// 2. ใช้กรอบวัตถุที่ Core ตรวจพบ
// 3. แยกวัตถุออกจากพื้นหลัง
// 4. หาจุดศูนย์กลางของวัตถุ
// 5. เดินรัศมีรอบวัตถุ
// 6. เก็บระยะถึง "ขอบนอกสุด"
// 7. normalize เป็น radialProfile
//
// ไม่มีการตัดสินแท้/ปลอม
// ไม่มีการตัดสินพระแท้/พระเก๊
// ไม่มีการให้คะแนนความแท้
// ไม่มีการเดารูปทรงจาก threshold สำเร็จรูป
// ============================================================

class ShapeAnalyzer {
  const ShapeAnalyzer();

  // ==========================================================
  // สกัดโครงร่างจากภาพ
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

    final borderColor = _estimateLocalBorderColor(crop);

    final threshold = _calculateThreshold(
      crop,
      borderColor,
    );

    final mask = _buildMask(
      crop,
      borderColor,
      threshold,
    );

    final centroid = _calculateCentroid(mask);

    if (centroid == null) {
      return null;
    }

    // --------------------------------------------------------
    // เก็บเส้นรอบนอก
    //
    // จุดสำคัญ:
    // ไม่หยุดที่รูหรือรายละเอียดภายใน
    // แต่ค้นหา pixel ของวัตถุที่ไกลที่สุดในแต่ละทิศ
    // เพื่อให้ได้ "ขอบนอก" ของวัตถุ
    // --------------------------------------------------------

    const sampleCount = 72;

    final profile = <double>[];

    for (int i = 0; i < sampleCount; i++) {
      final angle =
          (2 * math.pi * i) / sampleCount;

      final dx = math.cos(angle);
      final dy = math.sin(angle);

      final maxRadius = math.sqrt(
        math.pow(crop.width, 2) +
            math.pow(crop.height, 2),
      );

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

        if (mask[iy][ix]) {
          farthestRadius = radius;
        }
      }

      if (farthestRadius == null) {
        profile.add(0);
      } else {
        profile.add(farthestRadius);
      }
    }

    // --------------------------------------------------------
    // ตรวจว่าข้อมูลโครงร่างใช้ได้หรือไม่
    // --------------------------------------------------------

    final validCount =
        profile.where((v) => v > 0).length;

    if (validCount < sampleCount * 0.80) {
      return null;
    }

    // --------------------------------------------------------
    // Normalize
    //
    // ทำให้ขนาดภาพต่างกันได้
    // แต่รูปแบบของเส้นรอบนอกยังคงอยู่
    // --------------------------------------------------------

    final maxProfile =
        profile.reduce(math.max);

    if (maxProfile <= 0) {
      return null;
    }

    final normalized = profile
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
  // Resize ภาพสำหรับการวิเคราะห์
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
      final x = point[0]
          .clamp(0, image.width - 1);

      final y = point[1]
          .clamp(0, image.height - 1);

      final pixel = image.getPixel(x, y);

      red += pixel.r;
      green += pixel.g;
      blue += pixel.b;

      count++;
    }

    if (count == 0) {
      return img.ColorRgb8(255, 255, 255);
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

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

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

    for (int y = 0; y < mask.length; y++) {
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