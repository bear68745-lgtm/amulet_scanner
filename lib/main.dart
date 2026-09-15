import 'dart:convert';
 
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(
    AmuletScannerApp(cameras: cameras),
  );
}

// =====================================================
// APP
// =====================================================

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
// DATA
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
    final scanList = map['scans'] as List? ?? [];

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
      scans: scanList
          .map(
            (scan) => ScanData.fromMap(
              Map<String, dynamic>.from(scan),
            ),
          )
          .toList(),
    );
  }
}

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
// STORAGE HELPERS
// =====================================================

Future<List<AmuletData>> loadAllItems() async {
  final prefs = await SharedPreferences.getInstance();

  final saved = prefs.getStringList('amulet_data') ?? [];

  return saved.map((item) {
    return AmuletData.fromMap(
      jsonDecode(item),
    );
  }).toList();
}

Future<void> saveAllItems(List<AmuletData> items) async {
  final prefs = await SharedPreferences.getInstance();

  final data = items.map((item) {
    return jsonEncode(item.toMap());
  }).toList();

  await prefs.setStringList(
    'amulet_data',
    data,
  );
}

// =====================================================
// HOME
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
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
            ],
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
// CREATE DATA
// =====================================================

class CreateDataPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CreateDataPage({
    super.key,
    required this.cameras,
  });

  @override
  State<CreateDataPage> createState() =>
      _CreateDataPageState();
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

          _field(
            'รายละเอียดด้านหน้า',
            frontController,
            maxLines: 4,
          ),
          _field(
            'รายละเอียดด้านข้าง',
            sideController,
            maxLines: 4,
          ),
          _field(
            'รายละเอียดด้านหลัง',
            backController,
            maxLines: 4,
          ),

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
            'สามารถบันทึกข้อมูลโดยไม่สแกนได้ '
            'และกลับมาแก้ไขเพื่อสแกนเพิ่มภายหลัง',
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
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    final items = await loadAllItems();

    int nextNumber =
        prefs.getInt('next_real_item_number') ?? 1;

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
      name: nameController.text.trim(),
      model: modelController.text.trim(),
      type: typeController.text.trim(),
      temple: templeController.text.trim(),
      province: provinceController.text.trim(),
      year: yearController.text.trim(),
      material: materialController.text.trim(),
      size: sizeController.text.trim(),
      frontDetail: frontController.text.trim(),
      sideDetail: sideController.text.trim(),
      backDetail: backController.text.trim(),
    );

    items.add(newItem);

    await saveAllItems(items);

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
// SAVED LIST
// =====================================================

class SavedListPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SavedListPage({
    super.key,
    required this.cameras,
  });

  @override
  State<SavedListPage> createState() =>
      _SavedListPageState();
}

class _SavedListPageState extends State<SavedListPage> {
  List<AmuletData> items = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loaded = await loadAllItems();

    if (!mounted) return;

    setState(() {
      items = loaded;
    });
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

