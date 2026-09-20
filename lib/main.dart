import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App(await availableCameras()));
}

class App extends StatelessWidget {
  final List<CameraDescription> cameras;

  const App(this.cameras, {super.key});

  @override
  Widget build(BuildContext c) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'กล้องสแกนพระและเหรียญ',
      theme: ThemeData(useMaterial3: true),
      home: HomePage(cameras),
    );
  }
}

// =====================================================
// พื้นที่สแกน
// =====================================================

const areas = [
  'ด้านหน้า',
  'ด้านหลัง',
  'ด้านข้าง',
  'ก้นพระ',
];

// =====================================================
// ประเภทพระ / วัตถุ 20 ประเภท
// =====================================================

const types = [
  'เหรียญ',
  'เหรียญหล่อ',
  'พระสมเด็จ',
  'รูปหล่อ',
  'พระกริ่ง',
  'พระปิดตาเนื้อผง/หว้าน',
  'พระปิดตาเนื้อโลหะ',
  'พระเนื้อผง',
  'พระเนื้อดิน',
  'นางพญา',
  'ผงสุพรรณ',
  'พระรอด',
  'พระซุ้มกอ',
  'พระขุนแผน',
  'หลวงปู่ทวดเนื้อหว้าน',
  'หลวงปู่ทวดหลังเตารีด',
  'เขี้ยวแกะ',
  'งาแกะ',
  'ตะกรุด',
  'อื่น ๆ',
];

// =====================================================
// SCAN RESULT
// =====================================================

class ScanResult {
  final String area;
  final String quality;
  final String details;
  final double brightness;
  final double sharpness;
  final bool fromGallery;

  ScanResult({
    required this.area,
    required this.brightness,
    required this.sharpness,
    required this.quality,
    required this.details,
    required this.fromGallery,
  });

  Map<String, dynamic> toMap() => {
        'area': area,
        'brightness': brightness,
        'sharpness': sharpness,
        'quality': quality,
        'details': details,
        'fromGallery': fromGallery,
      };

  factory ScanResult.fromMap(Map<String, dynamic> m) {
    return ScanResult(
      area: m['area'] ?? '',
      brightness: (m['brightness'] ?? 0).toDouble(),
      sharpness: (m['sharpness'] ?? 0).toDouble(),
      quality: m['quality'] ?? '',
      details: m['details'] ?? '',
      fromGallery: m['fromGallery'] ?? false,
    );
  }
}

// =====================================================
// REFERENCE DATA
// =====================================================

class ReferenceData {
  final String id;

  // เลของค์อ้างอิงถาวร
  final int referenceNumber;

  final DateTime createdAt;

  // ข้อมูลพระ
  final String name;
  final String model;
  final String pim;
  final String type;
  final String temple;

  final List<ScanResult> scans;
  final List<String> noDataAreas;

  ReferenceData({
    required this.id,
    required this.referenceNumber,
    required this.createdAt,
    required this.name,
    required this.model,
    required this.pim,
    required this.type,
    required this.temple,
    required this.scans,
    required this.noDataAreas,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'referenceNumber': referenceNumber,
        'createdAt': createdAt.toIso8601String(),

        'name': name,
        'model': model,
        'pim': pim,
        'type': type,
        'temple': temple,

        'scans': scans.map((x) => x.toMap()).toList(),
        'noDataAreas': noDataAreas,
      };

  factory ReferenceData.fromMap(Map<String, dynamic> m) {
    return ReferenceData(
      id: m['id'] ?? '',

      referenceNumber:
          (m['referenceNumber'] ?? 0).toInt(),

      createdAt:
          DateTime.tryParse(m['createdAt'] ?? '') ??
              DateTime.now(),

      name: m['name'] ?? '',
      model: m['model'] ?? '',
      pim: m['pim'] ?? '',
      type: m['type'] ?? '',
      temple: m['temple'] ?? '',

      scans: (m['scans'] as List? ?? [])
          .map(
            (x) => ScanResult.fromMap(
              Map<String, dynamic>.from(x),
            ),
          )
          .toList(),

      noDataAreas:
          List<String>.from(m['noDataAreas'] ?? []),
    );
  }
}

// =====================================================
// STORAGE
// =====================================================

class ReferenceStorage {
  static const key = 'reference_data';

  static Future<List<ReferenceData>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final data = jsonDecode(raw);

      if (data is! List) {
        return [];
      }

      return data
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

