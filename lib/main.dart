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
    {'stage':_aiFront,'name':'ด้านหน้า','priority':'primary','requirePreviousPass':false},
    {'stage':_aiBack,'name':'ด้านหลัง','priority':'primary','requirePreviousPass':true},
    {'stage':_aiSideBottom,'name':'ด้านข้าง / ก้นพระ','priority':'primary','requirePreviousPass':true},
    {'stage':_aiDetails,'name':'รายละเอียดทั้งหมด','priority':'secondary','requirePreviousPass':true}
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
      final list=jsonDecode(utf8.decode(gzip.decode(base64Decode(z))))as List;
      return list.map((e)=>AmuletData.fromMap(Map<String,dynamic>.from(e))).toList();
    }
  }catch(_){}
  try{
    final old=p.getString(oldDataKey);
    if(old!=null&&old.isNotEmpty){
      final list=jsonDecode(old)as List;
      final items=list.map((e)=>AmuletData.fromMap(Map<String,dynamic>.from(e))).toList();
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

/* ================= MODEL ================= */

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

class AmuletData{
  int id;
  String name,model,pim,type,temple;
  String province,year,material,size;
  String frontDetail,sideDetail,backDetail;
  List<ScanData> scans;

  AmuletData({
    required this.id,
    this.name='',this.model='',this.pim='',
    this.type='',this.temple='',
    this.province='',this.year='',this.material='',this.size='',
    this.frontDetail='',this.sideDetail='',this.backDetail='',
    List<ScanData>? scans
  }):scans=scans??[];

  Map<String,dynamic> toMap()=> {
    'id':id,'name':name,'model':model,'pim':pim,
    'type':type,'temple':temple,'province':province,
    'year':year,'material':material,'size':size,
    'frontDetail':frontDetail,'sideDetail':sideDetail,
    'backDetail':backDetail,
    'scans':scans.map((e)=>e.toMap()).toList()
  };

  factory AmuletData.fromMap(Map<String,dynamic> m)=>AmuletData(
    id:int.tryParse('${m['id']??0}')??0,
    name:'${m['name']??''}',
    model:'${m['model']??''}',
    pim:'${m['pim']??''}',
    type:'${m['type']??''}',
    temple:'${m['temple']??''}',
    province:'${m['province']??''}',
    year:'${m['year']??''}',
    material:'${m['material']??''}',
    size:'${m['size']??''}',
    frontDetail:'${m['frontDetail']??''}',
    sideDetail:'${m['sideDetail']??''}',
    backDetail:'${m['backDetail']??''}',
    scans:m['scans'] is List
      ?(m['scans'] as List).map((e)=>ScanData.fromMap(
          Map<String,dynamic>.from(e))).toList()
      :[]
  );
}

class ScanData{
  String area,method;
  Map<String,dynamic> details,imageFeatures;

  ScanData({
    required this.area,
    required this.method,
    Map<String,dynamic>? details,
    Map<String,dynamic>? imageFeatures
  }):details=details??{},
     imageFeatures=imageFeatures??{};

  Map<String,dynamic> toMap()=> {
    'area':area,'method':method,
    'details':details,'imageFeatures':imageFeatures
  };

  factory ScanData.fromMap(Map<String,dynamic> m)=>ScanData(
    area:'${m['area']??''}',
    method:'${m['method']??''}',
    details:m['details'] is Map
      ?Map<String,dynamic>.from(m['details']):{},
    imageFeatures:m['imageFeatures'] is Map
      ?Map<String,dynamic>.from(m['imageFeatures']):{}
  );
}

/* ================= AI DATA ================= */

Map<String,dynamic> referenceModel()=> {
  'enabled':true,
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
  'note':'ขนาดนี้มาจากข้อมูลอ้างอิง ไม่ใช่การวัดองค์จริง'
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
    'วิเคราะห์และจดจำรายละเอียดทั้งหมดที่มองเห็นได้จากภาพสแกน '
    'โดยไม่จำกัดเฉพาะจุดที่กำหนดไว้ '
    'หากรายละเอียดไม่ชัดให้ระบุว่าตรวจสอบไม่ได้ '
    'ห้ามเดาว่าไม่มีรายละเอียด',

  'analysisFlow':aiComparisonRule(),
  'referenceScope':'all_references',
  'compareEveryAvailableReference':true,

  'referenceComparison':{
    'enabled':true,
    'referenceScope':'all_references',
    'compareEveryAvailableReference':true,
    'result':null,
    'matches':[],
    'differences':[],
    'wearFromUse':[],
    'notVisible':[],
    'uncertain':[],
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
    'rememberAllVisibleDetails':true,
    'fixedObservationPoints':false,
    'typeDependentObservationPoints':false,
    'wearMustBeSeparatedFromOriginalPattern':true,
    'notVisibleMeansCannotVerify':true,
    'doNotGuessMissingDetails':true,
    'smallDetailsNeedSufficientImageQuality':true,
    'canUseReferenceSize':true,
    'sizeMustComeFromReferenceData':true,
    'imagePixelsAreNotRealSize':true,
    'doNotJudgeAuthenticityFromSizeAlone':true
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
        tile(c,'สร้าง / บันทึกข้อมูล','สร้างข้อมูลพระและเหรียญ',
          Icons.add_box_outlined,CreateDataPage(cameras:cameras)),
        tile(c,'รายการข้อมูลที่บันทึก','ดู แก้ไข ลบ และสแกนเพิ่มข้อมูล',
          Icons.folder_open,SavedListPage(cameras:cameras)),
        tile(c,'สำรอง / นำเข้าข้อมูล','สำรองหรือนำข้อมูลกลับเข้าเครื่อง',
          Icons.import_export,const BackupPage()),
        tile(c,'ตั้งค่า','ตั้งค่าการสแกนและการแสดงข้อมูล',
          Icons.settings,const SettingsPage())
      ]
    )
  );
}

