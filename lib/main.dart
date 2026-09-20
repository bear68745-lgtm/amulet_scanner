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

    // อ่านแบบบีบอัด
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
    } catch (_) {}

    // อ่านข้อมูลเก่า JSON ธรรมดา
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
            scans: const [],
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
  // ---------------------------------------------------

  static Future<int>
      nextReferenceNumber() async {
    final p =
        await SharedPreferences.getInstance();

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
        await SharedPreferences.getInstance();

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
  // แก้ไขข้อมูลดิบทั้งกลุ่ม
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

            for (final group in groups)
              buildGroupCard(group),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // การ์ดชื่อพระ
  // ===================================================

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
                        Icons.auto_awesome,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Text(
                            first.name.isEmpty
                                ? 'ไม่ระบุชื่อพระ'
                                : first.name,
                            style:
                                const TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          if (first.model.isNotEmpty)
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
                      Icons.arrow_forward_ios,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            const Divider(),

            Row(
              children: [

                Expanded(
                  child:
                      OutlinedButton.icon(
                    icon: const Icon(
                      Icons.edit,
                    ),
                    label: const Text(
                      'แก้ไข',
                    ),
                    onPressed: () =>
                        editGroup(group),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      OutlinedButton.icon(
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                    label: const Text(
                      'ลบข้อมูลสแกน',
                    ),
                    onPressed: () =>
                        deleteGroup(group),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// ขั้นที่ 2
// รายการองค์อ้างอิง
// =====================================================

class ReferenceListPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String name;
  final String model;

  const ReferenceListPage({
    super.key,
    required this.cameras,
    required this.name,
    required this.model,
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
    final all =
        await ReferenceStorage.load();

    final list = all.where(
      (item) =>
          item.name == widget.name &&
          item.model == widget.model,
    ).toList();

    list.sort(
      (a, b) =>
          a.referenceNumber.compareTo(
        b.referenceNumber,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      references = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายการองค์อ้างอิง',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadReferences,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      widget.name.isEmpty
                          ? 'ไม่ระบุชื่อพระ'
                          : widget.name,
                      style:
                          const TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    if (widget.model.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          top: 4,
                        ),
                        child: Text(
                          'รุ่น: ${widget.model}',
                          style:
                              const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      'มีองค์อ้างอิง '
                      '${references.length} องค์',
                      style:
                          const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            if (references.isEmpty)
              const Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(20),
                  child: Text(
                    'ยังไม่มีองค์อ้างอิง',
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              ),

            for (final reference
                in references)
              buildReferenceCard(
                reference,
              ),
          ],
        ),
      ),
    );
  }

  Widget buildReferenceCard(
    ReferenceData reference,
  ) {
    final scanCount =
        reference.scans.length;

    final noDataCount =
        reference.noDataAreas.length;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ReferenceDetailPage(
                reference: reference,
              ),
            ),
          );

          loadReferences();
        },
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            children: [

              CircleAvatar(
                radius: 25,
                child: Text(
                  '${reference.referenceNumber}',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      'องค์อ้างอิงที่ '
                      '${reference.referenceNumber}',
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      'ข้อมูลสแกน '
                      '$scanCount รายการ',
                    ),

                    if (noDataCount > 0)
                      Text(
                        'ไม่มีข้อมูล '
                        '$noDataCount ด้าน',
                        style:
                            const TextStyle(
                          fontSize: 13,
                        ),
                      ),

                    if (scanCount == 0 &&
                        noDataCount == 0)
                      const Text(
                        'ยังไม่มีข้อมูลสแกน',
                        style:
                            TextStyle(
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// รายละเอียดองค์อ้างอิง
// =====================================================

class ReferenceDetailPage
    extends StatelessWidget {

  final ReferenceData reference;

  const ReferenceDetailPage({
    super.key,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'องค์อ้างอิงที่ '
          '${reference.referenceNumber}',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    'องค์อ้างอิงที่ '
                    '${reference.referenceNumber}',
                    style:
                        const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  infoRow(
                    'ชื่อพระ',
                    reference.name,
                  ),

                  infoRow(
                    'รุ่น',
                    reference.model,
                  ),

                  infoRow(
                    'พิมพ์',
                    reference.pim,
                  ),

                  infoRow(
                    'ประเภท',
                    reference.type,
                  ),

                  infoRow(
                    'วัด',
                    reference.temple,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'ข้อมูลจากการสแกน',
            style:
                TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          for (final scan
              in reference.scans)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                ),
                title: Text(
                  scan.area,
                ),
                subtitle: Text(
                  '${scan.quality}\n'
                  '${scan.details}',
                ),
              ),
            ),

          if (reference.scans.isEmpty)
            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(16),
                child: Text(
                  'ยังไม่มีข้อมูลจากการสแกน',
                ),
              ),
            ),

          if (reference.noDataAreas.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),

            const Text(
              'ด้านที่ไม่มีข้อมูล',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Text(
                  reference.noDataAreas.join(
                    '\n',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget infoRow(
    String title,
    String value,
  ) {
    if (value.isEmpty) {
      return Padding(
        padding:
            const EdgeInsets.only(
          bottom: 6,
        ),
        child: Text(
          '$title: -',
        ),
      );
    }

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 6,
      ),
      child: Text(
        '$title: $value',
      ),
    );
  }
}

// =====================================================
// สร้างข้อมูลใหม่
// =====================================================

class CreateReferencePage
    extends StatefulWidget {

  final List<CameraDescription> cameras;

  const CreateReferencePage({
    super.key,
    required this.cameras,
  });

  @override
  State<CreateReferencePage> createState() =>
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

  Future<void> next() async {
    final name =
        nameController.text.trim();

    final model =
        modelController.text.trim();

    final pim =
        pimController.text.trim();

    final temple =
        templeController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณาใส่ชื่อพระ',
          ),
        ),
      );
      return;
    }

    if (selectedType == null ||
        selectedType!.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณาเลือกประเภท',
          ),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ScanPage(
          cameras:
              widget.cameras,
          name: name,
          model: model,
          pim: pim,
          type: selectedType!,
          temple: temple,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'สร้าง / เพิ่มองค์อ้างอิง',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [

          const Text(
            'ข้อมูลหลัก',
            style:
                TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller:
                nameController,
            decoration:
                const InputDecoration(
              labelText: 'ชื่อพระ',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller:
                modelController,
            decoration:
                const InputDecoration(
              labelText: 'รุ่น',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller:
                pimController,
            decoration:
                const InputDecoration(
              labelText: 'พิมพ์',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

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

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller:
                templeController,
            decoration:
                const InputDecoration(
              labelText: 'วัด',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(14),
              child: Text(
                'ระบบจะกำหนดเลของค์อ้างอิงให้อัตโนมัติเมื่อบันทึกข้อมูล\n'
                'เลของค์อ้างอิงจะไม่ถูกนำกลับมาใช้ซ้ำ แม้จะลบข้อมูลภายหลัง',
              ),
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
                Icons.camera_alt,
              ),
              label: const Text(
                'เริ่มสแกนองค์อ้างอิง',
                style:
                    TextStyle(
                  fontSize: 17,
                ),
              ),
              onPressed: next,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// แก้ไขข้อมูลดิบ
// =====================================================

class EditReferencePage
    extends StatefulWidget {

  final String oldName;
  final String oldModel;

  final String name;
  final String model;
  final String pim;
  final String type;
  final String temple;

  const EditReferencePage({
    super.key,
    required this.oldName,
    required this.oldModel,
    required this.name,
    required this.model,
    required this.pim,
    required this.type,
    required this.temple,
  });

  @override
  State<EditReferencePage> createState() =>
      _EditReferencePageState();
}

class _EditReferencePageState
    extends State<EditReferencePage> {

  late TextEditingController nameController;
  late TextEditingController modelController;
  late TextEditingController pimController;
  late TextEditingController templeController;

  late String selectedType;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(
      text: widget.name,
    );

    modelController =
        TextEditingController(
      text: widget.model,
    );

    pimController =
        TextEditingController(
      text: widget.pim,
    );

    templeController =
        TextEditingController(
      text: widget.temple,
    );

    selectedType = widget.type;
  }

  @override
  void dispose() {
    nameController.dispose();
    modelController.dispose();
    pimController.dispose();
    templeController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final name =
        nameController.text.trim();

    final model =
        modelController.text.trim();

    final pim =
        pimController.text.trim();

    final temple =
        templeController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณาใส่ชื่อพระ',
          ),
        ),
      );
      return;
    }

    if (selectedType.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณาเลือกประเภท',
          ),
        ),
      );
      return;
    }

    await ReferenceStorage.updateGroup(
      widget.oldName,
      widget.oldModel,
      newName: name,
      newModel: model,
      newPim: pim,
      newType: selectedType,
      newTemple: temple,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'แก้ไขข้อมูลดิบเรียบร้อยแล้ว',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'แก้ไขข้อมูลดิบ',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [

          TextField(
            controller:
                nameController,
            decoration:
                const InputDecoration(
              labelText: 'ชื่อพระ',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller:
                modelController,
            decoration:
                const InputDecoration(
              labelText: 'รุ่น',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller:
                pimController,
            decoration:
                const InputDecoration(
              labelText: 'พิมพ์',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          DropdownButtonFormField<String>(
            value: types.contains(
              selectedType,
            )
                ? selectedType
                : null,
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
              if (value == null) {
                return;
              }

              setState(() {
                selectedType = value;
              });
            },
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller:
                templeController,
            decoration:
                const InputDecoration(
              labelText: 'วัด',
              border:
                  OutlineInputBorder(),
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
                Icons.save,
              ),
              label:
                  const Text(
                'บันทึกการแก้ไข',
              ),
              onPressed: save,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// SCAN PAGE
// =====================================================

class ScanPage extends StatefulWidget {

  final List<CameraDescription> cameras;

  final String name;
  final String model;
  final String pim;
  final String type;
  final String temple;

  const ScanPage({
    super.key,
    required this.cameras,
    required this.name,
    required this.model,
    required this.pim,
    required this.type,
    required this.temple,
  });

  @override
  State<ScanPage> createState() =>
      _ScanPageState();
}

class _ScanPageState
    extends State<ScanPage> {

  CameraController? controller;

  bool scanning = false;
  bool busy = false;

  int currentAreaIndex = 0;

  final List<ScanResult> results = [];

  final List<String> noDataAreas = [];

  XFile? temporaryGalleryImage;

  double brightness = 0;
  double sharpness = 0;

  String quality =
      'กำลังเตรียมกล้อง';

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> initializeCamera() async {
    CameraDescription? camera;

    for (final item in widget.cameras) {
      if (item.lensDirection ==
          CameraLensDirection.back) {
        camera = item;
        break;
      }
    }

    camera ??=
        widget.cameras.isNotEmpty
            ? widget.cameras.first
            : null;

    if (camera == null) {
      setState(() {
        quality = 'ไม่พบกล้อง';
      });
      return;
    }

    final c =
        CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    controller = c;

    try {
      await c.initialize();

      if (!mounted) {
        return;
      }

      setState(() {
        quality =
            'พร้อมสแกน';
      });

      startScan();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        quality =
            'เปิดกล้องไม่ได้';
      });
    }
  }

  // ---------------------------------------------------
  // หยุด stream
  // ---------------------------------------------------

  Future<void> stopStream() async {
    if (controller == null) {
      return;
    }

    try {
      if (controller!
          .value
          .isStreamingImages) {
        await controller!
            .stopImageStream();
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        scanning = false;
      });
    }
  }

  // ---------------------------------------------------
  // เริ่มสแกน
  // ---------------------------------------------------

  Future<void> startScan() async {
    if (controller == null ||
        !controller!.value.isInitialized ||
        scanning) {
      return;
    }

    try {
      await controller!
          .startImageStream(
        (CameraImage image) {
          if (busy) {
            return;
          }

          busy = true;

          _analyzeImage(image);

          Future.delayed(
            const Duration(
              milliseconds: 500,
            ),
            () {
              busy = false;
            },
          );
        },
      );

      if (mounted) {
        setState(() {
          scanning = true;
        });
      }
    } catch (_) {}
  }

  void _analyzeImage(
    CameraImage image,
  ) {
    if (!mounted) {
      return;
    }

    if (image.planes.isEmpty) {
      return;
    }

    final bytes =
        image.planes.first.bytes;

    if (bytes.isEmpty) {
      return;
    }

    double sum = 0;

    final step =
        bytes.length > 1000
            ? bytes.length ~/ 1000
            : 1;

    int count = 0;

    for (
      int i = 0;
      i < bytes.length;
      i += step
    ) {
      sum += bytes[i];
      count++;
    }

    final avg =
        count == 0
            ? 0
            : sum / count;

    double sharp =
        0;

    if (bytes.length > 10) {
      for (
        int i = 0;
        i < bytes.length - step;
        i += step
      ) {
        sharp +=
            (bytes[i] -
                    bytes[i + step])
                .abs();

        if (sharp > 100000) {
          break;
        }
      }

      sharp =
          sharp /
              (bytes.length / step);
    }

    String q;

    if (avg >= 45 &&
        avg <= 210 &&
        sharp >= 8) {
      q = 'ภาพใช้ได้';
    } else if (avg < 45) {
      q = 'มืดเกินไป';
    } else if (avg > 210) {
      q = 'สว่างเกินไป';
    } else {
      q = 'ภาพไม่ละเอียดพอ';
    }

    setState(() {
      brightness = avg;
      sharpness = sharp;
      quality = q;
    });
  }

  // ---------------------------------------------------
  // เลือกรูปจากแกลเลอรี
  //
  // รูปถูกใช้ชั่วคราวเท่านั้น
  // ไม่บันทึกเป็นไฟล์ของแอป
  // ---------------------------------------------------

  Future<void> pickGallery() async {
    final picker =
        ImagePicker();

    final image =
        await picker.pickImage(
      source:
          ImageSource.gallery,
    );

    if (image == null) {
      return;
    }

    await stopStream();

    if (!mounted) {
      return;
    }

    setState(() {
      temporaryGalleryImage =
          image;
      quality =
          'เลือกภาพจากแกลเลอรีแล้ว';
      brightness = 100;
      sharpness = 100;
    });
  }

  // ---------------------------------------------------
  // บันทึกพื้นที่ปัจจุบัน
  // ---------------------------------------------------

  void saveCurrentArea() {
    final area =
        areas[currentAreaIndex];

    final exists =
        results.any(
      (x) => x.area == area,
    );

    if (exists) {
      results.removeWhere(
        (x) => x.area == area,
      );
    }

    results.add(
      ScanResult(
        area: area,
        brightness:
            brightness,
        sharpness:
            sharpness,
        quality:
            quality,
        details:
            'รอระบบ AI วิเคราะห์รายละเอียดทั้งหมดที่มองเห็นในองค์พระ',
        fromGallery:
            temporaryGalleryImage != null,
      ),
    );

    temporaryGalleryImage = null;
  }

  // ---------------------------------------------------
  // ระบุว่าไม่มีข้อมูลด้านนี้
  // ---------------------------------------------------

  void markNoData() {
    final area =
        areas[currentAreaIndex];

    if (!noDataAreas.contains(area)) {
      noDataAreas.add(area);
    }

    results.removeWhere(
      (x) => x.area == area,
    );

    nextArea();
  }

  // ---------------------------------------------------
  // ไปด้านถัดไป
  // ---------------------------------------------------

  Future<void> nextArea() async {
    if (currentAreaIndex <
        areas.length - 1) {

      currentAreaIndex++;

      temporaryGalleryImage = null;

      if (mounted) {
        setState(() {
          quality =
              'กำลังเตรียมสแกน ${areas[currentAreaIndex]}';
        });
      }

      await startScan();

      return;
    }

    await showSummary();
  }

  // ---------------------------------------------------
  // ปุ่มถัดไป
  // ---------------------------------------------------

  Future<void> goNextArea() async {
    final area =
        areas[currentAreaIndex];

    final hasResult =
        results.any(
      (x) => x.area == area,
    );

    final hasNoData =
        noDataAreas.contains(area);

    if (!hasResult &&
        !hasNoData) {
      final answer =
          await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) {
          return AlertDialog(
            title:
                const Text(
              'ยังไม่มีข้อมูล',
            ),
            content:
                Text(
              'ด้าน $area ยังไม่มีข้อมูล\n\n'
              'ต้องการระบุว่าไม่มีข้อมูลด้านนี้หรือไม่?',
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
                    const Text(
                  'กลับไปสแกน',
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                child:
                    const Text(
                  'ไม่มีข้อมูล',
                ),
              ),
            ],
          );
        },
      );

      if (answer == true) {
        markNoData();
      }

      return;
    }

    await stopStream();

    await nextArea();
  }

  // ---------------------------------------------------
  // สรุปก่อนบันทึก
  // ---------------------------------------------------

  Future<void> showSummary() async {
    await stopStream();

    if (!mounted) {
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible:
          false,
      builder:
          (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'สรุปข้อมูล',
          ),
          content:
              SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  'ชื่อพระ: ${widget.name}',
                ),

                Text(
                  'รุ่น: ${widget.model.isEmpty ? "-" : widget.model}',
                ),

                Text(
                  'พิมพ์: ${widget.pim.isEmpty ? "-" : widget.pim}',
                ),

                Text(
                  'ประเภท: ${widget.type}',
                ),

                Text(
                  'วัด: ${widget.temple.isEmpty ? "-" : widget.temple}',
                ),

                const SizedBox(
                  height: 12,
                ),

                const Text(
                  'พื้นที่สแกน',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                for (final area
                    in areas)
                  buildAreaSummary(
                    area,
                  ),
              ],
            ),
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
                'กลับไปตรวจสอบ',
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                await saveReference();
              },
              child:
                  const Text(
                'บันทึกองค์อ้างอิง',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildAreaSummary(
    String area,
  ) {
    final result =
        results.where(
      (x) => x.area == area,
    );

    if (result.isNotEmpty) {
      return Padding(
        padding:
            const EdgeInsets.only(
          bottom: 5,
        ),
        child: Text(
          '✓ $area : มีข้อมูล',
        ),
      );
    }

    if (noDataAreas.contains(
      area,
    )) {
      return Padding(
        padding:
            const EdgeInsets.only(
          bottom: 5,
        ),
        child: Text(
          '— $area : ไม่มีข้อมูล',
        ),
      );
    }

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 5,
      ),
      child: Text(
        '? $area : ยังไม่ได้ตรวจสอบ',
      ),
    );
  }

  // ---------------------------------------------------
  // บันทึกองค์อ้างอิง
  // ---------------------------------------------------

  Future<void> saveReference() async {
    if (results.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'ต้องมีข้อมูลจากการสแกนอย่างน้อย 1 ด้าน',
          ),
        ),
      );

      return;
    }

    final number =
        await ReferenceStorage
            .nextReferenceNumber();

    final item =
        ReferenceData(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      referenceNumber:
          number,
      createdAt:
          DateTime.now(),
      name:
          widget.name,
      model:
          widget.model,
      pim:
          widget.pim,
      type:
          widget.type,
      temple:
          widget.temple,
      scans:
          List.from(results),
      noDataAreas:
          List.from(noDataAreas),
    );

    await ReferenceStorage.save(
      item,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'บันทึกองค์อ้างอิงที่ '
          '$number เรียบร้อยแล้ว',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady =
        controller != null &&
            controller!
                .value
                .isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'สแกน ${areas[currentAreaIndex]}',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(12),
        children: [

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    widget.name,
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  if (widget.model.isNotEmpty)
                    Text(
                      'รุ่น: ${widget.model}',
                    ),

                  Text(
                    'กำลังเก็บข้อมูลด้าน: '
                    '${areas[currentAreaIndex]}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          if (cameraReady)
            AspectRatio(
              aspectRatio:
                  controller!
                      .value
                      .aspectRatio,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                child:
                    CameraPreview(
                  controller!,
                ),
              ),
            )
          else
            Container(
              height: 300,
              alignment:
                  Alignment.center,
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                color:
                    Colors.black12,
              ),
              child:
                  const CircularProgressIndicator(),
            ),

          const SizedBox(
            height: 12,
          ),

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(12),
              child: Column(
                children: [

                  Text(
                    quality,
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    'ความสว่าง: '
                    '${brightness.toStringAsFixed(1)}',
                  ),

                  Text(
                    'ความคม: '
                    '${sharpness.toStringAsFixed(1)}',
                  ),
                ],
              ),
            ),
          ),

          if (temporaryGalleryImage != null)
            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(12),
                child: Text(
                  'มีภาพจากแกลเลอรีสำหรับตรวจสอบชั่วคราว\n'
                  'ระบบจะไม่บันทึกไฟล์ภาพนี้เป็นฐานข้อมูล',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [

              Expanded(
                child:
                    OutlinedButton.icon(
                  icon:
                      const Icon(
                    Icons.photo_library,
                  ),
                  label:
                      const Text(
                    'แกลเลอรี',
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
                    OutlinedButton.icon(
                  icon:
                      const Icon(
                    Icons.refresh,
                  ),
                  label:
                      const Text(
                    'สแกนใหม่',
                  ),
                  onPressed:
                      startScan,
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
                ElevatedButton.icon(
              icon:
                  const Icon(
                Icons.check,
              ),
              label:
                  const Text(
                'ใช้ข้อมูลด้านนี้',
              ),
              onPressed:
                  saveCurrentArea,
            ),
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
                Icons.remove_circle_outline,
              ),
              label:
                  Text(
                'ด้านนี้ไม่มีข้อมูล',
              ),
              onPressed:
                  markNoData,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          SizedBox(
            width:
                double.infinity,
            child:
                ElevatedButton.icon(
              icon:
                  const Icon(
                Icons.arrow_forward,
              ),
              label:
                  Text(
                currentAreaIndex ==
                        areas.length - 1
                    ? 'ดูสรุปข้อมูล'
                    : 'ไปด้านถัดไป',
              ),
              onPressed:
                  goNextArea,
            ),
          ),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
