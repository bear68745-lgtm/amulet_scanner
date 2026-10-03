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
// จุดของเส้นโครงร่างจริง
// ============================================================

class ShapeContourPoint {
  final double x;
  final double y;

  const ShapeContourPoint({
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
    };
  }

  factory ShapeContourPoint.fromMap(
    Map<String, dynamic> map,
  ) {
    return ShapeContourPoint(
      x: _toDouble(map['x']),
      y: _toDouble(map['y']),
    );
  }
}

// ============================================================
// โครงร่างของรุ่น
// ============================================================

class ShapeOutlineSymbol {
  final String name;

  final List<ShapeContourPoint> contour;

  // compatibility กับระบบเดิม
  final List<double> radialProfile;

  const ShapeOutlineSymbol({
    required this.name,
    this.contour = const [],
    this.radialProfile = const [],
  });

  bool get hasContour => contour.length >= 3;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contour': contour
          .map((point) => point.toMap())
          .toList(),
      'radialProfile': radialProfile,
    };
  }

  factory ShapeOutlineSymbol.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawContour = map['contour'];

    final contour = rawContour is List
        ? rawContour
            .whereType<Map>()
            .map(
              (value) => ShapeContourPoint.fromMap(
                Map<String, dynamic>.from(value),
              ),
            )
            .toList()
        : <ShapeContourPoint>[];

    final rawProfile = map['radialProfile'];

    final profile = rawProfile is List
        ? rawProfile
            .whereType<num>()
            .map((value) => value.toDouble())
            .toList()
        : <double>[];

    return ShapeOutlineSymbol(
      name: map['name']?.toString() ?? '',
      contour: contour,
      radialProfile: profile,
    );
  }
}