/* ================= CREATE ================= */

class CreateDataPage extends StatefulWidget{
  final List<CameraDescription> cameras;
  const CreateDataPage({super.key,required this.cameras});

  @override
  State<CreateDataPage> createState()=>_CreateDataPageState();
}

class _CreateDataPageState extends State<CreateDataPage>{
  final nameController=TextEditingController();
  final modelController=TextEditingController();
  final pimController=TextEditingController();
  final templeController=TextEditingController();
  String type=amuletTypes.first;

  @override
  void dispose(){
    nameController.dispose();
    modelController.dispose();
    pimController.dispose();
    templeController.dispose();
    super.dispose();
  }

  Future<void> save()async{
    if(nameController.text.trim().isEmpty){
      msg(context,'กรุณาใส่ชื่อพระ');
      return;
    }

    final items=await loadAllItems();
    items.add(AmuletData(
      id:newId(),
      name:nameController.text.trim(),
      model:modelController.text.trim(),
      pim:pimController.text.trim(),
      type:type,
      temple:templeController.text.trim()
    ));
    await saveAllItems(items);

    if(!mounted)return;
    msg(context,'บันทึกข้อมูลเรียบร้อย');
    Navigator.pop(context);
  }

  Widget field(TextEditingController x,String label)=>TextField(
    controller:x,
    decoration:InputDecoration(
      labelText:label,border:const OutlineInputBorder()
    )
  );

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('สร้าง / บันทึกข้อมูล')),
    body:ListView(
      padding:const EdgeInsets.all(16),
      children:[
        field(nameController,'ชื่อพระ'),
        const SizedBox(height:12),
        field(modelController,'รุ่น'),
        const SizedBox(height:12),
        DropdownButtonFormField<String>(
          value:type,
          decoration:const InputDecoration(
            labelText:'ชนิดพระ',border:OutlineInputBorder()
          ),
          items:amuletTypes.map((e)=>DropdownMenuItem(
            value:e,child:Text(e)
          )).toList(),
          onChanged:(v)=>setState(()=>type=v??type)
        ),
        const SizedBox(height:12),
        field(pimController,'พิมพ์'),
        const SizedBox(height:12),
        field(templeController,'วัด'),
        const SizedBox(height:20),
        FilledButton.icon(
          onPressed:save,
          icon:const Icon(Icons.save),
          label:const Padding(
            padding:EdgeInsets.all(12),
            child:Text('บันทึกข้อมูล',style:TextStyle(fontSize:18))
          )
        )
      ]
    )
  );
}

/* ================= SAVED LIST ================= */

class SavedListPage extends StatefulWidget{
  final List<CameraDescription> cameras;
  const SavedListPage({super.key,required this.cameras});

  @override
  State<SavedListPage> createState()=>_SavedListPageState();
}

class _SavedListPageState extends State<SavedListPage>{
  List<AmuletData> items=[];
  String search='';

