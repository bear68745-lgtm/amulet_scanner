import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AmuletScannerApp(cameras: await availableCameras()));
}

const dataKey='amulet_data_gz',oldDataKey='amulet_data';
const nextRefKey='next_reference_number';

const amuletTypes=[
  'เหรียญ','เหรียญหล่อ','พระสมเด็จ','รูปหล่อ','พระกริ่ง',
  'พระปิดตาเนื้อผง/หว้าน','พระปิดตาเนื้อโลหะ','พระเนื้อผง',
  'พระเนื้อดิน','นางพญา','ผงสุพรรณ','พระรอด','พระซุ้มกอ',
  'พระขุนแผน','หลวงปู่ทวดเนื้อหว้าน','หลวงปู่ทวดหลังเตารีด','อื่น ๆ'
];

const scanAreas=['ด้านหน้า','ด้านหลัง','ด้านข้าง','ก้นพระ'];
const _comparePoint='ความผิดปกติที่ควรนำไปเปรียบเทียบกับองค์อ้างอิง';

const _commonPattern=[
  'รูปทรงองค์พระ','พิมพ์ทรง','สัดส่วนองค์พระ','องค์ประกอบขององค์พระ',
  'ใบหน้า / พระพักตร์','ฐาน','รายละเอียดพิมพ์','เส้นสายสำคัญ',
  'ตำแหน่งองค์ประกอบ'
];

const _commonDetail=[
  'ตำหนิเฉพาะพิมพ์','ลักษณะเนื้อ','มวลสาร','การกระจายตัวของมวลสาร',
  'เนื้อว่าน / ส่วนผสมพิเศษ','ลักษณะผิว','คราบธรรมชาติ','คราบกรุ',
  'การยุบตัวของเนื้อ','รอยแตกราน','ร่องรอยการกดพิมพ์',
  'ร่องรอยจากแม่พิมพ์','รอยตัดขอบ / รอยแต่ง','ร่องรอยการสร้าง'
];

final amuletPatternPoints=<String,List<String>>{
  'เหรียญ':[
    'รูปทรงและขนาดสัดส่วน','พิมพ์และรูปแบบเหรียญ','ใบหน้า / รูปเหมือน',
    'ตัวหนังสือ','ตัวเลข / ศักราช','ลวดลายและองค์ประกอบ',
    'เส้นขอบเหรียญ','หูเหรียญ','ขอบตัด'
  ],
  'เหรียญหล่อ':[
    'รูปทรงและสัดส่วน','พิมพ์และรูปแบบ','ใบหน้า / รูปเหมือน',
    'ตัวหนังสือ / อักขระ','ตัวเลข / ศักราช','ลวดลายและองค์ประกอบ',
    'เส้นขอบเหรียญ','ก้นพระ','โค้ดตอก','รอยประกบพิมพ์'
  ],
  'พระสมเด็จ':[
    'รูปทรงองค์พระ','พิมพ์ทรง','ความเอียงของพิมพ์','สัดส่วนองค์พระ',
    'ซุ้ม','พระเกศ','ใบหน้า / พระพักตร์','องค์ประกอบขององค์พระ',
    'ฐาน','รายละเอียดพิมพ์','เส้นสายสำคัญ'
  ],
  'รูปหล่อ':[
    'รูปทรงและสัดส่วน','พิมพ์และรูปแบบ','ใบหน้า / รูปเหมือน',
    'ตัวหนังสือ / อักขระ','ตัวเลข / ศักราช','ลวดลายและองค์ประกอบ',
    'ก้นพระ','โค้ดตอก','รอยประกบพิมพ์'
  ],
  'พระกริ่ง':[
    'รูปทรงและสัดส่วน','พิมพ์และรูปแบบ','ใบหน้า / รูปเหมือน',
    'เม็ดพระศก','ตัวหนังสือ / อักขระ','ตัวเลข / ศักราช',
    'ลวดลายและองค์ประกอบ','ก้นพระ','โค้ดตอก','รอยประกบพิมพ์'
  ],
  'พระปิดตาเนื้อผง/หว้าน':[
    'รูปทรงองค์พระ','พิมพ์ทรง','มือ/แขน','ใบหน้า','ฐาน',
    'รายละเอียดพิมพ์','ยันต์/อักขระ','ตัวหนังสือ','ตัวเลข','ขอบ'
  ],
  'พระปิดตาเนื้อโลหะ':[
    'รูปทรงและสัดส่วน','พิมพ์และรูปแบบ','ใบหน้า / รูปเหมือน',
    'ตัวหนังสือ / อักขระ','ตัวเลข / ศักราช','ลวดลายและองค์ประกอบ',
    'ก้นพระ','โค้ดตอก','รอยประกบพิมพ์'
  ],
  'พระขุนแผน':[
    'รูปทรงองค์พระ','พิมพ์ทรง','องค์พระ','รายละเอียดใบหน้า',
    'แขน/มือ','ฐาน','ลวดลาย','รายละเอียดเฉพาะพิมพ์'
  ],
  'หลวงปู่ทวดเนื้อหว้าน':[
    'รูปทรงองค์พระ','องค์พระ','ใบหน้า','พิมพ์ทรง',
    'รายละเอียดพิมพ์','ฐาน','ตำแหน่งองค์ประกอบ'
  ],
  'หลวงปู่ทวดหลังเตารีด':[
    'รูปทรงและสัดส่วน','พิมพ์และรูปแบบ','ใบหน้า / รูปเหมือน',
    'ตัวหนังสือ / อักขระ','ตัวเลข / ศักราช','ลวดลายและองค์ประกอบ',
    'ก้นพระ','โค้ดตอก','รอยประกบพิมพ์','รอยปั้ม / รอยพิมพ์',
    'ร่องรอยการปั้มซ้ำหลังการหล่อ'
  ],
  'อื่น ๆ':[
    'รูปทรงองค์พระ','พิมพ์ทรง','รายละเอียดองค์พระ',
    'ลวดลาย','ขอบ','รายละเอียดเฉพาะรุ่น'
  ],
};

