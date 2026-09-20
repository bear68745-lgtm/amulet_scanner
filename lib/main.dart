import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  const App(
    this.cameras, {
    super.key,
  });

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
// พื้นที่สแกน
// =====================================================

const areas = [
  'ด้านหน้า',
  'ด้านหลัง',
  'ด้านข้าง',
  'ก้นพระ',
];

// =====================================================
// ประเภทพระ / วัตถุ
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

  factory ScanResult.fromMap(
    Map<String, dynamic> m,
  ) {
    return ScanResult(
      area: m['area'] ?? '',
      brightness:
          (m['brightness'] ?? 0).toDouble(),
      sharpness:
          (m['sharpness'] ?? 0).toDouble(),
      quality: m['quality'] ?? '',
      details: m['details'] ?? '',
      fromGallery:
          m['fromGallery'] ?? false,
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

  // ข้อมูลหลัก
  final String name;
  final String model;
  final String pim;
  final String type;
  final String temple;

  // ข้อมูลจากการสแกน
  final List<ScanResult> scans;

  // ด้านที่ระบุว่าไม่มีข้อมูล
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
        'createdAt':
            createdAt.toIso8601String(),
        'name': name,
        'model': model,
        'pim': pim,
        'type': type,
        'temple': temple,
        'scans':
            scans.map((x) => x.toMap()).toList(),
        'noDataAreas': noDataAreas,
      };

  factory ReferenceData.fromMap(
    Map<String, dynamic> m,
  ) {
    return ReferenceData(
      id: m['id'] ?? '',
      referenceNumber:
          (m['referenceNumber'] ?? 0).toInt(),
      createdAt:
          DateTime.tryParse(
                m['createdAt'] ?? '',
              ) ??
              DateTime.now(),
      name: m['name'] ?? '',
      model: m['model'] ?? '',
      pim: m['pim'] ?? '',
      type: m['type'] ?? '',
      temple: m['temple'] ?? '',
      scans:
          (m['scans'] as List? ?? [])
              .map(
                (x) =>
                    ScanResult.fromMap(
                  Map<String, dynamic>.from(x),
                ),
              )
              .toList(),
      noDataAreas:
          List<String>.from(
        m['noDataAreas'] ?? [],
      ),
    );
  }
}

// =====================================================
// STORAGE
// =====================================================
//
// เก็บข้อมูลแบบ:
//
// JSON
//   ↓
// UTF8
//   ↓
// GZip
//   ↓
// Base64
//   ↓
// SharedPreferences
//
// รองรับข้อมูลเก่าที่เป็น JSON ธรรมดา
// =====================================================

class ReferenceStorage {
  static const key = 'reference_data';

  // ---------------------------------------------------
  // LOAD
  // ---------------------------------------------------

