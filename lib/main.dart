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

const amuletTypes=[
  'เหรียญ','เหรียญหล่อ','พระสมเด็จ','รูปหล่อ','พระกริ่ง',
  'พระปิดตาเนื้อผง/หว้าน','พระปิดตาเนื้อโลหะ','พระเนื้อผง',
  'พระเนื้อดิน','นางพญา','ผงสุพรรณ','พระรอด','พระซุ้มกอ',
  'พระขุนแผน','หลวงปู่ทวดเนื้อหว้าน','หลวงปู่ทวด05','อื่น ๆ'
];

const scanAreas=['ด้านหน้า','ด้านหลัง','ด้านข้าง','ก้นพระ'];

const commonAiObservationPoints=[
  'รูปทรงและสัดส่วน','เปรียบเทียบกับข้อมูลอ้างอิง',
  'ตำหนิและรายละเอียด','เนื้อและผิว','ร่องรอยการสร้าง'
];

const amuletObservationPoints={
  'เหรียญ':[
    'รูปทรงและขนาดสัดส่วน',
    'พิมพ์และรูปแบบเหรียญ',
    'ใบหน้า / รูปเหมือน',
    'ตัวหนังสือ',
    'ตัวเลข / ศักราช',
    'ลวดลายและองค์ประกอบ',
    'เส้นขอบเหรียญ',
    'หูเหรียญ',
    'โค้ด / ตอกโค้ด',
    'รอยปั๊ม / รอยพิมพ์',
    'เนื้อโลหะ',
    'ผิวเหรียญ',
    'คราบและร่องรอยตามธรรมชาติ',
    'รอยตัด / รอยแต่งขอบ',
    'ตำหนิเฉพาะพิมพ์',
    'ร่องรอยการสร้าง',
    'ความผิดปกติที่ควรนำไปเปรียบเทียบกับข้อมูลอ้างอิง'
  ],
  'เหรียญหล่อ':[
    'รูปทรง','ลวดลาย','เส้นหล่อ','รอยตัดชนวน',
    'ผิวโลหะ','รูพรุน','ขอบ','หูเหรียญ',
    'โค้ดตอก','รอยตะไบ'
  ],
  'พระสมเด็จ':[
    'พิมพ์ทรง','ซุ้ม','องค์พระ','ฐาน','เส้นสายสำคัญ',
    'เนื้อ','ผิว/คราบ','รอยตัดขอบ'
  ],
  'รูปหล่อ':[
    'รูปทรง','ใบหน้า','สัดส่วน','ฐาน','รายละเอียดองค์พระ',
    'เส้นหล่อ','ผิวโลหะ','ก้นพระ'
  ],
  'พระกริ่ง':[
    'รูปทรง','ใบหน้า','รายละเอียดองค์พระ','ฐาน',
    'เส้นหล่อ','ผิวโลหะ','ก้นพระ','รู/ช่องก้น'
  ],
  'พระปิดตาเนื้อผง/หว้าน':[
    'รูปทรงองค์พระ','มือ/แขน','ใบหน้า','ฐาน','รายละเอียดพิมพ์',
    'ยันต์/อักขระ','ตัวหนังสือ','ตัวเลข','ลักษณะเนื้อ',
    'ลักษณะผิว','มวลสาร/การกระจายตัวของมวลสาร',
    'ร่องรอยการกดพิมพ์','ขอบ','รอยตัดแต่ง'
  ],
  'พระปิดตาเนื้อโลหะ':[
    'รูปทรงองค์พระ','มือ/แขน','รายละเอียดพิมพ์','ยันต์/อักขระ',
    'ตัวหนังสือ','ตัวเลข','เส้นหล่อ','ผิวโลหะ',
    'รอยตัด/รอยตัดชนวน','ขอบ','ก้นพระ'
  ],
  'พระเนื้อผง':[
    'พิมพ์ทรง','องค์พระ','ฐาน','รายละเอียดพิมพ์',
    'เนื้อ','ผิว','คราบ','รอยตัดขอบ'
  ],
  'พระเนื้อดิน':[
    'พิมพ์ทรง','องค์พระ','ฐาน','รายละเอียดพิมพ์',
    'เนื้อดิน','ผิว','คราบกรุ','รอยตัดขอบ'
  ],
  'นางพญา':[
    'พิมพ์ทรง','องค์พระ','ใบหน้า','ฐาน',
    'รายละเอียดพิมพ์','เนื้อ','ผิว','รอยตัดขอบ'
  ],
  'ผงสุพรรณ':[
    'พิมพ์ทรง','องค์พระ','ใบหน้า','ฐาน',
    'รายละเอียดพิมพ์','เนื้อ','ผิว','คราบกรุ','รอยตัดขอบ'
  ],
  'พระรอด':[
    'พิมพ์ทรง','องค์พระ','ซุ้ม','ฐาน',
    'รายละเอียดพิมพ์','เนื้อ','ผิว','คราบกรุ'
  ],
  'พระซุ้มกอ':[
    'พิมพ์ทรง','องค์พระ','ซุ้ม','ฐาน',
    'รายละเอียดพิมพ์','เนื้อ','ผิว','คราบกรุ'
  ],
  'พระขุนแผน':[
    'พิมพ์ทรง','องค์พระ','รายละเอียดใบหน้า',
    'แขน/มือ','ฐาน','เนื้อ','ผิว','คราบกรุ'
  ],
  'หลวงปู่ทวดเนื้อหว้าน':[
    'รูปทรงองค์พระ','องค์พระ','ใบหน้า','พิมพ์ทรง',
    'รายละเอียดพิมพ์','ฐาน','เนื้อหว่าน','มวลสาร',
    'การกระจายตัวของมวลสาร','ผิว','คราบกรุ',
    'รอยตัดขอบ','ร่องรอยการกดพิมพ์','ตำหนิเฉพาะพิมพ์'
  ],
  'อื่น ๆ':[
    'พิมพ์ทรง','รายละเอียดองค์พระ','ลวดลาย','ขอบ',
    'เนื้อ','ผิว','รอยตำหนิ','รายละเอียดเฉพาะรุ่น'
  ],
};