const _commonClayPattern=[
  'รูปทรงองค์พระ','พิมพ์ทรง','สัดส่วนองค์พระ',
  'ใบหน้า / พระพักตร์','องค์ประกอบขององค์พระ','ฐาน',
  'รายละเอียดพิมพ์','เส้นสายสำคัญ'
];

List<String> patternPointsFor(String type)=>
    amuletPatternPoints[type]??_commonClayPattern;

List<String> detailPointsFor(String type){
  switch(type){
    case 'เหรียญ':
      return [
        'ตำหนิเฉพาะพิมพ์','รอยตะไบ','รอยแต่งขอบ','รอยปั๊ม / รอยพิมพ์',
        'โค้ด / ตอกโค้ด','ผิวโลหะและคราบธรรมชาติ','ผิว','เนื้อโลหะ',
        'ร่องรอยการสร้าง','ลักษณะเฉพาะของเหรียญรุ่นนั้น'
      ];
    case 'เหรียญหล่อ':
    case 'รูปหล่อ':
    case 'พระกริ่ง':
    case 'พระปิดตาเนื้อโลหะ':
    case 'หลวงปู่ทวดหลังเตารีด':
      return [
        'ตำหนิเฉพาะพิมพ์','รอยตะไบ','รอยแต่งขอบ','รอยเทหล่อ',
        'รอยชนวน / รอยตัดชนวน','รอยยุบ / รอยพรุนจากการหล่อ',
        'ผิวโลหะและคราบธรรมชาติ','ผิว','เส้นหล่อ / ร่องรอยการสร้าง',
        'เนื้อโลหะ'
      ];
    case 'พระสมเด็จ':
      return [
        ..._commonDetail,
        'ตรายาง'
      ];
    case 'พระปิดตาเนื้อผง/หว้าน':
      return [
        'ลักษณะเนื้อ','ลักษณะผิว','มวลสาร/การกระจายตัวของมวลสาร',
        'ร่องรอยการกดพิมพ์','รอยตัดแต่ง','คราบหว่าน',
        'ตำหนิเฉพาะพิมพ์','ร่องรอยจากแม่พิมพ์'
      ];
    case 'พระขุนแผน':
      return ['เนื้อ','ผิว','คราบกรุ','รอยตำหนิ','ร่องรอยการสร้าง'];
    case 'หลวงปู่ทวดเนื้อหว้าน':
      return [
        'เนื้อหว่าน','มวลสาร','การกระจายตัวของมวลสาร','ผิว',
        'คราบกรุ','คราบหว่าน','รอยตัดขอบ','ร่องรอยการกดพิมพ์',
        'ร่องรอยจากแม่พิมพ์','ตำหนิเฉพาะพิมพ์'
      ];
    case 'ผงสุพรรณ':
      return [
        ..._commonDetail,
        'กระรอก','รอยนิ้วมือด้านหลัง'
      ];
    case 'พระรอด':
      return [
        ..._commonDetail,
        'รอยนิ้วมือด้านหลัง'
      ];
    case 'อื่น ๆ':
      return ['เนื้อ','ผิว','รอยตำหนิ','ร่องรอยการสร้าง'];
    default:
      return _commonDetail;
  }
}

List<String> observationPointsFor(String type)=>[
  ...patternPointsFor(type),
  ...detailPointsFor(type),
  _comparePoint
];

/* ================= AI FLOW ================= */

const _aiFront='front_pattern';
const _aiBack='back_pattern';
const _aiSideBottom='side_bottom_pattern';
const _aiDetails='detail_confirmation';
const _aiComplete='comparison_complete';

String aiStageName(String s){
  switch(s){
    case _aiFront:return 'ตรวจพิมพ์ด้านหน้า';
    case _aiBack:return 'ตรวจพิมพ์ด้านหลัง';
    case _aiSideBottom:return 'ตรวจด้านข้าง / ก้นพระ';
    case _aiDetails:return 'ตรวจรายละเอียดประกอบ';
    case _aiComplete:return 'เปรียบเทียบครบทุกขั้น';
    default:return 'ยังไม่ทราบขั้นตอน';
  }
}

