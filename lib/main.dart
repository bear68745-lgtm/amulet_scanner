import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(App(cameras));
}

// =====================================================
// APP
// =====================================================

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

// =====================================================
// REFERENCE DATA
// =====================================================

class ReferenceData {
  final String id;
  final DateTime createdAt;
  final List<ScanResult> scans;
  final List<String> noDataAreas;

  ReferenceData({
    required this.id,
    required this.createdAt,
    required this.scans,
    required this.noDataAreas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'scans': scans.map((x) => x.toMap()).toList(),
      'noDataAreas': noDataAreas,
    };
  }

  factory ReferenceData.fromMap(Map<String, dynamic> map) {
    return ReferenceData(
      id: map['id'] ?? '',
      createdAt: DateTime.tryParse(
            map['createdAt'] ?? '',
          ) ??
          DateTime.now(),
      scans: (map['scans'] as List? ?? [])
          .map(
            (x) => ScanResult.fromMap(
              Map<String, dynamic>.from(x),
            ),
          )
          .toList(),
      noDataAreas: List<String>.from(
        map['noDataAreas'] ?? [],
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

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      area: map['area'] ?? '',
      brightness: (map['brightness'] ?? 0).toDouble(),
      sharpness: (map['sharpness'] ?? 0).toDouble(),
      quality: map['quality'] ?? '',
      details: map['details'] ?? '',
      fromGallery: map['fromGallery'] ?? false,
    );
  }
}

// =====================================================
// LOCAL STORAGE
// =====================================================

class ReferenceStorage {
  static const String key = 'reference_data';

  static Future<List<ReferenceData>> load() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map(
            (x) => ReferenceData.fromMap(
              Map<String, dynamic>.from(x),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(
    ReferenceData reference,
  ) async {
    final list = await load();

    list.add(reference);

    await _write(list);
  }

  static Future<void> _write(
    List<ReferenceData> list,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final data = list
        .map((x) => x.toMap())
        .toList();

    await prefs.setString(
      key,
      jsonEncode(data),
    );
  }

  static Future<void> delete(
    String id,
  ) async {
    final list = await load();

    list.removeWhere(
      (x) => x.id == id,
    );

    await _write(list);
  }
}

// =====================================================
// HOME PAGE
// =====================================================

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage(this.cameras, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int referenceCount = 0;

  @override
  void initState() {
    super.initState();
    loadCount();
  }

  Future<void> loadCount() async {
    final data = await ReferenceStorage.load();

    if (!mounted) return;

    setState(() {
      referenceCount = data.length;
    });
  }

  Future<void> openScan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(widget.cameras),
      ),
    );

    loadCount();
  }

  Future<void> openReferences() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReferenceListPage(
          cameras: widget.cameras,
        ),
      ),
    );

    loadCount();
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'กล้องสแกนพระและเหรียญ',
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            Text(
              'ฐานข้อมูลส่วนตัว',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),

            const SizedBox(height: 8),

            Text(
              'มีองค์อ้างอิง $referenceCount องค์',
              style: const TextStyle(
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.camera_alt,
                ),
                label: const Text(
                  'สร้าง / เพิ่มองค์อ้างอิง',
                ),
                onPressed: openScan,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(
                  Icons.storage,
                ),
                label: const Text(
                  'รายการองค์อ้างอิง',
                ),
                onPressed: openReferences,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// REFERENCE LIST
// =====================================================

class ReferenceListPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ReferenceListPage({
    required this.cameras,
    super.key,
  });

  @override
  State<ReferenceListPage> createState() =>
      _ReferenceListPageState();
}