// ============================================================
// ผลการเปรียบเทียบโครงร่าง
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

    // --------------------------------------------------------
    // ลด noise
    // --------------------------------------------------------

    final cleanedMask =
        _removeSmallNoise(mask);

    // --------------------------------------------------------
    // เลือกวัตถุหลัก
    // --------------------------------------------------------

    final mainObject =
        _keepLargestComponent(cleanedMask);

    // --------------------------------------------------------
    // เติมรูภายในวัตถุ
    //
    // สำคัญสำหรับเหรียญที่มีสีหรือลวดลายด้านหน้า
    // เพราะรูหรือรอยแหว่งภายในไม่ควรกลายเป็น
    // เส้น contour สีน้ำเงิน
    // --------------------------------------------------------

    final solidObject =
        _fillInternalHoles(mainObject);

    // --------------------------------------------------------
    // หา contour เฉพาะขอบนอก
    // --------------------------------------------------------

    final contourPixels =
        _traceContour(solidObject);

    if (contourPixels.length < 10) {
      return null;
    }

    // --------------------------------------------------------
    // ทำความสะอาด contour
    //
    // ใช้การลดจุดแบบเบา ๆ เพียงขั้นเดียว
    // เพื่อให้ดูเป็นเส้นวาด 2D
    // โดยไม่ทำให้รูปทรงกลมเกินจริง
    // --------------------------------------------------------

    final cleanContour =
        _cleanContour(contourPixels);

    if (cleanContour.length < 10) {
      return null;
    }

    // --------------------------------------------------------
    // Normalize contour
    // --------------------------------------------------------

    final normalizedContour =
        _normalizeContour(
      cleanContour,
    );

    if (normalizedContour.length < 10) {
      return null;
    }

    return ShapeOutlineSymbol(
      name: shapeName,
      contour: normalizedContour,
      radialProfile: const [],
    );
  }

  // ==========================================================
  // เปรียบเทียบ contour
  // ==========================================================

  ShapeOutlineComparison compareOutline(
    ShapeOutlineSymbol scanned,
    ShapeOutlineSymbol reference,
  ) {
    if (!scanned.hasContour ||
        !reference.hasContour) {
      return const ShapeOutlineComparison(
        hasReference: false,
        difference: 0,
        result: 'ยังไม่มีโครงร่างอ้างอิง',
      );
    }

    final scannedPoints = scanned.contour;
    final referencePoints = reference.contour;

    if (scannedPoints.length < 3 ||
        referencePoints.length < 3) {
      return const ShapeOutlineComparison(
        hasReference: false,
        difference: 0,
        result: 'ยังไม่มีโครงร่างอ้างอิง',
      );
    }

    final forward =
        _averageNearestDistance(
      scannedPoints,
      referencePoints,
    );

    final backward =
        _averageNearestDistance(
      referencePoints,
      scannedPoints,
    );

    final difference =
        (forward + backward) / 2;

    String result;

    if (difference <= 0.035) {
      result = 'ตรงกับโครงร่างอ้างอิง';
    } else if (difference <= 0.080) {
      result = 'ใกล้เคียงโครงร่างอ้างอิง';
    } else {
      result = 'แตกต่างจากโครงร่างอ้างอิง';
    }

    return ShapeOutlineComparison(
      hasReference: true,
      difference: difference,
      result: result,
    );
  }

  // ==========================================================
  // แปลง contour เป็นข้อความ
  // ==========================================================

  String contourToText(
    List<ShapeContourPoint> contour,
  ) {
    return contour
        .map(
          (point) =>
              '${point.x.toStringAsFixed(5)},'
              '${point.y.toStringAsFixed(5)}',
        )
        .join('|');
  }

  // ==========================================================
  // compatibility
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
  // Crop ตามกรอบวัตถุ
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
  // ประมาณสีพื้นหลัง
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
  // คำนวณ threshold
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

    for (
      int y = 1;
      y < height - 1;
      y++
    ) {
      for (
        int x = 1;
        x < width - 1;
        x++
      ) {
        if (!source[y][x]) {
          continue;
        }

        int neighbours = 0;

        for (
          int dy = -1;
          dy <= 1;
          dy++
        ) {
          for (
            int dx = -1;
            dx <= 1;
            dx++
          ) {
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
  // เลือก connected component ที่ใหญ่ที่สุด
  // ==========================================================

  List<List<bool>> _keepLargestComponent(
    List<List<bool>> source,
  ) {
    final height = source.length;

    if (height == 0) {
      return source;
    }

    final width = source.first.length;

    final visited = List.generate(
      height,
      (_) => List<bool>.filled(
        width,
        false,
      ),
    );

    List<_Pixel>? largest;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (!source[y][x] ||
            visited[y][x]) {
          continue;
        }

        final component = <_Pixel>[];

        final queue = <_Pixel>[
          _Pixel(x, y),
        ];

        visited[y][x] = true;

        int index = 0;

        while (index < queue.length) {
          final current = queue[index++];

          component.add(current);

          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) {
                continue;
              }

              final nx =
                  current.x + dx;

              final ny =
                  current.y + dy;

              if (nx < 0 ||
                  ny < 0 ||
                  nx >= width ||
                  ny >= height) {
                continue;
              }

              if (!source[ny][nx] ||
                  visited[ny][nx]) {
                continue;
              }

              visited[ny][nx] = true;

              queue.add(
                _Pixel(nx, ny),
              );
            }
          }
        }

        if (largest == null ||
            component.length >
                largest.length) {
          largest = component;
        }
      }
    }

    if (largest == null ||
        largest.isEmpty) {
      return List.generate(
        height,
        (y) => List<bool>.from(source[y]),
      );
    }

    final result = List.generate(
      height,
      (_) => List<bool>.filled(
        width,
        false,
      ),
    );

    for (final pixel in largest) {
      result[pixel.y][pixel.x] = true;
    }

    return result;
  }

  // ==========================================================
  // เติมรูที่อยู่ภายในวัตถุ
  //
  // จุดประสงค์:
  // - ไม่ให้ลวดลายสีด้านในเหรียญกลายเป็น contour
  // - ไม่ให้เกิดเส้นแทงเข้าด้านใน
  // - รักษาขอบนอกของวัตถุไว้
  //
  // หลักการ:
  // background ที่เชื่อมต่อกับขอบภาพ
  // ถือเป็น "ด้านนอก"
  //
  // background ที่ไม่เชื่อมต่อกับขอบภาพ
  // ถือเป็น "รูภายในวัตถุ"
  // และจะถูกเติมกลับเป็น foreground
  // ==========================================================

  List<List<bool>> _fillInternalHoles(
    List<List<bool>> source,
  ) {
    final height = source.length;

    if (height == 0) {
      return source;
    }

    final width = source.first.length;

    final outside = List.generate(
      height,
      (_) => List<bool>.filled(
        width,
        false,
      ),
    );

    final queue = <_Pixel>[];

    void addOutside(
      int x,
      int y,
    ) {
      if (x < 0 ||
          y < 0 ||
          x >= width ||
          y >= height) {
        return;
      }

      if (outside[y][x]) {
        return;
      }

      if (source[y][x]) {
        return;
      }

      outside[y][x] = true;

      queue.add(
        _Pixel(x, y),
      );
    }

    // --------------------------------------------------------
    // เริ่มจาก background ที่ติดขอบภาพ
    // --------------------------------------------------------

    for (int x = 0; x < width; x++) {
      addOutside(x, 0);
      addOutside(x, height - 1);
    }

    for (int y = 0; y < height; y++) {
      addOutside(0, y);
      addOutside(width - 1, y);
    }

    // --------------------------------------------------------
    // เดิน background ที่เชื่อมกับขอบภาพ
    // ใช้ 4 ทิศทางเพื่อแยกพื้นที่ภายในชัดเจน
    // --------------------------------------------------------

    int index = 0;

    while (index < queue.length) {
      final current =
          queue[index++];

      const directions = <_Pixel>[
        _Pixel(1, 0),
        _Pixel(-1, 0),
        _Pixel(0, 1),
        _Pixel(0, -1),
      ];

      for (final direction in directions) {
        final nx =
            current.x + direction.x;

        final ny =
            current.y + direction.y;

        if (nx < 0 ||
            ny < 0 ||
            nx >= width ||
            ny >= height) {
          continue;
        }

        if (outside[ny][nx]) {
          continue;
        }

        if (source[ny][nx]) {
          continue;
        }

        outside[ny][nx] = true;

        queue.add(
          _Pixel(nx, ny),
        );
      }
    }

    // --------------------------------------------------------
    // false ที่ไม่ติดขอบภาพ
    // คือรูภายในวัตถุ
    // เติมกลับเป็น foreground
    // --------------------------------------------------------

    final result = List.generate(
      height,
      (y) => List<bool>.from(
        source[y],
      ),
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (!source[y][x] &&
            !outside[y][x]) {
          result[y][x] = true;
        }
      }
    }

    return result;
  }

  // ==========================================================
  // Trace contour
  // ==========================================================

  List<_Pixel> _traceContour(
    List<List<bool>> mask,
  ) {
    final height = mask.length;

    if (height == 0) {
      return [];
    }

    final width = mask.first.length;

    _Pixel? start;

    for (
      int y = 0;
      y < height && start == null;
      y++
    ) {
      for (
        int x = 0;
        x < width;
        x++
      ) {
        if (mask[y][x] &&
            _isBoundaryPixel(
              mask,
              x,
              y,
            )) {
          start = _Pixel(x, y);
          break;
        }
      }
    }

    if (start == null) {
      return [];
    }

    if (_countForeground(mask) <= 2) {
      return [start];
    }

    final contour = <_Pixel>[];

    _Pixel current = start;

    _Pixel previous = _Pixel(
      start.x - 1,
      start.y,
    );

    final firstCurrent = current;

    final firstPrevious = previous;

    final maxSteps =
        math.max(
          width * height * 2,
          100,
        );

    for (
      int step = 0;
      step < maxSteps;
      step++
    ) {
      contour.add(current);

      final next =
          _findNextBoundaryPixel(
        mask,
        current,
        previous,
      );

      if (next == null) {
        break;
      }

      current = next.current;

      previous = next.previous;

      if (current.x ==
              firstCurrent.x &&
          current.y ==
              firstCurrent.y &&
          previous.x ==
              firstPrevious.x &&
          previous.y ==
              firstPrevious.y &&
          contour.length > 8) {
        break;
      }
    }

    return _removeConsecutiveDuplicatePoints(
      contour,
    );
  }

  // ==========================================================
  // หา boundary pixel
  // ==========================================================

  bool _isBoundaryPixel(
    List<List<bool>> mask,
    int x,
    int y,
  ) {
    if (!mask[y][x]) {
      return false;
    }

    final height = mask.length;
    final width = mask.first.length;

    for (
      int dy = -1;
      dy <= 1;
      dy++
    ) {
      for (
        int dx = -1;
        dx <= 1;
        dx++
      ) {
        if (dx == 0 && dy == 0) {
          continue;
        }

        final nx = x + dx;
        final ny = y + dy;

        if (nx < 0 ||
            ny < 0 ||
            nx >= width ||
            ny >= height) {
          return true;
        }

        if (!mask[ny][nx]) {
          return true;
        }
      }
    }

    return false;
  }

  // ==========================================================
  // หา pixel ถัดไปบน boundary
  // ==========================================================

  _BoundaryStep? _findNextBoundaryPixel(
    List<List<bool>> mask,
    _Pixel current,
    _Pixel previous,
  ) {
    final directions = <_Pixel>[
      const _Pixel(-1, -1),
      const _Pixel(0, -1),
      const _Pixel(1, -1),
      const _Pixel(1, 0),
      const _Pixel(1, 1),
      const _Pixel(0, 1),
      const _Pixel(-1, 1),
      const _Pixel(-1, 0),
    ];

    final dx =
        previous.x - current.x;

    final dy =
        previous.y - current.y;

    int startIndex = 0;

    for (
      int i = 0;
      i < directions.length;
      i++
    ) {
      if (directions[i].x == dx &&
          directions[i].y == dy) {
        startIndex = i;
        break;
      }
    }

    final height = mask.length;
    final width = mask.first.length;

    for (
      int offset = 1;
      offset <= directions.length;
      offset++
    ) {
      final index =
          (startIndex + offset) %
              directions.length;

      final direction =
          directions[index];

      final nx =
          current.x + direction.x;

      final ny =
          current.y + direction.y;

      if (nx < 0 ||
          ny < 0 ||
          nx >= width ||
          ny >= height) {
        continue;
      }

      if (!mask[ny][nx]) {
        continue;
      }

      final previousDirection =
          directions[
            (index - 1 +
                    directions.length) %
                directions.length
          ];

      final newPrevious =
          _Pixel(
        current.x +
            previousDirection.x,
        current.y +
            previousDirection.y,
      );

      return _BoundaryStep(
        current: _Pixel(
          nx,
          ny,
        ),
        previous: newPrevious,
      );
    }

    return null;
  }

  // ==========================================================
  // ทำความสะอาด contour
  //
  // เป้าหมาย:
  // - ลดจุดจาก pixel
  // - ทำให้เส้นดูเป็นรูปวาด 2D
  // - ไม่ทำให้รูปทรงกลมเกินจริง
  // - ไม่ลบมุมสำคัญ
  // - ไม่กำหนดจำนวนจุดตายตัว
  //
  // ใช้ RDP เพียงขั้นเดียวแบบเบา
  // ==========================================================

  List<_Pixel> _cleanContour(
    List<_Pixel> contour,
  ) {
    if (contour.length < 10) {
      return contour;
    }

    final unique =
        _removeConsecutiveDuplicatePoints(
      contour,
    );

    if (unique.length < 10) {
      return unique;
    }

    final simplified =
        _simplifyClosedContour(
      unique,
      epsilon: 1.10,
    );

    if (simplified.length < 10) {
      return unique;
    }

    return simplified;
  }

  // ==========================================================
  // Simplify contour แบบวงปิด
  //
  // RDP ปกติใช้กับเส้นเปิด
  // จึงแบ่งวงปิดออกเป็น 2 ช่วงก่อน
  // ==========================================================

  List<_Pixel> _simplifyClosedContour(
    List<_Pixel> points, {
    required double epsilon,
  }) {
    if (points.length < 10) {
      return points;
    }

    final count = points.length;

    // --------------------------------------------------------
    // หา point ที่อยู่ไกลจากจุดเริ่มต้นที่สุด
    // ใช้เป็นจุดแบ่งของวง
    // --------------------------------------------------------

    final first = points.first;

    int splitIndex = 0;

    double farthest = -1;

    for (
      int i = 1;
      i < count;
      i++
    ) {
      final distance =
          _distance(
        first,
        points[i],
      );

      if (distance > farthest) {
        farthest = distance;

        splitIndex = i;
      }
    }

    if (splitIndex <= 1 ||
        splitIndex >= count - 2) {
      return points;
    }

    final firstPart =
        points.sublist(
      0,
      splitIndex + 1,
    );

    final secondPart = <_Pixel>[
      ...points.sublist(splitIndex),
      first,
    ];

    final simplifiedFirst =
        _rdpSimplify(
      firstPart,
      epsilon,
    );

    final simplifiedSecond =
        _rdpSimplify(
      secondPart,
      epsilon,
    );

    final result = <_Pixel>[
      ...simplifiedFirst,
      ...simplifiedSecond.skip(1),
    ];

    return _removeConsecutiveDuplicatePoints(
      result,
    );
  }

  // ==========================================================
  // Ramer-Douglas-Peucker
  // ==========================================================

  List<_Pixel> _rdpSimplify(
    List<_Pixel> points,
    double epsilon,
  ) {
    if (points.length <= 2) {
      return List<_Pixel>.from(
        points,
      );
    }

    final first = points.first;

    final last = points.last;

    double maximumDistance = 0;

    int index = -1;

    for (
      int i = 1;
      i < points.length - 1;
      i++
    ) {
      final distance =
          _distancePointToLine(
        points[i],
        first,
        last,
      );

      if (distance > maximumDistance) {
        maximumDistance = distance;

        index = i;
      }
    }

    if (maximumDistance <= epsilon ||
        index < 0) {
      return <_Pixel>[
        first,
        last,
      ];
    }

    final left =
        points.sublist(
      0,
      index + 1,
    );

    final right =
        points.sublist(index);

    final leftResult =
        _rdpSimplify(
      left,
      epsilon,
    );

    final rightResult =
        _rdpSimplify(
      right,
      epsilon,
    );

    return <_Pixel>[
      ...leftResult,
      ...rightResult.skip(1),
    ];
  }

  // ==========================================================
  // ระยะจากจุดถึงเส้น
  // ==========================================================

  double _distancePointToLine(
    _Pixel point,
    _Pixel lineStart,
    _Pixel lineEnd,
  ) {
    final x =
        point.x.toDouble();

    final y =
        point.y.toDouble();

    final x1 =
        lineStart.x.toDouble();

    final y1 =
        lineStart.y.toDouble();

    final x2 =
        lineEnd.x.toDouble();

    final y2 =
        lineEnd.y.toDouble();

    final dx = x2 - x1;

    final dy = y2 - y1;

    final lengthSquared =
        (dx * dx) +
            (dy * dy);

    if (lengthSquared <= 0) {
      return math.sqrt(
        ((x - x1) * (x - x1)) +
            ((y - y1) * (y - y1)),
      );
    }

    final cross =
        ((x - x1) * dy) -
            ((y - y1) * dx);

    return cross.abs() /
        math.sqrt(
          lengthSquared,
        );
  }

  // ==========================================================
  // ระยะห่างระหว่าง pixel
  // ==========================================================

  double _distance(
    _Pixel a,
    _Pixel b,
  ) {
    final dx =
        (a.x - b.x).toDouble();

    final dy =
        (a.y - b.y).toDouble();

    return math.sqrt(
      (dx * dx) +
          (dy * dy),
    );
  }

  // ==========================================================
  // Normalize contour
  // ==========================================================

  List<ShapeContourPoint> _normalizeContour(
    List<_Pixel> contour,
  ) {
    if (contour.isEmpty) {
      return [];
    }

    double minX =
        contour.first.x.toDouble();

    double maxX =
        contour.first.x.toDouble();

    double minY =
        contour.first.y.toDouble();

    double maxY =
        contour.first.y.toDouble();

    for (final point in contour) {
      minX = math.min(
        minX,
        point.x.toDouble(),
      );

      maxX = math.max(
        maxX,
        point.x.toDouble(),
      );

      minY = math.min(
        minY,
        point.y.toDouble(),
      );

      maxY = math.max(
        maxY,
        point.y.toDouble(),
      );
    }

    final width =
        maxX - minX;

    final height =
        maxY - minY;

    final scale =
        math.max(
      width,
      height,
    );

    if (scale <= 0) {
      return [];
    }

    final centerX =
        (minX + maxX) / 2;

    final centerY =
        (minY + maxY) / 2;

    return contour.map((point) {
      return ShapeContourPoint(
        x: (point.x - centerX) /
            scale,
        y: (point.y - centerY) /
            scale,
      );
    }).toList();
  }

  // ==========================================================
  // Average nearest distance
  // ==========================================================

  double _averageNearestDistance(
    List<ShapeContourPoint> a,
    List<ShapeContourPoint> b,
  ) {
    if (a.isEmpty || b.isEmpty) {
      return double.infinity;
    }

    double total = 0;

    for (final pointA in a) {
      double nearest =
          double.infinity;

      for (final pointB in b) {
        final dx =
            pointA.x - pointB.x;

        final dy =
            pointA.y - pointB.y;

        final distance =
            math.sqrt(
          (dx * dx) +
              (dy * dy),
        );

        if (distance < nearest) {
          nearest = distance;
        }
      }

      total += nearest;
    }

    return total / a.length;
  }

  // ==========================================================
  // นับ foreground
  // ==========================================================

  int _countForeground(
    List<List<bool>> mask,
  ) {
    int count = 0;

    for (final row in mask) {
      for (final value in row) {
        if (value) {
          count++;
        }
      }
    }

    return count;
  }

  // ==========================================================
  // ลบจุดซ้ำติดกัน
  // ==========================================================

  List<_Pixel> _removeConsecutiveDuplicatePoints(
    List<_Pixel> points,
  ) {
    if (points.isEmpty) {
      return [];
    }

    final result = <_Pixel>[
      points.first,
    ];

    for (
      int i = 1;
      i < points.length;
      i++
    ) {
      final previous =
          result.last;

      final current =
          points[i];

      if (previous.x != current.x ||
          previous.y != current.y) {
        result.add(current);
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
}

// ============================================================
// จุด pixel ภายใน
// ============================================================

class _Pixel {
  final int x;
  final int y;

  const _Pixel(
    this.x,
    this.y,
  );
}

// ============================================================
// ผลการเดิน contour
// ============================================================

class _BoundaryStep {
  final _Pixel current;
  final _Pixel previous;

  const _BoundaryStep({
    required this.current,
    required this.previous,
  });
}

// ============================================================
// Helper แปลงตัวเลข
// ============================================================

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
        '${value ?? ''}',
      ) ??
      0.0;
}