  static Future<void> save(ReferenceData item) async {
    final list = await load();

    list.add(item);

    await _write(list);
  }

  static Future<void> delete(String id) async {
    final list = await load();

    list.removeWhere((x) => x.id == id);

    await _write(list);
  }

  // หาเลของค์ใหม่
  // ลบองค์ไหนไปแล้ว เลขนั้นจะไม่ถูกนำกลับมาใช้
  static Future<int> nextReferenceNumber() async {
    final p = await SharedPreferences.getInstance();

    final last =
        p.getInt('last_reference_number') ?? 0;

    final next = last + 1;

    await p.setInt(
      'last_reference_number',
      next,
    );

    return next;
  }

  static Future<void> _write(
    List<ReferenceData> list,
  ) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      key,
      jsonEncode(
        list.map((x) => x.toMap()).toList(),
      ),
    );
  }
}

// =====================================================
// HOME
// =====================================================

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage(
    this.cameras, {
    super.key,
  });

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int count = 0;

  @override
  void initState() {
    super.initState();
    loadCount();
  }

  Future<void> loadCount() async {
    final data =
        await ReferenceStorage.load();

    if (mounted) {
      setState(() {
        count = data.length;
      });
    }
  }

  Future<void> open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
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
              style: Theme.of(c)
                  .textTheme
                  .headlineSmall,
            ),

            const SizedBox(height: 8),

            Text(
              'มีองค์อ้างอิง $count องค์',
              style:
                  const TextStyle(fontSize: 17),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.add_circle,
                ),
                label: const Text(
                  'สร้าง / เพิ่มองค์อ้างอิง',
                ),
                onPressed: () => open(
                  CreateReferencePage(
                    cameras: widget.cameras,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton.icon(
                icon: const Icon(
                  Icons.storage,
                ),
                label: const Text(
                  'รายการองค์อ้างอิง',
                ),
                onPressed: () => open(
                  ReferenceListPage(
                    cameras:
                        widget.cameras,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// หน้าสร้างข้อมูลพระ
// =====================================================

class CreateReferencePage
    extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CreateReferencePage({
    required this.cameras,
    super.key,
  });

  @override
  State<CreateReferencePage>
      createState() =>
          _CreateReferencePageState();
}

class _CreateReferencePageState
    extends State<CreateReferencePage> {
  final nameController =
      TextEditingController();

  final modelController =
      TextEditingController();

  final pimController =
      TextEditingController();

  final templeController =
      TextEditingController();

  String? selectedType;

  @override
  void dispose() {
    nameController.dispose();
    modelController.dispose();
    pimController.dispose();
    templeController.dispose();
    super.dispose();
  }

  void startScan() {
    if (nameController.text.trim().isEmpty) {
      showMessage('กรุณาใส่ชื่อพระ');
      return;
    }

    if (selectedType == null) {
      showMessage('กรุณาเลือกประเภท');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          name: nameController.text.trim(),
          model: modelController.text.trim(),
          pim: pimController.text.trim(),
          type: selectedType!,
          temple: templeController.text.trim(),
        ),
      ),
    );
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'สร้างข้อมูลองค์อ้างอิง',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'ข้อมูลพระ',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: nameController,
            decoration:
                const InputDecoration(
              labelText: 'ชื่อพระ',
              hintText:
                  'เช่น พระสมเด็จ',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: modelController,
            decoration:
                const InputDecoration(
              labelText: 'รุ่น',
              hintText:
                  'เช่น บางขุนพรหม',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: pimController,
            decoration:
                const InputDecoration(
              labelText: 'พิมพ์',
              hintText:
                  'เช่น พิมพ์ใหญ่ / พิมพ์เล็ก',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: selectedType,
            decoration:
                const InputDecoration(
              labelText: 'ประเภท',
              border:
                  OutlineInputBorder(),
            ),
            items: types
                .map(
                  (type) =>
                      DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedType = value;
              });
            },
          ),

          const SizedBox(height: 14),

          TextField(
            controller: templeController,
            decoration:
                const InputDecoration(
              labelText: 'วัด',
              hintText:
                  'เช่น วัดระฆัง',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 28),

          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(14),
              child: Text(
                'หมายเหตุ\n'
                'หน้านี้ไม่มีเลของค์อ้างอิง\n'
                'ระบบจะกำหนดเลขให้อัตโนมัติเมื่อบันทึกข้อมูล',
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.camera_alt,
              ),
              label: const Text(
                'เริ่มสแกนองค์นี้',
                style:
                    TextStyle(fontSize: 17),
              ),
              onPressed: startScan,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// LIST
// =====================================================

class ReferenceListPage
    extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ReferenceListPage({
    required this.cameras,
    super.key,
  });

  @override
  State<ReferenceListPage>
      createState() =>
          _ReferenceListPageState();
}

class _ReferenceListPageState
    extends State<ReferenceListPage> {
  List<ReferenceData> references = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data =
        await ReferenceStorage.load();

    if (mounted) {
      setState(() {
        references = data;
      });
    }
  }

  Future<void> deleteItem(
    ReferenceData item,
  ) async {
    final ok =
        await showDialog<bool>(
      context: context,
      builder: (c) =>
          AlertDialog(
        title: const Text(
          'ลบองค์อ้างอิง',
        ),
        content: Text(
          'ต้องการลบข้อมูลของ\n'
          'องค์อ้างอิง ${item.referenceNumber}\n'
          'ทั้งหมดหรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              c,
              false,
            ),
            child:
                const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(
              c,
              true,
            ),
            child:
                const Text('ลบ'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ReferenceStorage.delete(
        item.id,
      );

      load();
    }
  }

  @override
  Widget build(BuildContext c) {
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
                style:
                    TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.all(12),
              itemCount:
                  references.length,
              itemBuilder: (_, i) {
                final item =
                    references[i];

                return Card(
                  child: ListTile(
                    leading:
                        CircleAvatar(
                      child: Text(
                        '${item.referenceNumber}',
                      ),
                    ),

                    title: Text(
                      item.name.isEmpty
                          ? 'องค์อ้างอิง ${item.referenceNumber}'
                          : item.name,
                    ),

                    subtitle: Text(
                      'องค์อ้างอิง ${item.referenceNumber}\n'
                      'รุ่น: ${item.model.isEmpty ? "-" : item.model}\n'
                      'พิมพ์: ${item.pim.isEmpty ? "-" : item.pim}\n'
                      'ประเภท: ${item.type.isEmpty ? "-" : item.type}\n'
                      'วัด: ${item.temple.isEmpty ? "-" : item.temple}\n'
                      'มีข้อมูล ${item.scans.length} ด้าน'
                      ' • ไม่มีข้อมูล ${item.noDataAreas.length} ด้าน',
                    ),

                    isThreeLine: true,

                    trailing:
                        IconButton(
                      icon: const Icon(
                        Icons.delete,
                      ),
                      onPressed: () =>
                          deleteItem(
                        item,
                      ),
                    ),

                    onTap: () =>
                        Navigator.push(
                      c,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReferenceDetailPage(
                          reference:
                              item,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// =====================================================
// DETAIL
// =====================================================

class ReferenceDetailPage
    extends StatelessWidget {
  final ReferenceData reference;

  const ReferenceDetailPage({
    required this.reference,
    super.key,
  });

  ScanResult? find(String area) {
    for (final x
        in reference.scans) {
      if (x.area == area) {
        return x;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ข้อมูลองค์อ้างอิง',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Text(
            'องค์อ้างอิง ${reference.referenceNumber}',
            style: Theme.of(c)
                .textTheme
                .headlineSmall,
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  info('ชื่อพระ',
                      reference.name),
                  info('รุ่น',
                      reference.model),
                  info('พิมพ์',
                      reference.pim),
                  info('ประเภท',
                      reference.type),
                  info('วัด',
                      reference.temple),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'สร้างเมื่อ '
            '${reference.createdAt.day}/'
            '${reference.createdAt.month}/'
            '${reference.createdAt.year}',
          ),

          const SizedBox(height: 20),

          for (final area in areas)
            areaCard(area),

          const SizedBox(height: 20),

          const Text(
            'ระบบเก็บข้อมูลวิเคราะห์ '
            'ไม่เก็บรูปภาพถาวร',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget info(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        '$label: '
        '${value.isEmpty ? "-" : value}',
        style:
            const TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }

  Widget areaCard(String area) {
    final result = find(area);

    if (result != null) {
      return Card(
        child: ListTile(
          leading:
              const Icon(
            Icons.check_circle,
          ),
          title: Text(area),
          subtitle: Text(
            'สถานะ: มีข้อมูล\n'
            'คุณภาพ: ${result.quality}\n'
            'ความสว่าง: ${result.brightness.toStringAsFixed(0)}\n'
            'ความคม: ${result.sharpness.toStringAsFixed(1)}\n'
            '${result.details}',
          ),
        ),
      );
    }

    if (reference.noDataAreas
        .contains(area)) {
      return Card(
        child: ListTile(
          leading:
              const Icon(
            Icons.remove_circle_outline,
          ),
          title: Text(area),
          subtitle:
              const Text(
            'สถานะ: ไม่มีข้อมูลอ้างอิง',
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading:
            const Icon(
          Icons.help_outline,
        ),
        title: Text(area),
        subtitle:
            const Text(
          'ยังไม่ได้ระบุข้อมูล',
        ),
      ),
    );
  }
}

// =====================================================
// SCAN PAGE
// =====================================================

class ScanPage
    extends StatefulWidget {
  final List<CameraDescription> cameras;

  final String name;
  final String model;
  final String pim;
  final String type;
  final String temple;

  const ScanPage({
    required this.cameras,
    required this.name,
    required this.model,
    required this.pim,
    required this.type,
    required this.temple,
    super.key,
  });

  @override
  State<ScanPage> createState() =>
      _ScanPageState();
}

class _ScanPageState
    extends State<ScanPage> {
  CameraController? controller;

  final picker =
      ImagePicker();

  XFile? galleryImage;

  int areaIndex = 0;
  int frameCount = 0;

  bool ready = false;
  bool scanning = false;

  double brightness = 0;
  double sharpness = 0;

  String quality =
      'ยังไม่ได้ตรวจ';

  final results =
      <ScanResult>[];

  final noDataAreas =
      <String>{};

  String get area =>
      areas[areaIndex];

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

    controller =
        CameraController(
      cam,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller!
        .initialize();

    if (mounted) {
      setState(() {
        ready = true;
      });
    }
  }

  Future<void> stopStream() async {
    if (controller?.value
            .isStreamingImages ??
        false) {
      await controller!
          .stopImageStream();
    }

    if (mounted) {
      setState(() {
        scanning = false;
      });
    }
  }

  void checkQuality(
    CameraImage image,
  ) {
    if (image.planes.isEmpty) {
      return;
    }

    final bytes =
        image.planes.first.bytes;

    if (bytes.isEmpty) {
      return;
    }

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

    if (count == 0) {
      return;
    }

    final b =
        total / count;

    final w = image.width;
    final h = image.height;

    final row =
        image.planes.first.bytesPerRow;

    final sx =
        w ~/ 40 < 1
            ? 1
            : w ~/ 40;

    final sy =
        h ~/ 30 < 1
            ? 1
            : h ~/ 30;

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
        final p =
            y * row + x;

        final l =
            p - sx;

        final u =
            (y - sy) * row + x;

        if (p < bytes.length &&
            l >= 0 &&
            u >= 0) {
          edge +=
              (bytes[p] -
                      bytes[l])
                  .abs();

          edge +=
              (bytes[p] -
                      bytes[u])
                  .abs();

          ec += 2;
        }
      }
    }

    final s = ec == 0
        ? 0.0
        : edge / ec;

    String q;

    if (w < 640 ||
        h < 480) {
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
      q =
          'คุณภาพภาพเบื้องต้นใช้ได้';
    }

    if (mounted) {
      setState(() {
        brightness = b;
        sharpness = s;
        quality = q;
      });
    }
  }

  Future<void> pickGallery() async {
    await stopStream();

    final file =
        await picker.pickImage(
      source:
          ImageSource.gallery,
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

  Future<void> startScan() async {
    final cam = controller;

    if (cam == null ||
        !cam.value.isInitialized ||
        cam.value
            .isStreamingImages) {
      return;
    }

    setState(() {
      galleryImage = null;
      scanning = true;
      frameCount = 0;
      brightness = 0;
      sharpness = 0;
      quality =
          'กำลังตรวจ...';

      noDataAreas.remove(area);
    });

    await cam.startImageStream(
      (image) {
        if (!scanning) {
          return;
        }

        frameCount++;

        if (frameCount % 10 ==
            0) {
          checkQuality(image);
        }
      },
    );
  }

  Future<void> saveCurrentArea() async {
    await stopStream();

    if (galleryImage == null &&
        frameCount == 0 &&
        quality ==
            'ยังไม่ได้ตรวจ') {
      return;
    }

    final result =
        ScanResult(
      area: area,
      brightness: brightness,
      sharpness: sharpness,
      quality: quality,
      details:
          quality.contains(
                    'ใช้ได้',
                  ) ||
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
  }

  Future<void> markNoData() async {
    await stopStream();

    results.removeWhere(
      (x) => x.area == area,
    );

    galleryImage = null;

    noDataAreas.add(area);

    goNextArea();
  }

  Future<void> nextArea() async {
    final hasData =
        galleryImage != null ||
            frameCount > 0 ||
            quality !=
                'ยังไม่ได้ตรวจ';

    if (hasData) {
      await saveCurrentArea();
      goNextArea();
    } else {
      showNoDataDialog();
    }
  }

  Future<void> showNoDataDialog() async {
    await showDialog(
      context: context,
      builder: (c) =>
          AlertDialog(
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
            onPressed: () =>
                Navigator.pop(c),
            child:
                const Text(
              'กลับไปสแกน',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              markNoData();
            },
            child: const Text(
              'ไม่มีข้อมูล / ข้ามด้านนี้',
            ),
          ),
        ],
      ),
    );
  }

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

  Future<void> saveReference() async {
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

    final now =
        DateTime.now();

    final referenceNumber =
        await ReferenceStorage
            .nextReferenceNumber();

    await ReferenceStorage.save(
      ReferenceData(
        id: now.microsecondsSinceEpoch
            .toString(),

        referenceNumber:
            referenceNumber,

        createdAt: now,

        name: widget.name,
        model: widget.model,
        pim: widget.pim,
        type: widget.type,
        temple: widget.temple,

        scans:
            List.from(results),

        noDataAreas:
            noDataAreas.toList(),
      ),
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          'บันทึกองค์อ้างอิง '
          '$referenceNumber เรียบร้อยแล้ว',
        ),
      ),
    );
  }

  void showSummary() {
    showDialog(
      context: context,
      builder: (c) =>
          AlertDialog(
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
                'ชื่อพระ: ${widget.name}\n'
                'รุ่น: ${widget.model.isEmpty ? "-" : widget.model}\n'
                'พิมพ์: ${widget.pim.isEmpty ? "-" : widget.pim}\n'
                'ประเภท: ${widget.type}\n'
                'วัด: ${widget.temple.isEmpty ? "-" : widget.temple}',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                'มีข้อมูล ${results.length} ด้าน\n'
                'ไม่มีข้อมูล ${noDataAreas.length} ด้าน',
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 12,
              ),

              for (final a in areas)
                summaryArea(a),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(c),
            child:
                const Text('ปิด'),
          ),
          ElevatedButton(
            onPressed:
                saveReference,
            child:
                const Text(
              'บันทึกองค์อ้างอิง',
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryArea(
    String a,
  ) {
    ScanResult? result;

    for (final x
        in results) {
      if (x.area == a) {
        result = x;
        break;
      }
    }

    if (result != null) {
      return ListTile(
        dense: true,
        leading:
            const Icon(
          Icons.check_circle,
        ),
        title: Text(a),
        subtitle: Text(
          '${result!.fromGallery ? "รูปจากแกลเลอรี่" : "กล้อง"}\n'
          '${result!.quality}\n'
          '${result!.details}',
        ),
      );
    }

    if (noDataAreas
        .contains(a)) {
      return ListTile(
        dense: true,
        leading:
            const Icon(
          Icons.remove_circle_outline,
        ),
        title: Text(a),
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
        Icons.help_outline,
      ),
      title: Text(a),
      subtitle:
          const Text(
        'ยังไม่ได้ระบุข้อมูล',
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

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
                            fontSize: 12,
                            fontWeight:
                                i == areaIndex
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                          textAlign:
                              TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              fit:
                  StackFit.expand,
              children: [
                galleryImage ==
                        null
                    ? CameraPreview(
                        controller!,
                      )
                    : Image.file(
                        File(
                          galleryImage!
                              .path,
                        ),
                        fit:
                            BoxFit.contain,
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
                        child: Text(
                          'จัดพระให้อยู่ในกรอบ\n$area',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                18,
                            fontWeight:
                                FontWeight.bold,
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
                            .all(
                      10,
                    ),
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
                                  'ความสว่าง: ${brightness.toStringAsFixed(0)}\n'
                                  'ความคม: ${sharpness.toStringAsFixed(1)}\n'
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
                          TextAlign
                              .center,
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                          ElevatedButton.icon(
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
                          ElevatedButton.icon(
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
                            scanning
                                ? stopStream
                                : startScan,
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child:
                          ElevatedButton.icon(
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
                      OutlinedButton.icon(
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
