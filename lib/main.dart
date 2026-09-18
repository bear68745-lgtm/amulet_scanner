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

const dataKey='amulet_data_gz';
const oldDataKey='amulet_data';

const amuletTypes=[
  'เหรียญ','เหรียญหล่อ','พระสมเด็จ','รูปหล่อ','พระกริ่ง','พระปิดตา',
  'พระปิดตาเนื้อโลหะ','พระเนื้อผง','พระเนื้อดิน','นางพญา','ผงสุพรรณ',
  'พระรอด','พระซุ้มกอ','พระขุนแผน','อื่น ๆ'
];

const scanAreas=['ด้านหน้า','ด้านหลัง','ด้านข้าง','หูเหรียญ','ตูดพระ','จุดเฉพาะ'];

Future<SharedPreferences> prefs()=>SharedPreferences.getInstance();

void msg(BuildContext c,String s)=>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s)));

Future<dynamic> go(BuildContext c,Widget p)=>
    Navigator.push(c,MaterialPageRoute(builder:(_)=>p));

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
  String name,model,pim,type,temple;
  String province,year,material,size;
  String frontDetail,sideDetail,backDetail;
  List<ScanData> scans;

  AmuletData({
    required this.id,
    this.name='',
    this.model='',
    this.pim='',
    this.type='',
    this.temple='',
    this.province='',
    this.year='',
    this.material='',
    this.size='',
    this.frontDetail='',
    this.sideDetail='',
    this.backDetail='',
    List<ScanData>? scans,
  }):scans=scans??[];

  Map<String,dynamic> toMap()=> {
    'id':id,'name':name,'model':model,'pim':pim,'type':type,'temple':temple,
    'province':province,'year':year,'material':material,'size':size,
    'frontDetail':frontDetail,'sideDetail':sideDetail,'backDetail':backDetail,
    'scans':scans.map((e)=>e.toMap()).toList(),
  };

  factory AmuletData.fromMap(Map<String,dynamic> m)=>AmuletData(
    id:int.tryParse('${m['id']??0}')??0,
    name:'${m['name']??''}',model:'${m['model']??''}',pim:'${m['pim']??''}',
    type:'${m['type']??''}',temple:'${m['temple']??''}',
    province:'${m['province']??''}',year:'${m['year']??''}',
    material:'${m['material']??''}',size:'${m['size']??''}',
    frontDetail:'${m['frontDetail']??''}',sideDetail:'${m['sideDetail']??''}',
    backDetail:'${m['backDetail']??''}',
    scans:m['scans'] is List
      ?(m['scans'] as List).map((e)=>ScanData.fromMap(Map<String,dynamic>.from(e))).toList()
      :[],
  );
}

class ScanData{
  String area,method;
  Map<String,dynamic> details;
  Map<String,dynamic> imageFeatures;

  ScanData({
    required this.area,
    required this.method,
    Map<String,dynamic>? details,
    Map<String,dynamic>? imageFeatures,
  }):details=details??{},imageFeatures=imageFeatures??{};

  Map<String,dynamic> toMap()=> {
    'area':area,'method':method,'details':details,'imageFeatures':imageFeatures,
  };

  factory ScanData.fromMap(Map<String,dynamic> m)=>ScanData(
    area:'${m['area']??''}',
    method:'${m['method']??''}',
    details:m['details'] is Map?Map<String,dynamic>.from(m['details']):{},
    imageFeatures:m['imageFeatures'] is Map
      ?Map<String,dynamic>.from(m['imageFeatures']):{},
  );
}

Map<String,dynamic> toAiData(AmuletData e)=> {
  'recordType':'amulet_reference',
  'name':e.name,'model':e.model,'pim':e.pim,'type':e.type,'temple':e.temple,
  'scans':e.scans.map((s)=>s.toMap()).toList(),
  'aiContext':{
    'canReadScanHistory':true,
    'canRememberPreviousScan':true,
    'canAddAnalysis':true,
    'canCompareAreas':true,
  },
};

Future<List<AmuletData>> loadAllItems()async{
  final p=await prefs(),z=p.getString(dataKey);
  if(z!=null&&z.isNotEmpty){
    try{
      final d=jsonDecode(utf8.decode(gzip.decode(base64Decode(z))));
      if(d is List){
        return d.map((e)=>AmuletData.fromMap(Map<String,dynamic>.from(e))).toList();
      }
    }catch(e){debugPrint('โหลดข้อมูลบีบอัดไม่สำเร็จ: $e');}
  }

  final old=p.getStringList(oldDataKey)??[];
  if(old.isEmpty)return[];

  try{
    final x=old.map((e)=>AmuletData.fromMap(
      Map<String,dynamic>.from(jsonDecode(e)),
    )).toList();
    await saveAllItems(x);
    return x;
  }catch(e){
    debugPrint('โหลดข้อมูลเก่าไม่สำเร็จ: $e');
    return[];
  }
}

Future<void> saveAllItems(List<AmuletData> x)async{
  final p=await prefs();
  final text=jsonEncode(x.map((e)=>e.toMap()).toList());
  await p.setString(
    dataKey,
    base64Encode(gzip.encode(utf8.encode(text))),
  );
  await p.remove(oldDataKey);
}

Widget field(String label,TextEditingController c)=>Padding(
  padding:const EdgeInsets.only(bottom:12),
  child:TextField(
    controller:c,
    decoration:InputDecoration(
      labelText:label,
      border:const OutlineInputBorder(),
    ),
  ),
);

Widget typeField(String value,ValueChanged<String?> onChanged)=>
    DropdownButtonFormField<String>(
      value:value,
      decoration:const InputDecoration(
        labelText:'ชนิดพระ',
        border:OutlineInputBorder(),
      ),
      items:amuletTypes.map((e)=>DropdownMenuItem(
        value:e,child:Text(e),
      )).toList(),
      onChanged:onChanged,
    );

