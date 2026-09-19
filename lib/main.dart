import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main()async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AmuletScannerApp(cameras:await availableCameras()));
}

const dataKey='amulet_data_gz',oldDataKey='amulet_data';

const amuletTypes=[
  'เหรียญ','เหรียญหล่อ','พระสมเด็จ','รูปหล่อ','พระกริ่ง',
  'พระปิดตาเนื้อผง/หว้าน','พระปิดตาเนื้อโลหะ','พระเนื้อผง',
  'พระเนื้อดิน','นางพญา','ผงสุพรรณ','พระรอด','พระซุ้มกอ',
  'พระขุนแผน','หลวงปู่ทวดเนื้อหว้าน','หลวงปู่ทวดหลังเตารีด','อื่น ๆ'
];

const scanAreas=['ด้านหน้า','ด้านหลัง','ด้านข้าง','ก้นพระ'];

const _aiFront='front_pattern',
    _aiBack='back_pattern',
    _aiSideBottom='side_bottom_pattern',
    _aiDetails='detail_confirmation',
    _aiComplete='comparison_complete';

String aiStageName(String s){
  switch(s){
    case _aiFront:return 'วิเคราะห์รายละเอียดด้านหน้า';
    case _aiBack:return 'วิเคราะห์รายละเอียดด้านหลัง';
    case _aiSideBottom:return 'วิเคราะห์ด้านข้าง / ก้นพระ';
    case _aiDetails:return 'วิเคราะห์รายละเอียดทั้งหมด';
    case _aiComplete:return 'เปรียบเทียบครบทุกขั้น';
    default:return 'ยังไม่ทราบขั้นตอน';
  }
}

String stageForArea(String a){
  switch(a){
    case 'ด้านหน้า':return _aiFront;
    case 'ด้านหลัง':return _aiBack;
    case 'ด้านข้าง':
    case 'ก้นพระ':return _aiSideBottom;
    default:return _aiDetails;
  }
}

String nextStage(String s){
  switch(s){
    case _aiFront:return _aiBack;
    case _aiBack:return _aiSideBottom;
    case _aiSideBottom:return _aiDetails;
    case _aiDetails:return _aiComplete;
    default:return _aiComplete;
  }
}

Map<String,dynamic> aiComparisonRule()=> {
  'enabled':true,
  'referenceScope':'all_references',
  'compareEveryAvailableReference':true,
  'flow':[
    {'stage':_aiFront,'name':'ด้านหน้า'},
    {'stage':_aiBack,'name':'ด้านหลัง'},
    {'stage':_aiSideBottom,'name':'ด้านข้าง / ก้นพระ'},
    {'stage':_aiDetails,'name':'รายละเอียดทั้งหมด'}
  ],
  'wearRule':{
    'enabled':true,
    'separateFromOriginalPattern':true
  },
  'visibilityRule':{
    'ifNotVisible':'ตรวจสอบไม่ได้ / ภาพไม่ละเอียดพอ',
    'doNotInterpretAs':'ไม่มีรายละเอียด'
  },
  'fixedObservationPoints':false
};

Future<SharedPreferences> prefs()=>SharedPreferences.getInstance();

void msg(BuildContext c,String s)=>ScaffoldMessenger.of(c).showSnackBar(
  SnackBar(content:Text(s))
);

Future<dynamic> go(BuildContext c,Widget p)=>Navigator.push(
  c,MaterialPageRoute(builder:(_)=>p)
);

String groupKey(AmuletData e)=>
    '${e.name.trim().toLowerCase()}|||${e.model.trim().toLowerCase()}';

int newId()=>DateTime.now().microsecondsSinceEpoch;

Future<List<AmuletData>> loadAllItems()async{
  final p=await prefs();
  try{
    final z=p.getString(dataKey);
    if(z!=null&&z.isNotEmpty){
      final list=jsonDecode(
        utf8.decode(gzip.decode(base64Decode(z)))
      )as List;
      return list.map((e)=>AmuletData.fromMap(
        Map<String,dynamic>.from(e)
      )).toList();
    }
  }catch(_){}

  try{
    final old=p.getString(oldDataKey);
    if(old!=null&&old.isNotEmpty){
      final list=jsonDecode(old)as List;
      final items=list.map((e)=>AmuletData.fromMap(
        Map<String,dynamic>.from(e)
      )).toList();
      await saveAllItems(items);
      return items;
    }
  }catch(_){}

  return [];
}

Future<void> saveAllItems(List<AmuletData> items)async{
  final p=await prefs();
  final z=base64Encode(gzip.encode(utf8.encode(
    jsonEncode(items.map((e)=>e.toMap()).toList())
  )));
  await p.setString(dataKey,z);
  await p.remove(oldDataKey);
}

/* ================= APP ================= */

class AmuletScannerApp extends StatelessWidget{
  final List<CameraDescription> cameras;
  const AmuletScannerApp({super.key,required this.cameras});

  @override
  Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'กล้องสแกนพระและเหรียญ',
    theme:ThemeData(useMaterial3:true),
    home:HomePage(cameras:cameras)
  );
}

/* ================= MODEL ================= */

class AmuletData{
  int id;
  String name,model,pim,type,temple;
  List<ScanData> scans;

