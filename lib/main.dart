import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
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

  const App(this.cameras, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'กล้องสแกนพระและเหรียญ',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.brown,
      ),
      home: HomePage(cameras: cameras),
    );
  }
}

// =====================================================
// CONSTANTS
// =====================================================

const List<String> areas = [
  'ด้านหน้า',
  'ด้านหลัง',
  'ด้านข้าง',
  'ก้นพระ',
];

const List<String> types = [
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
    required this.quality,
    required this.details,
    required this.brightness,
    required this.sharpness,
    required this.fromGallery,
  });

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'quality': quality,
      'details': details,
      'brightness': brightness,
      'sharpness': sharpness,
      'fromGallery': fromGallery,
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      area: map['area']?.toString() ?? '',
      quality: map['quality']?.toString() ?? '',
      details: map['details']?.toString() ?? '',
      brightness: (map['brightness'] as num?)?.toDouble() ?? 0,
      sharpness: (map['sharpness'] as num?)?.toDouble() ?? 0,
      fromGallery: map['fromGallery'] == true,
    );
  }
}

// =====================================================
// REFERENCE DATA
// =====================================================

class ReferenceData {
  final String id;
  final String createdAt;

  String name;
  String model;
  String pim;
  String type;
  String temple;

  List<ScanResult> scans;

  ReferenceData({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.model,
    required this.pim,
    required this.type,
    required this.temple,
    required this.scans,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt,
      'name': name,
      'model': model,
      'pim': pim,
      'type': type,
      'temple': temple,
      'scans': scans.map((e) => e.toMap()).toList(),
    };
  }

  factory ReferenceData.fromMap(Map<String, dynamic> map) {
    final rawScans = map['scans'];

    final List<ScanResult> scanList = [];

    if (rawScans is List) {
      for (final scan in rawScans) {
        if (scan is Map) {
          try {
            scanList.add(
              ScanResult.fromMap(
                Map<String, dynamic>.from(scan),
              ),
            );
          } catch (_) {
            // ข้ามข้อมูลสแกนที่เสีย
          }
        }
      }
    }

    return ReferenceData(
      id: map['id']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      model: map['model']?.toString() ?? '',
      pim: map['pim']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      temple: map['temple']?.toString() ?? '',
      scans: scanList,
    );
  }
}

// =====================================================
// STORAGE
// =====================================================

class ReferenceStorage {
  static const String dataKey = 'reference_data';

  // ===================================================
  // LOAD
  // ===================================================

  static Future<List<ReferenceData>> load() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final raw = prefs.getString(dataKey);

      if (raw == null || raw.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      final List<ReferenceData> result = [];

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        try {
          final reference =
              ReferenceData.fromMap(
            Map<String, dynamic>.from(item),
          );

          result.add(reference);
        } catch (_) {
          // ข้ามข้อมูลรายการที่อ่านไม่ได้
        }
      }