  static Future<List<ReferenceData>> load() async {
    final p =
        await SharedPreferences.getInstance();

    final raw = p.getString(key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    // -----------------------------------------------
    // ลองอ่านแบบบีบอัดก่อน
    // -----------------------------------------------

    try {
      final compressed =
          base64Decode(raw);

      final jsonBytes =
          gzip.decode(compressed);

      final jsonText =
          utf8.decode(jsonBytes);

      final data =
          jsonDecode(jsonText);

      if (data is List) {
        return data
            .map(
              (x) =>
                  ReferenceData.fromMap(
                Map<String, dynamic>.from(x),
              ),
            )
            .toList();
      }
    } catch (_) {
      // ไม่ใช่ข้อมูลบีบอัด
      // ไปอ่านแบบเก่า
    }

    // -----------------------------------------------
    // รองรับข้อมูลเก่า JSON ธรรมดา
    // -----------------------------------------------

    try {
      final data =
          jsonDecode(raw);

      if (data is List) {
        final list = data
            .map(
              (x) =>
                  ReferenceData.fromMap(
                Map<String, dynamic>.from(x),
              ),
            )
            .toList();

        // หลังอ่านข้อมูลเก่าได้
        // เขียนกลับเป็นแบบบีบอัด
        await _write(list);

        return list;
      }
    } catch (_) {
      return [];
    }

    return [];
  }

  // ---------------------------------------------------
  // SAVE
  // ---------------------------------------------------

  static Future<void> save(
    ReferenceData item,
  ) async {
    final list =
        await load();

    list.add(item);

    await _write(list);
  }

  // ---------------------------------------------------
  // UPDATE องค์เดียว
  // ---------------------------------------------------

  static Future<void> update(
    ReferenceData updated,
  ) async {
    final list =
        await load();

    final index =
        list.indexWhere(
      (x) => x.id == updated.id,
    );

    if (index == -1) {
      return;
    }

    list[index] = updated;

    await _write(list);
  }

  // ---------------------------------------------------
  // UPDATE ข้อมูลหลักทั้งกลุ่ม
  //
  // ใช้เมื่อกด "แก้ไข" ที่ชื่อพระ
  //
  // แก้:
  // ชื่อพระ
  // รุ่น
  // พิมพ์
  // ประเภท
  // วัด
  //
  // แต่ไม่แตะ:
  // scans
  // noDataAreas
  // referenceNumber
  // id
  // createdAt
  // ---------------------------------------------------

  static Future<void> updateGroup(
    String oldName,
    String oldModel, {
    required String newName,
    required String newModel,
    required String newPim,
    required String newType,
    required String newTemple,
  }) async {
    final list =
        await load();

    final updated =
        list.map(
      (item) {
        if (item.name == oldName &&
            item.model == oldModel) {
          return ReferenceData(
            id: item.id,
            referenceNumber:
                item.referenceNumber,
            createdAt:
                item.createdAt,
            name: newName,
            model: newModel,
            pim: newPim,
            type: newType,
            temple: newTemple,
            scans: item.scans,
            noDataAreas:
                item.noDataAreas,
          );
        }

        return item;
      },
    ).toList();

    await _write(updated);
  }

  // ---------------------------------------------------
  // ลบเฉพาะข้อมูลจากการสแกนทั้งกลุ่ม
  //
  // ไม่ลบชื่อ
  // ไม่ลบรุ่น
  // ไม่ลบพิมพ์
  // ไม่ลบประเภท
  // ไม่ลบวัด
  // ไม่ลบเลของค์อ้างอิง
  // ไม่ลบ ID
  // ---------------------------------------------------

  static Future<void> deleteScans(
    String name,
    String model,
  ) async {
    final list =
        await load();

    final updated =
        list.map(
      (item) {
        if (item.name == name &&
            item.model == model) {
          return ReferenceData(
            id: item.id,
            referenceNumber:
                item.referenceNumber,
            createdAt:
                item.createdAt,
            name: item.name,
            model: item.model,
            pim: item.pim,
            type: item.type,
            temple: item.temple,

            // ลบเฉพาะข้อมูลสแกน
            scans: const [],

            // ล้างรายการด้านที่เคยระบุ
            noDataAreas: const [],
          );
        }

        return item;
      },
    ).toList();

    await _write(updated);
  }

  // ---------------------------------------------------
  // ลบองค์เดียว
  //
  // เก็บไว้สำหรับใช้งานภายหลัง
  // หน้าแรกจะไม่ใช้ฟังก์ชันนี้
  // ---------------------------------------------------

  static Future<void> delete(
    String id,
  ) async {
    final list =
        await load();

    list.removeWhere(
      (x) => x.id == id,
    );

    await _write(list);
  }

  // ---------------------------------------------------
  // เลของค์อ้างอิงใหม่
  //
  // เลขไม่ย้อนกลับ
  // ---------------------------------------------------

  static Future<int>
      nextReferenceNumber() async {
    final p =
        await SharedPreferences
            .getInstance();

    final last =
        p.getInt(
              'last_reference_number',
            ) ??
            0;

    final next =
        last + 1;

    await p.setInt(
      'last_reference_number',
      next,
    );

    return next;
  }

  // ---------------------------------------------------
  // WRITE แบบบีบอัด
  // ---------------------------------------------------

  static Future<void> _write(
    List<ReferenceData> list,
  ) async {
    final p =
        await SharedPreferences
            .getInstance();

    final jsonText =
        jsonEncode(
      list
          .map(
            (x) => x.toMap(),
          )
          .toList(),
    );

    final jsonBytes =
        utf8.encode(jsonText);

    final compressed =
        gzip.encode(jsonBytes);

    final encoded =
        base64Encode(compressed);

    await p.setString(
      key,
      encoded,
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

class _HomePageState
    extends State<HomePage> {
  List<ReferenceData> allData = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data =
        await ReferenceStorage.load();

    if (!mounted) {
      return;
    }

    setState(() {
      allData = data;
    });
  }

  // ---------------------------------------------------
  // รวมข้อมูลเป็นกลุ่ม
  //
  // ชื่อพระ + รุ่น
  // ---------------------------------------------------

  List<List<ReferenceData>>
      getGroups() {
    final groups =
        <String, List<ReferenceData>>{};

    for (final item in allData) {
      final key =
          '${item.name}|||${item.model}';

      groups.putIfAbsent(
        key,
        () => [],
      );

      groups[key]!.add(item);
    }

    return groups.values.toList();
  }

  // ---------------------------------------------------
  // เปิดหน้า
  // ---------------------------------------------------

  Future<void> open(
    Widget page,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );

    loadData();
  }

  // ---------------------------------------------------
  // แก้ไขชื่อพระ
  // ---------------------------------------------------

  Future<void> editGroup(
    List<ReferenceData> group,
  ) async {
    if (group.isEmpty) {
      return;
    }

    final first = group.first;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditReferencePage(
          oldName: first.name,
          oldModel: first.model,
          name: first.name,
          model: first.model,
          pim: first.pim,
          type: first.type,
          temple: first.temple,
        ),
      ),
    );

    loadData();
  }