  @override
  void initState(){
    super.initState();
    load();
  }

  Future<void> load()async{
    final x=await loadAllItems();
    if(mounted)setState(()=>items=x);
  }

  Map<String,List<AmuletData>> groups(){
    final m=<String,List<AmuletData>>{};
    for(final e in items){
      final q='${e.name} ${e.model} ${e.type} ${e.temple}'.toLowerCase();
      if(search.isNotEmpty&&!q.contains(search.toLowerCase()))continue;
      m.putIfAbsent(groupKey(e),()=>[]).add(e);
    }
    return m;
  }

  Future<void> deleteGroup(String key)async{
    final ok=await showDialog<bool>(
      context:context,
      builder:(c)=>AlertDialog(
        title:const Text('ลบข้อมูล'),
        content:const Text(
          'ต้องการลบข้อมูลกลุ่มนี้ทั้งหมดหรือไม่?\n'
          'ข้อมูลอ้างอิงและประวัติการสแกนทั้งหมดจะถูกลบ'
        ),
        actions:[
          TextButton(
            onPressed:()=>Navigator.pop(c,false),
            child:const Text('ยกเลิก')
          ),
          FilledButton(
            onPressed:()=>Navigator.pop(c,true),
            child:const Text('ลบ')
          )
        ]
      )
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
                labelText:'ค้นหา',
                border:OutlineInputBorder()
              )
            )
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
                        'รายการอ้างอิง ${g.value.length} รายการ'
                      ),
                      isThreeLine:true,
                      trailing:PopupMenuButton<String>(
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
                            value:'edit',child:Text('แก้ไขกลุ่ม')
                          ),
                          PopupMenuItem(
                            value:'delete',child:Text('ลบกลุ่ม')
                          )
                        ]
                      ),
                      onTap:()async{
                        await go(c,AmuletGroupPage(
                          group:g.value,cameras:widget.cameras
                        ));
                        await load();
                      }
                    )
                  );
                }).toList()
              )
          )
        ]
      )
    );
  }
}

/* ================= EDIT GROUP ================= */

class EditGroupPage extends StatefulWidget{
  final List<AmuletData> group;
  const EditGroupPage({super.key,required this.group});

  @override
  State<EditGroupPage> createState()=>_EditGroupPageState();
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
    name.dispose();
    model.dispose();
    pim.dispose();
    temple.dispose();
    super.dispose();
  }

  Future<void> save()async{
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

  Widget field(TextEditingController x,String label)=>TextField(
    controller:x,
    decoration:InputDecoration(
      labelText:label,border:const OutlineInputBorder()
    )
  );

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('แก้ไขข้อมูลกลุ่ม')),
    body:ListView(
      padding:const EdgeInsets.all(16),
      children:[
        field(name,'ชื่อพระ'),
        const SizedBox(height:12),
        field(model,'รุ่น'),
        const SizedBox(height:12),
        DropdownButtonFormField<String>(
          value:type,
          decoration:const InputDecoration(
            labelText:'ชนิดพระ',border:OutlineInputBorder()
          ),
          items:amuletTypes.map((e)=>DropdownMenuItem(
            value:e,child:Text(e)
          )).toList(),
          onChanged:(v)=>setState(()=>type=v??type)
        ),
        const SizedBox(height:12),
        field(pim,'พิมพ์'),
        const SizedBox(height:12),
        field(temple,'วัด'),
        const SizedBox(height:20),
        FilledButton.icon(
          onPressed:save,
          icon:const Icon(Icons.save),
          label:const Text('บันทึกการแก้ไข')
        )
      ]
    )
  );
}

/* ================= REFERENCE GROUP ================= */

class AmuletGroupPage extends StatefulWidget{
  final List<AmuletData> group;
  final List<CameraDescription> cameras;

  const AmuletGroupPage({
    super.key,required this.group,required this.cameras
  });

  @override
  State<AmuletGroupPage> createState()=>_AmuletGroupPageState();
}

class _AmuletGroupPageState extends State<AmuletGroupPage>{
  late List<AmuletData> group;

  @override
  void initState(){
    super.initState();
    group=[...widget.group];
  }

  Future<void> refresh()async{
    final all=await loadAllItems();
    final key=groupKey(widget.group.first);
    final x=all.where((e)=>groupKey(e)==key).toList();
    if(mounted)setState(()=>group=x);
  }