List<String> observationPointsFor(String type){
  if(type=='เหรียญ')return amuletObservationPoints['เหรียญ']!;
  return[
    ...commonAiObservationPoints,
    ...(amuletObservationPoints[type]??amuletObservationPoints['อื่น ๆ']!)
  ];
}

Future<SharedPreferences> prefs()=>SharedPreferences.getInstance();

void msg(BuildContext c,String s)=>ScaffoldMessenger.of(c)
    .showSnackBar(SnackBar(content:Text(s)));

Future<dynamic> go(BuildContext c,Widget p)=>Navigator.push(
  c,MaterialPageRoute(builder:(_)=>p));

String groupKey(AmuletData e)=>
    '${e.name.trim().toLowerCase()}|||${e.model.trim().toLowerCase()}';

int newId()=>DateTime.now().microsecondsSinceEpoch;

class AmuletScannerApp extends StatelessWidget{
  final List<CameraDescription> cameras;
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
  int id;
  String name,model,pim,type,temple,province,year,material,size;
  String frontDetail,sideDetail,backDetail;
  List<ScanData> scans;

  AmuletData({
    required this.id,
    this.name='',this.model='',this.pim='',this.type='',
    this.temple='',this.province='',this.year='',
    this.material='',this.size='',this.frontDetail='',
    this.sideDetail='',this.backDetail='',List<ScanData>? scans,
  }):scans=scans??[];

  Map<String,dynamic> toMap()=> {
    'id':id,'name':name,'model':model,'pim':pim,'type':type,
    'temple':temple,'province':province,'year':year,
    'material':material,'size':size,'frontDetail':frontDetail,
    'sideDetail':sideDetail,'backDetail':backDetail,
    'scans':scans.map((e)=>e.toMap()).toList()
  };

  factory AmuletData.fromMap(Map<String,dynamic> m)=>AmuletData(
    id:int.tryParse('${m['id']??0}')??0,
    name:'${m['name']??''}',model:'${m['model']??''}',
    pim:'${m['pim']??''}',type:'${m['type']??''}',
    temple:'${m['temple']??''}',province:'${m['province']??''}',
    year:'${m['year']??''}',material:'${m['material']??''}',
    size:'${m['size']??''}',frontDetail:'${m['frontDetail']??''}',
    sideDetail:'${m['sideDetail']??''}',
    backDetail:'${m['backDetail']??''}',
    scans:m['scans'] is List?(m['scans'] as List)
      .map((e)=>ScanData.fromMap(Map<String,dynamic>.from(e))).toList():[],
  );
}