class HomePage extends StatelessWidget{
  final List<CameraDescription> cameras;
  const HomePage({super.key,required this.cameras});

  @override
  Widget build(BuildContext c){
    final menu=[
      [Icons.add_circle_outline,'สร้าง / บันทึกข้อมูล','สร้างข้อมูลพระหรือเหรียญใหม่',Colors.blue,()=>go(c,const CreateDataPage())],
      [Icons.list_alt,'รายการข้อมูลที่บันทึก','ดู แก้ไข ลบ และสแกนเพิ่มข้อมูล',Colors.green,()=>go(c,SavedListPage(cameras:cameras))],
      [Icons.import_export,'สำรอง / นำเข้าข้อมูล','สำรองและกู้คืนฐานข้อมูล',Colors.orange,()=>go(c,const BackupPage())],
      [Icons.settings,'ตั้งค่า','ตั้งค่าการทำงานของแอป',Colors.grey,()=>go(c,const SettingsPage())],
    ];

    return Scaffold(
      appBar:AppBar(
        title:const Text('กล้องสแกนพระและเหรียญ',style:TextStyle(fontWeight:FontWeight.bold)),
        centerTitle:true,
      ),
      body:ListView(
        padding:const EdgeInsets.all(16),
        children:menu.map((x)=>Container(
          margin:const EdgeInsets.only(bottom:14),
          child:ElevatedButton(
            onPressed:x[4] as VoidCallback,
            style:ElevatedButton.styleFrom(
              padding:const EdgeInsets.all(18),
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
            ),
            child:Row(
              children:[
                Icon(x[0] as IconData,size:40,color:x[3] as Color),
                const SizedBox(width:16),
                Expanded(
                  child:Column(
                    crossAxisAlignment:CrossAxisAlignment.start,
                    children:[
                      Text(x[1] as String,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
                      const SizedBox(height:4),
                      Text(x[2] as String),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class CreateDataPage extends StatefulWidget{
  const CreateDataPage({super.key});
  @override State<CreateDataPage> createState()=>_CreateDataPageState();
}

class _CreateDataPageState extends State<CreateDataPage>{
  final name=TextEditingController();
  final model=TextEditingController();
  final pim=TextEditingController();
  final temple=TextEditingController();
  String type=amuletTypes.first;

  @override
  void dispose(){
    name.dispose();model.dispose();pim.dispose();temple.dispose();super.dispose();
  }

  Future<void> save()async{
    try{
      final x=await loadAllItems();
      x.add(AmuletData(
        id:newId(),
        name:name.text.trim(),
        model:model.text.trim(),
        pim:pim.text.trim(),
        type:type,
        temple:temple.text.trim(),
      ));
      await saveAllItems(x);
      if(!mounted)return;
      msg(context,'บันทึกข้อมูลเรียบร้อย');
      Navigator.pop(context,true);
    }catch(e){
      if(mounted)msg(context,'บันทึกข้อมูลไม่สำเร็จ: $e');
    }
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('สร้าง / บันทึกข้อมูล')),
    body:ListView(
      padding:const EdgeInsets.all(16),
      children:[
        field('ชื่อพระ',name),
        field('รุ่น',model),
        typeField(type,(v){if(v!=null)setState(()=>type=v);}),
        const SizedBox(height:12),
        field('พิมพ์',pim),
        field('วัด',temple),
        const SizedBox(height:8),
        SizedBox(
          height:56,
          child:ElevatedButton.icon(
            onPressed:save,
            icon:const Icon(Icons.save),
            label:const Text('บันทึกข้อมูล',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
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
  List<AmuletData> items=[];
  String search='';

  @override
  void initState(){super.initState();load();}

  Future<void> load()async{
    final x=await loadAllItems();
    if(mounted)setState(()=>items=x);
  }

  Future<void> deleteGroup(List<AmuletData> g)async{
    final ok=await showDialog<bool>(
      context:context,
      builder:(_)=>AlertDialog(
        title:const Text('ยืนยันการลบทั้งหมด'),
        content:Text(
          'จะลบข้อมูลกลุ่มนี้ทั้งหมด\n\n'
          '${g.first.name.isEmpty?'ยังไม่ได้ระบุชื่อ':g.first.name}\n'
          '${g.first.model.isEmpty?'':'รุ่น: ${g.first.model}\n'}\n'
          'รวม ${g.length} รายการอ้างอิง\n'
          'รวมข้อมูลสแกนและข้อมูล AI ที่ผูกกับรายการทั้งหมด\n\n'
          'การลบนี้ไม่สามารถย้อนกลับได้',
        ),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('ยกเลิก')),
          ElevatedButton(
            style:ElevatedButton.styleFrom(backgroundColor:Colors.red,foregroundColor:Colors.white),
            onPressed:()=>Navigator.pop(context,true),
            child:const Text('ลบทั้งหมด'),
          ),
        ],
      ),
    );
    if(ok!=true)return;
    final ids=g.map((e)=>e.id).toSet();
    final all=await loadAllItems();
    all.removeWhere((e)=>ids.contains(e.id));
    await saveAllItems(all);
    if(mounted){setState(()=>items=all);msg(context,'ลบข้อมูลกลุ่มทั้งหมดแล้ว');}
  }

  @override
  Widget build(BuildContext c){
    final groups=<String,List<AmuletData>>{};
    for(final e in items){groups.putIfAbsent(groupKey(e),()=>[]).add(e);}
    final q=search.trim().toLowerCase();
    final filtered=groups.values.where((g){
      if(q.isEmpty)return true;
      return g.any((e)=>[
        e.name,e.model,e.type,e.temple,e.province,e.year,e.material,e.size
      ].join(' ').toLowerCase().contains(q));
    }).toList()..sort((a,b)=>a.first.id.compareTo(b.first.id));

    return Scaffold(
      appBar:AppBar(title:const Text('รายการข้อมูลที่บันทึก')),
      body:Column(
        children:[
          Padding(
            padding:const EdgeInsets.all(12),
            child:TextField(
              decoration:InputDecoration(
                hintText:'ค้นหา ชื่อ รุ่น ชนิดพระ วัด',
                prefixIcon:const Icon(Icons.search),
                suffixIcon:search.isEmpty?null:IconButton(
                  icon:const Icon(Icons.clear),
                  onPressed:()=>setState(()=>search=''),
                ),
                border:const OutlineInputBorder(),
              ),
              onChanged:(v)=>setState(()=>search=v),
            ),
          ),
          Expanded(
            child:filtered.isEmpty
              ?Center(child:Text(
                items.isEmpty?'ยังไม่มีข้อมูลที่บันทึก':'ไม่พบข้อมูลที่ค้นหา',
                style:const TextStyle(fontSize:18),
              ))
              :ListView(
                padding:const EdgeInsets.symmetric(horizontal:12),
                children:filtered.map((g){
                  final e=g.first;
                  return Card(
                    child:ListTile(
                      title:Text(
                        e.name.isEmpty?'ยังไม่ได้ระบุชื่อ':e.name,
                        style:const TextStyle(fontWeight:FontWeight.bold),
                      ),
                      subtitle:Text(
                        '${e.model.isEmpty?'ยังไม่ได้ระบุรุ่น':e.model}\n'
                        'มี ${g.length} รายการอ้างอิง',
                      ),
                      isThreeLine:true,
                      leading:const Icon(Icons.folder_outlined),
                      trailing:Row(
                        mainAxisSize:MainAxisSize.min,
                        children:[
                          IconButton(
                            tooltip:'แก้ไขข้อมูลทั้งหมด',
                            icon:const Icon(Icons.edit_outlined),
                            onPressed:()async{
                              final changed=await Navigator.push<bool>(
                                c,
                                MaterialPageRoute(builder:(_)=>EditGroupPage(group:g)),
                              );
                              if(changed==true)load();
                            },
                          ),
                          IconButton(
                            tooltip:'ลบข้อมูลทั้งหมด',
                            icon:const Icon(Icons.delete_forever,color:Colors.red),
                            onPressed:()=>deleteGroup(g),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap:()async{
                        final changed=await Navigator.push<bool>(
                          c,
                          MaterialPageRoute(
                            builder:(_)=>AmuletGroupPage(group:g,cameras:widget.cameras),
                          ),
                        );
                        if(changed==true)load();
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
  late final TextEditingController name,model,pim,temple;
  late String type;

  @override
  void initState(){
    super.initState();
    final e=widget.group.first;
    name=TextEditingController(text:e.name);
    model=TextEditingController(text:e.model);
    pim=TextEditingController(text:e.pim);
    temple=TextEditingController(text:e.temple);
    type=amuletTypes.contains(e.type)?e.type:amuletTypes.first;
  }

  @override
  void dispose(){
    name.dispose();model.dispose();pim.dispose();temple.dispose();super.dispose();
  }

  Future<void> save()async{
    try{
      final ids=widget.group.map((e)=>e.id).toSet();
      final all=await loadAllItems();
      for(final e in all){
        if(!ids.contains(e.id))continue;
        e.name=name.text.trim();
        e.model=model.text.trim();
        e.pim=pim.text.trim();
        e.type=type;
        e.temple=temple.text.trim();
      }
      await saveAllItems(all);
      if(!mounted)return;
      msg(context,'แก้ไขข้อมูลหลักและรายการอ้างอิง ${widget.group.length} รายการแล้ว');
      Navigator.pop(context,true);
    }catch(e){
      if(mounted)msg(context,'แก้ไขไม่สำเร็จ: $e');
    }
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('แก้ไขข้อมูล')),
    body:ListView(
      padding:const EdgeInsets.all(16),
      children:[
        Card(
          child:Padding(
            padding:const EdgeInsets.all(14),
            child:Text(
              'แก้ไขข้อมูลหลัก\nข้อมูลนี้จะใช้กับรายการอ้างอิงทั้งหมด ${widget.group.length} รายการ\n\n'
              'ข้อมูลสแกนและรายละเอียด AI ของแต่ละรายการจะยังคงอยู่',
            ),
          ),
        ),
        const SizedBox(height:12),
        field('ชื่อพระ',name),
        field('รุ่น',model),
        typeField(type,(v){if(v!=null)setState(()=>type=v);}),
        const SizedBox(height:12),
        field('พิมพ์',pim),
        field('วัด',temple),
        SizedBox(
          height:56,
          child:ElevatedButton.icon(
            onPressed:save,
            icon:const Icon(Icons.save),
            label:const Text('บันทึกการแก้ไข',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          ),
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
    if(group.isEmpty)return;
    final ids=group.map((e)=>e.id).toSet();
    final x=await loadAllItems();
    final updated=x.where((e)=>ids.contains(e.id)).toList()..sort((a,b)=>a.id.compareTo(b.id));
    if(mounted)setState(()=>group=updated);
  }

  Future<void> editGroup()async{
    final changed=await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder:(_)=>EditGroupPage(group:group)),
    );
    if(changed==true)await refresh();
  }

  Future<void> deleteGroup()async{
    final ids=group.map((e)=>e.id).toSet();
    final ok=await showDialog<bool>(
      context:context,
      builder:(_)=>AlertDialog(
        title:const Text('ลบข้อมูลทั้งหมด'),
        content:Text(
          'ลบข้อมูลหลักและรายการอ้างอิงทั้งหมด ${group.length} รายการหรือไม่?\n\n'
          'ข้อมูลสแกนและ AI ของทุกรายการจะถูกลบด้วย',
        ),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('ยกเลิก')),
          ElevatedButton(
            style:ElevatedButton.styleFrom(backgroundColor:Colors.red,foregroundColor:Colors.white),
            onPressed:()=>Navigator.pop(context,true),
            child:const Text('ลบทั้งหมด'),
          ),
        ],
      ),
    );
    if(ok!=true)return;
    final x=await loadAllItems();
    x.removeWhere((e)=>ids.contains(e.id));
    await saveAllItems(x);
    if(mounted)Navigator.pop(context,true);
  }

  Future<void> deleteReference(AmuletData item,int index)async{
    final refNo=index+1;
    final ok=await showDialog<bool>(
      context:context,
      builder:(_)=>AlertDialog(
        title:Text('ลบรายการอ้างอิง $refNo'),
        content:Text(
          'ต้องการลบรายการอ้างอิง $refNo หรือไม่?\n\n'
          'ข้อมูลสแกนและข้อมูล AI ของรายการอ้างอิงนี้จะถูกลบด้วย\n\n'
          'รายการอ้างอิงอื่นจะยังคงอยู่',
        ),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('ยกเลิก')),
          ElevatedButton(
            style:ElevatedButton.styleFrom(backgroundColor:Colors.red,foregroundColor:Colors.white),
            onPressed:()=>Navigator.pop(context,true),
            child:const Text('ลบรายการอ้างอิง'),
          ),
        ],
      ),
    );
    if(ok!=true)return;

    try{
      final all=await loadAllItems();
      all.removeWhere((e)=>e.id==item.id);
      await saveAllItems(all);
      if(!mounted)return;
      setState(()=>group.removeWhere((e)=>e.id==item.id));
      if(group.isEmpty){Navigator.pop(context,true);return;}
      msg(context,'ลบรายการอ้างอิง $refNo แล้ว');
    }catch(e){
      if(mounted)msg(context,'ลบรายการอ้างอิงไม่สำเร็จ: $e');
    }
  }

  Future<void> addReference()async{
    if(group.isEmpty)return;
    try{
      final all=await loadAllItems(),b=group.first;
      final item=AmuletData(
        id:newId(),name:b.name,model:b.model,pim:b.pim,type:b.type,temple:b.temple,
        province:b.province,year:b.year,material:b.material,size:b.size,
      );
      all.add(item);
      await saveAllItems(all);
      group.add(item);
      if(!mounted)return;
      await go(context,ScanPage(item:item,cameras:widget.cameras));
      await refresh();
    }catch(e){
      if(mounted)msg(context,'เพิ่มรายการอ้างอิงไม่สำเร็จ: $e');
    }
  }

  @override
  Widget build(BuildContext c){
    if(group.isEmpty)return Scaffold(
      appBar:AppBar(title:const Text('รายการอ้างอิง')),
      body:const Center(child:Text('ไม่พบข้อมูล')),
    );

    final first=group.first;
    final name=first.name.isEmpty?'ยังไม่ได้ระบุชื่อ':first.name;
    final model=first.model.isEmpty?'ยังไม่ได้ระบุรุ่น':first.model;

    return Scaffold(
      appBar:AppBar(
        title:Text(name),
        actions:[
          IconButton(tooltip:'แก้ไขข้อมูลทั้งหมด',onPressed:editGroup,icon:const Icon(Icons.edit_outlined)),
          IconButton(tooltip:'ลบข้อมูลทั้งหมด',onPressed:deleteGroup,icon:const Icon(Icons.delete_forever,color:Colors.red)),
        ],
      ),
      body:ListView(
        padding:const EdgeInsets.all(12),
        children:[
          Card(
            child:ListTile(
              title:Text(name,style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
              subtitle:Text('รุ่น: $model\nรายการอ้างอิงทั้งหมด ${group.length} รายการ'),
            ),
          ),
          const SizedBox(height:8),
          const Text('รายการอ้างอิง',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
          ...group.asMap().entries.map((entry){
            final index=entry.key,item=entry.value;
            const total=6;
            final completed=item.scans.map((e)=>e.area).toSet().length;
            final remaining=total-completed;

            return Card(
              child:ListTile(
                leading:const Icon(Icons.article_outlined),
                title:Text('รายการอ้างอิง ${index+1}',style:const TextStyle(fontWeight:FontWeight.bold)),
                subtitle:Text(
                  '${item.type.isEmpty?'ยังไม่ได้ระบุชนิดพระ':'ชนิดพระ: ${item.type}'}\n'
                  'สแกนแล้ว $completed/$total รายการ'
                  '${remaining>0?' • ยังไม่ครบ $remaining รายการ':' • ครบรายการหลักแล้ว'}',
                ),
                isThreeLine:true,
                trailing:Row(
                  mainAxisSize:MainAxisSize.min,
                  children:[
                    IconButton(
                      tooltip:'ลบรายการอ้างอิง ${index+1}',
                      icon:const Icon(Icons.delete_forever,color:Colors.red),
                      onPressed:()=>deleteReference(item,index),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap:()async{
                  await go(c,ScanPage(item:item,cameras:widget.cameras));
                  await refresh();
                },
              ),
            );
          }),
          const SizedBox(height:8),
          SizedBox(
            height:58,
            child:ElevatedButton.icon(
              onPressed:addReference,
              icon:const Icon(Icons.add,size:28),
              label:const Text('+ เพิ่มรายการอ้างอิง',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
            ),
          ),
          const SizedBox(height:8),
          const Text(
            'เพิ่มรายการอ้างอิงได้เรื่อย ๆ และเข้าสู่รายการสแกนทันที',
            textAlign:TextAlign.center,
            style:TextStyle(fontSize:12),
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
  bool working=false;

  Future<void> backup()async{
    setState(()=>working=true);
    try{
      final x=await loadAllItems();
      final data={
        'backupVersion':4,
        'createdAt':DateTime.now().toIso8601String(),
        'containsImages':false,
        'data':x.map((e)=>e.toMap()).toList(),
      };
      final path=await FilePicker.platform.saveFile(
        dialogTitle:'บันทึกไฟล์สำรองข้อมูล',
        fileName:'amulet_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type:FileType.custom,
        allowedExtensions:['json'],
        bytes:utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
      );
      if(mounted&&path!=null)msg(context,'สำรองข้อมูลเรียบร้อยแล้ว');
    }catch(e){
      if(mounted)msg(context,'สำรองข้อมูลไม่สำเร็จ: $e');
    }finally{
      if(mounted)setState(()=>working=false);
    }
  }

  Future<void> importData()async{
    setState(()=>working=true);
    try{
      final r=await FilePicker.platform.pickFiles(
        type:FileType.custom,
        allowedExtensions:['json'],
        withData:true,
      );
      if(r==null)return;
      final bytes=r.files.single.bytes;
      if(bytes==null)throw Exception('ไม่สามารถอ่านไฟล์สำรองได้');
      final d=jsonDecode(utf8.decode(bytes));
      if(d is! Map||d['data'] is! List)throw Exception('รูปแบบไฟล์สำรองไม่ถูกต้อง');

      final x=<AmuletData>[];
      for(final e in d['data']){
        if(e is Map)x.add(AmuletData.fromMap(Map<String,dynamic>.from(e)));
      }
      if(!mounted)return;

      final ok=await showDialog<bool>(
        context:context,
        builder:(_)=>AlertDialog(
          title:const Text('นำเข้าข้อมูล'),
          content:Text('พบข้อมูล ${x.length} รายการ\n\nข้อมูลปัจจุบันจะถูกแทนที่ด้วยข้อมูลจากไฟล์สำรอง'),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('ยกเลิก')),
            ElevatedButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ยืนยัน')),
          ],
        ),
      );
      if(ok!=true)return;
      await saveAllItems(x);
      if(mounted)msg(context,'นำเข้าข้อมูล ${x.length} รายการเรียบร้อยแล้ว');
    }catch(e){
      if(mounted)msg(context,'นำเข้าข้อมูลไม่สำเร็จ: $e');
    }finally{
      if(mounted)setState(()=>working=false);
    }
  }

  Widget btn(String text,IconData icon,VoidCallback? fn)=>SizedBox(
    width:double.infinity,height:55,
    child:ElevatedButton.icon(
      onPressed:fn,icon:Icon(icon),
      label:Text(text,style:const TextStyle(fontSize:18)),
    ),
  );

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('สำรอง / นำเข้าข้อมูล')),
    body:Padding(
      padding:const EdgeInsets.all(16),
      child:Column(
        children:[
          const Card(
            child:Padding(
              padding:EdgeInsets.all(16),
              child:Text(
                'การจัดการข้อมูล\n\n'
                'สำรองเฉพาะข้อมูลพระ/เหรียญและข้อมูลการสแกน\n\n'
                'ไม่มีการบันทึกหรือสำรองรูปภาพ',
                style:TextStyle(fontSize:16),
              ),
            ),
          ),
          const SizedBox(height:20),
          btn('สำรองข้อมูล',Icons.backup,working?null:backup),
          const SizedBox(height:12),
          btn('นำเข้าข้อมูล',Icons.restore,working?null:importData),
          if(working)...[
            const SizedBox(height:20),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    ),
  );
}

class SettingsPage extends StatefulWidget{
  const SettingsPage({super.key});
  @override State<SettingsPage> createState()=>_SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>{
  bool realObject=true,history=true,autoNext=true;

  Future<void> loadSettings()async{
    final p=await prefs();
    if(!mounted)return;
    setState((){
      realObject=p.getBool('setting_real_object_default')??true;
      history=p.getBool('setting_show_scan_history')??true;
      autoNext=p.getBool('setting_auto_next_area')??true;
    });
  }

  @override
  void initState(){super.initState();loadSettings();}

  Widget sw(String title,String sub,bool value,String key,ValueChanged<bool> set)=>SwitchListTile(
    title:Text(title),
    subtitle:Text(sub),
    value:value,
    onChanged:(v)async{
      setState(()=>set(v));
      await(await prefs()).setBool(key,v);
    },
  );

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('ตั้งค่า')),
    body:ListView(
      padding:const EdgeInsets.all(16),
      children:[
        const Card(
          child:Padding(
            padding:EdgeInsets.all(16),
            child:Text(
              'ตั้งค่าการทำงานของแอป\n\n'
              'ระบบเก็บข้อมูลพระ/เหรียญโดยไม่บันทึกรูปภาพลงฐานข้อมูล',
              style:TextStyle(fontSize:16),
            ),
          ),
        ),
        sw('เริ่มต้นด้วยสแกนองค์จริง','ตั้งวิธีสแกนเริ่มต้นเป็นกล้อง',realObject,'setting_real_object_default',(v)=>realObject=v),
        sw('แสดงประวัติการสแกน','แสดงรายการการสแกนที่ผ่านมา',history,'setting_show_scan_history',(v)=>history=v),
        sw('เปลี่ยนพื้นที่ถัดไปอัตโนมัติ','หลังบันทึกการสแกนให้เลือกพื้นที่ถัดไป',autoNext,'setting_auto_next_area',(v)=>autoNext=v),
        const Card(
          child:Padding(
            padding:EdgeInsets.all(16),
            child:Text('🏅 พื้นฐาน 5+ องค์\n\n5 องค์เป็นเพียงจุดเตือนพื้นฐาน ไม่ใช่จำนวนสูงสุด'),
          ),
        ),
      ],
    ),
  );
}

/* =========================
   AI RECONSTRUCTION TEST
   ========================= */

class AiReconstructionPage extends StatelessWidget{
  final ScanData scan;
  const AiReconstructionPage({super.key,required this.scan});

  String countInfo(dynamic v){
    if(v is List&&v.isNotEmpty)return 'พบ ${v.length} รายการ';
    return 'ยังไม่มีข้อมูล';
  }

  Widget row(String a,String b)=>Padding(
    padding:const EdgeInsets.symmetric(vertical:5),
    child:Row(
      children:[
        SizedBox(width:115,child:Text(a)),
        Expanded(child:Text(b)),
      ],
    ),
  );

  @override
  Widget build(BuildContext c){
    final f=scan.imageFeatures;
    final embedding=f['embedding'];
    final hasEmbedding=embedding is List&&embedding.isNotEmpty;

    return Scaffold(
      appBar:AppBar(title:const Text('ภาพจำลอง AI')),
      body:ListView(
        padding:const EdgeInsets.all(16),
        children:[
          Card(
            child:Padding(
              padding:const EdgeInsets.all(16),
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  Text(
                    'พื้นที่สแกน: ${scan.area}',
                    style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold),
                  ),
                  const SizedBox(height:6),
                  Text('วิธีสแกน: ${scan.method}'),
                  const SizedBox(height:6),
                  const Text('ภาพจริงไม่ได้ถูกเก็บไว้ในเครื่อง'),
                ],
              ),
            ),
          ),
          const SizedBox(height:12),
          Card(
            child:Padding(
              padding:const EdgeInsets.all(12),
              child:Column(
                children:[
                  SizedBox(
                    height:290,
                    width:double.infinity,
                    child:CustomPaint(
                      painter:AiReconstructionPainter(
                        active:hasEmbedding,
                        details:scan.details,
                      ),
                      child:Center(
                        child:Padding(
                          padding:const EdgeInsets.all(20),
                          child:Text(
                            hasEmbedding
                              ?'โครงสร้างที่ AI เข้าใจ'
                              :'ยังไม่มีคุณลักษณะจาก AI',
                            textAlign:TextAlign.center,
                            style:const TextStyle(
                              fontSize:17,
                              fontWeight:FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height:8),
                  Text(
                    hasEmbedding
                      ?'สร้างจากคุณลักษณะ AI ที่บันทึกไว้'
                      :'หน้านี้พร้อมรับผลจาก MediaPipe + LiteRT',
                    textAlign:TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height:12),
          Card(
            child:Padding(
              padding:const EdgeInsets.all(16),
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  const Text(
                    'สิ่งที่ AI เข้าใจ',
                    style:TextStyle(fontSize:18,fontWeight:FontWeight.bold),
                  ),
                  const SizedBox(height:10),
                  row('รูปร่าง',hasEmbedding?'ตรวจพบคุณลักษณะ':'รอ MediaPipe/LiteRT'),
                  row('พื้นผิว',countInfo(scan.details['surfaceDetails'])),
                  row('ตำหนิ',countInfo(scan.details['defects'])),
                  row('เส้นหล่อ',countInfo(scan.details['castingLines'])),
                  row('รายละเอียดพิมพ์',countInfo(scan.details['patternDetails'])),
                  row('ข้อสังเกต',countInfo(scan.details['observations'])),
                  row('ความมั่นใจ',scan.details['aiConfidence']?.toString()??'ยังไม่มี'),
                ],
              ),
            ),
          ),
          const SizedBox(height:12),
          Card(
            child:Padding(
              padding:const EdgeInsets.all(16),
              child:Text(
                hasEmbedding
                  ?'AI มีข้อมูลคุณลักษณะสำหรับสร้างภาพจำลองแล้ว'
                  :'ตอนนี้ยังเป็นโหมดเตรียมระบบ ภาพจำลองนี้ยังไม่ใช่ผลจาก AI วิเคราะห์ภาพจริง',
              ),
            ),
          ),
          const SizedBox(height:8),
          const Card(
            child:Padding(
              padding:EdgeInsets.all(16),
              child:Text(
                'ความเป็นส่วนตัว\n\n'
                'ภาพสแกนจริงใช้ชั่วคราวในหน่วยความจำ '
                'ระบบไม่เก็บไฟล์รูปภาพ และไม่ใช้ภาพจำลองแทนรายการอ้างอิงจริง',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AiReconstructionPainter extends CustomPainter{
  final bool active;
  final Map<String,dynamic> details;

  AiReconstructionPainter({
    required this.active,
    required this.details,
  });

  @override
  void paint(Canvas p,Size s){
    final paint=Paint()
      ..style=PaintingStyle.stroke
      ..strokeWidth=3;

    final cx=s.width/2,cy=s.height/2;
    final w=s.width*.48,h=s.height*.68;

    final outer=RRect.fromRectAndRadius(
      Rect.fromCenter(
        center:Offset(cx,cy),
        width:w,
        height:h,
      ),
      const Radius.circular(45),
    );

    p.drawRRect(outer,paint);

    p.drawOval(
      Rect.fromCenter(
        center:Offset(cx,cy-42),
        width:w*.58,
        height:h*.27,
      ),
      paint,
    );

    p.drawLine(
      Offset(cx-w*.28,cy+25),
      Offset(cx+w*.28,cy+25),
      paint,
    );

    p.drawLine(
      Offset(cx-w*.18,cy+52),
      Offset(cx+w*.18,cy+52),
      paint,
    );

    if(active){
      p.drawCircle(Offset(cx-w*.18,cy-20),5,paint);
      p.drawCircle(Offset(cx+w*.18,cy-20),5,paint);
      p.drawArc(
        Rect.fromCenter(
          center:Offset(cx,cy+25),
          width:w*.38,
          height:h*.16,
        ),
        0,
        3.14,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AiReconstructionPainter oldDelegate)=>
      oldDelegate.active!=active||oldDelegate.details!=details;
}

/* =========================
   SCAN PAGE
   ========================= */

class ScanPage extends StatefulWidget{
  final AmuletData item;
  final List<CameraDescription> cameras;

  const ScanPage({
    super.key,
    required this.item,
    required this.cameras,
  });

  @override
  State<ScanPage> createState()=>_ScanPageState();
}

class _ScanPageState extends State<ScanPage>{
  final picker=ImagePicker();
  CameraController? camera;

  String area=scanAreas.first;
  bool realObject=true,history=true,autoNext=true,scanning=false;
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

  int count(String a)=>widget.item.scans.where((e)=>e.area==a).length;

  List<String> areas(){
    final x=[...scanAreas];
    for(final e in widget.item.scans){
      if(!x.contains(e.area))x.add(e.area);
    }
    return x;
  }

  Future<void> start(String a)async{
    setState(()=>area=a);
    if(realObject)await openCamera();
    else await pickImage();
  }

  Future<void> openCamera()async{
    if(widget.cameras.isEmpty){
      msg(context,'ไม่พบกล้องในเครื่อง');
      return;
    }

    try{
      final d=widget.cameras.firstWhere(
        (e)=>e.lensDirection==CameraLensDirection.back,
        orElse:()=>widget.cameras.first,
      );

      final con=CameraController(
        d,
        ResolutionPreset.medium,
        enableAudio:false,
      );

      await con.initialize();

      if(!mounted){
        await con.dispose();
        return;
      }

      camera=con;
      frames=0;

      await showModalBottomSheet(
        context:context,
        isScrollControlled:true,
        isDismissible:false,
        enableDrag:false,
        builder:(sheet)=>StatefulBuilder(
          builder:(context,setSheet)=>SafeArea(
            child:SizedBox(
              height:MediaQuery.of(context).size.height*.9,
              child:Padding(
                padding:const EdgeInsets.all(12),
                child:Column(
                  children:[
                    Row(
                      children:[
                        IconButton(
                          icon:const Icon(Icons.close),
                          onPressed:scanning?null:()=>Navigator.pop(sheet),
                        ),
                        Expanded(
                          child:Text(
                            'สแกน $area',
                            textAlign:TextAlign.center,
                            style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width:48),
                      ],
                    ),
                    const SizedBox(height:8),
                    Expanded(
                      child:Stack(
                        fit:StackFit.expand,
                        children:[
                          CameraPreview(camera!),
                          Center(
                            child:Container(
                              width:260,
                              height:330,
                              decoration:BoxDecoration(
                                border:Border.all(width:2),
                                borderRadius:BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          if(scanning)
                            Positioned(
                              top:12,left:12,right:12,
                              child:Container(
                                padding:const EdgeInsets.all(10),
                                color:Colors.black54,
                                child:Text(
                                  'กำลังสแกน • $frames ช่วงข้อมูล',
                                  textAlign:TextAlign.center,
                                  style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height:10),
                    const Text(
                      'ข้อมูลภาพใช้ชั่วคราวในหน่วยความจำ และไม่บันทึกไฟล์รูปภาพ',
                      textAlign:TextAlign.center,
                      style:TextStyle(fontSize:12),
                    ),
                    const SizedBox(height:10),
                    if(!scanning)
                      SizedBox(
                        width:double.infinity,
                        height:52,
                        child:ElevatedButton.icon(
                          icon:const Icon(Icons.document_scanner),
                          label:const Text('เริ่มสแกนพื้นที่นี้',style:TextStyle(fontSize:17)),
                          onPressed:()async{
                            setSheet(()=>scanning=true);
                            frames=0;

                            await temporaryScan((n){
                              if(sheet.mounted)setSheet(()=>frames=n);
                            });

                            if(!sheet.mounted)return;

                            setSheet(()=>scanning=false);
                            await saveScan('สแกนองค์จริง');

                            if(sheet.mounted)Navigator.pop(sheet);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await disposeCamera();
    }catch(e){
      await disposeCamera();
      if(mounted)msg(context,'เปิดกล้องไม่สำเร็จ: $e');
    }
  }

  Future<void> temporaryScan(void Function(int) progress)async{
    final c=camera;
    if(c==null||!c.value.isInitialized)return;

    const total=12;
    var n=0,running=true;

    try{
      await c.startImageStream((CameraImage image){
        if(!running)return;
        progress(++n);
        if(n>=total)running=false;
      });

      while(running&&mounted){
        await Future.delayed(const Duration(milliseconds:20));
      }

      if(c.value.isStreamingImages)await c.stopImageStream();
    }catch(e){
      running=false;
      try{
        if(c.value.isStreamingImages)await c.stopImageStream();
      }catch(_){}
      debugPrint('Temporary scan error: $e');
    }
  }

  Future<void> disposeCamera()async{
    final c=camera;
    camera=null;
    if(c==null)return;

    try{
      if(c.value.isStreamingImages)await c.stopImageStream();
    }catch(_){}

    try{await c.dispose();}catch(_){}
  }

  Future<void> pickImage()async{
    try{
      final p=await picker.pickImage(source:ImageSource.gallery);
      if(p!=null)await saveScan('นำเข้าจากโทรศัพท์');
    }catch(e){
      if(mounted)msg(context,'นำเข้ารูปไม่สำเร็จ: $e');
    }
  }

  Future<void> saveScan(String method)async{
    widget.item.scans.add(
      ScanData(
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
          'surfaceDetails':[],
          'defects':[],
          'moldDetails':[],
          'castingLines':[],
          'patternDetails':[],
          'observations':[],
        },
        imageFeatures:{
          'modelName':'',
          'modelVersion':'',
          'featureVersion':1,
          'embedding':[],
          'quality':null,
        },
      ),
    );

    final x=await loadAllItems();
    final i=x.indexWhere((e)=>e.id==widget.item.id);

    if(i!=-1){
      x[i]=widget.item;
      await saveAllItems(x);
    }

    final old=area;

    if(autoNext){
      final list=areas();
      final next=list.firstWhere((e)=>count(e)==0,orElse:()=>'');
      if(next.isNotEmpty){
        area=next;
      }else{
        final i=list.indexOf(area);
        if(i>=0&&i<list.length-1)area=list[i+1];
      }
    }

    if(!mounted)return;
    setState((){});
    msg(context,'บันทึกอัตโนมัติแล้ว • $old');
  }

  Future<void> addCustomArea()async{
    final c=TextEditingController();

    final result=await showDialog<String>(
      context:context,
      builder:(_)=>AlertDialog(
        title:const Text('เพิ่มหมวดพื้นที่'),
        content:TextField(
          controller:c,
          autofocus:true,
          decoration:const InputDecoration(
            hintText:'เช่น ขอบล่าง / หลังหู / จุดตำหนิ',
            border:OutlineInputBorder(),
          ),
        ),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context),child:const Text('ยกเลิก')),
          ElevatedButton(
            onPressed:(){
              final v=c.text.trim();
              if(v.isNotEmpty)Navigator.pop(context,v);
            },
            child:const Text('เพิ่ม'),
          ),
        ],
      ),
    );

    c.dispose();

    if(result!=null&&result.isNotEmpty)setState(()=>area=result);
  }

  @override
  void dispose(){
    camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c){
    final list=areas();
    final completed=list.where((e)=>count(e)>0).length;

    return Scaffold(
      appBar:AppBar(title:const Text('รายการสแกน')),
      body:ListView(
        padding:const EdgeInsets.all(16),
        children:[
          Card(
            child:ListTile(
              title:const Text('รายการอ้างอิง',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
              subtitle:Text(
                widget.item.name+
                (widget.item.model.isEmpty?'':'\nรุ่น: ${widget.item.model}'),
              ),
            ),
          ),
          Card(
            child:ListTile(
              title:const Text('สถานะการสแกน',style:TextStyle(fontWeight:FontWeight.bold)),
              subtitle:Text(
                'สแกนแล้ว $completed/${list.length} รายการ\n'
                '${completed==list.length?'ครบรายการหลักแล้ว':'ยังไม่ครบ ${list.length-completed} รายการ'}',
              ),
            ),
          ),
          const SizedBox(height:10),
          const Text('วิธีสแกน',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          const SizedBox(height:8),
          SegmentedButton<bool>(
            segments:const[
              ButtonSegment(value:true,icon:Icon(Icons.camera_alt),label:Text('สแกนองค์จริง')),
              ButtonSegment(value:false,icon:Icon(Icons.photo_library),label:Text('จากตัวเครื่อง')),
            ],
            selected:{realObject},
            onSelectionChanged:(v)=>setState(()=>realObject=v.first),
          ),
          const SizedBox(height:16),
          Card(
            child:ListTile(
              title:const Text('พื้นที่ที่เลือก'),
              subtitle:Text('$area\nสแกนแล้ว ${count(area)} ครั้ง',style:const TextStyle(fontSize:18)),
            ),
          ),
          const SizedBox(height:10),
          const Text('รายการสแกน',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          ...list.map((a)=>Card(
            color:a==area?Theme.of(c).colorScheme.primaryContainer:null,
            child:ListTile(
              leading:Icon(
                count(a)>0?Icons.check_circle:Icons.radio_button_unchecked,
                color:count(a)>0?Colors.green:null,
              ),
              title:Text(a,style:const TextStyle(fontWeight:FontWeight.bold)),
              subtitle:Text(
                count(a)==0?'ยังไม่ได้สแกน':'สแกนแล้ว ${count(a)} ครั้ง • บันทึกแล้ว',
              ),
              trailing:const Icon(Icons.chevron_right),
              onTap:()=>start(a),
            ),
          )),
          Card(
            child:ListTile(
              leading:const Icon(Icons.add),
              title:const Text('เพิ่มหมวดเอง',style:TextStyle(fontWeight:FontWeight.bold)),
              subtitle:const Text('สำหรับรายละเอียดเฉพาะของพระหรือเหรียญ'),
              onTap:addCustomArea,
            ),
          ),
          if(history)
            Card(
              child:Padding(
                padding:const EdgeInsets.all(12),
                child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,
                  children:[
                    const Text('ประวัติการสแกน',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
                    const SizedBox(height:8),
                    if(widget.item.scans.isEmpty)
                      const Text('ยังไม่มีข้อมูลการสแกน'),
                    ...widget.item.scans.map((s)=>Card(
                      margin:const EdgeInsets.only(bottom:8),
                      child:Padding(
                        padding:const EdgeInsets.all(4),
                        child:Column(
                          children:[
                            ListTile(
                              dense:true,
                              leading:const Icon(Icons.check_circle_outline,color:Colors.green),
                              title:Text(s.area),
                              subtitle:Text(
                                '${s.method}\nบันทึกแล้ว • AI: ${s.details['aiStatus']??'pending'}',
                              ),
                              isThreeLine:true,
                            ),
                            SizedBox(
                              width:double.infinity,
                              child:OutlinedButton.icon(
                                onPressed:()=>go(
                                  context,
                                  AiReconstructionPage(scan:s),
                                ),
                                icon:const Icon(Icons.auto_awesome),
                                label:const Text('ทดสอบภาพจำลอง AI'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