String stageForArea(String area){
  switch(area){
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

Map<String,dynamic> aiComparisonRule()=>{
  'enabled':true,
  'referenceScope':'all_references',
  'compareEveryAvailableReference':true,
  'flow':[
    {
      'stage':_aiFront,'name':'ด้านหน้า',
      'priority':'primary','requirePreviousPass':false
    },
    {
      'stage':_aiBack,'name':'ด้านหลัง',
      'priority':'primary','requirePreviousPass':true
    },
    {
      'stage':_aiSideBottom,'name':'ด้านข้าง / ก้นพระ',
      'priority':'primary','requirePreviousPass':true
    },
    {
      'stage':_aiDetails,'name':'รายละเอียดประกอบ',
      'priority':'secondary','requirePreviousPass':true
    }
  ],
  'gateRule':{
    'passCondition':'สอดคล้องกับอ้างอิงเพียงพอ',
    'failCondition':'พบความแตกต่างชัดเจน',
    'uncertainCondition':'ภาพไม่ชัดหรือข้อมูลไม่พอ',
    'onFail':'report_difference_before_next_stage',
    'onUncertain':'request_better_scan'
  },
  'wearRule':{
    'enabled':true,
    'separateFromOriginalPattern':true,
    'examples':[
      'การสึกจากการใช้งาน','รอยสัมผัส','ผิวสึก',
      'รายละเอียดที่หายจากการสึก','รอยกระแทกภายหลัง'
    ]
  },
  'smallDetailRule':{
    'ifNotVisible':'ตรวจสอบไม่ได้ / ภาพไม่ละเอียดพอ',
    'doNotInterpretAs':'ไม่มีรายละเอียด'
  },
  'typeDependentDetails':true,
  'fingerprintLikeMarksAreNotFixed':true
};

/* ================= STORAGE ================= */

Future<SharedPreferences> prefs()=>SharedPreferences.getInstance();

void msg(BuildContext c,String s)=>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s)));

Future<dynamic> go(BuildContext c,Widget p)=>
    Navigator.push(c,MaterialPageRoute(builder:(_)=>p));

String groupKey(AmuletData e)=>
    '${e.name.trim().toLowerCase()}|||${e.model.trim().toLowerCase()}';

int newId()=>DateTime.now().microsecondsSinceEpoch;

Future<int> nextReferenceNumber()async{
  final p=await prefs();
  final n=p.getInt(nextRefKey)??1;
  await p.setInt(nextRefKey,n+1);
  return n;
}

/* ================= MODEL ================= */

class AmuletScannerApp extends StatelessWidget{
  final List cameras;
  const AmuletScannerApp({super.key,required this.cameras});

  @override
  Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'กล้องสแกนพระและเหรียญ',
    theme:ThemeData(useMaterial3:true),
    home:HomePage(cameras:cameras),
  );
}

class AmuletData{
  int id,referenceNumber;
  String name,model,pim,type,temple,province,year,material,size;
  String frontDetail,sideDetail,backDetail;
  List scans;

  AmuletData({
    required this.id,
    this.referenceNumber=0,
    this.name='',this.model='',this.pim='',this.type='',this.temple='',
    this.province='',this.year='',this.material='',this.size='',
    this.frontDetail='',this.sideDetail='',this.backDetail='',
    List? scans,
  }):scans=scans??[];

  Map<String,dynamic> toMap()=>{
    'id':id,
    'referenceNumber':referenceNumber,
    'name':name,'model':model,'pim':pim,'type':type,'temple':temple,
    'province':province,'year':year,'material':material,'size':size,
    'frontDetail':frontDetail,'sideDetail':sideDetail,'backDetail':backDetail,
    'scans':scans.map((e)=>e.toMap()).toList()
  };

  factory AmuletData.fromMap(Map<String,dynamic> m)=>AmuletData(
    id:int.tryParse('${m['id']??0}')??0,
    referenceNumber:int.tryParse('${m['referenceNumber']??0}')??0,
    name:'${m['name']??''}',model:'${m['model']??''}',
    pim:'${m['pim']??''}',type:'${m['type']??''}',
    temple:'${m['temple']??''}',province:'${m['province']??''}',
    year:'${m['year']??''}',material:'${m['material']??''}',
    size:'${m['size']??''}',frontDetail:'${m['frontDetail']??''}',
    sideDetail:'${m['sideDetail']??''}',backDetail:'${m['backDetail']??''}',
    scans:m['scans'] is List
      ?(m['scans'] as List)
        .map((e)=>ScanData.fromMap(Map<String,dynamic>.from(e))).toList()
      :[],
  );
}

class ScanData{
  String area,method;
  Map<String,dynamic> details,imageFeatures;

  ScanData({
    required this.area,required this.method,
    Map<String,dynamic>? details,
    Map<String,dynamic>? imageFeatures,
  }):details=details??{},imageFeatures=imageFeatures??{};

  Map<String,dynamic> toMap()=>{
    'area':area,'method':method,
    'details':details,'imageFeatures':imageFeatures
  };

  factory ScanData.fromMap(Map<String,dynamic> m)=>ScanData(
    area:'${m['area']??''}',
    method:'${m['method']??''}',
    details:m['details'] is Map
      ?Map<String,dynamic>.from(m['details']):{},
    imageFeatures:m['imageFeatures'] is Map
      ?Map<String,dynamic>.from(m['imageFeatures']):{},
  );
}