class ScanData{
  String area,method;
  Map<String,dynamic> details,imageFeatures;

  ScanData({
    required this.area,required this.method,
    Map<String,dynamic>? details,Map<String,dynamic>? imageFeatures,
  }):details=details??{},imageFeatures=imageFeatures??{};

  Map<String,dynamic> toMap()=> {
    'area':area,'method':method,'details':details,
    'imageFeatures':imageFeatures
  };

  factory ScanData.fromMap(Map<String,dynamic> m)=>ScanData(
    area:'${m['area']??''}',method:'${m['method']??''}',
    details:m['details'] is Map
      ?Map<String,dynamic>.from(m['details']):{},
    imageFeatures:m['imageFeatures'] is Map
      ?Map<String,dynamic>.from(m['imageFeatures']):{},
  );
}

Map<String,dynamic> referenceModel()=> {
  'enabled':true,'available':false,'sourceType':'reference_data',
  'isActualObjectMeasurement':false,
  'imagePixelSizeIsNotRealSize':true,
  'size':{
    'height':null,'width':null,'thickness':null,'weight':null,
    'range':[],'unit':'cm'
  },
  'proportion':null,'sourceCount':0,'sourceReliability':null,
  'canCompareWithScan':true,
  'note':'ขนาดนี้มาจากข้อมูลอ้างอิง ไม่ใช่การวัดองค์จริง',
};

Map<String,dynamic> toAiData(AmuletData e)=> {
  'recordType':'amulet_reference','name':e.name,'model':e.model,
  'pim':e.pim,'type':e.type,'temple':e.temple,
  'scans':e.scans.map((s)=>s.toMap()).toList(),
  'aiObservationPoints':observationPointsFor(e.type),
  'referenceModel':referenceModel(),
  'referenceComparison':{
    'enabled':true,'referenceModelAvailable':false,
    'result':null,'differences':[]
  },
  'aiContext':{
    'canReadScanHistory':true,'canRememberPreviousScan':true,
    'canAddAnalysis':true,'canCompareAreas':true,
    'canBuildReferenceModel':true,'canUseReferenceSize':true,
    'sizeMustComeFromReferenceData':true,
    'imagePixelsAreNotRealSize':true,
    'doNotJudgeAuthenticityFromSizeAlone':true,
  },
};

Future<List<AmuletData>> loadAllItems()async{
  final p=await prefs();
  try{
    final z=p.getString(dataKey);
    if(z!=null&&z.isNotEmpty){
      final list=jsonDecode(utf8.decode(gzip.decode(base64Decode(z)))) as List;
      return list.map((e)=>AmuletData.fromMap(Map<String,dynamic>.from(e))).toList();
    }
  }catch(_){}
  try{
    final old=p.getString(oldDataKey);
    if(old!=null){
      final list=jsonDecode(old) as List;
      final items=list.map((e)=>AmuletData.fromMap(Map<String,dynamic>.from(e))).toList();
      await saveAllItems(items);
      return items;
    }
  }catch(_){}
  return[];
}

Future<void> saveAllItems(List<AmuletData> items)async{
  final p=await prefs();
  final json=jsonEncode(items.map((e)=>e.toMap()).toList());
  final z=base64Encode(gzip.encode(utf8.encode(json)));
  await p.setString(dataKey,z);
  await p.remove(oldDataKey);
}

class HomePage extends StatelessWidget{
  final List<CameraDescription> cameras;
  const HomePage({super.key,required this.cameras});