  int scannedAreas(AmuletData e)=>scanAreas.where(
    (a)=>e.scans.any((s)=>s.area==a)
  ).length;

  Future<void> deleteItem(AmuletData item)async{
    final ok=await showDialog<bool>(
      context:context,
      builder:(c)=>AlertDialog(
        title:const Text('ลบรายการอ้างอิง'),
        content:const Text(
          'ต้องการลบรายการอ้างอิงนี้ทั้งหมด '
          'รวมประวัติการสแกนหรือไม่?'
        ),
        actions:[
          TextButton(
            onPressed:()=>Navigator.pop(c,false),
            child:const Text('ยกเลิก')
          ),
          FilledButton(
            onPressed:()=>Navigator.pop(c,true),
            child:const Text('ลบ')
          )
        ]
      )
    );

    if(ok!=true)return;

    final all=await loadAllItems();
    all.removeWhere((e)=>e.id==item.id);
    await saveAllItems(all);
    await refresh();
  }

  Future<void> addReference()async{
    if(group.isEmpty)return;

    final a=group.first;
    final all=await loadAllItems();

    final e=AmuletData(
      id:newId(),name:a.name,model:a.model,pim:a.pim,
      type:a.type,temple:a.temple
    );

    all.add(e);
    await saveAllItems(all);

    if(!mounted)return;

    await go(context,ScanPage(
      item:e,cameras:widget.cameras
    ));

    await refresh();
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(
      title:Text(
        widget.group.first.name.isEmpty
          ?'รายการอ้างอิง'
          :widget.group.first.name
      )
    ),
    floatingActionButton:FloatingActionButton.extended(
      onPressed:addReference,
      icon:const Icon(Icons.add),
      label:const Text('เพิ่มรายการอ้างอิง')
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
                    ?'ไม่ระบุชื่อ'
                    :widget.group.first.name,
                  style:const TextStyle(
                    fontSize:20,fontWeight:FontWeight.bold
                  )
                ),
                Text(
                  'รุ่น: ${widget.group.first.model.isEmpty?'ไม่ระบุ':widget.group.first.model}'
                ),
                Text(
                  'ชนิด: ${widget.group.first.type.isEmpty?'ไม่ระบุ':widget.group.first.type}'
                ),
                const SizedBox(height:6),
                const Text(
                  'พื้นฐาน 5+ องค์ เป็นเพียงตัวเตือน '
                  'สามารถเพิ่มรายการอ้างอิงได้ไม่จำกัด'
                )
              ]
            )
          )
        ),
        ...group.map((e)=>Card(
          child:ListTile(
            leading:const Icon(Icons.account_balance_outlined),
            title:const Text('รายการอ้างอิง'),
            subtitle:Text(
              'สแกนแล้ว ${scannedAreas(e)}/${scanAreas.length} จุด'
            ),
            trailing:PopupMenuButton<String>(
              onSelected:(v)async{
                if(v=='delete')await deleteItem(e);
              },
              itemBuilder:(_)=>const[
                PopupMenuItem(
                  value:'delete',child:Text('ลบรายการนี้')
                )
              ]
            ),
            onTap:()async{
              await go(c,ScanPage(
                item:e,cameras:widget.cameras
              ));
              await refresh();
            }
          )
        )),
        const SizedBox(height:80)
      ]
    )
  );
}

/* ================= SCAN ================= */

class ScanPage extends StatefulWidget{
  final AmuletData item;
  final List<CameraDescription> cameras;

  const ScanPage({
    super.key,required this.item,required this.cameras
  });

  @override
  State<ScanPage> createState()=>_ScanPageState();
}

class _ScanPageState extends State<ScanPage>{
  final picker=ImagePicker();
  CameraController? camera;

  String area=scanAreas.first;

  bool realObject=true;
  bool history=true;
  bool autoNext=true;
  bool scanning=false;

  int frames=0;

  @override
  void initState(){
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings()async{
    final p=await prefs();
    if(!mounted)return;

    setState((){
      realObject=p.getBool('setting_real_object_default')??true;
      history=p.getBool('setting_show_scan_history')??true;
      autoNext=p.getBool('setting_auto_next_area')??true;
    });
  }

  int count(String a)=>widget.item.scans.where(
    (e)=>e.area==a
  ).length;

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
      orElse:()=>widget.cameras.first
    );

    camera=CameraController(
      cam,ResolutionPreset.medium,enableAudio:false
    );

