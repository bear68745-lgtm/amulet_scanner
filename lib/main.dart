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
// ค่าพื้นฐาน
// =====================================================

const areas = [
'ด้านหน้า',
'ด้านหลัง',
'ด้านข้าง',
'ก้นพระ',
];

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
final int referenceNumber;
final DateTime createdAt;

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

Map<String, dynamic> toMap() {
return {
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
}

factory ReferenceData.fromMap(Map<String, dynamic> m) {
return ReferenceData(
id: m['id'] ?? '',
referenceNumber: (m['referenceNumber'] ?? 0).toInt(),
createdAt:
DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
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
noDataAreas: List<String>.from(
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

static Future<List<ReferenceData>> load() async {
final p = await SharedPreferences.getInstance();
final raw = p.getString(key);

if (raw == null || raw.isEmpty) {  
  return [];  
}  

// -----------------------------  
// โหลดข้อมูลแบบ gzip  
// -----------------------------  
try {  
  final data = jsonDecode(  
    utf8.decode(  
      gzip.decode(  
        base64Decode(raw),  
      ),  
    ),  
  );  

  if (data is List) {  
    return data  
        .map(  
          (x) => ReferenceData.fromMap(  
            Map<String, dynamic>.from(x),  
          ),  
        )  
        .toList();  
  }  
} catch (_) {}  

// -----------------------------  
// รองรับข้อมูลแบบ JSON เดิม  
// -----------------------------  
try {  
  final data = jsonDecode(raw);  

  if (data is List) {  
    final list = data  
        .map(  
          (x) => ReferenceData.fromMap(  
            Map<String, dynamic>.from(x),  
          ),  
        )  
        .toList();  

    await _write(list);  

    return list;  
  }  
} catch (_) {}  

return [];

}

// เพิ่มองค์อ้างอิงใหม่
static Future<void> save(ReferenceData item) async {
final list = await load();

list.add(item);  

await _write(list);

}

// แก้ไขข้อมูลของชื่อพระ + รุ่น
static Future<void> updateGroup(
String oldName,
String oldModel, {
required String newName,
required String newModel,
required String newPim,
required String newType,
required String newTemple,
}) async {
final list = await load();

for (int i = 0; i < list.length; i++) {  
  final x = list[i];  

  if (x.name == oldName && x.model == oldModel) {  
    list[i] = ReferenceData(  
      id: x.id,  
      referenceNumber: x.referenceNumber,  
      createdAt: x.createdAt,  
      name: newName,  
      model: newModel,  
      pim: newPim,  
      type: newType,  
      temple: newTemple,  
      scans: x.scans,  
      noDataAreas: x.noDataAreas,  
    );  
  }  
}  

await _write(list);

}

// ลบชื่อพระ + องค์อ้างอิง + ข้อมูลสแกนทั้งหมด
static Future<void> deleteGroup(
String name,
String model,
) async {
final list = await load();

list.removeWhere(  
  (x) => x.name == name && x.model == model,  
);  

await _write(list);

}

// ===================================================
// เลของค์อ้างอิง
//
// เพิ่มได้ไม่จำกัด
// เลขที่ใช้แล้วจะไม่ย้อนกลับมาใช้ใหม่
// ===================================================

static Future<int> nextReferenceNumber() async {
final p = await SharedPreferences.getInstance();

final next =  
    (p.getInt('last_reference_number') ?? 0) + 1;  

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

final text = jsonEncode(  
  list.map((x) => x.toMap()).toList(),  
);  

final encoded = base64Encode(  
  gzip.encode(  
    utf8.encode(text),  
  ),  
);  

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

class _HomePageState extends State<HomePage> {
List<ReferenceData> allData = [];

@override
void initState() {
super.initState();
loadData();
}

Future<void> loadData() async {
final data = await ReferenceStorage.load();

if (!mounted) return;  

setState(() {  
  allData = data;  
});

}

List<List<ReferenceData>> getGroups() {
final groups =
<String, List<ReferenceData>>{};

for (final x in allData) {  
  final key =  
      '${x.name}|||${x.model}';  

  groups.putIfAbsent(  
    key,  
    () => [],  
  ).add(x);  
}  

return groups.values.toList();

}

Future<void> open(Widget page) async {
await Navigator.push(
context,
MaterialPageRoute(
builder: (_) => page,
),
);

await loadData();

}

Future<void> editGroup(
List<ReferenceData> group,
) async {
if (group.isEmpty) return;

final x = group.first;  

await Navigator.push(  
  context,  
  MaterialPageRoute(  
    builder: (_) => EditReferencePage(  
      oldName: x.name,  
      oldModel: x.model,  
      name: x.name,  
      model: x.model,  
      pim: x.pim,  
      type: x.type,  
      temple: x.temple,  
    ),  
  ),  
);  

await loadData();

}

// ===================================================
// ลบชื่อพระ + ข้อมูลทั้งหมด
// ===================================================

Future<void> deleteGroup(
List<ReferenceData> group,
) async {
if (group.isEmpty) return;

final x = group.first;  

final ok = await showDialog<bool>(  
  context: context,  
  builder: (d) {  
    return AlertDialog(  
      title: const Text('ลบข้อมูล'),  
      content: Text(  
        'ต้องการลบรายการนี้ทั้งหมดหรือไม่?\n\n'  
        'ชื่อพระ: ${x.name}\n'  
        '${x.model.isEmpty ? '' : 'รุ่น: ${x.model}\n'}\n'  
        'การลบจะลบ:\n'  
        '• ชื่อพระ\n'  
        '• องค์อ้างอิงทั้งหมด\n'  
        '• ข้อมูลการสแกนทั้งหมด\n\n'  
        'ข้อมูลที่ลบแล้วจะไม่สามารถกู้คืนได้',  
      ),  
      actions: [  
        TextButton(  
          onPressed: () =>  
              Navigator.pop(d, false),  
          child: const Text('ยกเลิก'),  
        ),  
        ElevatedButton(  
          onPressed: () =>  
              Navigator.pop(d, true),  
          child: const Text('ลบ'),  
        ),  
      ],  
    );  
  },  
);  

if (ok != true) return;  

await ReferenceStorage.deleteGroup(  
  x.name,  
  x.model,  
);  

await loadData();  

if (!mounted) return;  

ScaffoldMessenger.of(context).showSnackBar(  
  const SnackBar(  
    content: Text(  
      'ลบชื่อพระและข้อมูลทั้งหมดแล้ว',  
    ),  
  ),  
);

}

@override
Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(16),  
      children: [  
        const SizedBox(height: 10),  

        const Text(  
          'ฐานข้อมูลส่วนตัว',  
          textAlign: TextAlign.center,  
          style: TextStyle(  
            fontSize: 24,  
            fontWeight: FontWeight.bold,  
          ),  
        ),  

        const SizedBox(height: 8),  

        Text(  
          'มีชื่อพระ ${groups.length} รายการ',  
          textAlign: TextAlign.center,  
          style: const TextStyle(  
            fontSize: 17,  
          ),  
        ),  

        const SizedBox(height: 20),  

        SizedBox(  
          width: double.infinity,  
          child: ElevatedButton.icon(  
            icon: const Icon(  
              Icons.add_circle,  
            ),  
            label: const Text(  
              'สร้าง / เพิ่มองค์อ้างอิง',  
              style: TextStyle(  
                fontSize: 16,  
              ),  
            ),  
            onPressed: () => open(  
              CreateReferencePage(  
                cameras: widget.cameras,  
              ),  
            ),  
          ),  
        ),  

        const SizedBox(height: 20),  

        if (groups.isEmpty)  
          const Card(  
            child: Padding(  
              padding: EdgeInsets.all(20),  
              child: Column(  
                children: [  
                  Icon(  
                    Icons.storage,  
                    size: 50,  
                  ),  
                  SizedBox(height: 10),  
                  Text(  
                    'ยังไม่มีข้อมูลพระ',  
                    style: TextStyle(  
                      fontSize: 18,  
                    ),  
                  ),  
                  SizedBox(height: 6),  
                  Text(  
                    'กดสร้าง / เพิ่มองค์อ้างอิง '  
                    'เพื่อเริ่มสร้างฐานข้อมูล',  
                    textAlign: TextAlign.center,  
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

Widget buildGroupCard(
List<ReferenceData> group,
) {
final x = group.first;

final scanCount = group.fold<int>(  
  0,  
  (sum, item) =>  
      sum + item.scans.length,  
);  

return Card(  
  margin: const EdgeInsets.only(  
    bottom: 12,  
  ),  
  child: Padding(  
    padding: const EdgeInsets.all(12),  
    child: Column(  
      children: [  
        InkWell(  
          onTap: () => open(  
            ReferenceListPage(  
              cameras: widget.cameras,  
              name: x.name,  
              model: x.model,  
            ),  
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

              const SizedBox(width: 12),  

              Expanded(  
                child: Column(  
                  crossAxisAlignment:  
                      CrossAxisAlignment.start,  
                  children: [  
                    Text(  
                      x.name.isEmpty  
                          ? 'ไม่ระบุชื่อพระ'  
                          : x.name,  
                      style: const TextStyle(  
                        fontSize: 19,  
                        fontWeight:  
                            FontWeight.bold,  
                      ),  
                    ),  

                    if (x.model.isNotEmpty)  
                      Text(  
                        'รุ่น: ${x.model}',  
                      ),  

                    const SizedBox(height: 4),  

                    Text(  
                      'มีองค์อ้างอิง '  
                      '${group.length} องค์',  
                    ),  

                    Text(  
                      'ข้อมูลสแกน '  
                      '$scanCount รายการ',  
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

        const Divider(),  

        Row(  
          children: [  
            Expanded(  
              child: OutlinedButton.icon(  
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

            const SizedBox(width: 10),  

            Expanded(  
              child: OutlinedButton.icon(  
                icon: const Icon(  
                  Icons.delete_outline,  
                ),  
                label: const Text(  
                  'ลบ',  
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
// รายการองค์อ้างอิง
// =====================================================

class ReferenceListPage
extends StatefulWidget {
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

final list = all  
    .where(  
      (x) =>  
          x.name == widget.name &&  
          x.model == widget.model,  
    )  
    .toList();  

list.sort(  
  (a, b) =>  
      a.referenceNumber.compareTo(  
    b.referenceNumber,  
  ),  
);  

if (!mounted) return;  

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
padding: const EdgeInsets.all(16),
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
style: const TextStyle(
fontSize: 22,
fontWeight:
FontWeight.bold,
),
),

if (widget.model.isNotEmpty)  
                  Text(  
                    'รุ่น: ${widget.model}',  
                    style:  
                        const TextStyle(  
                      fontSize: 16,  
                    ),  
                  ),  

                const SizedBox(height: 8),  

                Text(  
                  'มีองค์อ้างอิง '  
                  '${references.length} องค์',  
                ),  
              ],  
            ),  
          ),  
        ),  

        const SizedBox(height: 12),  

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

        for (final x in references)  
          buildReferenceCard(x),  
      ],  
    ),  
  ),  
);

}

Widget buildReferenceCard(
ReferenceData x,
) {
return Card(
margin:
const EdgeInsets.only(bottom: 12),
child: InkWell(
onTap: () async {
await Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
ReferenceDetailPage(
reference: x,
),
),
);

await loadReferences();  
    },  
    child: Padding(  
      padding:  
          const EdgeInsets.all(16),  
      child: Row(  
        children: [  
          CircleAvatar(  
            radius: 25,  
            child: Text(  
              '${x.referenceNumber}',  
              style:  
                  const TextStyle(  
                fontWeight:  
                    FontWeight.bold,  
              ),  
            ),  
          ),  

          const SizedBox(width: 14),  

          Expanded(  
            child: Column(  
              crossAxisAlignment:  
                  CrossAxisAlignment.start,  
              children: [  
                Text(  
                  'องค์อ้างอิงที่ '  
                  '${x.referenceNumber}',  
                  style:  
                      const TextStyle(  
                    fontSize: 18,  
                    fontWeight:  
                        FontWeight.bold,  
                  ),  
                ),  

                const SizedBox(height: 5),  

                Text(  
                  'ข้อมูลสแกน '  
                  '${x.scans.length} รายการ',  
                ),  

                if (x.noDataAreas  
                    .isNotEmpty)  
                  Text(  
                    'ข้าม ${x.noDataAreas.length} ด้าน',  
                    style:  
                        const TextStyle(  
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
padding: const EdgeInsets.all(16),
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
style: const TextStyle(
fontSize: 22,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 12),  

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

      const SizedBox(height: 12),  

      const Text(  
        'ข้อมูลจากการสแกน',  
        style: TextStyle(  
          fontSize: 20,  
          fontWeight:  
              FontWeight.bold,  
        ),  
      ),  

      const SizedBox(height: 8),  

      for (final scan  
          in reference.scans)  
        Card(  
          child: ListTile(  
            leading: const Icon(  
              Icons.camera_alt,  
            ),  
            title: Text(scan.area),  
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

      if (reference.noDataAreas  
          .isNotEmpty) ...[  
        const SizedBox(height: 12),  

        const Text(  
          'ด้านที่ไม่ได้เก็บข้อมูล',  
          style: TextStyle(  
            fontSize: 20,  
            fontWeight:  
                FontWeight.bold,  
          ),  
        ),  

        const SizedBox(height: 8),  

        Card(  
          child: Padding(  
            padding:  
                const EdgeInsets.all(16),  
            child: Text(  
              reference.noDataAreas  
                  .join('\n'),  
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
return Padding(
padding:
const EdgeInsets.only(bottom: 6),
child: Text(
'$title: '
'${value.isEmpty ? "-" : value}',
),
);
}
}

// =====================================================
// สร้างข้อมูล
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
      content:  
          Text('กรุณาใส่ชื่อพระ'),  
    ),  
  );  
  return;  
}  

if (selectedType == null) {  
  ScaffoldMessenger.of(context)  
      .showSnackBar(  
    const SnackBar(  
      content:  
          Text('กรุณาเลือกประเภท'),  
    ),  
  );  
  return;  
}  

await Navigator.push(  
  context,  
  MaterialPageRoute(  
    builder: (_) => ScanPage(  
      cameras: widget.cameras,  
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
title: const Text(
'สร้าง / เพิ่มองค์อ้างอิง',
),
),
body: ListView(
padding: const EdgeInsets.all(16),
children: [
const Text(
'ข้อมูลหลัก',
style: TextStyle(
fontSize: 21,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 12),  

      field(  
        nameController,  
        'ชื่อพระ',  
      ),  

      field(  
        modelController,  
        'รุ่น',  
      ),  

      field(  
        pimController,  
        'พิมพ์',  
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
              (x) =>  
                  DropdownMenuItem<  
                      String>(  
                value: x,  
                child: Text(x),  
              ),  
            )  
            .toList(),  
        onChanged: (value) {  
          setState(() {  
            selectedType = value;  
          });  
        },  
      ),  

      const SizedBox(height: 12),  

      field(  
        templeController,  
        'วัด',  
      ),  

      const SizedBox(height: 20),  

      SizedBox(  
        width: double.infinity,  
        child: ElevatedButton.icon(  
          icon: const Icon(  
            Icons.camera_alt,  
          ),  
          label: const Text(  
            'ไปสแกนองค์อ้างอิง',  
            style: TextStyle(  
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

Widget field(
TextEditingController controller,
String label,
) {
return Padding(
padding:
const EdgeInsets.only(bottom: 12),
child: TextField(
controller: controller,
decoration:
InputDecoration(
labelText: label,
border:
const OutlineInputBorder(),
),
),
);
}
}

// =====================================================
// แก้ไขข้อมูล
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
late final TextEditingController
nameController;

late final TextEditingController
modelController;

late final TextEditingController
pimController;

late final TextEditingController
templeController;

String? selectedType;

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

selectedType =  
    types.contains(widget.type)  
        ? widget.type  
        : null;

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

if (name.isEmpty) {  
  ScaffoldMessenger.of(context)  
      .showSnackBar(  
    const SnackBar(  
      content:  
          Text('กรุณาใส่ชื่อพระ'),  
    ),  
  );  
  return;  
}  

if (selectedType == null) {  
  ScaffoldMessenger.of(context)  
      .showSnackBar(  
    const SnackBar(  
      content:  
          Text('กรุณาเลือกประเภท'),  
    ),  
  );  
  return;  
}  

await ReferenceStorage.updateGroup(  
  widget.oldName,  
  widget.oldModel,  
  newName: name,  
  newModel:  
      modelController.text.trim(),  
  newPim:  
      pimController.text.trim(),  
  newType: selectedType!,  
  newTemple:  
      templeController.text.trim(),  
);  

if (!mounted) return;  

Navigator.pop(context);

}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title:
const Text('แก้ไขข้อมูล'),
),
body: ListView(
padding:
const EdgeInsets.all(16),
children: [
field(
nameController,
'ชื่อพระ',
),

field(  
        modelController,  
        'รุ่น',  
      ),  

      field(  
        pimController,  
        'พิมพ์',  
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
              (x) =>  
                  DropdownMenuItem<  
                      String>(  
                value: x,  
                child: Text(x),  
              ),  
            )  
            .toList(),  
        onChanged: (value) {  
          setState(() {  
            selectedType = value;  
          });  
        },  
      ),  

      const SizedBox(height: 12),  

      field(  
        templeController,  
        'วัด',  
      ),  

      const SizedBox(height: 20),  

      SizedBox(  
        width: double.infinity,  
        child: ElevatedButton.icon(  
          icon:  
              const Icon(Icons.save),  
          label: const Text(  
            'บันทึกการแก้ไข',  
          ),  
          onPressed: save,  
        ),  
      ),  
    ],  
  ),  
);

}

Widget field(
TextEditingController controller,
String label,
) {
return Padding(
padding:
const EdgeInsets.only(bottom: 12),
child: TextField(
controller: controller,
decoration:
InputDecoration(
labelText: label,
border:
const OutlineInputBorder(),
),
),
);
}
}

// =====================================================
// SCAN PAGE
//
// ระบบใหม่:
//
// 1. เลือกด้านเอง
// 2. ถ่ายภาพ หรือ เลือกรูป
// 3. บันทึกข้อมูลด้านนั้นทันที
// 4. เปลี่ยนด้านเองได้
// 5. ไม่ต้องสแกนครบ 4 ด้าน
// 6. กดออกเมื่อไรก็ได้
// 7. ออกแล้วบันทึกองค์อ้างอิงอัตโนมัติ
//
// รูปภาพไม่ได้ถูกนำไปเก็บในฐานข้อมูล
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

final ImagePicker picker =
ImagePicker();

// ด้านที่ผู้ใช้กำลังเลือก
int currentArea = 0;

// ข้อมูลที่สแกนแล้ว
final Map<String, ScanResult>
results = {};

// ด้านที่ผู้ใช้เลือกข้าม
final Set<String> noDataAreas = {};

bool loadingCamera = true;
bool saving = false;

@override
void initState() {
super.initState();
startCamera();
}

// ===================================================
// เปิดกล้อง
// ===================================================

Future<void> startCamera() async {
if (widget.cameras.isEmpty) {
setState(() {
loadingCamera = false;
});
return;
}

final camera =  
    widget.cameras.firstWhere(  
  (x) =>  
      x.lensDirection ==  
      CameraLensDirection.back,  
  orElse: () =>  
      widget.cameras.first,  
);  

final newController =  
    CameraController(  
  camera,  
  ResolutionPreset.medium,  
  enableAudio: false,  
);  

controller = newController;  

try {  
  await newController.initialize();  

  if (!mounted) return;  

  setState(() {  
    loadingCamera = false;  
  });  
} catch (_) {  
  if (!mounted) return;  

  setState(() {  
    loadingCamera = false;  
  });  
}

}

// ===================================================
// เลือกด้าน
// ===================================================

void selectArea(int index) {
if (saving) return;

setState(() {  
  currentArea = index;  
});

}

// ===================================================
// ถ่ายภาพ
//
// ภาพใช้เป็นข้อมูลชั่วคราว
// ไม่ถูกเก็บลงฐานข้อมูล
// ===================================================

Future<void> takePhoto() async {
if (saving) return;

final c = controller;  

if (c == null ||  
    !c.value.isInitialized ||  
    c.value.isTakingPicture) {  
  return;  
}  

try {  
  final image =  
      await c.takePicture();  

  await saveScanResult(  
    fromGallery: false,  
  );  

  // image เป็นไฟล์ชั่วคราวจาก camera  
  // เราไม่ได้เก็บ path หรือบันทึกลงฐานข้อมูล  
  image.path;  
} catch (_) {  
  if (!mounted) return;  

  ScaffoldMessenger.of(context)  
      .showSnackBar(  
    const SnackBar(  
      content:  
          Text('ถ่ายภาพไม่สำเร็จ'),  
    ),  
  );  
}

}

// ===================================================
// เลือกรูปจากเครื่อง
// ===================================================

Future<void> chooseGallery() async {
if (saving) return;

try {  
  final image =  
      await picker.pickImage(  
    source: ImageSource.gallery,  
  );  

  if (image == null) return;  

  await saveScanResult(  
    fromGallery: true,  
  );  

  // ไม่คัดลอกรูปเข้าแอป  
  // ไม่เก็บ path ของรูป  
  image.path;  
} catch (_) {  
  if (!mounted) return;  

  ScaffoldMessenger.of(context)  
      .showSnackBar(  
    const SnackBar(  
      content:  
          Text('เลือกรูปไม่สำเร็จ'),  
    ),  
  );  
}

}

// ===================================================
// บันทึกข้อมูลของด้านที่เลือก
//
// ตอนนี้ยังเป็นข้อมูลโครงสร้างสำหรับ AI
// ภายหลังสามารถนำระบบวิเคราะห์จริงมาใส่ตรงนี้
// ===================================================

Future<void> saveScanResult({
required bool fromGallery,
}) async {
final area = areas[currentArea];

final result = ScanResult(  
  area: area,  
  brightness: 0,  
  sharpness: 0,  
  quality:  
      'พร้อมสำหรับเก็บข้อมูลอ้างอิง',  
  details:  
      'รอระบบ AI วิเคราะห์รายละเอียดทั้งหมดที่มองเห็นในองค์พระ',  
  fromGallery: fromGallery,  
);  

if (!mounted) return;  

setState(() {  
  results[area] = result;  
  noDataAreas.remove(area);  
});  

ScaffoldMessenger.of(context)  
    .showSnackBar(  
  SnackBar(  
    duration:  
        const Duration(seconds: 1),  
    content: Text(  
      'บันทึกข้อมูล $area แล้ว',  
    ),  
  ),  
);

}

// ===================================================
// ข้ามด้าน
// ===================================================

void skipCurrentArea() {
final area = areas[currentArea];

setState(() {  
  results.remove(area);  
  noDataAreas.add(area);  
});  

ScaffoldMessenger.of(context)  
    .showSnackBar(  
  SnackBar(  
    duration:  
        const Duration(seconds: 1),  
    content: Text(  
      'ข้าม $area',  
    ),  
  ),  
);

}

// ===================================================
// ออกจากการสแกน
//
// ระบบจะบันทึกข้อมูลที่สแกนไว้ให้อัตโนมัติ
// ===================================================

Future<void> exitScan() async {
if (saving) return;

if (results.isEmpty) {  
  if (!mounted) return;  

  final leave =  
      await showDialog<bool>(  
    context: context,  
    builder: (d) {  
      return AlertDialog(  
        title:  
            const Text(  
          'ออกจากการสแกน',  
        ),  
        content:  
            const Text(  
          'ยังไม่มีข้อมูลสแกน\n'  
          'ต้องการออกโดยไม่สร้างองค์อ้างอิงหรือไม่?',  
        ),  
        actions: [  
          TextButton(  
            onPressed: () =>  
                Navigator.pop(  
              d,  
              false,  
            ),  
            child:  
                const Text('อยู่ต่อ'),  
          ),  
          ElevatedButton(  
            onPressed: () =>  
                Navigator.pop(  
              d,  
              true,  
            ),  
            child:  
                const Text('ออก'),  
          ),  
        ],  
      );  
    },  
  );  

  if (leave == true &&  
      mounted) {  
    Navigator.pop(context);  
  }  

  return;  
}  

await saveReference();

}

// ===================================================
// สร้างองค์อ้างอิง
// ===================================================

Future<void> saveReference() async {
if (saving) return;

if (results.isEmpty) {  
  return;  
}  

setState(() {  
  saving = true;  
});  

try {  
  // เลขเพิ่มได้ไม่จำกัด  
  final number =  
      await ReferenceStorage  
          .nextReferenceNumber();  

  final item = ReferenceData(  
    id: DateTime.now()  
        .microsecondsSinceEpoch  
        .toString(),  
    referenceNumber: number,  
    createdAt: DateTime.now(),  
    name: widget.name,  
    model: widget.model,  
    pim: widget.pim,  
    type: widget.type,  
    temple: widget.temple,  
    scans:  
        results.values.toList(),  
    noDataAreas:  
        noDataAreas.toList(),  
  );  

  await ReferenceStorage.save(  
    item,  
  );  

  if (!mounted) return;  

  Navigator.pop(context);  

  ScaffoldMessenger.of(context)  
      .showSnackBar(  
    SnackBar(  
      content: Text(  
        'บันทึกองค์อ้างอิงที่ '  
        '$number แล้ว',  
      ),  
    ),  
  );  
} catch (_) {  
  if (!mounted) return;  

  setState(() {  
    saving = false;  
  });  

  ScaffoldMessenger.of(context)  
      .showSnackBar(  
    const SnackBar(  
      content:  
          Text('บันทึกข้อมูลไม่สำเร็จ'),  
    ),  
  );  
}

}

// ===================================================
// ปุ่มแสดงสถานะของแต่ละด้าน
// ===================================================

Widget areaButton(int index) {
final area = areas[index];

final hasData =  
    results.containsKey(area);  

final skipped =  
    noDataAreas.contains(area);  

final selected =  
    currentArea == index;  

String text = area;  

if (hasData) {  
  text = '$area ✓';  
} else if (skipped) {  
  text = '$area -';  
}  

return Expanded(  
  child: Padding(  
    padding:  
        const EdgeInsets.symmetric(  
      horizontal: 3,  
    ),  
    child: OutlinedButton(  
      style:  
          OutlinedButton.styleFrom(  
        padding:  
            const EdgeInsets.symmetric(  
          vertical: 10,  
        ),  
        side: BorderSide(  
          width: selected ? 2 : 1,  
        ),  
      ),  
      onPressed: () =>  
          selectArea(index),  
      child: Text(  
        text,  
        textAlign: TextAlign.center,  
        style: TextStyle(  
          fontWeight: selected  
              ? FontWeight.bold  
              : FontWeight.normal,  
        ),  
      ),  
    ),  
  ),  
);

}

// ===================================================
// หน้าจอ
// ===================================================

@override
Widget build(BuildContext context) {
final initialized =
controller
?.value
.isInitialized ??
false;

return PopScope(  
  canPop: false,  
  onPopInvokedWithResult:  
      (didPop, result) {  
    if (didPop) return;  
    exitScan();  
  },  
  child: Scaffold(  
    appBar: AppBar(  
      title: const Text(  
        'สแกนองค์อ้างอิง',  
      ),  
      actions: [  
        TextButton.icon(  
          onPressed:  
              saving  
                  ? null  
                  : exitScan,  
          icon: const Icon(  
            Icons.exit_to_app,  
          ),  
          label:  
              const Text('ออก'),  
        ),  
      ],  
    ),  

    body: Column(  
      children: [  
        // =========================================  
        // เลือกด้าน  
        // =========================================  

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
              areaButton(0),  
              areaButton(1),  
              areaButton(2),  
              areaButton(3),  
            ],  
          ),  
        ),  

        Padding(  
          padding:  
              const EdgeInsets.only(  
            bottom: 6,  
          ),  
          child: Text(  
            'กำลังเลือก: '  
            '${areas[currentArea]}',  
            style:  
                const TextStyle(  
              fontWeight:  
                  FontWeight.bold,  
            ),  
          ),  
        ),  

        // =========================================  
        // กล้อง  
        // =========================================  

        Expanded(  
          child: initialized  
              ? Stack(  
                  fit: StackFit.expand,  
                  children: [  
                    CameraPreview(  
                      controller!,  
                    ),  

                    Center(  
                      child: Container(  
                        width: 260,  
                        height: 320,  
                        decoration:  
                            BoxDecoration(  
                          border:  
                              Border.all(  
                            color:  
                                Colors.white,  
                            width: 2,  
                          ),  
                          borderRadius:  
                              BorderRadius  
                                  .circular(  
                            12,  
                          ),  
                        ),  
                      ),  
                    ),  

                    Positioned(  
                      top: 12,  
                      left: 12,  
                      right: 12,  
                      child: Card(  
                        color: Colors  
                            .black  
                            .withOpacity(  
                          .60,  
                        ),  
                        child:  
                            Padding(  
                          padding:  
                              const EdgeInsets  
                                  .all(  
                            10,  
                          ),  
                          child: Text(  
                            areas[  
                                currentArea],  
                            textAlign:  
                                TextAlign  
                                    .center,  
                            style:  
                                const TextStyle(  
                              color: Colors  
                                  .white,  
                              fontSize: 18,  
                              fontWeight:  
                                  FontWeight  
                                      .bold,  
                            ),  
                          ),  
                        ),  
                      ),  
                    ),  
                  ],  
                )  
              : loadingCamera  
                  ? const Center(  
                      child:  
                          CircularProgressIndicator(),  
                    )  
                  : const Center(  
                      child: Text(  
                        'ไม่สามารถเปิดกล้องได้',  
                      ),  
                    ),  
        ),  

        // =========================================  
        // ปุ่มควบคุม  
        // =========================================  

        SafeArea(  
          top: false,  
          child: Padding(  
            padding:  
                const EdgeInsets.all(  
              10,  
            ),  
            child: Column(  
              children: [  
                Row(  
                  children: [  
                    Expanded(  
                      child:  
                          ElevatedButton.icon(  
                        icon:  
                            const Icon(  
                          Icons  
                              .camera_alt,  
                        ),  
                        label:  
                            const Text(  
                          'ถ่ายภาพ',  
                        ),  
                        onPressed:  
                            initialized &&  
                                    !saving  
                                ? takePhoto  
                                : null,  
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
                          Icons  
                              .photo_library,  
                        ),  
                        label:  
                            const Text(  
                          'เลือกรูป',  
                        ),  
                        onPressed:  
                            saving  
                                ? null  
                                : chooseGallery,  
                      ),  
                    ),  
                  ],  
                ),  

                const SizedBox(  
                  height: 6,  
                ),  

                Row(  
                  children: [  
                    Expanded(  
                      child:  
                          OutlinedButton(  
                        onPressed:  
                            saving  
                                ? null  
                                : skipCurrentArea,  
                        child:  
                            const Text(  
                          'ข้ามด้านนี้',  
                        ),  
                      ),  
                    ),  

                    const SizedBox(  
                      width: 8,  
                    ),  

                    Expanded(  
                      child:  
                          TextButton(  
                        onPressed:  
                            saving  
                                ? null  
                                : exitScan,  
                        child:  
                            const Text(  
                          'ออกและบันทึก',  
                        ),  
                      ),  
                    ),  
                  ],  
                ),  

                const SizedBox(  
                  height: 4,  
                ),  

                Text(  
                  'บันทึกแล้ว '  
                  '${results.length} / ${areas.length} ด้าน',  
                  style:  
                      const TextStyle(  
                    fontSize: 13,  
                  ),  
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

@override
void dispose() {
controller?.dispose();
super.dispose();
}
}
ลืมอะไรหรือปล่าว