Map<String,dynamic> referenceModel()=>{
  'enabled':true,
  'available':false,
  'sourceType':'reference_data',
  'isActualObjectMeasurement':false,
  'imagePixelSizeIsNotRealSize':true,
  'size':{
    'height':null,'width':null,'thickness':null,'weight':null,
    'range':[],'unit':'cm'
  },
  'proportion':null,
  'sourceCount':0,
  'sourceReliability':null,
  'canCompareWithScan':true,
  'note':'ขนาดนี้มาจากข้อมูลอ้างอิง ไม่ใช่การวัดองค์จริง'
};

Map<String,dynamic> toAiData(AmuletData e)=>{
  'recordType':'amulet_reference',
  'name':e.name,'model':e.model,'pim':e.pim,
  'type':e.type,'temple':e.temple,
  'aiPatternPoints':patternPointsFor(e.type),
  'aiDetailPoints':detailPointsFor(e.type),
  'aiObservationPoints':observationPointsFor(e.type),
  'analysisFlow':aiComparisonRule(),
  'referenceScope':'all_references',
  'compareEveryAvailableReference':true,
  'referenceComparison':{
    'enabled':true,
    'referenceScope':'all_references',
    'compareEveryAvailableReference':true,
    'result':null,
    'differences':[],
    'front':{
      'status':'pending','result':null,
      'matches':[],'differences':[]
    },
    'back':{
      'status':'locked_until_front_pass','result':null,
      'matches':[],'differences':[]
    },
    'sideBottom':{
      'status':'locked_until_back_pass','result':null,
      'matches':[],'differences':[]
    },
    'details':{
      'status':'locked_until_side_bottom_pass','result':null,
      'matches':[],'differences':[],'notVisible':[]
    },
    'wearFromUse':[],
    'needsCloseup':[]
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
    'frontBeforeBack':true,
    'backBeforeSideBottom':true,
    'sideBottomBeforeDetails':true,
    'patternBeforeSmallDetails':true,
    'secondaryPointsAreTypeDependent':true,
    'fingerprintLikeMarksAreNotFixed':true,
    'wearMustBeSeparatedFromOriginalPattern':true,
    'canUseReferenceSize':true,
    'sizeMustComeFromReferenceData':true,
    'imagePixelsAreNotRealSize':true,
    'doNotJudgeAuthenticityFromSizeAlone':true,
    'smallDetailsNeedSufficientImageQuality':true,
    'doNotGuessMissingDetails':true,
  }
};

Future<List> loadAllItems()async{
  final p=await prefs();
  try{
    final z=p.getString(dataKey);
    if(z!=null&&z.isNotEmpty){
      final list=jsonDecode(
        utf8.decode(gzip.decode(base64Decode(z)))
      ) as List;
      return list.map((e)=>AmuletData.fromMap(
        Map<String,dynamic>.from(e)
      )).toList();
    }
  }catch(_){}
  try{
    final old=p.getString(oldDataKey);
    if(old!=null){
      final list=jsonDecode(old) as List;
      final items=list.map((e)=>AmuletData.fromMap(
        Map<String,dynamic>.from(e)
      )).toList();
      await saveAllItems(items);
      return items;
    }
  }catch(_){}
  return [];
}

Future saveAllItems(List items)async{
  final p=await prefs();
  final z=base64Encode(gzip.encode(utf8.encode(
    jsonEncode(items.map((e)=>e.toMap()).toList())
  )));
  await p.setString(dataKey,z);
  await p.remove(oldDataKey);
}

/* ================= HOME ================= */

class HomePage extends StatelessWidget{
  final List cameras;
  const HomePage({super.key,required this.cameras});

  Widget tile(BuildContext c,String t,String s,IconData i,Widget p)=>Card(
    child:ListTile(
      leading:Icon(i,size:32),
      title:Text(t,style:const TextStyle(fontWeight:FontWeight.bold)),
      subtitle:Text(s),
      trailing:const Icon(Icons.chevron_right),
      onTap:()=>go(c,p),
    ),
  );

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('กล้องสแกนพระและเหรียญ')),
    body:ListView(
      padding:const EdgeInsets.all(12),
      children:[
        tile(c,'สร้าง / บันทึกข้อมูล','สร้างข้อมูลพระและเหรียญ',
          Icons.add_box_outlined,CreateDataPage(cameras:cameras)),
        tile(c,'รายการข้อมูลที่บันทึก','ดู แก้ไข ลบ และสแกนเพิ่มข้อมูล',
          Icons.folder_open,SavedListPage(cameras:cameras)),
        tile(c,'สำรอง / นำเข้าข้อมูล','สำรองหรือนำข้อมูลกลับเข้าเครื่อง',
          Icons.import_export,const BackupPage()),
        tile(c,'ตั้งค่า','ตั้งค่าการสแกนและการแสดงข้อมูล',
          Icons.settings,const SettingsPage()),
      ],
    ),
  );
}

/* ================= CREATE ================= */

class CreateDataPage extends StatefulWidget{
  final List cameras;
  const CreateDataPage({super.key,required this.cameras});
  @override State createState()=>_CreateDataPageState();
}

class _CreateDataPageState extends State<CreateDataPage>{
  final nameController=TextEditingController();
  final modelController=TextEditingController();
  final pimController=TextEditingController();
  final templeController=TextEditingController();
  String type=amuletTypes.first;