    bool completed=false;

    try{
      await camera!.initialize();
      frames=0;
      scanning=true;
      if(mounted)setState((){});

      await camera!.startImageStream((CameraImage image)async{
        if(!scanning)return;
        frames++;

        if(frames>=12){
          completed=true;
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
                      :const Center(child:CircularProgressIndicator())
                  ),
                  const SizedBox(height:8),
                  Text('เฟรมชั่วคราว $frames / 12'),
                  const Text(
                    'ภาพถูกใช้ชั่วคราวใน RAM และไม่บันทึกเป็นรูปภาพ'
                  )
                ]
              )
            ),
            actions:[
              TextButton(
                onPressed:(){
                  scanning=false;
                  try{camera?.stopImageStream();}catch(_){}
                  Navigator.pop(c);
                },
                child:const Text('หยุด')
              )
            ]
          )
        );
      }

      if(completed){
        await saveScan('กล้อง');
      }else if(mounted){
        msg(context,'ยกเลิกการสแกน ยังไม่มีการบันทึกข้อมูล');
      }
    }catch(e){
      if(mounted)msg(context,'เปิดกล้องไม่สำเร็จ: $e');
    }finally{
      try{await camera?.stopImageStream();}catch(_){}
      await camera?.dispose();
      camera=null;
      scanning=false;
    }
  }

  String nextAutoArea(){
    if(area=='ด้านหน้า'){
      if(count('ด้านหลัง')==0)return 'ด้านหลัง';
      if(count('ด้านข้าง')==0)return 'ด้านข้าง';
      if(count('ก้นพระ')==0)return 'ก้นพระ';
    }

    if(area=='ด้านหลัง'){
      if(count('ด้านข้าง')==0)return 'ด้านข้าง';
      if(count('ก้นพระ')==0)return 'ก้นพระ';
    }

    if(area=='ด้านข้าง'||area=='ก้นพระ'){
      final custom=areas().where(
        (a)=>!scanAreas.contains(a)&&count(a)==0
      );
      if(custom.isNotEmpty)return custom.first;
      return area;
    }

    final custom=areas().where(
      (a)=>!scanAreas.contains(a)&&count(a)==0
    );
    if(custom.isNotEmpty)return custom.first;

    return area;
  }

  Future<void> saveScan(String method)async{
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

        'aiObservationMode':'remember_all_visible_details',

        'aiMemory':{
          'allVisibleDetails':[],
          'shape':[],
          'proportion':[],
          'surface':[],
          'material':[],
          'texture':[],
          'pattern':[],
          'marks':[],
          'defects':[],
          'castingDetails':[],
          'wearFromUse':[],
          'specialDetails':[],
          'differences':[],
          'matches':[],
          'notVisible':[],
          'uncertain':[]
        },

        'analysisFlow':{
          'currentArea':area,
          'currentStage':stage,
          'currentStageName':aiStageName(stage),
          'referenceScope':'all_references',
          'compareEveryAvailableReference':true,
          'nextStage':nextStage(stage),
          'requiresPreviousStagePass':stage!=_aiFront
        },

        'comparisonGate':{
          'status':'pending',
          'passMeaning':'สอดคล้องกับอ้างอิงเพียงพอ',
          'failMeaning':'พบความแตกต่างจากอ้างอิง',
          'uncertainMeaning':'ภาพไม่ชัดหรือข้อมูลไม่เพียงพอ',
          'doNotJudgeAuthenticity':true
        },

        'wearAnalysis':{
          'enabled':true,
          'separateFromPattern':true,
          'status':'pending',
          'findings':[]
        },

        'analysisOrder':[
          'remember_all_visible_details',
          'compare_with_all_references',
          'separate_wear_from_original',
          'mark_unclear_details_as_not_visible'
        ],

        'patternAnalysis':{
          'status':'pending',
          'result':null,
          'allVisibleDetails':[],
          'matches':[],
          'differences':[],
          'confidence':null
        },

        'detailAnalysis':{
          'status':'pending',
          'result':null,
          'allVisibleDetails':[],
          'matches':[],
          'differences':[],
          'notVisible':[],
          'uncertain':[],
          'confidence':null
        },

        'imageCheck':{
          'status':'pending',
          'quality':null,
          'patternVisibility':null,
          'smallDetailVisibility':null,
          'needsCloseup':false,
          'suggestedAreas':[]
        },

        'verificationStatus':{
          'pattern':'ยังไม่ได้วิเคราะห์',
          'details':'ยังไม่ได้วิเคราะห์',
          'smallDetails':'ยังไม่ได้วิเคราะห์'
        },

        'visibleDetails':[],
        'surfaceDetails':[],
        'defects':[],
        'moldDetails':[],
        'castingLines':[],
        'patternDetails':[],
        'marks':[],
        'materialDetails':[],
        'textureDetails':[],
        'specialDetails':[],
        'wornDetails':[],
        'uncertainDetails':[],
        'notVisibleDetails':[],

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
          'canCompareWithScan':true
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
          'uncertain':[],
          'patternResult':null,
          'detailResult':null,
          'smallDetailResult':null,
          'sizeDifference':null,
          'proportionDifference':null,
          'needsCloseup':[]
        },

        'authenticityDecision':{
          'enabled':false,
          'result':null,
          'note':
            'ระบบเปรียบเทียบกับองค์อ้างอิงทั้งหมด '
            'โดยจดจำรายละเอียดที่มองเห็นได้ทุกอย่าง '
            'แยกความสึกจากการใช้งานออกจากความแตกต่าง '
            'และไม่ตัดสินแท้/เก๊จากจุดใดจุดหนึ่ง'
        }
      },

      imageFeatures:{
        'modelName':'',
        'modelVersion':'',
        'featureVersion':3,
        'embedding':[],
        'quality':null,
        'patternQuality':null,
        'detailQuality':null
      }
    );

    widget.item.scans.add(s);

    final all=await loadAllItems();
    final i=all.indexWhere((e)=>e.id==widget.item.id);

    if(i>=0)all[i]=widget.item;
    else all.add(widget.item);

    await saveAllItems(all);

    if(!mounted)return;

    msg(context,'บันทึกผลสแกน $area แล้ว');

    if(autoNext){
      setState(()=>area=nextAutoArea());
    }else{
      setState((){});
    }
  }

  Future<void> addCustomArea()async{
    final controller=TextEditingController();

    final ok=await showDialog<bool>(
      context:context,
      builder:(d)=>AlertDialog(
        title:const Text('เพิ่มพื้นที่สแกน'),
        content:TextField(
          controller:controller,
          decoration:const InputDecoration(labelText:'ชื่อพื้นที่')
        ),
        actions:[
          TextButton(
            onPressed:()=>Navigator.pop(d,false),
            child:const Text('ยกเลิก')
          ),
          FilledButton(
            onPressed:()=>Navigator.pop(d,true),
            child:const Text('เพิ่ม')
          )
        ]
      )
    );

    final v=controller.text.trim();
    controller.dispose();

    if(ok==true&&v.isNotEmpty)setState(()=>area=v);
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(
      title:Text(area),
      actions:[
        IconButton(
          tooltip:'เพิ่มพื้นที่',
          onPressed:addCustomArea,
          icon:const Icon(Icons.add_location_alt_outlined)
        )
      ]
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
                  widget.item.name.isEmpty
                    ?'ไม่ระบุชื่อ'
                    :widget.item.name,
                  style:const TextStyle(
                    fontSize:20,fontWeight:FontWeight.bold
                  )
                ),
                Text(
                  'รุ่น: ${widget.item.model.isEmpty?'ไม่ระบุ':widget.item.model}'
                ),
                Text(
                  'พิมพ์: ${widget.item.pim.isEmpty?'ไม่ระบุ':widget.item.pim}'
                ),
                Text(
                  'ชนิด: ${widget.item.type.isEmpty?'ไม่ระบุ':widget.item.type}'
                ),
                Text(
                  'วัด: ${widget.item.temple.isEmpty?'ไม่ระบุ':widget.item.temple}'
                )
              ]
            )
          )
        ),

        const SizedBox(height:8),

        Card(
          child:Padding(
            padding:const EdgeInsets.all(12),
            child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                const Text(
                  'พื้นที่สแกน',
                  style:TextStyle(
                    fontSize:17,fontWeight:FontWeight.bold
                  )
                ),
                const SizedBox(height:8),

                Wrap(
                  spacing:8,
                  runSpacing:8,
                  children:areas().map((a)=>ChoiceChip(
                    label:Text(a),
                    selected:area==a,
                    onSelected:(_)=>start(a)
                  )).toList()
                ),

                const SizedBox(height:12),

                SizedBox(
                  width:double.infinity,
                  child:FilledButton.icon(
                    onPressed:()=>start(area),
                    icon:const Icon(Icons.document_scanner),
                    label:Text(
                      realObject
                        ?'สแกน $area'
                        :'นำข้อมูลจากโทรศัพท์'
                    )
                  )
                ),

                const SizedBox(height:6),

                Text(
                  'สแกนพื้นที่นี้แล้ว ${count(area)} ครั้ง',
                  style:Theme.of(c).textTheme.bodySmall
                )
              ]
            )
          )
        ),

        const SizedBox(height:8),

        if(history)
          Card(
            child:ExpansionTile(
              leading:const Icon(Icons.history),
              title:const Text('ประวัติการสแกน'),
              subtitle:Text('${widget.item.scans.length} รายการ'),
              children:widget.item.scans.isEmpty
                ?[
                    const Padding(
                      padding:EdgeInsets.all(16),
                      child:Text('ยังไม่มีประวัติการสแกน')
                    )
                  ]
                :widget.item.scans.reversed.map((s)=>ListTile(
                    leading:const Icon(Icons.check_circle_outline),
                    title:Text(s.area),
                    subtitle:Text('วิธี: ${s.method}')
                  )).toList()
            )
          ),

        const SizedBox(height:8),

        Card(
          child:Padding(
            padding:const EdgeInsets.all(14),
            child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                const Text(
                  'AI จดจำรายละเอียดจากการสแกน',
                  style:TextStyle(
                    fontSize:17,fontWeight:FontWeight.bold
                  )
                ),
                const SizedBox(height:8),
                const Text(
                  'AI จะวิเคราะห์และจดจำรายละเอียดทั้งหมด '
                  'ที่มองเห็นได้จากภาพสแกน '
                  'โดยไม่จำกัดเฉพาะจุดที่กำหนดไว้'
                ),
                const SizedBox(height:6),
                const Text(
                  'รายละเอียดที่มองไม่ชัดจะบันทึกว่า '
                  '“ตรวจสอบไม่ได้ / ภาพไม่ละเอียดพอ” '
                  'และจะไม่เดาว่าไม่มีรายละเอียด'
                ),
                const SizedBox(height:6),
                const Text(
                  'รายละเอียดจากทุกพื้นที่และทุกอ้างอิง '
                  'สามารถนำมาเปรียบเทียบร่วมกันได้'
                )
              ]
            )
          )
        ),

        const SizedBox(height:100)
      ]
    )
  );
}