      return result;
    } catch (_) {
      return [];
    }
  }

  // ===================================================
  // SAVE
  // ===================================================

  static Future<void> save(
    List<ReferenceData> data,
  ) async {
    await _write(data);
  }

  static Future<void> _write(
    List<ReferenceData> data,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final raw = jsonEncode(
      data.map((e) => e.toMap()).toList(),
    );

    await prefs.setString(
      dataKey,
      raw,
    );
  }

  // ===================================================
  // UPDATE REFERENCE
  // ===================================================

  static Future<void> updateReference(
    ReferenceData reference,
  ) async {
    final list = await load();

    final index = list.indexWhere(
      (e) => e.id == reference.id,
    );

    if (index >= 0) {
      list[index] = reference;
    } else {
      list.add(reference);
    }

    await _write(list);
  }

  // ===================================================
  // UPDATE REFERENCE INFO
  // ===================================================

  static Future<void> updateReferenceInfo({
    required String id,
    required String name,
    required String model,
    required String pim,
    required String type,
    required String temple,
  }) async {
    final list = await load();

    final index = list.indexWhere(
      (e) => e.id == id,
    );

    if (index < 0) return;

    list[index].name = name;
    list[index].model = model;
    list[index].pim = pim;
    list[index].type = type;
    list[index].temple = temple;

    await _write(list);
  }

  // ===================================================
  // DELETE ONE REFERENCE
  // ===================================================

  static Future<void> deleteReference(
    String id,
  ) async {
    final list = await load();

    list.removeWhere(
      (e) => e.id == id,
    );

    await _write(list);
  }

  // ===================================================
  // DELETE GROUP
  // ===================================================

  static Future<void> deleteGroup({
    required String name,
    required String model,
    required String pim,
    required String type,
    required String temple,
  }) async {
    final list = await load();

    list.removeWhere(
      (e) =>
          e.name == name &&
          e.model == model &&
          e.pim == pim &&
          e.type == type &&
          e.temple == temple,
    );

    await _write(list);
  }

  // ===================================================
  // BACKUP
  // ===================================================

  static Future<String> createBackupJson() async {
    final data = await load();

    final backup = {
      'databaseVersion': 1,
      'appName': 'กล้องสแกนพระและเหรียญ',
      'exportedAt':
          DateTime.now().toIso8601String(),
      'references':
          data.map((e) => e.toMap()).toList(),
    };

    return const JsonEncoder.withIndent(
      '  ',
    ).convert(backup);
  }

  // ===================================================
  // DECODE BACKUP
  // ===================================================

  static Future<List<ReferenceData>> decodeBackup(
    String jsonText,
  ) async {
    final decoded = jsonDecode(jsonText);

    if (decoded is! Map) {
      throw Exception(
        'รูปแบบไฟล์ไม่ถูกต้อง',
      );
    }

    final version =
        decoded['databaseVersion'];

    if (version != 1) {
      throw Exception(
        'ไม่รองรับฐานข้อมูลเวอร์ชันนี้',
      );
    }

    final rawReferences =
        decoded['references'];

    if (rawReferences is! List) {
      throw Exception(
        'ไม่พบข้อมูลอ้างอิงในไฟล์',
      );
    }

    final List<ReferenceData> result = [];

    for (final item in rawReferences) {
      if (item is! Map) {
        continue;
      }

      try {
        result.add(
          ReferenceData.fromMap(
            Map<String, dynamic>.from(item),
          ),
        );
      } catch (_) {
        // ข้ามรายการที่เสีย
      }
    }

    return result;
  }

  // ===================================================
  // REPLACE ALL DATA
  // ===================================================

  static Future<void> replaceAll(
    List<ReferenceData> data,
  ) async {
    await _write(data);
  }

  // ===================================================
  // DELETE ALL DATA
  // ===================================================

  static Future<void> deleteAll() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(dataKey);
  }
}