  Widget tile(BuildContext c,String t,String s,IconData i,Widget p)=>Card(
    child:ListTile(
      leading:Icon(i,size:32),title:Text(t,style:const TextStyle(fontWeight:FontWeight.bold)),
      subtitle:Text(s),trailing:const Icon(Icons.chevron_right),
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

class CreateDataPage extends StatefulWidget{
  final List<CameraDescription> cameras;
  const CreateDataPage({super.key,required this.cameras});
  @override State<CreateDataPage> createState()=>_CreateDataPageState();
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
    pimController.dispose();templeController.dispose();super.dispose();
  }

  Future<void> save()async{
    if(nameController.text.trim().isEmpty){
      msg(context,'กรุณาใส่ชื่อพระ');return;
    }
    final items=await loadAllItems();
    items.add(AmuletData(
      id:newId(),name:nameController.text.trim(),
      model:modelController.text.trim(),pim:pimController.text.trim(),
      type:type,temple:templeController.text.trim(),
    ));
    await saveAllItems(items);
    if(mounted){msg(context,'บันทึกข้อมูลเรียบร้อย');Navigator.pop(context);}
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('สร้าง / บันทึกข้อมูล')),
    body:ListView(
      padding:const EdgeInsets.all(16),
      children:[
        TextField(controller:nameController,decoration:const InputDecoration(
          labelText:'ชื่อพระ',border:OutlineInputBorder())),
        const SizedBox(height:12),
        TextField(controller:modelController,decoration:const InputDecoration(
          labelText:'รุ่น',border:OutlineInputBorder())),
        const SizedBox(height:12),
        DropdownButtonFormField<String>(
          value:type,decoration:const InputDecoration(
            labelText:'ชนิดพระ',border:OutlineInputBorder()),
          items:amuletTypes.map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),
          onChanged:(v)=>setState(()=>type=v??type),
        ),
        const SizedBox(height:12),
        TextField(controller:pimController,decoration:const InputDecoration(
          labelText:'พิมพ์',border:OutlineInputBorder())),
        const SizedBox(height:12),
        TextField(controller:templeController,decoration:const InputDecoration(
          labelText:'วัด',border:OutlineInputBorder())),
        const SizedBox(height:20),
        FilledButton.icon(
          onPressed:save,icon:const Icon(Icons.save),
          label:const Padding(
            padding:EdgeInsets.all(12),
            child:Text('บันทึกข้อมูล',style:TextStyle(fontSize:18)),
          ),
        ),
      ],
    ),
  );
}

class SavedListPage extends StatefulWidget{
  final List<CameraDescription> cameras;
  const SavedListPage({super.key,required this.cameras});
  @override State<SavedListPage> createState()=>_SavedListPageState();
}

class _SavedListPageState extends State<SavedListPage>{
  List<AmuletData> items=[];String search='';

  @override
  void initState(){super.initState();load();}

  Future<void> load()async{
    final x=await loadAllItems();
    if(mounted)setState(()=>items=x);
  }

  Map<String,List<AmuletData>> groups(){
    final m=<String,List<AmuletData>>{};
    for(final e in items){
      if(search.isNotEmpty&&!('${e.name} ${e.model} ${e.type} ${e.temple}')
          .toLowerCase().contains(search.toLowerCase()))continue;
      m.putIfAbsent(groupKey(e),()=>[]).add(e);
    }
    return m;
  }