class _ReferenceListPageState
    extends State<ReferenceListPage> {
  List<ReferenceData> references = [];

  @override
  void initState() {
    super.initState();
    loadReferences();
  }

  Future<void> loadReferences() async {
    final data = await ReferenceStorage.load();

    if (!mounted) return;

    setState(() {
      references = data;
    });
  }

  Future<void> deleteReference(
    ReferenceData reference,
  ) async {
    await ReferenceStorage.delete(
      reference.id,
    );

    loadReferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายการองค์อ้างอิง',
        ),
      ),

      body: references.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีองค์อ้างอิง',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: references.length,
              itemBuilder: (context, index) {
                final reference =
                    references[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        '${index + 1}',
                      ),
                    ),

                    title: Text(
                      'องค์อ้างอิง ${index + 1}',
                    ),

                    subtitle: Text(
                      'มีข้อมูล ${reference.scans.length} ด้าน'
                      ' • ไม่มีข้อมูล ${reference.noDataAreas.length} ด้าน',
                    ),

                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete,
                      ),
                      onPressed: () async {
                        final ok =
                            await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: const Text(
                                'ลบองค์อ้างอิง',
                              ),
                              content: const Text(
                                'ต้องการลบข้อมูลขององค์อ้างอิงนี้ทั้งหมดหรือไม่?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(
                                      dialogContext,
                                      false,
                                    );
                                  },
                                  child: const Text(
                                    'ยกเลิก',
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(
                                      dialogContext,
                                      true,
                                    );
                                  },
                                  child: const Text(
                                    'ลบ',
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (ok == true) {
                          await deleteReference(
                            reference,
                          );
                        }
                      },
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReferenceDetailPage(
                            reference: reference,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// =====================================================
// REFERENCE DETAIL
// =====================================================

class ReferenceDetailPage
    extends StatelessWidget {
  final ReferenceData reference;

  const ReferenceDetailPage({
    required this.reference,
    super.key,
  });

  static const areas = [
    'ด้านหน้า',
    'ด้านหลัง',
    'ด้านข้าง',
    'ก้นพระ',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ข้อมูลองค์อ้างอิง',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'องค์อ้างอิง',
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),

          const SizedBox(height: 6),

          Text(
            'สร้างเมื่อ ${reference.createdAt.day}/'
            '${reference.createdAt.month}/'
            '${reference.createdAt.year}',
          ),

          const SizedBox(height: 20),

          for (final area in areas)
            _areaCard(area),

          const SizedBox(height: 20),

          const Text(
            'หมายเหตุ: ระบบเก็บข้อมูลวิเคราะห์ '
            'ไม่ได้เก็บรูปภาพถาวร',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _areaCard(String area) {
    final result = reference.scans
        .where((x) => x.area == area)
        .firstOrNull;

    final noData =
        reference.noDataAreas.contains(area);

    if (result != null) {
      return Card(
        child: ListTile(
          leading: const Icon(
            Icons.check_circle,
          ),
          title: Text(area),
          subtitle: Text(
            'สถานะ: มีข้อมูล\n'
            'คุณภาพ: ${result.quality}\n'
            'ความสว่าง: '
            '${result.brightness.toStringAsFixed(0)}\n'
            'ความคม: '
            '${result.sharpness.toStringAsFixed(1)}\n'
            '${result.details}',
          ),
        ),
      );
    }

    if (noData) {
      return Card(
        child: ListTile(
          leading: const Icon(
            Icons.remove_circle_outline,
          ),
          title: Text(area),
          subtitle: const Text(
            'สถานะ: ไม่มีข้อมูลอ้างอิง',
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.help_outline,
        ),
        title: Text(area),
        subtitle: const Text(
          'ยังไม่ได้ระบุข้อมูล',
        ),
      ),
    );
  }
}

// =====================================================
// SCAN PAGE
// =====================================================

class ScanPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScanPage(this.cameras, {super.key});

  @override
  State<ScanPage> createState() =>
      _ScanPageState();
}

class _ScanPageState
    extends State<ScanPage> {
  CameraController? controller;

  final ImagePicker picker =
      ImagePicker();

  XFile? galleryImage;

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

    final cam =
        widget.cameras.firstWhere(
      (x) =>
          x.lensDirection ==
          CameraLensDirection.back,
      orElse: () =>
          widget.cameras.first,
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
  // QUALITY
  // =====================================================

  void checkQuality(
    CameraImage image,
  ) {
    if (image.planes.isEmpty) return;

    final bytes =
        image.planes.first.bytes;

    if (bytes.isEmpty) return;

    int step =
        bytes.length ~/ 1000;

    if (step < 1) {
      step = 1;
    }

    double total = 0;
    int count = 0;

    for (
      int i = 0;
      i < bytes.length;
      i += step
    ) {
      total += bytes[i];
      count++;
    }

    if (count == 0) return;

    final b = total / count;

    final w = image.width;
    final h = image.height;

    final row =
        image.planes.first.bytesPerRow;

    final sx =
        w ~/ 40 < 1 ? 1 : w ~/ 40;

    final sy =
        h ~/ 30 < 1 ? 1 : h ~/ 30;

    double edge = 0;
    int ec = 0;

    for (
      int y = sy;
      y < h;
      y += sy
    ) {
      for (
        int x = sx;
        x < w;
        x += sx
      ) {
        final p = y * row + x;
        final l =
            y * row + x - sx;
        final u =
            (y - sy) * row + x;

        if (
          p < bytes.length &&
          l >= 0 &&
          u >= 0
        ) {
          edge +=
              (bytes[p] - bytes[l])
                  .abs();

          edge +=
              (bytes[p] - bytes[u])
                  .abs();

          ec += 2;
        }
      }
    }

    final s =
        ec == 0 ? 0 : edge / ec;

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
      if (controller
              ?.value.isStreamingImages ??
          false) {
        await controller!
            .stopImageStream();
      }

      scanning = false;
    }

    final file =
        await picker.pickImage(
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

      quality =
          'นำเข้ารูปจากแกลเลอรี่แล้ว';

      noDataAreas.remove(area);
    });
  }

  // =====================================================
  // START SCAN
  // =====================================================

  Future<void> startScan() async {
    if (controller == null ||
        !controller!.value
            .isInitialized ||
        controller!.value
            .isStreamingImages) {
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

    await controller!
        .startImageStream(
      (CameraImage image) {
        if (!scanning) return;

        frameCount++;

        if (frameCount % 10 == 0) {
          checkQuality(image);
        }
      },
    );
  }

  // =====================================================
  // STOP SCAN
  // =====================================================

  Future<void> stopScan() async {
    if (scanning) {
      if (controller
              ?.value.isStreamingImages ??
          false) {
        await controller!
            .stopImageStream();
      }

      setState(() {
        scanning = false;
      });
    }
  }

  // =====================================================
  // SAVE AREA
  // =====================================================

  Future<bool> saveCurrentArea() async {
    if (scanning) {
      if (controller
              ?.value.isStreamingImages ??
          false) {
        await controller!
            .stopImageStream();
      }

      scanning = false;
    }

    if (galleryImage == null &&
        frameCount == 0 &&
        quality ==
            'ยังไม่ได้ตรวจ') {
      return false;
    }

    final result = ScanResult(
      area: area,
      brightness: brightness,
      sharpness: sharpness,
      quality: quality,
      details:
          quality.contains('ใช้ได้') ||
                  galleryImage != null
              ? 'รอระบบ AI วิเคราะห์รายละเอียดทั้งหมดที่มองเห็นในองค์พระ'
              : 'ตรวจสอบไม่ได้ / ภาพไม่ละเอียดพอ',
      fromGallery:
          galleryImage != null,
    );

    results.removeWhere(
      (x) => x.area == area,
    );

    results.add(result);

    noDataAreas.remove(area);

    return true;
  }

  // =====================================================
  // NO DATA
  // =====================================================

  Future<void> markNoData() async {
    if (scanning) {
      await stopScan();
    }

    results.removeWhere(
      (x) => x.area == area,
    );

    galleryImage = null;

    noDataAreas.add(area);

    if (areaIndex <
        areas.length - 1) {
      goNextArea();
    } else {
      showSummary();
    }
  }

  // =====================================================
  // NEXT
  // =====================================================

  Future<void> nextArea() async {
    final hasImage =
        galleryImage != null ||
        frameCount > 0 ||
        quality !=
            'ยังไม่ได้ตรวจ';

    if (hasImage) {
      final saved =
          await saveCurrentArea();

      if (saved) {
        goNextArea();
      }

      return;
    }

    await showNoDataDialog();
  }

  // =====================================================
  // NO DATA DIALOG
  // =====================================================

  Future<void>
      showNoDataDialog() async {
    await showDialog(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title: Text(
            'ยังไม่มีข้อมูล$area',
          ),
          content: Text(
            'ถ้าองค์อ้างอิงนี้ไม่มีข้อมูล$area\n'
            'สามารถข้ามด้านนี้ได้\n\n'
            'ระบบจะไม่สร้างข้อมูลว่าง และ AI จะเข้าใจว่า '
            'ด้านนี้ไม่มีข้อมูลอ้างอิง',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text(
                'กลับไปสแกน',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                markNoData();
              },
              child: const Text(
                'ไม่มีข้อมูล / ข้ามด้านนี้',
              ),
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
    if (areaIndex <
        areas.length - 1) {
      setState(() {
        areaIndex++;

        galleryImage = null;

        frameCount = 0;

        brightness = 0;

        sharpness = 0;

        quality =
            'ยังไม่ได้ตรวจ';
      });
    } else {
      showSummary();
    }
  }

  // =====================================================
  // SAVE REFERENCE
  // =====================================================

  Future<void>
      saveReference() async {
    if (results.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'ยังไม่มีข้อมูลด้านใดสำหรับบันทึก',
          ),
        ),
      );

      return;
    }

    final reference =
        ReferenceData(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      createdAt: DateTime.now(),
      scans: List.from(results),
      noDataAreas:
          noDataAreas.toList(),
    );

    await ReferenceStorage.save(
      reference,
    );

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'บันทึกองค์อ้างอิงเรียบร้อยแล้ว',
        ),
      ),
    );
  }

  // =====================================================
  // SUMMARY
  // =====================================================

  void showSummary() {
    final dataCount =
        results.length;

    final noDataCount =
        noDataAreas.length;

    showDialog(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text(
            'สรุปข้อมูลอ้างอิง',
          ),
          content:
              SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  'มีข้อมูล $dataCount ด้าน\n'
                  'ไม่มีข้อมูล $noDataCount ด้าน',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                for (final a in areas)
                  Builder(
                    builder: (_) {
                      final result =
                          results
                              .where(
                                (x) =>
                                    x.area ==
                                    a,
                              )
                              .firstOrNull;

                      final noData =
                          noDataAreas
                              .contains(a);

                      if (result !=
                          null) {
                        return ListTile(
                          dense: true,
                          leading:
                              const Icon(
                            Icons
                                .check_circle,
                          ),
                          title:
                              Text(a),
                          subtitle:
                              Text(
                            '${result.fromGallery ? "รูปจากแกลเลอรี่" : "กล้อง"}\n'
                            '${result.quality}\n'
                            '${result.details}',
                          ),
                        );
                      }

                      if (noData) {
                        return ListTile(
                          dense: true,
                          leading:
                              const Icon(
                            Icons
                                .remove_circle_outline,
                          ),
                          title:
                              Text(a),
                          subtitle:
                              const Text(
                            'ไม่มีข้อมูลอ้างอิง',
                          ),
                        );
                      }

                      return ListTile(
                        dense: true,
                        leading:
                            const Icon(
                          Icons
                              .help_outline,
                        ),
                        title:
                            Text(a),
                        subtitle:
                            const Text(
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
              child:
                  const Text('ปิด'),
            ),
            ElevatedButton(
              onPressed:
                  saveReference,
              child: const Text(
                'บันทึกองค์อ้างอิง',
              ),
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
    if (!ready ||
        controller == null) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Text('สแกน$area'),
      ),

      body: Column(
        children: [
          // =================================================
          // PROGRESS
          // =================================================

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              8,
              8,
              8,
              4,
            ),
            child: Row(
              children: [
                for (
                  int i = 0;
                  i < areas.length;
                  i++
                )
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          results.any(
                            (x) =>
                                x.area ==
                                areas[i],
                          )
                              ? Icons
                                  .check_circle
                              : noDataAreas
                                      .contains(
                                    areas[i],
                                  )
                                  ? Icons
                                      .remove_circle_outline
                                  : i ==
                                          areaIndex
                                      ? Icons
                                          .radio_button_checked
                                      : Icons
                                          .radio_button_unchecked,
                          size: 26,
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          areas[i],
                          style:
                              TextStyle(
                            fontSize:
                                12,
                            fontWeight:
                                i ==
                                        areaIndex
                                    ? FontWeight
                                        .bold
                                    : FontWeight
                                        .normal,
                          ),
                          textAlign:
                              TextAlign
                                  .center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // =================================================
          // CAMERA
          // =================================================

          Expanded(
            child: Stack(
              fit:
                  StackFit.expand,
              children: [
                if (galleryImage ==
                    null)
                  CameraPreview(
                    controller!,
                  )
                else
                  Image.file(
                    File(
                      galleryImage!
                          .path,
                    ),
                    fit: BoxFit
                        .contain,
                  ),

                if (galleryImage ==
                    null)
                  Center(
                    child:
                        Container(
                      width: 260,
                      height: 360,
                      decoration:
                          BoxDecoration(
                        border:
                            Border.all(
                          color:
                              Colors.white,
                          width: 3,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                      child:
                          Center(
                        child:
                            Text(
                          'จัดพระให้อยู่ในกรอบ\n$area',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                18,
                            fontWeight:
                                FontWeight
                                    .bold,
                            shadows: [
                              Shadow(
                                blurRadius:
                                    4,
                                offset:
                                    Offset(
                                  1,
                                  1,
                                ),
                              ),
                            ],
                          ),
                          textAlign:
                              TextAlign
                                  .center,
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child:
                      Container(
                    padding:
                        const EdgeInsets
                            .all(10),
                    color:
                        Colors.black54,
                    child: Text(
                      galleryImage !=
                              null
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
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            15,
                      ),
                      textAlign:
                          TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // =================================================
          // BUTTONS
          // =================================================

          Padding(
            padding:
                const EdgeInsets.all(
              12,
            ),
            child: Column(
              children: [
                Text(
                  'สแกน$area\n'
                  'ภาพใช้ชั่วคราวสำหรับการวิเคราะห์\n'
                  'ไม่มีการบันทึกรูปเข้าข้อมูลพระ',
                  textAlign:
                      TextAlign.center,
                ),

                const SizedBox(
                  height: 10,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          ElevatedButton
                              .icon(
                        icon:
                            const Icon(
                          Icons
                              .photo_library,
                        ),
                        label:
                            const Text(
                          'แกลเลอรี่',
                        ),
                        onPressed:
                            pickGallery,
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child:
                          ElevatedButton
                              .icon(
                        icon: Icon(
                          scanning
                              ? Icons
                                  .stop
                              : Icons
                                  .camera,
                        ),
                        label: Text(
                          scanning
                              ? 'หยุด'
                              : 'กล้อง',
                        ),
                        onPressed:
                            scanning
                                ? stopScan
                                : startScan,
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child:
                          ElevatedButton
                              .icon(
                        icon:
                            const Icon(
                          Icons
                              .arrow_forward,
                        ),
                        label: Text(
                          areaIndex ==
                                  areas.length -
                                      1
                              ? 'เสร็จสิ้น'
                              : 'ถัดไป',
                        ),
                        onPressed:
                            nextArea,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  child:
                      OutlinedButton
                          .icon(
                    icon:
                        const Icon(
                      Icons
                          .remove_circle_outline,
                    ),
                    label: Text(
                      'ไม่มีข้อมูล$area / ข้ามด้านนี้',
                    ),
                    onPressed:
                        markNoData,
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