// =====================================================
// HOME PAGE
// =====================================================

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage({
    super.key,
    required this.cameras,
  });

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  int savedCount = 0;

  @override
  void initState() {
    super.initState();
    loadCount();
  }

  Future<void> loadCount() async {
    final data =
        await ReferenceStorage.load();

    final Set<String> uniqueGroups = {};

    for (final item in data) {
      final key = [
        item.name.trim(),
        item.model.trim(),
        item.pim.trim(),
        item.type.trim(),
        item.temple.trim(),
      ].join('|||');

      uniqueGroups.add(key);
    }

    if (!mounted) return;

    setState(() {
      savedCount =
          uniqueGroups.length;
    });
  }

  Future<void> createData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateReferencePage(
          cameras: widget.cameras,
        ),
      ),
    );

    await loadCount();
  }

  Future<void> openSavedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SavedDataPage(
          cameras: widget.cameras,
        ),
      ),
    );

    await loadCount();
  }

  Future<void> openBackupData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BackupDataPage(
          cameras: widget.cameras,
        ),
      ),
    );

    await loadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'กล้องสแกนพระและเหรียญ',
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: loadCount,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),

            _menuCard(
              icon:
                  Icons.add_circle_outline,
              title:
                  'สร้าง / บันทึกข้อมูล',
              subtitle:
                  'สร้างข้อมูลพระหรือเหรียญองค์อ้างอิงใหม่',
              onTap: createData,
            ),

            const SizedBox(height: 12),

            _menuCard(
              icon: Icons.folder_open,
              title:
                  'รายการข้อมูลที่บันทึก',
              subtitle:
                  'ข้อมูลหลักทั้งหมด $savedCount รายการ',
              onTap: openSavedData,
            ),

            const SizedBox(height: 12),

            _menuCard(
              icon:
                  Icons.import_export,
              title:
                  'สำรอง / นำเข้าข้อมูล',
              subtitle:
                  'สำรอง นำเข้า และจัดการฐานข้อมูล',
              onTap: openBackupData,
            ),

            const SizedBox(height: 12),

            _menuCard(
              icon: Icons.settings,
              title: 'ตั้งค่า',
              subtitle:
                  'ตั้งค่าการทำงานของแอป',
              onTap: () {
                _message(
                  'ระบบตั้งค่าจะเพิ่มในขั้นตอนถัดไป',
                );
              },
            ),

            const SizedBox(height: 24),

            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สถานะข้อมูลอ้างอิง',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ข้อมูลแต่ละองค์สามารถเพิ่มข้อมูลการสแกนได้หลายครั้ง '
                      'และสามารถเพิ่มองค์อ้างอิงต่อไปได้เรื่อย ๆ',
                    ),
                    SizedBox(height: 6),
                    Text(
                      'ครบ 5 องค์เป็นเพียงตัวช่วยดูสถานะ ไม่ใช่จำนวนสูงสุด',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 25,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 4,
          ),
          child: Text(subtitle),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }
}

// =====================================================
// BACKUP / IMPORT DATA PAGE
// =====================================================

class BackupDataPage
    extends StatefulWidget {
  final List<CameraDescription> cameras;

  const BackupDataPage({
    super.key,
    required this.cameras,
  });

  @override
  State<BackupDataPage> createState() =>
      _BackupDataPageState();
}

class _BackupDataPageState
    extends State<BackupDataPage> {
  bool working = false;

  // ===================================================
  // BACKUP
  // ===================================================

  Future<void> backupData() async {
    if (working) return;

    setState(() {
      working = true;
    });

    try {
      final jsonText =
          await ReferenceStorage
              .createBackupJson();

      final bytes =
          utf8.encode(jsonText);

      final fileName =
          'amulet_scanner_backup_'
          '${DateTime.now().year}_'
          '${DateTime.now().month.toString().padLeft(2, '0')}_'
          '${DateTime.now().day.toString().padLeft(2, '0')}.json';

      final path =
          await FilePicker.platform
              .saveFile(
        dialogTitle:
            'บันทึกไฟล์สำรองข้อมูล',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [
          'json',
        ],
        bytes: bytes,
      );

      if (!mounted) return;

      if (path == null) {
        msg(
          'ยกเลิกการสำรองข้อมูล',
        );
      } else {
        msg(
          'สำรองข้อมูลเรียบร้อยแล้ว',
        );
      }
    } catch (_) {
      if (mounted) {
        msg(
          'สำรองข้อมูลไม่สำเร็จ',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          working = false;
        });
      }
    }
  }

  // ===================================================
  // IMPORT
  // ===================================================

  Future<void> importData() async {
    if (working) return;

    final result =
        await FilePicker.platform
            .pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'json',
      ],
      withData: true,
    );

    if (result == null ||
        result.files.isEmpty) {
      return;
    }

    final file =
        result.files.first;

    if (file.bytes == null) {
      msg(
        'ไม่สามารถอ่านไฟล์ได้',
      );
      return;
    }

    List<ReferenceData> imported;

    try {
      final jsonText =
          utf8.decode(file.bytes!);

      imported =
          await ReferenceStorage
              .decodeBackup(
        jsonText,
      );
    } catch (_) {
      if (mounted) {
        msg(
          'ไฟล์ไม่ใช่ฐานข้อมูลของแอป '
          'หรือไฟล์เสียหาย