  Future<void> deleteGroup(String key)async{
    final ok=await showDialog<bool>(
      context:context,builder:(c)=>AlertDialog(
        title:const Text('ลบข้อมูล'),
        content:const Text('ต้องการลบข้อมูลกลุ่มนี้ทั้งหมดหรือไม่?'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('ยกเลิก')),
          FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('ลบ')),
        ],
      ),
    );
    if(ok!=true)return;
    items.removeWhere((e)=>groupKey(e)==key);
    await saveAllItems(items);setState((){});
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
                        '${a.model.isEmpty?'ไม่ระบุรุ่น':a.model}'
                        ' • ${a.type.isEmpty?'ไม่ระบุชนิด':a.type}'
                        '\nพื้นฐาน 5+ องค์ • ${g.value.length} องค์',
                      ),
                      isThreeLine:true,
                      trailing:PopupMenuButton<String>(
                        onSelected:(v)async{
                          if(v=='edit'){
                            await go(c,EditGroupPage(group:g.value));await load();
                          }else await deleteGroup(g.key);
                        },
                        itemBuilder:(_)=>const[
                          PopupMenuItem(value:'edit',child:Text('แก้ไขกลุ่ม')),
                          PopupMenuItem(value:'delete',child:Text('ลบกลุ่ม')),
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

class EditGroupPage extends StatefulWidget{
  final List<AmuletData> group;
  const EditGroupPage({super.key,required this.group});
  @override State<EditGroupPage> createState()=>_EditGroupPageState();
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
    type=a.type.isEmpty?amuletTypes.first:a.type;
  }

  @override
  void dispose(){
    name.dispose();model.dispose();pim.dispose();temple.dispose();super.dispose();
  }

  Future<void> save()async{
    final all=await loadAllItems(),key=groupKey(widget.group.first);
    for(final e in all){
      if(groupKey(e)==key){
        e.name=name.text.trim();e.model=model.text.trim();
        e.pim=pim.text.trim();e.type=type;e.temple=temple.text.trim();
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
        DropdownButtonFormField<String>(
          value:amuletTypes.contains(type)?type:amuletTypes.last,
          decoration:const InputDecoration(
            labelText:'ชนิดพระ',border:OutlineInputBorder()),
          items:amuletTypes.map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),
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
          onPressed:save,icon:const Icon(Icons.save),
          label:const Text('บันทึกการแก้ไข'),
        ),
      ],
    ),
  );
}

class AmuletGroupPage extends StatefulWidget{
  final List<AmuletData> group;
  final List<CameraDescription> cameras;
  const AmuletGroupPage({super.key,required this.group,required this.cameras});
  @override State<AmuletGroupPage> createState()=>_AmuletGroupPageState();
}

class _AmuletGroupPageState extends State<AmuletGroupPage>{
  late List<AmuletData> group;

  @override
  void initState(){
    super.initState();
    group=[...widget.group]..sort((a,b)=>a.id.compareTo(b.id));
  }

  Future<void> refresh()async{
    final all=await loadAllItems(),key=groupKey(widget.group.first);
    final x=all.where((e)=>groupKey(e)==key).toList()
      ..sort((a,b)=>a.id.compareTo(b.id));
    if(mounted)setState(()=>group=x);
  }

