import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(
    AmuletScannerApp(cameras: cameras),
  );
}

class AmuletScannerApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const AmuletScannerApp({
    super.key,
    required this.cameras,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'กล้องสแกนพระและเหรียญ',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: HomePage(cameras: cameras),
    );
  }
}

// =====================================================
// โครงสร้างข้อมูลพระ / เหรียญ
// =====================================================

class AmuletData {
  int id;
  int realItemNumber;

  String name;
  String model;
  String type;
  String temple;
  String province;
  String year;
  String material;
  String size;

  String frontDetail;
  String sideDetail;
  String backDetail;

  List<ScanData> scans;

  AmuletData({
    required this.id,
    required this.realItemNumber,
    this.name = '',
    this.model = '',
    this.type = '',
    this.temple = '',
    this.province = '',
    this.year = '',
    this.material = '',
    this.size = '',
    this.frontDetail = '',
    this.sideDetail = '',
    this.backDetail = '',
    List<ScanData>? scans,
  }) : scans = scans ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'realItemNumber': realItemNumber,
      'name': name,
      'model': model,
      'type': type,
      'temple': temple,
      'province': province,
      'year': year,
      'material': material,
      'size': size,
      'frontDetail': frontDetail,
      'sideDetail': sideDetail,
      'backDetail': backDetail,
      'scans': scans.map((scan) => scan.toMap()).toList(),
    };
  }

  factory AmuletData.fromMap(Map<String, dynamic> map) {
    return AmuletData(
      id: map['id'] ?? 0,
      realItemNumber: map['realItemNumber'] ?? 0,
      name: map['name'] ?? '',
      model: map['model'] ?? '',
      type: map['type'] ?? '',
      temple: map['temple'] ?? '',
      province: map['province'] ?? '',
      year: map['year'] ?? '',
      material: map['material'] ?? '',
      size: map['size'] ?? '',
      frontDetail: map['frontDetail'] ?? '',
      sideDetail: map['sideDetail'] ?? '',
      backDetail: map['backDetail'] ?? '',
      scans: (map['scans'] as List? ?? [])
          .map(
            (scan) => ScanData.fromMap(
              Map<String, dynamic>.from(scan),
            ),
          )
          .toList(),
    );
  }
}

// =====================================================
// ข้อมูลการสแกน
// =====================================================

class ScanData {
  String area;
  int scanNumber;
  String method;
  Map<String, dynamic> details;

  ScanData({
    required this.area,
    required this.scanNumber,
    required this.method,
    Map<String, dynamic>? details,
  }) : details = details ?? {};

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'scanNumber': scanNumber,
      'method': method,
      'details': details,
    };
  }

  factory ScanData.fromMap(Map<String, dynamic> map) {
    return ScanData(
      area: map['area'] ?? '',
      scanNumber: map['scanNumber'] ?? 0,
      method: map['method'] ?? '',
      details: Map<String, dynamic>.from(
        map['details'] ?? {},
      ),
    );
  }
}

// =====================================================
// หน้าหลัก
// =====================================================

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomePage({
    super.key,
    required this.cameras,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'กล้องสแกนพระและเหรียญ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 10),

              _mainButton(
                context,
                icon: Icons.add_circle_outline,
                title: 'สร้าง / บันทึกข้อมูล',
                subtitle: 'สร้างข้อมูลพระหรือเหรียญใหม่',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateDataPage(
                        cameras: cameras,
                      ),
                    ),
                  );
                },
              ),

              _mainButton(
                context,
                icon: Icons.list_alt,
                title: 'รายการข้อมูลที่บันทึก',
                subtitle: 'ดู แก้ไข ลบ และสแกนเพิ่มข้อมูล',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedListPage(
                        cameras: cameras,
                      ),
                    ),
                  );
                },
              ),

              _mainButton(
                context,
                icon: Icons.import_export,
                title: 'สำรอง / นำเข้าข้อมูล',
                subtitle: 'สำรองและกู้คืนฐานข้อมูล',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BackupPage(
                        cameras: cameras,
                      ),
                    ),
                  );
                },
              ),

              _mainButton(
                context,
                icon: Icons.settings,
                title: 'ตั้งค่า',
                subtitle: 'ตั้งค่าการทำงานของแอป',
                color: Colors.grey,
                
                onTap: () {
                Navigator.push(
                 context,
                MaterialPageRoute(
                 builder: (_) => SettingsPage(
                cameras: cameras,
               ),
             ),
            );
           },
         ),
        ),
       ),
      ),
    );
  }

  Widget _mainButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// หน้าสร้างข้อมูล
