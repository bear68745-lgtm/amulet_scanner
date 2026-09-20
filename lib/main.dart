import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(App(cameras));
}

class App extends StatelessWidget {
  final List<CameraDescription> cameras;

  const App(this.cameras, {super.key});

  @override
  Widget build(BuildContext c) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'กล้องสแกนพระและเหรียญ',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: HomePage(cameras),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomePage(this.cameras, {super.key});

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('กล้องสแกนพระและเหรียญ'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('เริ่มสแกน'),
          onPressed: () {
            Navigator.push(
              c,
              MaterialPageRoute(
                builder: (_) => ScanPage(cameras),
              ),
            );
          },
        ),
      ),
    );
  }
}

// =====================================================
// SCAN RESULT
// =====================================================

class ScanResult {
  final String area;
  final double brightness;
  final double sharpness;
  final String quality;
  final String details;
  final bool fromGallery;

  ScanResult({
    required this.area,
    required this.brightness,
    required this.sharpness,
    required this.quality,
    required this.details,
    required this.fromGallery,
  });

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'brightness': brightness,
      'sharpness': sharpness,
      'quality': quality,
      'details': details,
      'fromGallery': fromGallery,
    };
  }
}

// =====================================================
// SCAN PAGE
// =====================================================

class ScanPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScanPage(this.cameras, {super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? controller;

  final ImagePicker picker = ImagePicker();

  XFile? galleryImage;

  // กรอบข้อมูลมาตรฐาน
  static const areas = [
    'ด้านหน้า',
    'ด้านหลัง',
    'ด้านข้าง',
    'ก้นพระ',
  ];

  int areaIndex = 0;

  bool ready = false;
  bool scanning = false;

  int frameCount = 0;

  double brightness = 0;
  double sharpness = 0;

  String quality = 'ยังไม่ได้ตรวจ';

  final List<ScanResult> results = [];

  // ด้านที่ผู้ใช้ระบุว่าไม่มีข้อมูล
  final Set<String> noDataAreas = {};

  String get area => areas[areaIndex];

  // =====================================================
  // CAMERA
  // =====================================================

  @override
  void initState() {
    super.initState();
    startCamera();
  }

  Future<void> startCamera() async {
    if (widget.cameras.isEmpty) {
      return;
    }

    final cam = widget.cameras.firstWhere(
      (x) => x.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    controller = CameraController(
      cam,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller!.initialize();

    if (mounted) {
      setState(() {
        ready = true;
      });
    }
  }

  // =====================================================
  // IMAGE QUALITY
  // =====================================================

  void checkQuality(CameraImage image) {
    if (image.planes.isEmpty) return;

    final bytes = image.planes.first.bytes;

    if (bytes.isEmpty) return;

    int step = bytes.length ~/ 1000;

    if (step < 1) {
      step = 1;
    }

    double total = 0;
    int count = 0;

    for (int i = 0; i < bytes.length; i += step) {
      total += bytes[i];
      count++;
    }

    if (count == 0) return;

    final b = total / count;

    final w = image.width;
    final h = image.height;

    final row = image.planes.first.bytesPerRow;

    final sx = w ~/ 40 < 1 ? 1 : w ~/ 40;
    final sy = h ~/ 30 < 1 ? 1 : h ~/ 30;

    double edge = 0;
    int ec = 0;

    for (int y = sy; y < h; y += sy) {
      for (int x = sx; x < w; x += sx) {
        final p = y * row + x;
        final l = y * row + x - sx;
        final u = (y - sy) * row + x;

        if (p < bytes.length && l >= 0 && u >= 0) {
          edge += (bytes[p] - bytes[l]).abs();
          edge += (bytes[p] - bytes[u]).abs();
          ec += 2;
        }
      }
    }

    final s = ec == 0 ? 0 : edge / ec;

    brightness = b;
    sharpness = s.toDouble();

    String q;

    if (w < 640 || h < 480) {
      q = 'ความละเอียดต่ำ';
    } else if (b < 45) {
      q = 'ภาพมืดเกินไป';
    } else if (b > 235) {
      q = 'ภาพสว่างเกินไป';
    } else if (s < 5) {
      q = 'ภาพเบลอหรือไม่คม';
    } else if (s < 10) {
      q = 'ภาพค่อนข้างไม่คม';
    } else {
      q = 'คุณภาพภาพเบื้องต้นใช้ได้';
    }

    if (mounted) {
      setState(() {
        quality = q;
      });
    }
  }

  // =====================================================
  // GALLERY
  // =====================================================

  Future<void> pickGallery() async {
    if (scanning) {
      if (controller?.value.isStreamingImages ?? false) {
        await controller!.stopImageStream();
      }

      scanning = false;
    }

    final file = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (file == null) {
      return;
    }

    setState(() {
      galleryImage = file;

      frameCount = 0;
      brightness = 0;
      sharpness = 0;

      quality = 'นำเข้ารูปจากแกลเลอรี่แล้ว';

      // ถ้าเคยกดไม่มีข้อมูลด้านนี้
      // แล้วกลับมามีรูป ให้ยกเลิกสถานะไม่มีข้อมูล
      noDataAreas.remove(area);
    });
  }

  // =====================================================
  // START SCAN
  // =====================================================

  Future<void> startScan() async {
    if (controller == null ||
        !controller!.value.isInitialized ||
        controller!.value.isStreamingImages) {
      return;
    }

    setState(() {
      galleryImage = null;

      scanning = true;

      frameCount = 0;
      brightness = 0;
      sharpness = 0;

      quality = 'กำลังตรวจ...';

      noDataAreas.remove(area);
    });

    await controller!.startImageStream((CameraImage image) {
      if (!scanning) return;

      frameCount++;

      if (frameCount % 10 == 0) {
        checkQuality(image);
      }
    });
  }

  // =====================================================
  // STOP SCAN
  // =====================================================

  Future<void> stopScan() async {
    if (scanning) {
      if (controller?.value.isStreamingImages ?? false) {
        await controller!.stopImageStream();
      }

      setState(() {
        scanning = false;
      });
    }
  }

  // =====================================================
  // SAVE CURRENT AREA
  // =====================================================

  Future<bool> saveCurrentArea() async {
    if (scanning) {
      if (controller?.value.isStreamingImages ?? false) {
        await controller!.stopImageStream();
      }

      scanning = false;
    }

    // ถ้าไม่มีภาพ
    if (galleryImage == null &&
        frameCount == 0 &&
        quality == 'ยังไม่ได้ตรวจ') {
      return false;
    }

    final result = ScanResult(
      area: area,
      brightness: brightness,
      sharpness: sharpness,
      quality: quality,
      details: quality.contains('ใช้ได้') ||
              galleryImage != null
          ? 'รอระบบ AI วิเคราะห์รายละเอียดทั้งหมดที่มองเห็นในองค์พระ'
          : 'ตรวจสอบไม่ได้ / ภาพไม่ละเอียดพอ',
      fromGallery: galleryImage != null,
    );

    results.removeWhere(
      (x) => x.area == area,
    );

    results.add(result);

    noDataAreas.remove(area);

    return true;
  }

  // =====================================================
  // MARK NO DATA
  // =====================================================

  Future<void> markNoData() async {
    if (scanning) {
      await stopScan();
    }

    // ลบข้อมูลเก่าของด้านนี้ก่อน
    results.removeWhere(
      (x) => x.area == area,
    );

    galleryImage = null;

    noDataAreas.add(area);

    if (areaIndex < areas.length - 1) {
      goNextArea();
    } else {
      showSummary();
    }
  }

  // =====================================================
  // NEXT AREA
  // =====================================================

  Future<void> nextArea() async {
    final hasImage =
        galleryImage != null ||
        frameCount > 0 ||
        quality != 'ยังไม่ได้ตรวจ';

    if (hasImage) {
      final saved = await saveCurrentArea();

      if (saved) {
        goNextArea();
      }

      return;
    }

    // ไม่มีข้อมูล → ไม่บันทึกช่องว่าง
    await showNoDataDialog();
  }

  // =====================================================
  // NO DATA DIALOG
  // =====================================================

  Future<void> showNoDataDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('ยังไม่มีข้อมูล$area'),
          content: Text(
            'ถ้าองค์อ้างอิงนี้ไม่มีข้อมูล$area\n'
            'สามารถข้ามด้านนี้ได้\n\n'
            'ระบบจะไม่สร้างข้อมูลว่าง และ AI จะเข้าใจว่า '
            'ด้านนี้ไม่มีข้อมูลอ้างอิง',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('กลับไปสแกน'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                markNoData();
              },
              child: const Text('ไม่มีข้อมูล / ข้ามด้านนี้'),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // GO NEXT
  // =====================================================

  void goNextArea() {
    if (areaIndex < areas.length - 1) {
      setState(() {
        areaIndex++;

        galleryImage = null;

        frameCount = 0;

        brightness = 0;

        sharpness = 0;

        quality = 'ยังไม่ได้ตรวจ';
      });
    } else {
      showSummary();
    }
  }

  // =====================================================
  // SUMMARY
  // =====================================================

  void showSummary() {
    final dataCount = results.length;

    final noDataCount = noDataAreas.length;

    showDialog(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text('สรุปข้อมูลอ้างอิง'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'มีข้อมูล $dataCount ด้าน\n'
                  'ไม่มีข้อมูล $noDataCount ด้าน',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                for (final a in areas)
                  Builder(
                    builder: (_) {
                      final result = results
                          .where((x) => x.area == a)
                          .firstOrNull;

                      final noData =
                          noDataAreas.contains(a);

                      if (result != null) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.check_circle,
                          ),
                          title: Text(a),
                          subtitle: Text(
                            '${result.fromGallery ? "รูปจากแกลเลอรี่" : "กล้อง"}\n'
                            '${result.quality}\n'
                            '${result.details}',
                          ),
                        );
                      }

                      if (noData) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.remove_circle_outline,
                          ),
                          title: Text(a),
                          subtitle: const Text(
                            'ไม่มีข้อมูลอ้างอิง',
                          ),
                        );
                      }

                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.help_outline,
                        ),
                        title: Text(a),
                        subtitle: const Text(
                          'ยังไม่ได้ระบุข้อมูล',
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(c);
              },
              child: const Text('ปิด'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(c);
                Navigator.pop(context);
              },
              child: const Text('เสร็จสิ้น'),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    controller?.dispose();

    super.dispose();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext c) {
    if (!ready || controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('สแกน$area'),
      ),

      body: Column(
        children: [
          // =================================================
          // AREA PROGRESS
          // =================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              8,
              8,
              8,
              4,
            ),
            child: Row(
              children: [
                for (int i = 0; i < areas.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          results.any(
                            (x) => x.area == areas[i],
                          )
                              ? Icons.check_circle
                              : noDataAreas.contains(
                                  areas[i],
                                )
                                  ? Icons.remove_circle_outline
                                  : i == areaIndex
                                      ? Icons
                                          .radio_button_checked
                                      : Icons
                                          .radio_button_unchecked,
                          size: 26,
                        ),

                        const SizedBox(height: 2),

                        Text(
                          areas[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: i == areaIndex
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // =================================================
          // CAMERA / IMAGE
          // =================================================

          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (galleryImage == null)
                  CameraPreview(controller!)
                else
                  Image.file(
                    File(galleryImage!.path),
                    fit: BoxFit.contain,
                  ),

                if (galleryImage == null)
                  Center(
                    child: Container(
                      width: 260,
                      height: 360,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'จัดพระให้อยู่ในกรอบ\n$area',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.black54,
                    child: Text(
                      galleryImage != null
                          ? 'รูปจากแกลเลอรี่\n'
                              '$area\n'
                              '$quality'
                          : scanning
                              ? 'รับภาพชั่วคราว\n'
                                  'เฟรม: $frameCount\n'
                                  'ความสว่าง: '
                                  '${brightness.toStringAsFixed(0)}\n'
                                  'ความคม: '
                                  '${sharpness.toStringAsFixed(1)}\n'
                                  '$quality'
                              : 'พร้อมสแกน$area',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // =================================================
          // BOTTOM CONTROLS
          // =================================================

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  'สแกน$area\n'
                  'ภาพใช้ชั่วคราวสำหรับการวิเคราะห์\n'
                  'ไม่มีการบันทึกรูปเข้าข้อมูลพระ',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    // แกลเลอรี่
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.photo_library,
                        ),
                        label: const Text(
                          'แกลเลอรี่',
                        ),
                        onPressed: pickGallery,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // กล้อง
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          scanning
                              ? Icons.stop
                              : Icons.camera,
                        ),
                        label: Text(
                          scanning
                              ? 'หยุด'
                              : 'กล้อง',
                        ),
                        onPressed:
                            scanning ? stopScan : startScan,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ถัดไป
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.arrow_forward,
                        ),
                        label: Text(
                          areaIndex ==
                                  areas.length - 1
                              ? 'เสร็จสิ้น'
                              : 'ถัดไป',
                        ),
                        onPressed: nextArea,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ปุ่มไม่มีข้อมูล
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                    ),
                    label: Text(
                      'ไม่มีข้อมูล$area / ข้ามด้านนี้',
                    ),
                    onPressed: markNoData,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