  @override
  void dispose(){
    nameController.dispose();modelController.dispose();
    pimController.dispose();templeController.dispose();
    super.dispose();
  }

  Future save()async{
    if(nameController.text.trim().isEmpty){
      msg(context,'กรุณาใส่ชื่อพระ');return;
    }
    final items=await loadAllItems();
    items.add(AmuletData(
      id:newId(),
      name:nameController.text.trim(),
      model:modelController.text.trim(),
      pim:pimController.text.trim(),
      type:type,
      temple:templeController.text.trim(),
    ));
    await saveAllItems(items);
    if(!mounted)return;
    msg(context,'บันทึกข้อมูลเรียบร้อย');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('สร้าง / บันทึกข้อมูล')),
    body:ListView(
      padding:const EdgeInsets.all(16),
      children:[
        TextField(controller:nameController,
          decoration:const InputDecoration(
            labelText:'ชื่อพระ',border:OutlineInputBorder())),
        const SizedBox(height:12),
        TextField(controller:modelController,
          decoration:const InputDecoration(
            labelText:'รุ่น',border:OutlineInputBorder())),
        const SizedBox(height:12),
        DropdownButtonFormField(
          value:type,
          decoration:const InputDecoration(
            labelText:'ชนิดพระ',border:OutlineInputBorder()),
          items:amuletTypes.map((e)=>DropdownMenuItem(
            value:e,child:Text(e))).toList(),
          onChanged:(v)=>setState(()=>type=v??type),
        ),
        const SizedBox(height:12),
        TextField(controller:pimController,
          decoration:const InputDecoration(
            labelText:'พิมพ์',border:OutlineInputBorder())),
        const SizedBox(height:12),
        TextField(controller:templeController,
          decoration:const InputDecoration(
            labelText:'วัด',border:OutlineInputBorder())),
        const SizedBox(height:20),
        FilledButton.icon(
          onPressed:save,
          icon:const Icon(Icons.save),
          label:const Padding(
            padding:EdgeInsets.all(12),
            child:Text('บันทึกข้อมูล',style:TextStyle(fontSize:18)),
          ),
        ),
      ],
    ),
  );
}

/* ================= SAVED LIST ================= */

class SavedListPage extends StatefulWidget{
  final List cameras;
  const SavedListPage({super.key,required this.cameras});
  @override State createState()=>_SavedListPageState();
}

class _SavedListPageState extends State<SavedListPage>{
  List items=[];String search='';

  @override void initState(){super.initState();load();}

  Future load()async{
    final x=await loadAllItems();
    if(mounted)setState(()=>items=x);
  }

  Map<String,List> groups(){
    final m=<String,List>{};
    for(final e in items){
      final q='${e.name} ${e.model} ${e.type} ${e.temple}'.toLowerCase();
      if(search.isNotEmpty&&!q.contains(search.toLowerCase()))continue;
      m.putIfAbsent(groupKey(e),()=>[]).add(e);
    }
    return m;
  }

  Future deleteGroup(String key)async{
    final ok=await showDialog(
      context:context,
      builder:(c)=>AlertDialog(
        title:const Text('ลบข้อมูล'),
        content:const Text('ต้องการลบข้อมูลกลุ่มนี้ทั้งหมดหรือไม่?'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(c,false),
            child:const Text('ยกเลิก')),
          FilledButton(onPressed:()=>Navigator.pop(c,true),
            child:const Text('ลบ')),
        ],
      ),
    );
    if(ok!=true)return;
    items.removeWhere((e)=>groupKey(e)==key);
    await saveAllItems(items);
    if(mounted)setState((){});
  }

  @override
  Widget build(BuildContext c){
    final gs=groups();
    return Scaffold(
      appBar:AppBar(title:const Text('รายการข้อมูลที่บันทึก')),
      body:Column(
        children:[
          Padding(
            padding:const EdgeInsets.all(12),
            child:TextField(
              onChanged:(v)=>setState(()=>search=v),
              decoration:const InputDecoration(
                prefixIcon:Icon(Icons.search),
                labelText:'ค้นหา',border:OutlineInputBorder()),
            ),
          ),
          Expanded(
            child:gs.isEmpty
              ?const Center(child:Text('ยังไม่มีข้อมูล'))
              :ListView(
                padding:const EdgeInsets.fromLTRB(12,0,12,12),
                children:gs.entries.map((g){
                  final a=g.value.first;
                  return Card(
                    child:ListTile(
                      leading:const Icon(Icons.folder_outlined),
                      title:Text(a.name.isEmpty?'ไม่ระบุชื่อ':a.name),
                      subtitle:Text(
                        '${a.model.isEmpty?'ไม่ระบุรุ่น':a.model} • '
                        '${a.type.isEmpty?'ไม่ระบุชนิด':a.type}\n'
                        'รายการอ้างอิง ${g.value.length} รายการ',
                      ),
                      isThreeLine:true,
                      trailing:PopupMenuButton(
                        onSelected:(v)async{
                          if(v=='edit'){
                            await go(c,EditGroupPage(group:g.value));
                            await load();
                          }else{
                            await deleteGroup(g.key);
                          }
                        },
                        itemBuilder:(_)=>const[
                          PopupMenuItem(
                            value:'edit',child:Text('แก้ไขกลุ่ม')),
                          PopupMenuItem(
                            value:'delete',child:Text('ลบกลุ่ม')),
                        ],
                      ),
                      onTap:()async{
                        await go(c,AmuletGroupPage(
                          group:g.value,cameras:widget.cameras));
                        await load();
                      },
                    ),
                  );
                }).toList(),
              ),
          ),
        ],
      ),
    );
  }
}