  bool _matchesSearch(AmuletData item) {
    final q = searchText.trim().toLowerCase();

    if (q.isEmpty) return true;

    final text = [
      item.realItemNumber,
      item.name,
      item.model,
      item.type,
      item.temple,
      item.province,
      item.year,
      item.material,
      item.size,
    ].join(' ').toLowerCase();

    return text.contains(q);
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

    items.removeWhere(
      (element) => element.id == item.id,
    );

    await saveAllItems(items);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ลบองค์จริงลำดับที่ '
          '${item.realItemNumber} แล้ว',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems =
        items.where(_matchesSearch).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายการข้อมูลที่บันทึก',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText:
                    'ค้นหา ชื่อ รุ่น พิมพ์ วัด จังหวัด...',
                prefixIcon:
                    const Icon(Icons.search),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchText = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
          ),

          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Text(
                      items.isEmpty
                          ? 'ยังไม่มีข้อมูลที่บันทึก'
                          : 'ไม่พบข้อมูลที่ค้นหา',
                      style:
                          const TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(
                      12,
                      0,
                      12,
                      12,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item =
                          filteredItems[index];

                      final count =
                          _sameModelCount(item);

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
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
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'องค์จริงลำดับที่ '
                                '${item.realItemNumber}'
                                '${item.model.isEmpty ? '' : ' • ${item.model}'}',
                              ),
                              if (count >= 5)
                                Text(
                                  '🏅 พื้นฐาน 5+ องค์ • '
                                  '$count องค์',
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          isThreeLine: count >= 5,
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
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
                                      widget.cameras,
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
// DETAIL
// =====================================================

class DetailPage extends StatefulWidget {
  final AmuletData item;
  final List<CameraDescription> cameras;

  const DetailPage({
    super.key,
    required this.item,
    required this.cameras,
  });

  @override
  State<DetailPage> createState() =>
      _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late TextEditingController nameController;
  late TextEditingController modelController;
  late TextEditingController typeController;
  late TextEditingController templeController;
  late TextEditingController provinceController;
  late TextEditingController yearController;
  late TextEditingController materialController;
  late TextEditingController sizeController;

  late TextEditingController frontController;
  late TextEditingController sideController;
  late TextEditingController backController;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    nameController =
        TextEditingController(text: item.name);
    modelController =
        TextEditingController(text: item.model);
    typeController =
        TextEditingController(text: item.type);
    templeController =
        TextEditingController(text: item.temple);
    provinceController =
        TextEditingController(text: item.province);
    yearController =
        TextEditingController(text: item.year);
    materialController =
        TextEditingController(text: item.material);
    sizeController =
        TextEditingController(text: item.size);

    frontController =
        TextEditingController(text: item.frontDetail);
    sideController =
        TextEditingController(text: item.sideDetail);
    backController =
        TextEditingController(text: item.backDetail);
  }

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
        title: Text(
          'องค์จริง ${widget.item.realItemNumber}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'องค์จริงลำดับที่ '
                '${widget.item.realItemNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _field(
            'ชื่อพระ / เหรียญ',
            nameController,
          ),
          _field('รุ่น', modelController),
          _field('พิมพ์', typeController),
          _field('วัด / สำนัก', templeController),
          _field('จังหวัด', provinceController),
          _field('ปีสร้าง', yearController),
          _field('เนื้อ', materialController),
          _field('ขนาด', sizeController),

          const SizedBox(height: 8),

          const Text(
            'รายละเอียด',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          _field(
            'รายละเอียดด้านหน้า',
            frontController,
            maxLines: 4,
          ),
          _field(
            'รายละเอียดด้านข้าง',
            sideController,
            maxLines: 4,
          ),
          _field(
            'รายละเอียดด้านหลัง',
            backController,
            maxLines: 4,
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.camera_alt),
              title: const Text(
                'สแกนเพิ่ม',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                widget.item.scans.isEmpty
                    ? 'ยังไม่มีข้อมูลการสแกน'
                    : 'มีข้อมูลการสแกน '
                        '${widget.item.scans.length} รายการ',
              ),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanPage(
                      item: widget.item,
                      cameras: widget.cameras,
                    ),
                  ),
                );

                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text(
                'บันทึกการแก้ไข',
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
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final items = await loadAllItems();

    final index = items.indexWhere(
      (element) => element.id == widget.item.id,
    );

    if (index == -1) return;

    final oldItem = items[index];

    items[index] = AmuletData(
      id: oldItem.id,
      realItemNumber:
          oldItem.realItemNumber,
      name: nameController.text.trim(),
      model: modelController.text.trim(),
      type: typeController.text.trim(),
      temple: templeController.text.trim(),
      province: provinceController.text.trim(),
      year: yearController.text.trim(),
      material:
          materialController.text.trim(),
      size: sizeController.text.trim(),
      frontDetail:
          frontController.text.trim(),
      sideDetail:
          sideController.text.trim(),
      backDetail:
          backController.text.trim(),
      scans: oldItem.scans,
    );

    await saveAllItems(items);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'บันทึกการแก้ไขเรียบร้อยแล้ว',
        ),
      ),
    );

    Navigator.pop(context);
  }
}