/* ================= BACKUP ================= */

class BackupPage extends StatefulWidget{
  const BackupPage({super.key});

  @override
  State<BackupPage> createState()=>_BackupPageState();
}

class _BackupPageState extends State<BackupPage>{
  Future<void> backup()async{
    try{
      final items=await loadAllItems();
      final data=jsonEncode(items.map((e)=>e.toMap()).toList());

      final path=await FilePicker.platform.saveFile(
        dialogTitle:'บันทึกไฟล์สำรองข้อมูล',
        fileName:'amulet_scanner_backup.json',
        type:FileType.custom,
        allowedExtensions:['json']
      );

      if(path==null||path.isEmpty)return;

      await File(path).writeAsString(data);

      if(mounted)msg(context,'สำรองข้อมูลเรียบร้อย');
    }catch(e){
      if(mounted)msg(context,'สำรองข้อมูลไม่สำเร็จ: $e');
    }
  }

  Future<void> restore()async{
    try{
      final result=await FilePicker.platform.pickFiles(
        type:FileType.custom,
        allowedExtensions:['json'],
        withData:true
      );

      if(result==null||result.files.isEmpty)return;

      final file=result.files.first;
      String data='';

      if(file.bytes!=null){
        data=utf8.decode(file.bytes!);
      }else if(file.path!=null){
        data=await File(file.path!).readAsString();
      }

      final decoded=jsonDecode(data);

      if(decoded is! List){
        if(mounted)msg(context,'ไฟล์ไม่ใช่ข้อมูลสำรองของแอป');
        return;
      }

      final imported=decoded.map((e)=>AmuletData.fromMap(
        Map<String,dynamic>.from(e)
      )).toList();

      final ok=await showDialog<bool>(
        context:context,
        builder:(c)=>AlertDialog(
          title:const Text('นำเข้าข้อมูล'),
          content:Text(
            'พบข้อมูล ${imported.length} รายการ\n'
            'ต้องการแทนที่ข้อมูลในเครื่องหรือไม่?'
          ),
          actions:[
            TextButton(
              onPressed:()=>Navigator.pop(c,false),
              child:const Text('ยกเลิก')
            ),
            FilledButton(
              onPressed:()=>Navigator.pop(c,true),
              child:const Text('นำเข้า')
            )
          ]
        )
      );

      if(ok!=true)return;

      await saveAllItems(imported);

      if(mounted)msg(context,'นำเข้าข้อมูลเรียบร้อย');
    }catch(e){
      if(mounted)msg(context,'นำเข้าข้อมูลไม่สำเร็จ: $e');
    }
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('สำรอง / นำเข้าข้อมูล')),
    body:ListView(
      padding:const EdgeInsets.all(16),
      children:[
        Card(
          child:ListTile(
            leading:const Icon(Icons.backup,size:32),
            title:const Text('สำรองข้อมูล'),
            subtitle:const Text(
              'สร้างไฟล์ข้อมูลสำหรับเก็บไว้ภายนอกเครื่อง'
            ),
            trailing:const Icon(Icons.chevron_right),
            onTap:backup
          )
        ),
        Card(
          child:ListTile(
            leading:const Icon(Icons.restore,size:32),
            title:const Text('นำเข้าข้อมูล'),
            subtitle:const Text(
              'นำไฟล์สำรองกลับมาใช้ในเครื่องนี้'
            ),
            trailing:const Icon(Icons.chevron_right),
            onTap:restore
          )
        ),
        const SizedBox(height:12),
        const Card(
          child:Padding(
            padding:EdgeInsets.all(14),
            child:Text(
              'ไฟล์สำรองเก็บเฉพาะข้อมูลและรายละเอียดการสแกน '
              'ไม่มีการเก็บรูปภาพพระหรือเหรียญ'
            )
          )
        )
      ]
    )
  );
}