/* ================= EDIT GROUP ================= */

class EditGroupPage extends StatefulWidget{
  final List group;
  const EditGroupPage({super.key,required this.group});
  @override State createState()=>_EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage>{
  late TextEditingController name,model,pim,temple;
  late String type;

  @override
  void initState(){
    super.initState();
    final a=widget.group.first;
    name=TextEditingController(text:a.name);
    model=TextEditingController(text:a.model);
    pim=TextEditingController(text:a.pim);
    temple=TextEditingController(text:a.temple);
    type=amuletTypes.contains(a.type)?a.type:amuletTypes.first;
  }

  @override
  void dispose(){
    name.dispose();model.dispose();pim.dispose();temple.dispose();
    super.dispose();
  }

  Future save()async{
    final all=await loadAllItems();
    final key=groupKey(widget.group.first);
    for(final e in all){
      if(groupKey(e)==key){
        e.name=name.text.trim();
        e.model=model.text.trim();
        e.pim=pim.text.trim();
        e.type=type;
        e.temple=temple.text.trim();
      }
    }
    await saveAllItems(all);
    if(mounted)Navigator.pop(context);
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('แก้ไขข้อมูลกลุ่ม')),
    body:ListView(
      padding:const EdgeInsets.all(16),
      children:[
        TextField(controller:name,decoration:const InputDecoration(
          labelText:'ชื่อพระ',border:OutlineInputBorder())),
        const SizedBox(height:12),
        TextField(controller:model,decoration:const InputDecoration(
          labelText:'รุ่น',border:OutlineInputBorder())),
        const SizedBox(height:12),
        DropdownButtonFormField(
          value:type,
          decoration:const InputDecoration(
            labelText:'ชนิดพระ',border:OutlineInputBorder()),
          items:amuletTypes.map((e)=>DropdownMenuItem(
            value:e,child:Text(e))).toList(),
          onChanged:(v)=>setState(()=>type=v??type),
        ),
        const SizedBox(height:12),
        TextField(controller:pim,decoration:const InputDecoration(
          labelText:'พิมพ์',border:OutlineInputBorder())),
        const SizedBox(height:12),
        TextField(controller:temple,decoration:const InputDecoration(
          labelText:'วัด',border:OutlineInputBorder())),
        const SizedBox(height:20),
        FilledButton.icon(
          onPressed:save,
          icon:const Icon(Icons.save),
          label:const Text('บันทึกการแก้ไข'),
        ),
      ],
    ),
  );
}

/* ================= REFERENCE GROUP ================= */

class AmuletGroupPage extends StatefulWidget{
  final List group;
  final List cameras;
  const AmuletGroupPage({
    super.key,required this.group,required this.cameras
  });
  @override State createState()=>_AmuletGroupPageState();
}

class _AmuletGroupPageState extends State<AmuletGroupPage>{
  late List group;

  @override
  void initState(){
    super.initState();
    group=[...widget.group]..sort(
      (a,b)=>a.referenceNumber.compareTo(b.referenceNumber));
  }

  Future refresh()async{
    final all=await loadAllItems();
    final key=groupKey(widget.group.first);
    final x=all.where((e)=>groupKey(e)==key).toList()
      ..sort((a,b)=>a.referenceNumber.compareTo(b.referenceNumber));
    if(mounted)setState(()=>group=x);
  }