// =====================================================

class CreateDataPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CreateDataPage({
    super.key,
    required this.cameras,
  });

  @override
  State<CreateDataPage> createState() => _CreateDataPageState();
}

class _CreateDataPageState extends State<CreateDataPage> {
  final nameController = TextEditingController();
  final modelController = TextEditingController();
  final typeController = TextEditingController();
  final templeController = TextEditingController();
  final provinceController = TextEditingController();
  final yearController = TextEditingController();
  final materialController = TextEditingController();
  final sizeController = TextEditingController();
  final frontController = TextEditingController();
  final sideController = TextEditingController();
  final backController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    modelController.dispose();
    typeController.dispose();
    templeController.dispose();
    provinceController.dispose();
    yearController.dispose();
    materialController.dispose();
    sizeController.dispose();
    frontController.dispose();
    sideController.dispose();
    backController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้าง / บันทึกข้อมูล'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('ชื่อพระ / เหรียญ', nameController),
          _field('รุ่น', modelController),
          _field('พิมพ์', typeController),
          _field('วัด / สำนัก', templeController),
          _field('จังหวัด', provinceController),
          _field('ปีสร้าง', yearController),
          _field('เนื้อ', materialController),
          _field('ขนาด', sizeController),

          const SizedBox(height: 10),

          const Text(
            'รายละเอียดองค์จริง',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          _field('รายละเอียดด้านหน้า', frontController),
          _field('รายละเอียดด้านข้าง', sideController),
          _field('รายละเอียดด้านหลัง', backController),

          const SizedBox(height: 20),

          const Text(
            'การสแกน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'สามารถบันทึกข้อมูลโดยไม่สแกนได้ และกลับมาแก้ไขเพื่อสแกนเพิ่มภายหลัง',
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _saveData,
              icon: const Icon(Icons.save),
              label: const Text(
                'บันทึกข้อมูล',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    final oldData = prefs.getStringList('amulet_data') ?? [];

    final List<AmuletData> items = oldData.map((item) {
      return AmuletData.fromMap(
        jsonDecode(item),
      );
    }).toList();

    // =================================================
    // เลของค์จริงแบบไม่ซ้ำ
    // เก็บเลขถัดไปแยกต่างหาก
    // =================================================

    int nextNumber =
        prefs.getInt('next_real_item_number') ?? 0;

    if (nextNumber <= 0) {
      int maxNumber = 0;

      for (final item in items) {
        if (item.realItemNumber > maxNumber) {
          maxNumber = item.realItemNumber;
        }
      }

      nextNumber = maxNumber + 1;
    }

    final newItem = AmuletData(
      id: DateTime.now().millisecondsSinceEpoch,
      realItemNumber: nextNumber,
      name: nameController.text,
      model: modelController.text,
      type: typeController.text,
      temple: templeController.text,
      province: provinceController.text,
      year: yearController.text,
      material: materialController.text,
      size: sizeController.text,
      frontDetail: frontController.text,
      sideDetail: sideController.text,
      backDetail: backController.text,
    );

    items.add(newItem);

    final saveData = items.map((item) {
      return jsonEncode(item.toMap());
    }).toList();

    await prefs.setStringList(
      'amulet_data',
      saveData,
    );

    await prefs.setInt(
      'next_real_item_number',
      nextNumber + 1,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'บันทึกองค์จริงลำดับที่ $nextNumber เรียบร้อยแล้ว',
        ),
      ),
    );

    Navigator.pop(context);
  }
}