// =====================================================
// BACKUP / IMPORT
// =====================================================

class BackupPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const BackupPage({
    super.key,
    required this.cameras,
  });

  @override
  State<BackupPage> createState() =>
      _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool working = false;

  Future<void> _backupData() async {
    setState(() {
      working = true;
    });

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final saved =
          prefs.getStringList('amulet_data') ?? [];

      final nextNumber =
          prefs.getInt(
                'next_real_item_number',
              ) ??
              1;

      final backup = {
        'backupVersion': 1,
        'createdAt':
            DateTime.now().toIso8601String(),
        'containsImages': false,
        'nextRealItemNumber': nextNumber,
        'data': saved.map(
          (item) => jsonDecode(item),
        ).toList(),
      };

      final jsonText =
          const JsonEncoder.withIndent(
        '  ',
      ).convert(backup);

      final fileName =
          'amulet_backup_'
          '${DateTime.now().millisecondsSinceEpoch}.json';

      await FilePicker.platform.saveFile(
        dialogTitle:
            'บันทึกไฟล์สำรองข้อมูล',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonText),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'สำรองข้อมูลเรียบร้อยแล้ว',
          ),
        ),
      );
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
      final result =
          await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null) return;

      final bytes =
          result.files.single.bytes;

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
          List<dynamic>.from(
        decoded['data'],
      );

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

      final confirm =
          await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'นำเข้าข้อมูล',
            ),
            content: Text(
              'พบข้อมูล ${validItems.length} รายการ\n\n'
              'การนำเข้าจะใช้ข้อมูลจากไฟล์สำรอง '
              'แทนข้อมูลปัจจุบัน\n\n'
              'ควรสำรองข้อมูลปัจจุบันก่อนนำเข้า',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
                child:
                    const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  );
                },
                child:
                    const Text('ยืนยัน'),
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

      if (decoded['nextRealItemNumber']
          is int) {
        nextNumber =
            decoded['nextRealItemNumber'];
      } else {
        for (final jsonString
            in validItems) {
          final map =
              jsonDecode(jsonString);

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
            'นำเข้าข้อมูล '
            '${validItems.length} รายการเรียบร้อยแล้ว',
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
                        fontWeight:
                            FontWeight.bold,
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
                icon:
                    const Icon(Icons.backup),
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
                icon:
                    const Icon(Icons.restore),
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
  }
}

// =====================================================
// SETTINGS
// =====================================================

class SettingsPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SettingsPage({
    super.key,
    required this.cameras,
  });

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState
    extends State<SettingsPage> {
  bool realObjectDefault = true;
  bool showScanHistory = true;
  bool autoNextArea = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs =
        await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      realObjectDefault =
          prefs.getBool(
                'setting_real_object_default',
              ) ??
              true;

      showScanHistory =
          prefs.getBool(
                'setting_show_scan_history',
              ) ??
              true;

      autoNextArea =
          prefs.getBool(
                'setting_auto_next_area',
              ) ??
              true;
    });
  }

  Future<void> _setSetting(
    String key,
    bool value,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่า'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'ตั้งค่าการทำงานของแอป\n\n'
                'ระบบออกแบบให้เก็บข้อมูลพระ/เหรียญ '
                'โดยไม่บันทึกรูปภาพลงฐานข้อมูล',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text(
              'เริ่มต้นด้วยสแกนองค์จริง',
            ),
            subtitle: const Text(
              'ตั้งวิธีสแกนเริ่มต้นเป็นกล้อง',
            ),
            value: realObjectDefault,
            onChanged: (value) async {
              setState(() {
                realObjectDefault = value;
              });

              await _setSetting(
                'setting_real_object_default',
                value,
              );
            },
          ),

          SwitchListTile(
            title: const Text(
              'แสดงประวัติการสแกน',
            ),
            subtitle: const Text(
              'แสดงรายการการสแกนที่ผ่านมา',
            ),
            value: showScanHistory,
            onChanged: (value) async {
              setState(() {
                showScanHistory = value;
              });

              await _setSetting(
                'setting_show_scan_history',
                value,
              );
            },
          ),

          SwitchListTile(
            title: const Text(
              'เปลี่ยนพื้นที่ถัดไปอัตโนมัติ',
            ),
            subtitle: const Text(
              'หลังบันทึกการสแกน ให้เลือกพื้นที่ถัดไป',
            ),
            value: autoNextArea,
            onChanged: (value) async {
              setState(() {
                autoNextArea = value;
              });

              await _setSetting(
                'setting_auto_next_area',
                value,
              );
            },
          ),

          const SizedBox(height: 16),

          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '🏅 พื้นฐาน 5+ องค์\n\n'
                '5 องค์เป็นเพียงจุดเตือนพื้นฐาน '
                'ไม่ใช่จำนวนสูงสุด สามารถเพิ่ม '
                '6, 7, 10, 20 องค์ หรือมากกว่าได้',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// SCAN
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
  CameraController? cameraController;

  final ImagePicker picker = ImagePicker();

  final List<String> defaultAreas = [
    'ด้านหน้า',
    'ด้านหลัง',
    'ด้านข้าง',
    'หูเหรียญ',
    'ตูดพระ',
    'จุดเฉพาะ',
  ];

  String selectedArea = 'ด้านหน้า';

  bool realObjectMode = true;
  bool showHistory = true;
  bool autoNextArea = true;

  bool scanning = false;
  bool cameraReady = false;

  int temporaryFrameCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // =====================================================
  // LOAD SETTINGS
  // =====================================================

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      realObjectMode =
          prefs.getBool(
                'setting_real_object_default',
              ) ??
              true;

      showHistory =
          prefs.getBool(
                'setting_show_scan_history',
              ) ??
              true;

      autoNextArea =
          prefs.getBool(
                'setting_auto_next_area',
              ) ??
              true;
    });
  }

  // =====================================================
  // CAMERA
  // =====================================================

  Future<void> _openCameraScanner() async {
    if (widget.cameras.isEmpty) {
      _showMessage('ไม่พบกล้องในเครื่อง');
      return;
    }

    try {
      final camera = widget.cameras.firstWhere(
        (camera) =>
            camera.lensDirection ==
            CameraLensDirection.back,
        orElse: () => widget.cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      cameraController = controller;

      setState(() {
        cameraReady = true;
        scanning = false;
        temporaryFrameCount = 0;
      });

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (
              context,
              setSheetState,
            ) {
              return SafeArea(
                child: Container(
                  height:
                      MediaQuery.of(context)
                          .size
                          .height *
                          0.90,
                  padding:
                      const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                            ),
                            onPressed: scanning
                                ? null
                                : () {
                                    Navigator.pop(
                                      sheetContext,
                                    );
                                  },
                          ),
                          Expanded(
                            child: Text(
                              'สแกน$selectedArea',
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 48,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(12),
                        decoration:
                            BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        child: Text(
                          scanning
                              ? 'กำลังรับข้อมูลจากกล้อง...'
                              : 'จัดองค์พระ/เหรียญให้อยู่ในกรอบ แล้วกดเริ่มสแกน',
                          textAlign:
                              TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Expanded(
                        child: cameraController !=
                                    null &&
                                cameraController!
                                    .value
                                    .isInitialized
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CameraPreview(
                                      cameraController!,
                                    ),

                                    Center(
                                      child:
                                          IgnorePointer(
                                        child:
                                            Container(
                                          width: 260,
                                          height: 330,
                                          decoration:
                                              BoxDecoration(
                                            border:
                                                Border.all(
                                              width: 2,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    if (scanning)
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
                                          decoration:
                                              BoxDecoration(
                                            color: Colors
                                                .black
                                                .withValues(
                                              alpha:
                                                  0.65,
                                            ),
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            'กำลังสแกน • '
                                            '$temporaryFrameCount '
                                            'ช่วงข้อมูล',
                                            textAlign:
                                                TextAlign
                                                    .center,
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors
                                                      .white,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : const Center(
                                child:
                                    CircularProgressIndicator(),
                              ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'ข้อมูลภาพจะใช้ชั่วคราวในหน่วยความจำ '
                        'และจะไม่บันทึกไฟล์รูปภาพ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (!scanning)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child:
                              ElevatedButton.icon(
                            icon: const Icon(
                              Icons.document_scanner,
                            ),
                            label: const Text(
                              'เริ่มสแกนพื้นที่นี้',
                              style: TextStyle(
                                fontSize: 17,
                              ),
                            ),
                            onPressed: () async {
                              setSheetState(() {
                                scanning = true;
                                temporaryFrameCount =
                                    0;
                              });

                              await _runTemporaryScan(
                                onProgress:
                                    (count) {
                                  if (sheetContext
                                      .mounted) {
                                    setSheetState(() {
                                      temporaryFrameCount =
                                          count;
                                    });
                                  }
                                },
                              );

                              if (!sheetContext
                                  .mounted) {
                                return;
                              }

                              setSheetState(() {
                                scanning = false;
                              });

                              final save =
                                  await showDialog<
                                      bool>(
                                context:
                                    sheetContext,
                                builder:
                                    (dialogContext) {
                                  return AlertDialog(
                                    title:
                                        const Text(
                                      'สแกนเสร็จแล้ว',
                                    ),
                                    content:
                                        Text(
                                      'พื้นที่ $selectedArea\n\n'
                                      'ระบบรับข้อมูลชั่วคราว '
                                      '$temporaryFrameCount ช่วง\n\n'
                                      'ต้องการบันทึก "ข้อมูลการสแกน" หรือไม่?\n'
                                      'ไม่มีการบันทึกรูปภาพ',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () {
                                          Navigator
                                              .pop(
                                            dialogContext,
                                            false,
                                          );
                                        },
                                        child:
                                            const Text(
                                          'ยกเลิก',
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () {
                                          Navigator
                                              .pop(
                                            dialogContext,
                                            true,
                                          );
                                        },
                                        child:
                                            const Text(
                                          'บันทึกข้อมูล',
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (save == true) {
                                Navigator.pop(
                                  sheetContext,
                                );

                                await _saveScan(
                                  'สแกนองค์จริง',
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      await cameraController?.dispose();
      cameraController = null;

      if (mounted) {
        setState(() {
          cameraReady = false;
          scanning = false;
        });
      }
    } catch (e) {
      await cameraController?.dispose();
      cameraController = null;

      if (!mounted) return;

      setState(() {
        cameraReady = false;
        scanning = false;
      });

      _showMessage(
        'เปิดกล้องไม่สำเร็จ: $e',
      );
    }
  }

  // =====================================================
  // TEMPORARY SCAN
  // =====================================================
Future<void> _runTemporaryScan({
  required void Function(int count) onProgress,
}) async {
  if (cameraController == null ||
      !cameraController!.value.isInitialized) {
    return;
  }

  const totalFrames = 12;

  int frameCount = 0;
  bool scanning = true;

  // ป้องกันการรับภาพซ้ำหลังครบ 12 เฟรม
  void stopScanning() {
    scanning = false;
  }

  try {
    await cameraController!.startImageStream(
      (CameraImage image) {
        if (!scanning) {
          return;
        }

        frameCount++;

        // -----------------------------------------
        // จุดสำคัญ:
        // image อยู่ใน RAM ระหว่างการประมวลผลเท่านั้น
        // ยังไม่มีการบันทึกเป็นไฟล์
        // -----------------------------------------

        // ขั้นต่อไปเราจะนำ image ไปวิเคราะห์
        // เช่น ขนาดภาพ / ความสว่าง / รายละเอียด
        // / ด้านหน้า / ด้านข้าง / ด้านหลัง
        //
        // ตอนนี้ยังไม่ใส่ AI
        // เพียงรับและนับ CameraImage จริงก่อน

        onProgress(frameCount);

        // ครบ 12 เฟรม
        if (frameCount >= totalFrames) {
          stopScanning();
        }
      },
    );

    // รอจนกว่าจะครบ 12 เฟรม
    while (scanning) {
      await Future.delayed(
        const Duration(milliseconds: 20),
      );

      if (!mounted) {
        scanning = false;
        break;
      }
    }

    // หยุดรับภาพจากกล้อง
    if (cameraController!.value.isStreamingImages) {
      await cameraController!.stopImageStream();
    }
  } catch (e) {
    // หากเกิดข้อผิดพลาด ให้หยุด stream
    scanning = false;

    if (cameraController!.value.isStreamingImages) {
      await cameraController!.stopImageStream();
    }

    debugPrint('Temporary scan error: $e');
  }
}
  
// =====================================================
// START SELECTED SCAN
// =====================================================

Future<void> _startSelectedScan(
  String area,
) async {
  setState(() {
    selectedArea = area;
  });

  if (realObjectMode) {
    await _openCameraScanner();
  } else {
    await _pickFromPhone();
  }
}

// =====================================================
// PICK FROM PHONE
// =====================================================
  
 Future<void> _pickFromPhone() async {
  try {
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked == null) {
      return;
    }

    // ใช้รูปจากแกลเลอรี่ชั่วคราวเท่านั้น
    // ไม่บันทึกสำเนารูปเข้าแอป

    if (!mounted) return;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('นำเข้ารูปสำเร็จ'),
          content: const Text(
            'ระบบได้รับรูปเพื่อใช้วิเคราะห์ชั่วคราว\n\n'
            'ยังไม่มีการบันทึกรูปภาพเข้าแอป',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('บันทึกข้อมูลการสแกน'),
            ),
          ],
        );
      },
    );

    if (save == true) {
      await _saveScan('นำเข้าจากโทรศัพท์');
    }
  } catch (e) {
    _showMessage(
      'นำเข้ารูปไม่สำเร็จ: $e',
    );
  }
}

  // =====================================================
  // SAVE SCAN DATA
  // =====================================================

  Future<void> _saveScan(
    String method,
  ) async {
    final scanNumber =
        widget.item.scans
                .where(
                  (scan) =>
                      scan.area ==
                      selectedArea,
                )
                .length +
            1;

    final scan = ScanData(
      area: selectedArea,
      scanNumber: scanNumber,
      method: method,
      details: {
        'analysisStatus':
            'รอระบบวิเคราะห์',
        'imageSaved':
            false,
        'temporaryOnly':
            true,
        'sourceArea':
            selectedArea,
      },
    );

    widget.item.scans.add(scan);

    final items = await loadAllItems();

    final index = items.indexWhere(
      (element) =>
          element.id == widget.item.id,
    );

    if (index != -1) {
      items[index] = widget.item;
      await saveAllItems(items);
    }

    final oldArea = selectedArea;

    if (autoNextArea) {
      final areas = _allAreas();

      final currentIndex =
          areas.indexOf(selectedArea);

      if (currentIndex >= 0 &&
          currentIndex <
              areas.length - 1) {
        selectedArea =
            areas[currentIndex + 1];
      }
    }

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'บันทึกข้อมูล $oldArea '
          '• สแกนครั้งที่ $scanNumber แล้ว',
        ),
      ),
    );
  }

  // =====================================================
  // AREAS
  // =====================================================

  List<String> _allAreas() {
    final areas = [
      ...defaultAreas,
    ];

    final customAreas = widget.item.scans
        .map((scan) => scan.area)
        .where(
          (area) =>
              !defaultAreas.contains(area),
        )
        .toSet()
        .toList();

    areas.addAll(customAreas);

    return areas;
  }

  int _scanCount(String area) {
    return widget.item.scans
        .where(
          (scan) => scan.area == area,
        )
        .length;
  }

  // =====================================================
  // ADD CUSTOM AREA
  // =====================================================

  Future<void> _addCustomArea() async {
    final controller =
        TextEditingController();

    final result =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'เพิ่มหมวดพื้นที่',
          ),
          content: TextField(
            controller: controller,
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
                Navigator.pop(context);
              },
              child:
                  const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(
                    context,
                    value,
                  );
                }
              },
              child: const Text('เพิ่ม'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null ||
        result.isEmpty) {
      return;
    }

    setState(() {
      selectedArea = result;
    });
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final areas = _allAreas();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'สแกนเพิ่มข้อมูล',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -------------------------------------------------
          // ITEM NUMBER
          // -------------------------------------------------

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Text(
                'องค์จริงลำดับที่ '
                '${widget.item.realItemNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'เลือกวิธีนำเข้าข้อมูล แล้วเลือกพื้นที่ที่ต้องการสแกน',
            style: TextStyle(
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 18),

          // -------------------------------------------------
          // METHOD
          // -------------------------------------------------

          const Text(
            'วิธีสแกน',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: true,
                icon: Icon(
                  Icons.camera_alt,
                ),
                label: Text(
                  'สแกนองค์จริง',
                ),
              ),
              ButtonSegment<bool>(
                value: false,
                icon: Icon(
                  Icons.photo_library,
                ),
                label: Text(
                  'จากตัวเครื่อง',
                ),
              ),
            ],
            selected: {
              realObjectMode,
            },
            onSelectionChanged:
                (selection) {
              setState(() {
                realObjectMode =
                    selection.first;
              });
            },
          ),

          const SizedBox(height: 20),

          // -------------------------------------------------
          // CURRENT AREA
          // -------------------------------------------------

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'พื้นที่ที่เลือก',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedArea,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'สแกนแล้ว '
                    '${_scanCount(selectedArea)} ครั้ง',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // -------------------------------------------------
          // AREAS
          // -------------------------------------------------

          const Text(
            'พื้นที่สแกน',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          ...areas.map(
            (area) {
              final count =
                  _scanCount(area);

              final selected =
                  selectedArea == area;

              return Card(
                color: selected
                    ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                    : null,
                child: ListTile(
                  leading: Icon(
                    count > 0
                        ? Icons.check_circle
                        : Icons
                            .radio_button_unchecked,
                  ),
                  title: Text(
                    area,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    count == 0
                        ? 'ยังไม่ได้สแกน'
                        : 'สแกนแล้ว $count ครั้ง',
                  ),
                  trailing:
                      const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () {
                    _startSelectedScan(
                      area,
                    );
                  },
                ),
              );
            },
          ),

          // -------------------------------------------------
          // ADD AREA
          // -------------------------------------------------

          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.add),
              title: const Text(
                'เพิ่มหมวดเอง',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'สำหรับรายละเอียดเฉพาะของพระหรือเหรียญ',
              ),
              onTap:
                  _addCustomArea,
            ),
          ),

          // -------------------------------------------------
          // SCAN HISTORY
          // -------------------------------------------------

          if (showHistory) ...[
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ประวัติการสแกน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

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
                      (scan) {
                        return ListTile(
                          dense: true,
                          leading:
                              const Icon(
                            Icons
                                .check_circle_outline,
                          ),
                          title: Text(
                            '${scan.area} • '
                            'สแกน ${scan.scanNumber}',
                          ),
                          subtitle:
                              Text(
                            scan.method,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

                    