  Future deleteItem(AmuletData item)async{
    final ok=await showDialog(
      context:context,
      builder:(c)=>AlertDialog(
        title:const Text('ลบรายการอ้างอิง'),
        content:const Text(
          'ต้องการลบรายการอ้างอิงนี้ทั้งหมด รวมประวัติการสแกนหรือไม่?'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(c,false),
            child:const Text('ยกเลิก')),
          FilledButton(onPressed:()=>Navigator.pop(c,true),
            child:const Text('ลบ')),
        ],
      ),
    );
    if(ok!=true)return;
    final all=await loadAllItems();
    all.removeWhere((e)=>e.id==item.id);
    await saveAllItems(all);
    await refresh();
  }

  Future addReference()async{
    if(group.isEmpty)return;
    final a=group.first;
    final all=await loadAllItems();
    final ref=await nextReferenceNumber();
    final e=AmuletData(
      id:newId(),
      referenceNumber:ref,
      name:a.name,model:a.model,pim:a.pim,
      type:a.type,temple:a.temple,
    );
    all.add(e);
    await saveAllItems(all);
    await go(context,ScanPage(item:e,cameras:widget.cameras));
    await refresh();
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(
      title:Text(widget.group.first.name.isEmpty
        ?'รายการอ้างอิง':widget.group.first.name),
    ),
    floatingActionButton:FloatingActionButton.extended(
      onPressed:addReference,
      icon:const Icon(Icons.add),
      label:const Text('เพิ่มรายการอ้างอิง'),
    ),
    body:ListView(
      padding:const EdgeInsets.all(12),
      children:[
        Card(
          child:Padding(
            padding:const EdgeInsets.all(14),
            child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text(
                  widget.group.first.name.isEmpty
                    ?'ไม่ระบุชื่อ':widget.group.first.name,
                  style:const TextStyle(
                    fontSize:20,fontWeight:FontWeight.bold)),
                Text('รุ่น: ${widget.group.first.model.isEmpty
                  ?'ไม่ระบุ':widget.group.first.model}'),
                Text('ชนิด: ${widget.group.first.type.isEmpty
                  ?'ไม่ระบุ':widget.group.first.type}'),
                const SizedBox(height:6),
                const Text(
                  'พื้นฐาน 5+ องค์ เป็นเพียงตัวเตือน '
                  'สามารถเพิ่มรายการอ้างอิงได้ไม่จำกัด'),
              ],
            ),
          ),
        ),
        ...group.map((e)=>Card(
          child:ListTile(
            leading:const Icon(Icons.account_balance_outlined),
            title:Text('ลำดับอ้างอิง ${e.referenceNumber}'),
            subtitle:Text(
              'สแกนแล้ว ${e.scans.length}/${scanAreas.length} จุด'),
            trailing:PopupMenuButton(
              onSelected:(v)async{
                if(v=='delete')await deleteItem(e);
              },
              itemBuilder:(_)=>const[
                PopupMenuItem(
                  value:'delete',child:Text('ลบรายการนี้')),
              ],
            ),
            onTap:()async{
              await go(c,ScanPage(item:e,cameras:widget.cameras));
              await refresh();
            },
          ),
        )),
        const SizedBox(height:80),
      ],
    ),
  );
}

/* ================= SCAN ================= */

class ScanPage extends StatefulWidget{
  final AmuletData item;
  final List cameras;
  const ScanPage({super.key,required this.item,required this.cameras});
  @override State createState()=>_ScanPageState();
}

class _ScanPageState extends State<ScanPage>{
  final picker=ImagePicker();
  CameraController? camera;
  String area=scanAreas.first;
  bool realObject=true,history=true,autoNext=true,scanning=false;
  int frames=0;

  @override void initState(){super.initState();loadSettings();}

  Future loadSettings()async{
    final p=await prefs();
    if(!mounted)return;
    setState((){
      realObject=p.getBool('setting_real_object_default')??true;
      history=p.getBool('setting_show_scan_history')??true;
      autoNext=p.getBool('setting_auto_next_area')??true;
    });
  }

  int count(String a)=>widget.item.scans.where((e)=>e.area==a).length;

  List areas(){
    final x=[...scanAreas];
    for(final s in widget.item.scans){
      if(s.area.isNotEmpty&&!x.contains(s.area))x.add(s.area);
    }
    return x;
  }

  Future start(String a)async{
    setState(()=>area=a);
    if(realObject&&widget.cameras.isNotEmpty){
      await openCamera();
    }else{
      final f=await picker.pickImage(source:ImageSource.gallery);
      if(f!=null)await saveScan('นำเข้าจากโทรศัพท์');
    }
  }

  Future openCamera()async{
    final cam=widget.cameras.firstWhere(
      (e)=>e.lensDirection==CameraLensDirection.back,
      orElse:()=>widget.cameras.first,
    );

    camera=CameraController(
      cam,ResolutionPreset.medium,enableAudio:false);

    try{
      await camera!.initialize();
      frames=0;
      scanning=true;
      if(mounted)setState((){});

      await camera!.startImageStream((CameraImage image)async{
        if(!scanning)return;
        frames++;
        if(frames>=12){
          scanning=false;
          try{await camera?.stopImageStream();}catch(_){}
          if(mounted)setState((){});
        }
      });

      if(mounted){
        await showDialog(
          context:context,
          barrierDismissible:false,
          builder:(c)=>AlertDialog(
            title:Text('กำลังสแกน $area'),
            content:SizedBox(
              width:280,height:360,
              child:Column(
                children:[
                  Expanded(
                    child:camera!.value.isInitialized
                      ?CameraPreview(camera!)
                      :const Center(
                          child:CircularProgressIndicator()),
                  ),
                  const SizedBox(height:8),
                  Text('เฟรมชั่วคราว $frames / 12'),
                  const Text(
                    'ภาพถูกใช้ชั่วคราวใน RAM '
                    'และไม่บันทึกเป็นรูปภาพ'),
                ],
              ),
            ),
            actions:[
              TextButton(
                onPressed:(){
                  scanning=false;
                  try{camera?.stopImageStream();}catch(_){}
                  Navigator.pop(c);
                },
                child:const Text('หยุด'),
              ),
            ],
          ),
        );
      }

      await saveScan('กล้อง');
    }catch(e){
      if(mounted)msg(context,'เปิดกล้องไม่สำเร็จ: $e');
    }finally{
      try{await camera?.stopImageStream();}catch(_){}
      await camera?.dispose();
      camera=null;
      scanning=false;
    }
  }