  Future<void> deleteItem(AmuletData item)async{
    final ok=await showDialog<bool>(
      context:context,builder:(c)=>AlertDialog(
        title:const Text('ลบรายการอ้างอิง'),
        content:const Text('ต้องการลบรายการองค์จริงนี้หรือไม่?'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('ยกเลิก')),
          FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('ลบ')),
        ],
      ),
    );
    if(ok!=true)return;
    final all=await loadAllItems();
    all.removeWhere((e)=>e.id==item.id);
    await saveAllItems(all);await refresh();
  }

  Future<void> addReference()async{
    if(group.isEmpty)return;
    final a=group.first,all=await loadAllItems();
    final e=AmuletData(
      id:newId(),name:a.name,model:a.model,pim:a.pim,
      type:a.type,temple:a.temple,
    );
    all.add(e);await saveAllItems(all);
    await go(context,ScanPage(item:e,cameras:widget.cameras));
    await refresh();
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:Text(
      widget.group.first.name.isEmpty?'รายการอ้างอิง':widget.group.first.name)),
    floatingActionButton:FloatingActionButton.extended(
      onPressed:addReference,icon:const Icon(Icons.add),
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
                  widget.group.first.name.isEmpty?'ไม่ระบุชื่อ':widget.group.first.name,
                  style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
                Text('รุ่น: ${widget.group.first.model.isEmpty?'ไม่ระบุ':widget.group.first.model}'),
                Text('ชนิด: ${widget.group.first.type.isEmpty?'ไม่ระบุ':widget.group.first.type}'),
                const SizedBox(height:6),
                const Text('พื้นฐาน 5+ องค์ เป็นเพียงตัวเตือน สามารถเพิ่มได้ไม่จำกัด'),
              ],
            ),
          ),
        ),
        ...group.map((e)=>Card(
          child:ListTile(
            leading:const Icon(Icons.account_balance_outlined),
            title:const Text('องค์จริง'),
            subtitle:Text('สแกนแล้ว ${e.scans.length}/${scanAreas.length} จุด'),
            trailing:PopupMenuButton<String>(
              onSelected:(v)async{if(v=='delete')await deleteItem(e);},
              itemBuilder:(_)=>const[
                PopupMenuItem(value:'delete',child:Text('ลบรายการนี้')),
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

class ScanPage extends StatefulWidget{
  final AmuletData item;
  final List<CameraDescription> cameras;
  const ScanPage({super.key,required this.item,required this.cameras});
  @override State<ScanPage> createState()=>_ScanPageState();
}

class _ScanPageState extends State<ScanPage>{
  final picker=ImagePicker();
  CameraController? camera;
  String area=scanAreas.first;
  bool realObject=true,history=true,autoNext=true,scanning=false;
  int frames=0;

  @override
  void initState(){super.initState();loadSettings();}

  Future<void> loadSettings()async{
    final p=await prefs();
    if(mounted)setState((){
      realObject=p.getBool('setting_real_object_default')??true;
      history=p.getBool('setting_show_scan_history')??true;
      autoNext=p.getBool('setting_auto_next_area')??true;
    });
  }

  int count(String a)=>widget.item.scans.where((e)=>e.area==a).length;

  List<String> areas(){
    final x=<String>[...scanAreas];
    for(final s in widget.item.scans){
      if(s.area.isNotEmpty&&!x.contains(s.area))x.add(s.area);
    }
    return x;
  }

  Future<void> start(String a)async{
    setState(()=>area=a);
    if(realObject&&widget.cameras.isNotEmpty){
      await openCamera();
    }else{
      final f=await picker.pickImage(source:ImageSource.gallery);
      if(f!=null)await saveScan('นำเข้าจากโทรศัพท์');
    }
  }

  Future<void> openCamera()async{
    final cam=widget.cameras.firstWhere(
      (e)=>e.lensDirection==CameraLensDirection.back,
      orElse:()=>widget.cameras.first,
    );

    camera=CameraController(cam,ResolutionPreset.medium,enableAudio:false);

    try{
      await camera!.initialize();
      frames=0;scanning=true;
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

      if(mounted)await showDialog(
        context:context,barrierDismissible:false,
        builder:(c)=>AlertDialog(
          title:Text('กำลังสแกน $area'),
          content:SizedBox(
            width:280,height:360,
            child:Column(
              children:[
                Expanded(
                  child:camera!.value.isInitialized
                    ?CameraPreview(camera!)
                    :const Center(child:CircularProgressIndicator()),
                ),
                const SizedBox(height:8),
                Text('เฟรมชั่วคราว $frames / 12'),
                const Text('ภาพถูกใช้ชั่วคราวใน RAM และไม่บันทึกเป็นรูปภาพ'),
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

      await saveScan('กล้อง');
    }catch(e){
      if(mounted)msg(context,'เปิดกล้องไม่สำเร็จ: $e');
    }finally{
      try{await camera?.stopImageStream();}catch(_){}
      await camera?.dispose();
      camera=null;scanning=false;
    }
  }

  Future<void> saveScan(String method)async{
    final s=ScanData(
      area:area,method:method,
      details:{
        'analysisStatus':'รอระบบ AI วิเคราะห์',
        'aiStatus':'pending','aiFindings':[],'aiNotes':'',
        'aiConfidence':null,'aiAnalyzedAt':null,'sourceArea':area,
        'imageSaved':false,'temporaryOnly':true,
        'canCompareWithPreviousScans':true,'surfaceDetails':[],
        'defects':[],'moldDetails':[],'castingLines':[],
        'patternDetails':[],'observations':[],
        'referenceModel':{
          'available':false,'sourceType':'reference_data',
          'isActualObjectMeasurement':false,
          'imagePixelSizeIsNotRealSize':true,
          'size':{
            'height':null,'width':null,'thickness':null,
            'weight':null,'range':[],'unit':'cm'
          },
          'proportion':null,'sourceCount':0,
          'sourceReliability':null,'canCompareWithScan':true,
        },
        'referenceComparison':{
          'enabled':true,'referenceModelAvailable':false,
          'result':null,'differences':[],
          'sizeDifference':null,'proportionDifference':null,
        },
        'authenticityDecision':{
          'enabled':false,'result':null,
          'note':'ขนาดและสัดส่วนใช้เป็นหลักฐานประกอบ ไม่ตัดสินแท้/เก๊เพียงอย่างเดียว',
        },
      },
      imageFeatures:{
        'modelName':'','modelVersion':'','featureVersion':2,
        'embedding':[],'quality':null,
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
        (a)=>count(a)==0,orElse:()=>area);
      setState(()=>area=next);
    }else{
      setState((){});
    }
  }

  Future<void> addCustomArea()async{
    final c=TextEditingController();
    final ok=await showDialog<bool>(
      context:context,
      builder:(d)=>AlertDialog(
        title:const Text('เพิ่มพื้นที่สแกน'),
        content:TextField(
          controller:c,
          decoration:const InputDecoration(labelText:'ชื่อพื้นที่')),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('ยกเลิก')),
          FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('เพิ่ม')),
        ],
      ),
    );
    final v=c.text.trim();c.dispose();
    if(ok==true&&v.isNotEmpty)setState(()=>area=v);
  }

  @override
  Widget build(BuildContext c){
    final list=areas();
    final completed=list.where((e)=>count(e)>0).length;
    final observations=observationPointsFor(widget.item.type);

    return Scaffold(
      appBar:AppBar(
        title:const Text('สแกนข้อมูล'),
        actions:[
          IconButton(
            onPressed:()=>go(c,AiReconstructionPage(
              scan:widget.item.scans.isEmpty
                ?ScanData(area:area,method:'ยังไม่มี')
                :widget.item.scans.last)),
            icon:const Icon(Icons.auto_awesome),
          ),
        ],
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
                    widget.item.name.isEmpty?'ไม่ระบุชื่อ':widget.item.name,
                    style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
                  Text('รุ่น: ${widget.item.model.isEmpty?'ไม่ระบุ':widget.item.model}'),
                  Text('ชนิด: ${widget.item.type.isEmpty?'อื่น ๆ':widget.item.type}'),
                  const SizedBox(height:6),
                  Text('ความคืบหน้า $completed/${list.length} จุด'),
                ],
              ),
            ),
          ),
          Card(
            child:Padding(
              padding:const EdgeInsets.all(14),
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  const Text('พื้นที่ที่เลือก',
                    style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
                  const SizedBox(height:8),
                  Text(area),
                  const SizedBox(height:10),
                  Wrap(
                    spacing:8,runSpacing:8,
                    children:[
                      FilledButton.icon(
                        onPressed:()=>start(area),
                        icon:const Icon(Icons.camera_alt),
                        label:Text(realObject?'สแกนองค์จริง':'เริ่มสแกน'),
                      ),
                      OutlinedButton.icon(
                        onPressed:()async{
                          final old=realObject;
                          setState(()=>realObject=false);
                          await start(area);
                          if(mounted)setState(()=>realObject=old);
                        },
                        icon:const Icon(Icons.photo_library),
                        label:const Text('จากตัวเครื่อง'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            child:Padding(
              padding:const EdgeInsets.all(14),
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  const Text('จุดสังเกต',
                    style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
                  const SizedBox(height:8),
                  const Text('สิ่งที่ระบบ AI ควรตรวจสอบจากภาพสแกน'),
                  const SizedBox(height:10),
                  Wrap(
                    spacing:6,runSpacing:6,
                    children:observations.map((e)=>Chip(
                      avatar:const Icon(Icons.visibility_outlined,size:18),
                      label:Text(e),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child:Padding(
              padding:const EdgeInsets.all(14),
              child:Column(
                children:[
                  Row(
                    children:[
                      const Expanded(
                        child:Text('พื้นที่สแกน',
                          style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
                      ),
                      TextButton.icon(
                        onPressed:addCustomArea,
                        icon:const Icon(Icons.add),
                        label:const Text('เพิ่ม'),
                      ),
                    ],
                  ),
                  ...list.map((a)=>RadioListTile<String>(
                    value:a,groupValue:area,title:Text(a),
                    subtitle:Text('สแกนแล้ว ${count(a)} ครั้ง'),
                    onChanged:(v)=>setState(()=>area=v!),
                  )),
                ],
              ),
            ),
          ),
          if(history)Card(
            child:Padding(
              padding:const EdgeInsets.all(14),
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  const Text('ประวัติการสแกน',
                    style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
                  if(widget.item.scans.isEmpty)
                    const Padding(
                      padding:EdgeInsets.only(top:8),
                      child:Text('ยังไม่มีประวัติการสแกน'))
                  else
                    ...widget.item.scans.map((s)=>ListTile(
                      dense:true,
                      leading:const Icon(Icons.check_circle_outline),
                      title:Text(s.area),
                      subtitle:Text(s.method),
                      trailing:Text(
                        s.details['aiStatus']=='pending'?'รอ AI':'วิเคราะห์แล้ว'),
                    )),
                ],
              ),
            ),
          ),
          Card(
            child:Padding(
              padding:const EdgeInsets.all(14),
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  const Text('AI',
                    style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
                  const SizedBox(height:6),
                  const Text('ระบบเตรียมข้อมูลสำหรับ AI โดยยังไม่เก็บรูปภาพต้นฉบับ'),
                  const SizedBox(height:10),
                  OutlinedButton.icon(
                    onPressed:()=>go(c,AiReconstructionPage(
                      scan:widget.item.scans.isEmpty
                        ?ScanData(area:area,method:'ยังไม่มี')
                        :widget.item.scans.last)),
                    icon:const Icon(Icons.auto_awesome),
                    label:const Text('ทดสอบภาพจำลอง AI'),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child:Padding(
              padding:const EdgeInsets.all(14),
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  const Text('ขนาดจากข้อมูลอ้างอิง',
                    style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
                  const SizedBox(height:6),
                  const Text(
                    'AI สามารถสร้าง Reference Model จากข้อมูลอ้างอิง หลายแหล่งได้ โดยไม่ใช้ขนาดพิกเซลของรูปแทนขนาดจริง'),
                  const SizedBox(height:6),
                  const Text(
                    'ยังไม่ใช่การวัดองค์จริง และจะไม่ใช้ขนาดเพียงอย่างเดียว ในการตัดสินความแท้'),
                ],
              ),
            ),
          ),
          const Card(
            child:Padding(
              padding:EdgeInsets.all(14),
              child:Row(
                children:[
                  Icon(Icons.lock_outline),
                  SizedBox(width:10),
                  Expanded(
                    child:Text(
                      'ความเป็นส่วนตัว: ภาพจากกล้องหรือโทรศัพท์ใช้ชั่วคราว ไม่บันทึกรูปภาพ และไม่เก็บไฟล์ภาพลงฐานข้อมูล',
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

class BackupPage extends StatefulWidget{
  const BackupPage({super.key});
  @override State<BackupPage> createState()=>_BackupPageState();
}

class _BackupPageState extends State<BackupPage>{
  Future<void> backup()async{
    final items=await loadAllItems();
    final data=jsonEncode({
      'backupVersion':4,'containsImages':false,
      'createdAt':DateTime.now().toIso8601String(),
      'items':items.map((e)=>e.toMap()).toList(),
    });

    final path=await FilePicker.platform.saveFile(
      dialogTitle:'บันทึกไฟล์สำรอง',
      fileName:'amulet_backup.json',
      type:FileType.custom,allowedExtensions:['json'],
    );
    if(path==null)return;
    await File(path).writeAsString(data);
    if(mounted)msg(context,'สำรองข้อมูลเรียบร้อย');
  }

  Future<void> restore()async{
    final r=await FilePicker.platform.pickFiles(
      type:FileType.custom,allowedExtensions:['json']);
    if(r==null||r.files.single.path==null)return;

    try{
      final data=jsonDecode(
        await File(r.files.single.path!).readAsString());
      final list=(data['items'] as List)
        .map((e)=>AmuletData.fromMap(Map<String,dynamic>.from(e)))
        .toList();

      if(!mounted)return;
      final ok=await showDialog<bool>(
        context:context,
        builder:(c)=>AlertDialog(
          title:const Text('นำเข้าข้อมูล'),
          content:Text('พบข้อมูล ${list.length} รายการ ต้องการแทนที่ข้อมูลเดิมหรือไม่?'),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('ยกเลิก')),
            FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('นำเข้า')),
          ],
        ),
      );
      if(ok!=true)return;
      await