// =====================================================
// รายการข้อมูลที่บันทึก
// =====================================================

class SavedListPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SavedListPage({
    super.key,
    required this.cameras,
  });

  @override
  State<SavedListPage> createState() => _SavedListPageState();
}

class _SavedListPageState extends State<SavedListPage> {
  List<AmuletData> items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getStringList('amulet_data') ?? [];

    final loaded = saved.map((item) {
      return AmuletData.fromMap(
        jsonDecode(item),
      );
    }).toList();

    if (!mounted) return;

    setState(() {
      items = loaded;
    });
  }

  Future<void> _deleteItem(AmuletData item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ลบข้อมูล'),
          content: Text(
            'ต้องการลบข้อมูลนี้หรือไม่?\n\n'
            'องค์จริงลำดับที่ ${item.realItemNumber}\n'
            '${item.name.isEmpty ? 'ยังไม่ได้ระบุชื่อ' : item.name}\n\n'
            'ข้อมูลการสแกนขององค์นี้จะถูกลบด้วย',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ลบข้อมูล'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getStringList('amulet_data') ?? [];

    final remaining = saved.where((jsonString) {
      final map = jsonDecode(jsonString);

      return map['id'] != item.id;
    }).toList();

    await prefs.setStringList(
      'amulet_data',
      remaining,
    );

    await _loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ลบองค์จริงลำดับที่ ${item.realItemNumber} แล้ว',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการข้อมูลที่บันทึก'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีข้อมูลที่บันทึก',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        '${item.realItemNumber}',
                      ),
                    ),
                    title: Text(
                      item.name.isEmpty
                          ? 'ยังไม่ได้ระบุชื่อ'
                          : item.name,
                    ),
                    subtitle: Text(
                      'องค์จริงลำดับที่ ${item.realItemNumber}'
                      '${item.model.isEmpty ? '' : ' • ${item.model}'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'ลบข้อมูล',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _deleteItem(item);
                          },
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailPage(
                            item: item,
                            cameras: widget.cameras,
                          ),
                        ),
                      );

                      _loadData();
                    },
                  ),
                );
              },
            ),
    );
  }
}

// =====================================================
// หน้ารายละเอียด
// =====================================================

class SavedListPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SavedListPage({
    super.key,
    required this.cameras,
  });

  @override
  State<SavedListPage> createState() => _SavedListPageState();
}