  Future saveScan(String method)async{
    final stage=stageForArea(area);

    final s=ScanData(
      area:area,
      method:method,
      details:{
        'analysisStatus':'รอระบบ AI วิเคราะห์',
        'aiStatus':'pending',
        'aiFindings':[],
        'aiNotes':'',
        'aiConfidence':null,
        'aiAnalyzedAt':null,
        'sourceArea':area,
        'imageSaved':false,
        'temporaryOnly':true,
        'canCompareWithPreviousScans':true,

        'analysisFlow':{
          'currentArea':area,
          'currentStage':stage,
          'currentStageName':aiStageName(stage),
          'referenceScope':'all_references',
          'compareEveryAvailableReference':true,
          'nextStage':nextStage(stage),
          'requiresPreviousStagePass':stage!=_aiFront,
        },

        'comparisonGate':{
          'status':'pending',
          'passMeaning':'สอดคล้องกับอ้างอิงเพียงพอ',
          'failMeaning':'พบความแตกต่างจากอ้างอิง',
          'uncertainMeaning':'ภาพไม่ชัดหรือข้อมูลไม่เพียงพอ',
          'doNotJudgeAuthenticity':true,
        },

        'wearAnalysis':{
          'enabled':true,
          'separateFromPattern':true,
          'status':'pending',
          'findings':[],
        },

        'analysisOrder':[
          'pattern_first',
          'detail_second',
          'small_detail_if_image_quality_allows'
        ],

        'patternAnalysis':{
          'status':'pending',
          'result':null,
          'matches':[],
          'differences':[],
          'confidence':null,
        },

        'detailAnalysis':{
          'status':'pending',
          'result':null,
          'matches':[],
          'differences':[],
          'notVisible':[],
          'confidence':null,
        },

        'imageCheck':{
          'status':'pending',
          'quality':null,
          'patternVisibility':null,
          'smallDetailVisibility':null,
          'needsCloseup':false,
          'suggestedAreas':[],
        },

        'verificationStatus':{
          'pattern':'ยังไม่ได้วิเคราะห์',
          'details':'ยังไม่ได้วิเคราะห์',
          'smallDetails':'ยังไม่ได้วิเคราะห์',
        },

        'surfaceDetails':[],
        'defects':[],
        'moldDetails':[],
        'castingLines':[],
        'patternDetails':[],
        'observations':[],

        'referenceModel':{
          'available':false,
          'sourceType':'reference_data',
          'isActualObjectMeasurement':false,
          'imagePixelSizeIsNotRealSize':true,
          'size':{
            'height':null,'width':null,'thickness':null,
            'weight':null,'range':[],'unit':'cm'
          },
          'proportion':null,
          'sourceCount':0,
          'sourceReliability':null,
          'canCompareWithScan':true,
        },

        'referenceComparison':{
          'enabled':true,
          'referenceScope':'all_references',
          'compareEveryAvailableReference':true,
          'result':null,
          'matches':[],
          'differences':[],
          'wearFromUse':[],
          'notVisible':[],
          'patternResult':null,
          'detailResult':null,
          'smallDetailResult':null,
          'sizeDifference':null,
          'proportionDifference':null,
          'needsCloseup':[],
        },

        'authenticityDecision':{
          'enabled':false,
          'result':null,
          'note':
            'ระบบเปรียบเทียบกับองค์อ้างอิงทั้งหมดตามลำดับ '
            'ด้านหน้า → ด้านหลัง → ด้านข้าง/ก้นพระ → รายละเอียด '
            'โดยแยกความสึกจากการใช้งานออกจากความแตกต่างของพิมพ์ '
            'และไม่ตัดสินแท้/เก๊จากจุดใดจุดหนึ่งเพียงอย่างเดียว',
        },
      },

      imageFeatures:{
        'modelName':'',
        'modelVersion':'',
        'featureVersion':3,
        'embedding':[],
        'quality':null,
        'patternQuality':null,
        'detailQuality':null,
      },
    );

    widget.item.scans.add(s);

    final all=await loadAllItems();
    final i=all.indexWhere((e)=>e.id==widget.item.id);
    if(i>=0)all[i]=widget.item;
    await saveAllItems(all);

    if(!mounted)return;
    msg(context,'บันทึกผลสแกน $area แล้ว');

    if(autoNext){
      final next=areas().firstWhere(
        (a)=>count(a)==0,
        orElse:()=>area,
      );
      setState(()=>area=next);
    }else{
      setState((){});
    }
  }

  Future addCustomArea()async{
    final controller=TextEditingController();
    final ok=await showDialog(
      context:context,
      builder:(d)=>AlertDialog(
        title:const Text('เพิ่มพื้นที่สแกน'),
        content:TextField(
          controller:controller,
          decoration:const InputDecoration(labelText:'ชื่อพื้นที่'),
        ),
        actions:[
          TextButton(
            onPressed:()=>Navigator.pop(d,false),
            child:const Text('ยกเลิก')),
          FilledButton(
            onPressed:()=>Navigator.pop(d,true),
            child:const Text('เพิ่ม')),
        ],
      ),
    );
    final v=controller.text.trim();
    controller.dispose();
    if(ok==true&&v.isNotEmpty)setState(()=>area=v);
  }

  Widget observationSection(
    String title,List list,IconData icon)=>Column(
      crossAxisAlignment:CrossAxisAlignment.start,
      children:[
        Text(title,style:const TextStyle(
          fontSize:16,fontWeight:FontWeight.bold)),
        const SizedBox(height:6),