  AmuletData({
    required this.id,
    this.name='',this.model='',this.pim='',
    this.type='',this.temple='',
    List<ScanData>? scans
  }):scans=scans??[];

  Map<String,dynamic> toMap()=> {
    'id':id,
    'name':name,
    'model':model,
    'pim':pim,
    'type':type,
    'temple':temple,
    'scans':scans.map((e)=>e.toMap()).toList()
  };

  factory AmuletData.fromMap(Map<String,dynamic> m)=>AmuletData(
    id:int.tryParse('${m['id']??0}')??0,
    name:'${m['name']??''}',
    model:'${m['model']??''}',
    pim:'${m['pim']??''}',
    type:'${m['type']??''}',
    temple:'${m['temple']??''}',
    scans:m['scans'] is List
      ?(m['scans'] as List).map((e)=>ScanData.fromMap(
          Map<String,dynamic>.from(e)
        )).toList()
      :[]
  );
}

class ScanData{
  String area,method;
  Map<String,dynamic> details;

  ScanData({
    required this.area,
    required this.method,
    Map<String,dynamic>? details
  }):details=details??{};

  Map<String,dynamic> toMap()=> {
    'area':area,
    'method':method,
    'details':details
  };

  factory ScanData.fromMap(Map<String,dynamic> m)=>ScanData(
    area:'${m['area']??''}',
    method:'${m['method']??''}',
    details:m['details'] is Map
      ?Map<String,dynamic>.from(m['details'])
      :{}
  );
}

/* ================= AI DATA ================= */

Map<String,dynamic> referenceModel()=> {
  'enabled':true,
  'available':false,
  'sourceType':'reference_data',
  'canCompareWithScan':true,
  'imagePixelsAreNotRealSize':true
};

Map<String,dynamic> toAiData(AmuletData e)=> {
  'recordType':'amulet_reference',
  'name':e.name,
  'model':e.model,
  'pim':e.pim,
  'type':e.type,
  'temple':e.temple,

  'aiObservationMode':'remember_all_visible_details',

  'aiInstruction':
    'วิเคราะห์และจดจำรายละเอียดทั้งหมดที่มองเห็นได้จากการสแกน '
    'โดยไม่จำกัดเฉพาะจุดที่กำหนดไว้ '
    'หากรายละเอียดไม่ชัดให้ระบุว่าตรวจสอบไม่ได้ '
    'ห้ามเดาว่าไม่มีรายละเอียด',

  'analysisFlow':aiComparisonRule(),

  'referenceComparison':{
    'enabled':true,
    'referenceScope':'all_references',
    'compareEveryAvailableReference':true,
    'result':null,
    'matches':[],
    'differences':[],
    'wearFromUse':[],
    'notVisible':[],
    'uncertain':[]
  },

  'scans':e.scans.map((s)=>s.toMap()).toList(),
  'referenceModel':referenceModel(),

  'aiContext':{
    'canReadScanHistory':true,
    'canRememberPreviousScan':true,
    'canAddAnalysis':true,
    'canCompareAreas':true,
    'canBuildReferenceModel':true,
    'compareAllReferences':true,
    'rememberAllVisibleDetails':true,
    'fixedObservationPoints':false,
    'wearMustBeSeparatedFromOriginalPattern':true,
    'notVisibleMeansCannotVerify':true,
    'doNotGuessMissingDetails':true,
    'smallDetailsNeedSufficientImageQuality':true,
    'imagePixelsAreNotRealSize':true
  }
};

/* ================= HOME ================= */

class HomePage extends StatelessWidget{
  final List<CameraDescription> cameras;
  const HomePage({super.key,required this.cameras});

  Widget tile(BuildContext c,String t,String s,IconData i,Widget p)=>Card(
    child:ListTile(
      leading:Icon(i,size:32),
      title:Text(t,style:const TextStyle(fontWeight:FontWeight.bold)),
      subtitle:Text(s),
      trailing:const Icon(Icons.chevron_right),
      onTap:()=>go(c,p)
    )
  );

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('กล้องสแกนพระและเหรียญ')),
    body:ListView(
      padding:const EdgeInsets.all(12),
      children:[
        tile(
          c,'สร้าง / บันทึกข้อมูล','สร้างข้อมูลพระและเหรียญ',
          Icons.add_box_outlined,const CreateDataPage()
        ),
        tile(
          c,'รายการข้อมูลที่บันทึก','ดู แก้ไข ลบ และสแกนเพิ่มข้อมูล',
          Icons.folder_open,SavedListPage(cameras:cameras)
        ),
        tile(
          c,'สำรอง / นำเข้าข้อมูล','สำรองหรือนำข้อมูลกลับเข้าเครื่อง',
          Icons.import_export,const BackupPage()
        ),
        tile(
          c,'ตั้งค่า','ตั้งค่าการสแกนและการแสดงข้อมูล',
          Icons.settings,const SettingsPage()
        )
      ]
    )
  );
}

/* ================= CREATE ================= */

class CreateDataPage extends StatefulWidget{
  const CreateDataPage({super.key});

  @override
  State<CreateDataPage> createState()=>_CreateDataPageState();
}