class _SavedListPageState extends State<SavedListPage> {
  List<AmuletData> items = [];
  List<AmuletData> filteredItems = [];

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_search);
    _loadData();
  }

  @override
  void dispose() {
    searchController.removeListener(_search);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final saved =
        prefs.getStringList('amulet_data') ?? [];

    final loaded = saved.map((item) {
      return AmuletData.fromMap(
        jsonDecode(item),
      );
    }).toList();

    if (!mounted) return;

    setState(() {
      items = loaded;
      filteredItems = loaded;
    });

    _search();
  }

  void _search() {
    final keyword =
        searchController.text.trim().toLowerCase();

    if (keyword.isEmpty) {
      if (mounted) {
        setState(() {
          filteredItems = items;
        });
      }
      return;
    }

    final result = items.where((item) {
      final text = [
        item.realItemNumber.toString(),
        item.name,
        item.model,
        item.type,
        item.temple,
        item.province,
        item.year,
        item.material,
        item.size,
      ].join(' ').toLowerCase();

      return text.contains(keyword);
    }).toList();

    if (mounted) {
      setState(() {
        filteredItems = result;
      });
    }
  }

  int _sameModelCount(AmuletData item) {
    final name = item.name.trim().toLowerCase();
    final model = item.model.trim().toLowerCase();

    if (name.isEmpty && model.isEmpty) {
      return 0;
    }

    return items.where((other) {
      return other.name.trim().toLowerCase() == name &&
          other.model.trim().toLowerCase() == model;
    }).length;
  }

  Future<void> _deleteItem(
    AmuletData item,
  ) async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ลบข้อมูล'),
          content: Text(
            'ต้องการลบข้อมูลนี้หรือไม่?\n\n'
            'องค์จริงลำดับที่ ${item.realItemNumber}\n'
            '${item.name.isEmpty ? 'ยังไม่ได้ระบุชื่อ' : item.name}\n\n'
            'ข้อมูลการสแกนขององค์นี้จะถูกลบด้วย',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('ลบข้อมูล'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final prefs =
        await SharedPreferences.getInstance();

    final saved =
        prefs.getStringList('amulet_data') ?? [];

    final remaining =
        saved.where((jsonString) {
      final map = jsonDecode(jsonString);

      return map['id'] != item.id;
    }).toList();

    await prefs.setStringList(
      'amulet_data',
      remaining,
    );

    await _loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ลบองค์จริงลำดับที่ '
          '${item.realItemNumber} แล้ว',
        ),
      ),
    );
  }

  Widget _achievement(int count) {
    if (count < 5) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.amber.shade100,
      ),
      child: Text(
        '🏅 พื้นฐาน 5+ องค์ • $count องค์',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายการข้อมูลที่บันทึก',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              6,
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText:
                    'ค้นหา ชื่อ รุ่น วัด จังหวัด ปี เนื้อ หรือเลขรายการ',
                prefixIcon:
                    const Icon(Icons.search),
                suffixIcon:
                    searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.clear,
                            ),
                            onPressed: () {
                              searchController.clear();
                            },
                          ),
                border:
                    const OutlineInputBorder(),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'พบ ${filteredItems.length} รายการ',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      'ไม่พบข้อมูล',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.all(12),
                    itemCount:
                        filteredItems.length,
                    itemBuilder:
                        (context, index) {
                      final item =
                          filteredItems[index];

                      final sameCount =
                          _sameModelCount(item);

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: ListTile(
                          leading:
                              CircleAvatar(
                            child: Text(
                              '${item.realItemNumber}',
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                item.name.isEmpty
                                    ? 'ยังไม่ได้ระบุชื่อ'
                                    : item.name,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              _achievement(
                                sameCount,
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              top: 5,
                            ),
                            child: Text(
                              'องค์จริงลำดับที่ '
                              '${item.realItemNumber}'
                              '${item.model.isEmpty ? '' : ' • ${item.model}'}',
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip:
                                    'ลบข้อมูล',
                                icon: const Icon(
                                  Icons
                                      .delete_outline,
                                  color:
                                      Colors.red,
                                ),
                                onPressed: () {
                                  _deleteItem(
                                    item,
                                  );
                                },
                              ),
                              const Icon(
                                Icons.chevron_right,
                              ),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailPage(
                                  item: item,
                                  cameras:
                                      widget
                                          .cameras,
                                ),
                              ),
                            );

                            await _loadData();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


// =====================================================
// สำรอง / นำเข้าข้อมูล
// =====================================================

class BackupPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const BackupPage({
    super.key,
    required this.cameras,
  });

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool working = false;

  Future<void> _backupData() async {
    setState(() {
      working = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final saved = prefs.getStringList('amulet_data') ?? [];

      final nextNumber =
          prefs.getInt('next_real_item_number') ?? 1;

      final backup = {
        'backupVersion': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'containsImages': false,
        'nextRealItemNumber': nextNumber,
        'data': saved.map((item) {
          return jsonDecode(item);
        }).toList(),
      };

      final jsonText = const JsonEncoder.withIndent(
        '  ',
      ).convert(backup);

      final fileName =
          'amulet_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'บันทึกไฟล์สำรองข้อมูล',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonText),
      );

      if (!mounted) return;

      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยกเลิกการสำรองข้อมูล'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'สำรองข้อมูลเรียบร้อยแล้ว',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'สำรองข้อมูลไม่สำเร็จ: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          working = false;
        });
      }
    }
  }

  Future<void> _importData() async {
    setState(() {
      working = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null) {
        return;
      }

      final bytes = result.files.single.bytes;

      if (bytes == null) {
        throw Exception(
          'ไม่สามารถอ่านไฟล์สำรองได้',
        );
      }

      final jsonText = utf8.decode(bytes);

      final decoded = jsonDecode(jsonText);

      if (decoded is! Map ||
          decoded['data'] is! List) {
        throw Exception(
          'รูปแบบไฟล์สำรองไม่ถูกต้อง',
        );
      }

      final importedData =
          List<dynamic>.from(decoded['data']);

      final validItems = <String>[];

      for (final item in importedData) {
        if (item is Map) {
          validItems.add(
            jsonEncode(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }

      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'นำเข้าข้อมูล',
            ),
            content: Text(
              'พบข้อมูล ${validItems.length} รายการ\n\n'
              'การนำเข้าจะใช้ข้อมูลจากไฟล์สำรองแทนข้อมูลปัจจุบัน\n\n'
              'ควรสำรองข้อมูลปัจจุบันก่อนนำเข้า',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('ยืนยัน'),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setStringList(
        'amulet_data',
        validItems,
      );

      int nextNumber = 1;

      if (decoded['nextRealItemNumber'] is int) {
        nextNumber =
            decoded['nextRealItemNumber'];
      } else {
        for (final jsonString in validItems) {
          final map = jsonDecode(jsonString);

          final number =
              map['realItemNumber'] ?? 0;

          if (number >= nextNumber) {
            nextNumber = number + 1;
          }
        }
      }

      await prefs.setInt(
        'next_real_item_number',
        nextNumber,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'นำเข้าข้อมูล ${validItems.length} รายการเรียบร้อยแล้ว',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'นำเข้าข้อมูลไม่สำเร็จ: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          working = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'สำรอง / นำเข้าข้อมูล',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'การจัดการข้อมูล',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'สำรองเฉพาะข้อมูลพระ/เหรียญ '
                      'และข้อมูลการสแกน',
                    ),
                    SizedBox(height: 6),
                    Text(
                      'ไม่มีการบันทึกหรือสำรองรูปภาพ',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                    working ? null : _backupData,
                icon: const Icon(Icons.backup),
                label: const Text(
                  'สำรองข้อมูล',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                    working ? null : _importData,
                icon: const Icon(Icons.restore),
                label: const Text(
                  'นำเข้าข้อมูล',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            if (working) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  // =====================================================
// หน้าสแกน
// =====================================================

class ScanPage extends StatefulWidget {
  final AmuletData item;
  final List<CameraDescription> cameras;

  const ScanPage({
    super.key,
    required this.item,
    required this.cameras,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? controller;

  final ImagePicker _picker = ImagePicker();

  final List<String> defaultAreas = [
    'ด้านหน้า',
    'ด้านหลัง',
    'ด้านข้าง',
    'หูเหรียญ',
    'ตูดพระ',
    'จุดเฉพาะ',
  ];

  String selectedArea = 'ด้านหน้า';

  // true = องค์จริง
  // false = จากตัวเครื่อง
  bool realObjectMode = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;

    controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller!.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(
        'Camera initialize error: $e',
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  int _scanCount(String area) {
    return widget.item.scans
        .where(
          (scan) => scan.area == area,
        )
        .length;
  }

  String? _nextArea() {
    final index =
        defaultAreas.indexOf(selectedArea);

    if (index == -1) return null;

    if (index + 1 >= defaultAreas.length) {
      return null;
    }

    return defaultAreas[index + 1];
  }

  Future<void> _saveScan(
    String method,
  ) async {
    final currentArea =
        selectedArea;

    final scanNumber =
        _scanCount(currentArea) + 1;

    final scan = ScanData(
      area: currentArea,
      scanNumber: scanNumber,
      method: method,
      details: {},
    );

    widget.item.scans.add(scan);

    final prefs =
        await SharedPreferences.getInstance();

    final data =
        prefs.getStringList(
              'amulet_data',
            ) ??
            [];

    final updatedData =
        data.map((jsonString) {
      final map = jsonDecode(
        jsonString,
      );

      if (map['id'] ==
          widget.item.id) {
        map['scans'] =
            widget.item.scans
                .map(
                  (scan) =>
                      scan.toMap(),
                )
                .toList();
      }

      return jsonEncode(map);
    }).toList();

    await prefs.setStringList(
      'amulet_data',
      updatedData,
    );

    // ---------------------------------------------
    // ไปพื้นที่ถัดไปอัตโนมัติ
    // ---------------------------------------------

    final next = _nextArea();

    if (!mounted) return;

    setState(() {
      if (next != null) {
        selectedArea = next;
      }
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          next == null
              ? '$currentArea • สแกนครั้งที่ '
                  '$scanNumber เรียบร้อยแล้ว'
              : '$currentArea • สแกนครั้งที่ '
                  '$scanNumber เรียบร้อยแล้ว\n'
                  'ต่อไป: $next',
        ),
      ),
    );
  }

  Future<void> _startSelectedScan(
    String area,
  ) async {
    setState(() {
      selectedArea = area;
    });

    if (realObjectMode) {
      await _scanRealObject();
    } else {
      await _scanFromPhone();
    }
  }

  Future<void> _scanRealObject() async {
    if (controller == null ||
        !controller!.value.isInitialized) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'กล้องยังไม่พร้อม',
          ),
        ),
      );

      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.all(12),
                child: Text(
                  'สแกน${selectedArea}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              AspectRatio(
                aspectRatio:
                    controller!
                        .value
                        .aspectRatio,
                child: CameraPreview(
                  controller!,
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'จัดพระให้อยู่ในกรอบ '
                      'แล้วแตะบันทึกเมื่อพร้อม',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.white,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
                      child:
                          ElevatedButton.icon(
                        icon:
                            const Icon(
                          Icons.check,
                        ),
                        label: Text(
                          'เสร็จ ${selectedArea}',
                        ),
                        onPressed: () async {
                          Navigator.pop(
                            context,
                          );

                          await _saveScan(
                            'สแกนองค์จริง',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanFromPhone() async {
    final image =
        await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) {
      return;
    }

    // ---------------------------------------------
    // สำคัญ:
    // ใช้รูปเพื่อการสแกนเท่านั้น
    // ไม่เก็บ path
    // ไม่เก็บรูป
    // ไม่ใส่รูปลงฐานข้อมูล
    // ---------------------------------------------

    await _saveScan(
      'สแกนจากตัวเครื่อง',
    );
  }

  Future<void> _addCustomArea() async {
    final textController =
        TextEditingController();

    final result =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'เพิ่มจุดสแกน',
          ),
          content: TextField(
            controller:
                textController,
            autofocus: true,
            decoration:
                const InputDecoration(
              hintText:
                  'เช่น ขอบล่าง / หลังหู / จุดตำหนิ',
              border:
                  OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child: const Text(
                'ยกเลิก',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                    textController.text
                        .trim();

                if (value.isNotEmpty) {
                  Navigator.pop(
                    context,
                    value,
                  );
                }
              },
              child: const Text(
                'เพิ่ม',
              ),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (result == null ||
        result.isEmpty) {
      return;
    }

    setState(() {
      selectedArea = result;
    });
  }

  Widget _methodButton({
    required bool realObject,
    required IconData icon,
    required String title,
  }) {
    final selected =
        realObjectMode == realObject;

    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            realObjectMode =
                realObject;
          });
        },
        icon: Icon(icon),
        label: Text(
          title,
          textAlign: TextAlign.center,
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor: selected
              ? Colors.blue
              : Colors.grey.shade200,
          foregroundColor: selected
              ? Colors.white
              : Colors.black87,
          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _areaButton(
    String area,
  ) {
    final count =
        _scanCount(area);

    final selected =
        selectedArea == area;

    return Card(
      color: selected
          ? Colors.blue.shade50
          : null,
      child: ListTile(
        leading: Icon(
          count > 0
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: count > 0
              ? Colors.green
              : null,
        ),
        title: Text(
          area,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          count == 0
              ? 'ยังไม่ได้สแกน'
              : 'สแกนแล้ว $count ครั้ง',
        ),
        trailing: selected
            ? const Icon(
                Icons.play_arrow,
              )
            : null,

        // -----------------------------------------
        // สำคัญ:
        // แตะด้านไหน = เริ่มวิธีที่เลือกทันที
        // -----------------------------------------
        onTap: () {
          _startSelectedScan(
            area,
          );
        },
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final areas =
        [...defaultAreas];

    final customAreas =
        widget.item.scans
            .map(
              (scan) =>
                  scan.area,
            )
            .where(
              (area) =>
                  !defaultAreas
                      .contains(
                    area,
                  ),
            )
            .toSet()
            .toList();

    areas.addAll(
      customAreas,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'สแกนข้อมูล',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Text(
            'องค์จริงลำดับที่ '
            '${widget.item.realItemNumber}',
            style:
                const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          if (widget.item.name
              .isNotEmpty) ...[
            const SizedBox(
              height: 4,
            ),
            Text(
              widget.item.name,
              style:
                  const TextStyle(
                fontSize: 16,
              ),
            ),
          ],

          const SizedBox(
            height: 16,
          ),

          const Text(
            'วิธีสแกน',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            children: [
              _methodButton(
                realObject: true,
                icon:
                    Icons.camera_alt,
                title:
                    '📷 สแกนองค์จริง',
              ),

              const SizedBox(
                width: 8,
              ),

              _methodButton(
                realObject: false,
                icon:
                    Icons.phone_android,
                title:
                    '🖼️ จากตัวเครื่อง',
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          Container(
            padding:
                const EdgeInsets.all(14),
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              color:
                  Colors.blue.shade50,
            ),
            child: Row(
              children: [
                Icon(
                  realObjectMode
                      ? Icons.camera_alt
                      : Icons.photo_library,
                  color:
                      Colors.blue,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    realObjectMode
                        ? 'เลือก “ด้านหน้า” หรือด้านอื่นเพื่อเปิดกล้องทันที'
                        : 'เลือก “ด้านหน้า” หรือด้านอื่นเพื่อเลือกรูปจากตัวเครื่องทันที',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          const Text(
            'เลือกด้านที่จะสแกน',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'แตะด้านที่ต้องการ แล้วระบบจะเริ่มวิธีสแกนที่เลือกทันที',
          ),

          const SizedBox(
            height: 10,
          ),

          ...areas.map(
            _areaButton,
          ),

          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.add,
              ),
              title:
                  const Text(
                'เพิ่มจุดสแกนเอง',
              ),
              subtitle:
                  const Text(
                'สำหรับรายละเอียดเฉพาะขององค์นั้น',
              ),
              onTap:
                  _addCustomArea,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'ประวัติการสแกน',
                    style:
                        TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  if (widget
                      .item
                      .scans
                      .isEmpty)
                    const Text(
                      'ยังไม่มีข้อมูลการสแกน',
                    ),

                  ...widget
                      .item
                      .scans
                      .map(
                    (scan) =>
                        ListTile(
                      dense: true,
                      leading:
                          const Icon(
                        Icons
                            .check_circle_outline,
                        color:
                            Colors.green,
                      ),
                      title: Text(
                        '${scan.area} • '
                        'สแกน ${scan.scanNumber}',
                      ),
                      subtitle:
                          Text(
                        scan.method,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