  // ---------------------------------------------------
  // ลบข้อมูลสแกนของชื่อพระ
  // ---------------------------------------------------

  Future<void> deleteGroup(
    List<ReferenceData> group,
  ) async {
    if (group.isEmpty) {
      return;
    }

    final first = group.first;

    final ok =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'ลบข้อมูลการสแกน',
          ),
          content: Text(
            'ชื่อพระ\n'
            '${first.name}\n\n'
            'จะลบเฉพาะข้อมูลที่ได้จากการสแกน '
            'ขององค์อ้างอิงในชื่อนี้\n\n'
            'ชื่อพระและเลของค์อ้างอิงจะยังคงอยู่ '
            'เพื่อให้สามารถสแกนใหม่ได้',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text('ลบข้อมูลสแกน'),
            ),
          ],
        );
      },
    );

    if (ok != true) {
      return;
    }

    await ReferenceStorage.deleteScans(
      first.name,
      first.model,
    );

    await loadData();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'ลบข้อมูลจากการสแกนแล้ว '
          'ชื่อพระและเลของค์อ้างอิงยังอยู่',
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // BUILD
  // ---------------------------------------------------

  @override
  Widget build(BuildContext c) {
    final groups = getGroups();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'กล้องสแกนพระและเหรียญ',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            const SizedBox(
              height: 10,
            ),

            const Text(
              'ฐานข้อมูลส่วนตัว',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'มีชื่อพระ ${groups.length} รายการ',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 17,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton.icon(
                icon: const Icon(
                  Icons.add_circle,
                ),
                label: const Text(
                  'สร้าง / เพิ่มองค์อ้างอิง',
                  style:
                      TextStyle(
                    fontSize: 16,
                  ),
                ),
                onPressed: () => open(
                  CreateReferencePage(
                    cameras:
                        widget.cameras,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            if (groups.isEmpty)
              const Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.storage,
                        size: 50,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        'ยังไม่มีข้อมูลพระ',
                        style:
                            TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(
                        height: 6,
                      ),
                      Text(
                        'กดสร้าง / เพิ่มองค์อ้างอิง '
                        'เพื่อเริ่มสร้างฐานข้อมูล',
                        textAlign:
                            TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            // -----------------------------------------
            // รายชื่อพระ
            // -----------------------------------------

            for (final group in groups)
              buildGroupCard(group),
          ],
        ),
      ),
    );
  }

  Widget buildGroupCard(
    List<ReferenceData> group,
  ) {
    final first = group.first;

    final scanCount =
        group.fold<int>(
      0,
      (sum, item) =>
          sum + item.scans.length,
    );

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => open(
                ReferenceListPage(
                  cameras:
                      widget.cameras,
                  name:
                      first.name,
                  model:
                      first.model,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 4,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      child: Icon(
                        Icons
                            .auto_awesome,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            first.name
                                    .isEmpty
                                ? 'ไม่ระบุชื่อพระ'
                                : first.name,
                            style:
                                const TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          if (first
                              .model
                              .isNotEmpty)
                            Text(
                              'รุ่น: ${first.model}',
                              style:
                                  const TextStyle(
                                fontSize: 15,
                              ),
                            ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            'มีองค์อ้างอิง '
                            '${group.length} องค์',
                            style:
                                const TextStyle(
                              fontSize: 15,
                            ),
                          ),

                          Text(
                            'ข้อมูลสแกน '
                            '$scanCount รายการ',
                            style:
                                const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons
                          .arrow_forward_ios,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