/* ================= SETTINGS ================= */

class SettingsPage extends StatefulWidget{
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState()=>_SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>{
  bool realObject=true,history=true,autoNext=true;

  @override
  void initState(){
    super.initState();
    load();
  }

  Future<void> load()async{
    final p=await prefs();
    if(!mounted)return;

    setState((){
      realObject=p.getBool('setting_real_object_default')??true;
      history=p.getBool('setting_show_scan_history')??true;
      autoNext=p.getBool('setting_auto_next_area')??true;
    });
  }

  Future<void> setBool(String key,bool value)async{
    final p=await prefs();
    await p.setBool(key,value);
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('ตั้งค่า')),
    body:ListView(
      children:[
        SwitchListTile(
          title:const Text('ใช้กล้องเป็นค่าเริ่มต้น'),
          subtitle:const Text(
            'ถ้าปิด จะเปิดการเลือกภาพจากโทรศัพท์เป็นหลัก'
          ),
          value:realObject,
          onChanged:(v)async{
            setState(()=>realObject=v);
            await setBool('setting_real_object_default',v);
          }
        ),

        const Divider(),

        SwitchListTile(
          title:const Text('แสดงประวัติการสแกน'),
          subtitle:const Text(
            'แสดงรายการสแกนเดิมในหน้าสแกน'
          ),
          value:history,
          onChanged:(v)async{
            setState(()=>history=v);
            await setBool('setting_show_scan_history',v);
          }
        ),

        const Divider(),

        SwitchListTile(
          title:const Text('ไปพื้นที่ถัดไปอัตโนมัติ'),
          subtitle:const Text(
            'ลำดับหลัก: ด้านหน้า → ด้านหลัง → '
            'ด้านข้าง/ก้นพระ'
          ),
          value:autoNext,
          onChanged:(v)async{
            setState(()=>autoNext=v);
            await setBool('setting_auto_next_area',v);
          }
        ),

        const Divider(),

        const Padding(
          padding:EdgeInsets.all(16),
          child:Text(
            'AI จะจดจำรายละเอียดทั้งหมดที่มองเห็นจากการสแกน '
            'โดยไม่ใช้จุดสังเกตแบบตายตัว '
            'รายละเอียดที่ไม่ชัดจะถือว่า “ตรวจสอบไม่ได้” '
            'และจะไม่เดาว่าไม่มีรายละเอียด'
          )
        )
      ]
    )
  );
}
