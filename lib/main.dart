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

const dataKey='amulet_data_gz',oldDataKey='amulet_data',nextNumberKey='next_real_item_number';
const amuletTypes=[
  'เหรียญ','เหรียญหล่อ','พระสมเด็จ','รูปหล่อ','พระกริ่ง','พระปิดตา',
  'พระปิดตาเนื้อโลหะ','พระเนื้อผง','พระเนื้อดิน','นางพญา','ผงสุพรรณ',
  'พระรอด','พระซุ้มกอ','พระขุนแผน','อื่น ๆ'
];
const scanAreas=['ด้านหน้า','ด้านหลัง','ด้านข้าง','หูเหรียญ','ตูดพระ','จุดเฉพาะ'];

Future<SharedPreferences> prefs()=>SharedPreferences.getInstance();

int maxRef(List<AmuletData> x)=>x.fold(0,(m,e)=>e.realItemNumber>m?e.realItemNumber:m);

Future<void> syncReferenceNumber(List<AmuletData> x) async {
  final p=await prefs(),cur=p.getInt(nextNumberKey)??1,n=maxRef(x)+1;
  if(n>cur) await p.setInt(nextNumberKey,n);
}

Future<int> nextReferenceNumber(List<AmuletData> x) async {
  await syncReferenceNumber(x);
  return (await prefs()).getInt(nextNumberKey)??1;
}

Future<void> commitReferenceNumber(int n) async {
  final p=await prefs(),cur=p.getInt(nextNumberKey)??1;
  if(n+1>cur) await p.setInt(nextNumberKey,n+1);
}

Future<bool> repairReferenceNumbers(List<AmuletData> x) async {
  final p=await prefs(),stored=p.getInt(nextNumberKey)??1;
  var next=stored>maxRef(x)+1?stored:maxRef(x)+1;
  final used=<int>{};
  var changed=false;
  for(final e in x){
    if(e.realItemNumber<=0||used.contains(e.realItemNumber)){
      while(used.contains(next)||next<=0) next++;
      e.realItemNumber=next++;
      changed=true;
    }
    used.add(e.realItemNumber);
  }
  final req=maxRef(x)+1;
  if(next<req) next=req;
  if(next<stored) next=stored;
  if(next>stored) await p.setInt(nextNumberKey,next);
  return changed;
}

void message(BuildContext c,String s)=>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s)));

String groupKey(AmuletData e)=>
    '${e.name.trim().toLowerCase()}|||${e.model.trim().toLowerCase()}';

class AmuletScannerApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const AmuletScannerApp({super.key,required this.cameras});
  @override Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'กล้องสแกนพระและเหรียญ',
    theme:ThemeData(useMaterial3:true),
    home:HomePage(cameras:cameras),
  );
}

class AmuletData {
  int id,realItemNumber;
  String name,model,pim,type,temple,province,year,material,size,
      frontDetail,sideDetail,backDetail;
  List<ScanData> scans;
  AmuletData({
    required this.id,required this.realItemNumber,
    this.name='',this.model='',this.pim='',this.type='',this.temple='',
    this.province='',this.year='',this.material='',this.size='',
    this.frontDetail='',this.sideDetail='',this.backDetail='',
    List<ScanData>? scans,
  }):scans=scans??[];

  Map<String,dynamic> toMap()=>{
    'id':id,'realItemNumber':realItemNumber,'name':name,'model':model,
    'pim':pim,'type':type,'temple':temple,'province':province,'year':year,
    'material':material,'size':size,'frontDetail':frontDetail,
    'sideDetail':sideDetail,'backDetail':backDetail,
    'scans':scans.map((e)=>e.toMap()).toList()
  };

  factory AmuletData.fromMap(Map<String,dynamic> m)=>AmuletData(
    id:m['id']??0,realItemNumber:m['realItemNumber']??0,
    name:m['name']??'',model:m['model']??'',pim:m['pim']??'',
    type:m['type']??'',temple:m['temple']??'',province:m['province']??'',
    year:m['year']??'',material:m['material']??'',size:m['size']??'',
    frontDetail:m['frontDetail']??'',sideDetail:m['sideDetail']??'',
    backDetail:m['backDetail']??'',
    scans:(m['scans'] as List???[])
      .map((e)=>ScanData.fromMap(Map<String,dynamic>.from(e))).toList(),
  );
}

class ScanData {
  String area,method;
  int scanNumber;
  Map<String,dynamic> details;
  ScanData({
    required this.area,required this.scanNumber,required this.method,
    Map<String,dynamic>? details
  }):details=details??[];

  Map<String,dynamic> toMap()=>{
    'area':area,'scanNumber':scanNumber,'method':method,'details':details
  };

  factory ScanData.fromMap(Map<String,dynamic> m)=>ScanData(
    area:m['area']??'',scanNumber:m['scanNumber']??0,method:m['method']??'',
    details:Map<String,dynamic>.from(m['details']??{})
  );
}

Map<String,dynamic> toAiData(AmuletData e)=>{
  'recordType':'amulet_reference','name':e.name,'model':e.model,
  'pim':e.pim,'type':e.type,'temple':e.temple,
  'scans':e.scans.map((s)=>s.toMap()).toList(),
  'aiContext':{
    'canReadScanHistory':true,'canRememberPreviousScan':true,
    'canAddAnalysis':true,'canCompareAreas':true
  }
};

Future<List<AmuletData>> loadAllItems() async {
  final p=await prefs();
  List<AmuletData>? items;
  final z=p.getString(dataKey);

  if(z!=null&&z.isNotEmpty){
    try{
      final d=jsonDecode(utf8.decode(gzip.decode(base64Decode(z))));
      if(d is List) items=d.map((e)=>AmuletData.fromMap(Map<String,dynamic>.from(e))).toList();
    }catch(e){debugPrint('โหลดข้อมูลบีบอัดไม่สำเร็จ: $e');}
  }

  if(items==null){
    final old=p.getStringList(oldDataKey);
    if(old==null||old.isEmpty)return[];
    try{
      items=old.map((e)=>AmuletData.fromMap(Map<String,dynamic>.from(jsonDecode(e)))).toList();
      await p.remove(oldDataKey);
    }catch(e){
      debugPrint('โหลดข้อมูลเก่าไม่สำเร็จ: $e');
      return[];
    }
  }

  final fixed=await repairReferenceNumbers(items);
  if(fixed||z==null||z.isEmpty) await saveAllItems(items);
  else await syncReferenceNumber(items);
  return items;
}

Future<void> saveAllItems(List<AmuletData> x) async {
  final p=await prefs();
  final text=jsonEncode(x.map((e)=>e.toMap()).toList());
  await p.setString(dataKey,base64Encode(gzip.encode(utf8.encode(text))));
  await p.remove(oldDataKey);
  await syncReferenceNumber(x);
}

Widget dataField(String label,TextEditingController c)=>Padding(
  padding:const EdgeInsets.only(bottom:12),
  child:TextField(
    controller:c,
    decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),
  ),
);

Widget typeField(String value,ValueChanged<String?> onChanged)=>
    DropdownButtonFormField<String>(
      value:value,
      decoration:const InputDecoration(
        labelText:'ชนิดพระ',border:OutlineInputBorder()),
      items:amuletTypes.map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),
      onChanged:onChanged,
    );

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;
  const HomePage({super.key,required this.cameras});

  void open(BuildContext c,Widget p)=>Navigator.push(
    c,MaterialPageRoute(builder:(_)=>p));

  @override Widget build(BuildContext c){
    final b=[
      [Icons.add_circle_outline,'สร้าง / บันทึกข้อมูล','สร้างข้อมูลพระหรือเหรียญใหม่',Colors.blue,
        ()=>open(c,CreateDataPage(cameras:cameras))],
      [Icons.list_alt,'รายการข้อมูลที่บันทึก','ดู แก้ไข ลบ และสแกนเพิ่มข้อมูล',Colors.green,
        ()=>open(c,SavedListPage(cameras:cameras))],
      [Icons.import_export,'สำรอง / นำเข้าข้อมูล','สำรองและกู้คืนฐานข้อมูล',Colors.orange,
        ()=>open(c,BackupPage(cameras:cameras))],
      [Icons.settings,'ตั้งค่า','ตั้งค่าการทำงานของแอป',Colors.grey,
        ()=>open(c,SettingsPage(cameras:cameras))],
    ];
    return Scaffold(
      appBar:AppBar(
        title:const Text('กล้องสแกนพระและเหรียญ',
          style:TextStyle(fontWeight:FontWeight.bold)),
        centerTitle:true,
      ),
      body:ListView(
        padding:const EdgeInsets.all(16),
        children:b.map((x)=>Container(
          margin:const EdgeInsets.only(bottom:14),
          child:ElevatedButton(
            onPressed:x[4] as VoidCallback,
            style:ElevatedButton.styleFrom(
              padding:const EdgeInsets.all(18),
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
            ),
            child:Row(children:[
              Icon(x[0] as IconData,size:40,color:x[3] as Color),
              const SizedBox(width:16),
              Expanded(child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  Text(x[1] as String,
                    style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
                  const SizedBox(height:4),Text(x[2] as String)
                ],
              )),
              const Icon(Icons.chevron_right)
            ]),
          ),
        )).toList(),
      ),
    );
  }
}

class CreateDataPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isAddingReference;
  const CreateDataPage({
    super.key,required this.cameras,this.isAddingReference=false});
  @override State<CreateDataPage> createState()=>_CreateDataPageState();
}

class _CreateDataPageState extends State<CreateDataPage>{
  final name=TextEditingController(),model=TextEditingController(),
      pim=TextEditingController(),temple=TextEditingController();
  String type='เหรียญ';

  @override void dispose(){
    name.dispose();model.dispose();pim.dispose();temple.dispose();super.dispose();
  }

  Future<void> save() async {
    try{
      final x=await loadAllItems(),n=await nextReferenceNumber(x);
      x.add(AmuletData(
        id:DateTime.now().millisecondsSinceEpoch,realItemNumber:n,
        name:name.text.trim(),model:model.text.trim(),pim:pim.text.trim(),
        type:type,temple:temple.text.trim(),
      ));
      await saveAllItems(x);await commitReferenceNumber(n);
      if(!mounted)return;
      message(c,widget.isAddingReference
        ?'เพิ่มรายการอ้างอิงเรียบร้อย • ลำดับอ้างอิงที่ $n'
        :'บันทึกข้อมูลเรียบร้อย • ลำดับอ้างอิงที่ $n');
      Navigator.pop(c,true);
    }catch(e){if(mounted)message(c,'บันทึกข้อมูลไม่สำเร็จ: $e');}
  }

  BuildContext get c=>context;

  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:Text(widget.isAddingReference
      ?'เพิ่มรายการอ้างอิง':'สร้าง / บันทึกข้อมูล')),
    body:ListView(
      padding:const EdgeInsets.all(16),
      children:[
        dataField('ชื่อพระ',name),dataField('รุ่น',model),
        typeField(type,(v){if(v!=null)setState(()=>type=v);}),
        const SizedBox(height:12),dataField('พิมพ์',pim),
        dataField('วัด',temple),const SizedBox(height:10),
        SizedBox(height:56,child:ElevatedButton.icon(
          onPressed:save,icon:const Icon(Icons.save),
          label:Text(widget.isAddingReference
            ?'บันทึกรายการอ้างอิง':'บันทึกข้อมูล',
            style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        )),
      ],
    ),
  );
}

class SavedListPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SavedListPage({super.key,required this.cameras});
  @override State<SavedListPage> createState()=>_SavedListPageState();
}

class _SavedListPageState extends State<SavedListPage>{
  List<AmuletData> items=[];String search='';

  @override void initState(){super.initState();load();}
  Future<void> load() async{
    final x=await loadAllItems();if(mounted)setState(()=>items=x);
  }

  @override Widget build(BuildContext c){
    final groups=<String,List<AmuletData>>{};
    for(final e in items)groups.putIfAbsent(groupKey(e),()=>[]).add(e);
    for(final g in groups.values)g.sort((a,b)=>a.realItemNumber.compareTo(b.realItemNumber));
    final q=search.trim().toLowerCase();
    final filtered=groups.values.where((g)=>q.isEmpty||g.any((e)=>[
      e.name,e.model,e.type,e.temple,e.province,e.year,e.material,e.size
    ].join(' ').toLowerCase().contains(q))).toList();
    filtered.sort((a,b)=>a.first.realItemNumber.compareTo(b.first.realItemNumber));

    return Scaffold(
      appBar:AppBar(title:const Text('รายการข้อมูลที่บันทึก')),
      body:Column(children:[
        Padding(
          padding:const EdgeInsets.all(12),
          child:TextField(
            decoration:InputDecoration(
              hintText:'ค้นหา ชื่อ รุ่น ชนิดพระ วัด',
              prefixIcon:const Icon(Icons.search),
              suffixIcon:search.isEmpty?null:IconButton(
                icon:const Icon(Icons.clear),onPressed:()=>setState(()=>search='')),
              border:const OutlineInputBorder(),
            ),
            onChanged:(v)=>setState(()=>search=v),
          ),
        ),
        Expanded(
          child:filtered.isEmpty
            ?Center(child:Text(
              items.isEmpty?'ยังไม่มีข้อมูลที่บันทึก':'ไม่พบข้อมูลที่ค้นหา',
              style:const TextStyle(fontSize:18)))
            :ListView(
              padding:const EdgeInsets.symmetric(horizontal:12),
              children:filtered.map((g){
                final e=g.first;
                return Card(child:ListTile(
                  title:Text(e.name.isEmpty?'ยังไม่ได้ระบุชื่อ':e.name,
                    style:const TextStyle(fontWeight:FontWeight.bold)),
                  subtitle:Text(
                    '${e.model.isEmpty?'ยังไม่ได้ระบุรุ่น':e.model}\n'
                    'มี ${g.length} รายการอ้างอิง'),
                  isThreeLine:true,trailing:const Icon(Icons.chevron_right),
                  onTap:()async{
                    final changed=await Navigator.push<bool>(c,
                      MaterialPageRoute(builder:(_)=>AmuletGroupPage(
                        group:g,cameras:widget.cameras)));
                    if(changed==true)load();
                  },
                ));
              }).toList(),
            ),
        ),
      ]),
    );
  }
}

class EditDataPage extends StatefulWidget {
  final AmuletData item;
  const EditDataPage({super.key,required this.item});
  @override State<EditDataPage> createState()=>_EditDataPageState();
}

class _EditDataPageState extends State<EditDataPage>{
  late final TextEditingController name,model,pim,temple;
  late String type;

  @override void initState(){
    super.initState();
    name=TextEditingController(text:widget.item.name);
    model=TextEditingController(text:widget.item.model);
    pim=TextEditingController(text:widget.item.pim);
    temple=TextEditingController(text:widget.item.temple);
    type=amuletTypes.contains(widget.item.type)?widget.item.type:amuletTypes.first;
  }

  @override void dispose(){
    name.dispose();model.dispose();pim.dispose();temple.dispose();super.dispose();
  }

  Future<void> save() async {
    try{
      final x=await loadAllItems();
      final i=x.indexWhere((e)=>e.id==widget.item.id);
      if(i<0){
        if(mounted)message(context,'ไม่พบข้อมูลที่ต้องการแก้ไข');
        return;
      }
      final o=x[i];
      x[i]=AmuletData(
        id:o.id,realItemNumber:o.realItemNumber,
        name:name.text.trim(),model:model.text.trim(),pim:pim.text.trim(),
        type:type,temple:temple.text.trim(),
        province:o.province,year:o.year,material:o.material,size:o.size,
        frontDetail:o.frontDetail,sideDetail:o.sideDetail,
        backDetail:o.backDetail,scans:o.scans,
      );
      await saveAllItems(x);
      if(!mounted)return;
      message(context,'แก้ไขลำดับอ้างอิงที่ ${o.realItemNumber} แล้ว');
      Navigator.pop(context,true);
    }catch(e){if(mounted)message(context,'แก้ไขข้อมูลไม่สำเร็จ: $e');}
  }

  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('แก้ไขข้อมูล')),
    body:ListView(
      padding:const EdgeInsets.all(16),
      children:[
        Text('ลำดับอ้างอิงที่ ${widget.item.realItemNumber}',
          style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        const SizedBox(height:16),dataField('ชื่อพระ',name),
        dataField('รุ่น',model),typeField(type,(v){
          if(v!=null)setState(()=>type=v);
        }),
        const SizedBox(height:12),dataField('พิมพ์',pim),dataField('วัด',temple),
        SizedBox(height:55,child:ElevatedButton.icon(
          onPressed:save,icon:const Icon(Icons.save),
          label:const Text('บันทึกการแก้ไข',style:TextStyle(fontSize:18)),
        )),
      ],
    ),
  );
}

class AmuletGroupPage extends StatefulWidget {
  final List<AmuletData> group;
  final List<CameraDescription> cameras;
  const AmuletGroupPage({super.key,required this.group,required this.cameras});
  @override State<AmuletGroupPage> createState()=>_AmuletGroupPageState();
}

class _AmuletGroupPageState extends State<AmuletGroupPage>{
  late List<AmuletData> group;

  @override void initState(){
    super.initState();
    group=[...widget.group]..sort((a,b)=>a.realItemNumber.compareTo(b.realItemNumber));
  }

  Future<void> refresh() async {
    final x=await loadAllItems();
    if(!mounted||group.isEmpty)return;
    final k=groupKey(group.first);
    setState(()=>group=x.where((e)=>groupKey(e)==k).toList()
      ..sort((a,b)=>a.realItemNumber.compareTo(b.realItemNumber)));
  }

  Future<void> addReference() async {
    if(group.isEmpty)return;
    try{
      final all=await loadAllItems(),n=await nextReferenceNumber(all),b=group.first;
      final item=AmuletData(
        id:DateTime.now().millisecondsSinceEpoch,realItemNumber:n,
        name:b.name,model:b.model,pim:b.pim,type:b.type,temple:b.temple,
        province:b.province,year:b.year,material:b.material,size:b.size,
      );
      all.add(item);await saveAllItems(all);await commitReferenceNumber(n);
      if(!mounted)return;
      await Navigator.push(context,MaterialPageRoute(
        builder:(_)=>ScanPage(item:item,cameras:widget.cameras)));
      await refresh();
    }catch(e){if(mounted)message(context,'เพิ่มรายการอ้างอิงไม่สำเร็จ: $e');}
  }

  Future<void> deleteItem(AmuletData item) async {
    final yes=await showDialog<bool>(
      context:context,
      builder:(_)=>AlertDialog(
        title:const Text('ยืนยันการลบข้อมูล',
          style:TextStyle(fontWeight:FontWeight.bold)),
        content:Text(
          'คุณกำลังจะลบ\n\n'
          'ลำดับอ้างอิงที่ ${item.realItemNumber}\n'
          '${item.name.isEmpty?'ยังไม่ได้ระบุชื่อ':item.name}\n'
          '${item.model.isEmpty?'':'รุ่น: ${item.model}\n'}\n'
          'ข้อมูลทั้งหมดของรายการนี้จะถูกลบถาวร ได้แก่\n'
          '• ข้อมูลรายการอ้างอิง\n'
          '• ข้อมูลการสแกนทั้งหมด ${item.scans.length} รายการ\n'
          '• รายละเอียดการวิเคราะห์ AI ที่บันทึกไว้\n'
          '• ข้อมูลรายละเอียดอื่น ๆ ที่ผูกกับรายการนี้\n\n'
          'รายการอ้างอิงอื่นจะไม่ถูกลบ\n'
          'เลขอ้างอิงที่ลบแล้วจะไม่ถูกนำกลับมาใช้ซ้ำ',
        ),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context,false),
            child:const Text('ยกเลิก')),
          ElevatedButton.icon(
            style:ElevatedButton.styleFrom(
              backgroundColor:Colors.red,foregroundColor:Colors.white),
            onPressed:()=>Navigator.pop(context,true),
            icon:const Icon(Icons.delete_forever),
            label:const Text('ลบข้อมูลทั้งหมด'),
          ),
        ],
      ),
    );
    if(yes!=true)return;
    try{
      final x=await loadAllItems()..removeWhere((e)=>e.id==item.id);
      await saveAllItems(x);
      if(!mounted)return;
      setState(()=>group.removeWhere((e)=>e.id==item.id));
      message(context,'ลบข้อมูลทั้งหมดของลำดับอ้างอิงที่ ${item.realItemNumber} แล้ว');
      if(group.isEmpty)Navigator.pop(context,true);
    }catch(e){if(mounted)message(context,'ลบข้อมูลไม่สำเร็จ: $e');}
  }

  @override Widget build(BuildContext c){
    if(group.isEmpty)return Scaffold(
      appBar:AppBar(title:const Text('รายการอ้างอิง')),
      body:Center(child:ElevatedButton(
        onPressed:()=>Navigator.pop(c,true),
        child:const Text('กลับไปรายการข้อมูล'))),
    );

    final first=group.first;
    final name=first.name.isEmpty?'ยังไม่ได้ระบุชื่อ':first.name;
    final model=first.model.isEmpty?'ยังไม่ได้ระบุรุ่น':first.model;

    return Scaffold(
      appBar:AppBar(title:Text(name)),
      body:ListView(
        padding:const EdgeInsets.all(12),
        children:[
          Card(child:ListTile(
            title:Text(name,style:const TextStyle(
              fontSize:21,fontWeight:FontWeight.bold)),
            subtitle:Text('รุ่น: $model\nรายการอ้างอิงทั้งหมด ${group.length} รายการ'),
          )),
          const SizedBox(height:8),
          const Text('รายการอ้างอิง',style:TextStyle(
            fontSize:20,fontWeight:FontWeight.bold)),
          ...group.map((item){
            const total=6;
            final completed=item.scans.map((e)=>e.area).toSet().length;
            final remaining=total-completed;
            return Card(child:ListTile(
              leading:CircleAvatar(child:Text('${item.realItemNumber}')),
              title:Text('ลำดับอ้างอิงที่ ${item.realItemNumber}'),
              subtitle:Text(
                '${item.type.isEmpty?'ยังไม่ได้ระบุชนิดพระ':'ชนิดพระ: ${item.type}'}\n'
                'สแกนแล้ว $completed/$total รายการ'
                '${remaining>0?' • ยังไม่ครบ $remaining รายการ':' • ครบรายการหลักแล้ว'}'),
              isThreeLine:true,
              trailing:Row(
                mainAxisSize:MainAxisSize.min,
                children:[
                  IconButton(
                    tooltip:'แก้ไขข้อมูล',
                    icon:const Icon(Icons.edit_outlined),
                    onPressed:()async{
                      final changed=await Navigator.push<bool>(c,
                        MaterialPageRoute(builder:(_)=>EditDataPage(item:item)));
                      if(changed==true)await refresh();
                    }),
                  IconButton(
                    tooltip:'ลบข้อมูลทั้งหมด',
                    icon:const Icon(Icons.delete_forever,color:Colors.red),
                    onPressed:()=>deleteItem(item)),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap:()async{
                await Navigator.push(c,MaterialPageRoute(
                  builder:(_)=>ScanPage(item:item,cameras:widget.cameras)));
                await refresh();
              },
            ));
          }),
          const SizedBox(height:8),
          SizedBox(height:58,child:ElevatedButton.icon(
            onPressed:addReference,icon:const Icon(Icons.add,size:28),
            label:const Text('+ เพิ่มรายการอ้างอิง',
              style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          )),
          const SizedBox(height:8),
          const Text('เพิ่มรายการอ้างอิงถัดไปและเข้าสู่รายการสแกนทันที',
            textAlign:TextAlign.center,style:TextStyle(fontSize:12)),
        ],
      ),
    );
  }
}

class BackupPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const BackupPage({super.key,required this.cameras});
  @override State<BackupPage> createState()=>_BackupPageState();
}

class _BackupPageState extends State<BackupPage>{
  bool working=false;

  Future<void> backup() async {
    setState(()=>working=true);
    try{
      final p=await prefs(),x=await loadAllItems();
      await syncReferenceNumber(x);
      final data={
        'backupVersion':3,'createdAt':DateTime.now().toIso8601String(),
        'containsImages':false,
        'nextRealItemNumber':p.getInt(nextNumberKey)??1,
        'data':x.map((e)=>e.toMap()).toList(),
      };
      await FilePicker.platform.saveFile(
        dialogTitle:'บันทึกไฟล์สำรองข้อมูล',
        fileName:'amulet_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type:FileType.custom,allowedExtensions:['json'],
        bytes:utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
      );
      if(mounted)message(context,'สำรองข้อมูลเรียบร้อยแล้ว');
    }catch(e){if(mounted)message(context,'สำรองข้อมูลไม่สำเร็จ: $e');}
    finally{if(mounted)setState(()=>working=false);}
  }

  Future<void> importData() async {
    setState(()=>working=true);
    try{
      final r=await FilePicker.platform.pickFiles(
        type:FileType.custom,allowedExtensions:['json'],withData:true);
      if(r==null)return;
      final bytes=r.files.single.bytes;
      if(bytes==null)throw Exception('ไม่สามารถอ่านไฟล์สำรองได้');
      final d=jsonDecode(utf8.decode(bytes));
      if(d is! Map||d['data'] is! List)throw Exception('รูปแบบไฟล์สำรองไม่ถูกต้อง');

      final x=<AmuletData>[];
      for(final e in d['data'])if(e is Map)
        x.add(AmuletData.fromMap(Map<String,dynamic>.from(e)));

      await repairReferenceNumbers(x);
      if(!mounted)return;

      final ok=await showDialog<bool>(
        context:context,
        builder:(_)=>AlertDialog(
          title:const Text('นำเข้าข้อมูล'),
          content:Text('พบข้อมูล ${x.length} รายการ\n\nข้อมูลปัจจุบันจะถูกแทนที่ด้วยข้อมูลจากไฟล์สำรอง'),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(context,false),
              child:const Text('ยกเลิก')),
            ElevatedButton(onPressed:()=>Navigator.pop(context,true),
              child:const Text('ยืนยัน')),
          ],
        ),
      );
      if(ok!=true)return;

      final p=await prefs();
      final current=p.getInt(nextNumberKey)??1;
      final backup=d['nextRealItemNumber'] is int?d['nextRealItemNumber'] as int:1;
      var next=current;
      if(backup>next)next=backup;
      if(maxRef(x)+1>next)next=maxRef(x)+1;
      await saveAllItems(x);
      await p.setInt(nextNumberKey,next);

      if(mounted)message(context,'นำเข้าข้อมูล ${x.length} รายการเรียบร้อยแล้ว');
    }catch(e){if(mounted)message(context,'นำเข้าข้อมูลไม่สำเร็จ: $e');}
    finally{if(mounted)setState(()=>working=false);}
  }

  Widget button(String text,IconData icon,VoidCallback? fn)=>SizedBox(
    width:double.infinity,height:55,
    child:ElevatedButton.icon(
      onPressed:fn,icon:Icon(icon),
      label:Text(text,style:const TextStyle(fontSize:18)),
    ),
  );

  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('สำรอง / นำเข้าข้อมูล')),
    body:Padding(
      padding:const EdgeInsets.all(16),
      child:Column(children:[
        const Card(child:Padding(
          padding:EdgeInsets.all(16),
          child:Text(
            'การจัดการข้อมูล\n\n'
            'สำรองเฉพาะข้อมูลพระ/เหรียญและข้อมูลการสแกน\n\n'
            'ไม่มีการบันทึกหรือสำรองรูปภาพ',
            style:TextStyle(fontSize:16),
          ),
        )),
        const SizedBox(height:20),
        button('สำรองข้อมูล',Icons.backup,working?null:backup),
        const SizedBox(height:12),
        button('นำเข้าข้อมูล',Icons.restore,working?null:importData),
        if(working)...[
          const SizedBox(height:20),const CircularProgressIndicator()
        ],
      ]),
    ),
  );
}

class SettingsPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SettingsPage({super.key,required this.cameras});
  @override State<SettingsPage> createState()=>_SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>{
  bool realObject=true,history=true,autoNext=true;
  static const keys=[
    'setting_real_object_default',
    'setting_show_scan_history',
    'setting_auto_next_area'
  ];

  @override void initState(){super.initState();loadSettings();}

  Future<void> loadSettings() async {
    final p=await prefs();
    if(!mounted)return;
    setState((){
      realObject=p.getBool(keys[0])??true;
      history=p.getBool(keys[1])??true;
      autoNext=p.getBool(keys[2])??true;
    });
  }

  Future<void> setValue(String k,bool v)async=>
      (await prefs()).setBool(k,v);

  Widget sw(String title,String sub,bool value,String key,
      ValueChanged<bool> set)=>SwitchListTile(
    title:Text(title),subtitle:Text(sub),value:value,
    onChanged:(v)async{setState(()=>set(v));await setValue(key,v);},
  );

  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('ตั้งค่า')),
    body:ListView(
      padding:const EdgeInsets.all(16),
      children:[
        const Card(child:Padding(
          padding:EdgeInsets.all(16),
          child:Text(
            'ตั้งค่าการทำงานของแอป\n\n'
            'ระบบเก็บข้อมูลพระ/เหรียญโดยไม่บันทึกรูปภาพลงฐานข้อมูล',
            style:TextStyle(fontSize:16),
          ),
        )),
        sw('เริ่มต้นด้วยสแกนองค์จริง','ตั้งวิธีสแกนเริ่มต้นเป็นกล้อง',
          realObject,keys[0],(v)=>realObject=v),
        sw('แสดงประวัติการสแกน','แสดงรายการการสแกนที่ผ่านมา',
          history,keys[1],(v)=>history=v),
        sw('เปลี่ยนพื้นที่ถัดไปอัตโนมัติ','หลังบันทึกการสแกนให้เลือกพื้นที่ถัดไป',
          autoNext,keys[2],(v)=>autoNext=v),
        const Card(child:Padding(
          padding:EdgeInsets.all(16),
          child:Text(
            '🏅 พื้นฐาน 5+ องค์\n\n'
            '5 องค์เป็นเพียงจุดเตือนพื้นฐาน ไม่ใช่จำนวนสูงสุด',
          ),
        )),
      ],
    ),
  );
}

class ScanPage extends StatefulWidget {
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

  @override void initState(){super.initState();loadSettings();}

  Future<void> loadSettings()async{
    final p=await prefs();
    if(!mounted)return;
    setState((){
      realObject=p.getBool('setting_real_object_default')??true;
      history=p.getBool('setting_show_scan_history')??true;
      autoNext=p.getBool('setting_auto_next_area')??true;
    });
  }

  void show(String s){if(mounted)message(context,s);}
  int count(String a)=>widget.item.scans.where((e)=>e.area==a).length;

  List<String> areas(){
    final x=[...scanAreas];
    for(final e in widget.item.scans)if(!x.contains(e.area))x.add(e.area);
    return x;
  }

  Future<void> start(String a)async{
    setState(()=>area=a);
    if(realObject)await openCamera();else await pickImage();
  }

  Future<void> openCamera()async{
    if(widget.cameras.isEmpty){show('ไม่พบกล้องในเครื่อง');return;}
    try{
      final d=widget.cameras.firstWhere(
        (e)=>e.lensDirection==CameraLensDirection.back,
        orElse:()=>widget.cameras.first);
      final con=CameraController(d,ResolutionPreset.medium,enableAudio:false);
      await con.initialize();
      if(!mounted){await con.dispose();return;}
      camera=con;frames=0;

      await showModalBottomSheet(
        context:context,isScrollControlled:true,
        isDismissible:false,enableDrag:false,
        builder:(sheet)=>StatefulBuilder(
          builder:(context,setSheet)=>SafeArea(
            child:SizedBox(
              height:MediaQuery.of(context).size.height*.9,
              child:Padding(
                padding:const EdgeInsets.all(12),
                child:Column(children:[
                  Row(children:[
                    IconButton(
                      icon:const Icon(Icons.close),
                      onPressed:scanning?null:()=>Navigator.pop(sheet)),
                    Expanded(child:Text('สแกน $area',textAlign:TextAlign.center,
                      style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))),
                    const SizedBox(width:48),
                  ]),
                  const SizedBox(height:8),
                  Expanded(child:Stack(
                    fit:StackFit.expand,
                    children:[
                      CameraPreview(camera!),
                      Center(child:Container(
                        width:260,height:330,
                        decoration:BoxDecoration(
                          border:Border.all(width:2),
                          borderRadius:BorderRadius.circular(20)),
                      )),
                      if(scanning)Positioned(
                        top:12,left:12,right:12,
                        child:Container(
                          padding:const EdgeInsets.all(10),
                          color:Colors.black54,
                          child:Text('กำลังสแกน • $frames ช่วงข้อมูล',
                            textAlign:TextAlign.center,
                            style:const TextStyle(
                              color:Colors.white,fontWeight:FontWeight.bold)),
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(height:10),
                  const Text(
                    'ข้อมูลภาพใช้ชั่วคราวในหน่วยความจำ และไม่บันทึกไฟล์รูปภาพ',
                    textAlign:TextAlign.center,
                    style:TextStyle(fontSize:12),
                  ),
                  const SizedBox(height:10),
                  if(!scanning)SizedBox(
                    width:double.infinity,height:52,
                    child:ElevatedButton.icon(
                      icon:const Icon(Icons.document_scanner),
                      label:const Text('เริ่มสแกนพื้นที่นี้',
                        style:TextStyle(fontSize:17)),
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
                ]),
              ),
            ),
          ),
        ),
      );
      await disposeCamera();
    }catch(e){
      await disposeCamera();show('เปิดกล้องไม่สำเร็จ: $e');
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
      while(running&&mounted)await Future.delayed(
        const Duration(milliseconds:20));
      if(c.value.isStreamingImages)await c.stopImageStream();
    }catch(e){
      running=false;
      try{if(c.value.isStreamingImages)await c.stopImageStream();}catch(_){}
      debugPrint('Temporary scan error: $e');
    }
  }

  Future<void> disposeCamera()async{
    final c=camera;camera=null;
    if(c==null)return;
    try{if(c.value.isStreamingImages)await c.stopImageStream();}catch(_){}
    try{await c.dispose();}catch(_){}
  }

  Future<void> pickImage()async{
    try{
      final p=await picker.pickImage(source:ImageSource.gallery);
      if(p!=null)await saveScan('นำเข้าจากโทรศัพท์');
    }catch(e){show('นำเข้ารูปไม่สำเร็จ: $e');}
  }

  Future<void> saveScan(String method)async{
    final n=count(area)+1;
    widget.item.scans.add(ScanData(
      area:area,scanNumber:n,method:method,
      details:{
        'analysisStatus':'รอระบบ AI วิเคราะห์','aiStatus':'pending',
        'aiFindings':[],'aiNotes':'','aiConfidence':null,
        'aiAnalyzedAt':null,'sourceArea':area,'imageSaved':false,
        'temporaryOnly':true,'canCompareWithPreviousScans':true,
        'surfaceDetails':[],'defects':[],'moldDetails':[],
        'castingLines':[],'patternDetails':[],'observations':[],
      },
    ));

    final x=await loadAllItems(),i=x.indexWhere((e)=>e.id==widget.item.id);
    if(i!=-1){x[i]=widget.item;await saveAllItems(x);}
    final old=area;

    if(autoNext){
      final list=areas();
      final next=list.firstWhere((e)=>count(e)==0,orElse=>'');
      if(next.isNotEmpty)area=next;
      else{
        final i=list.indexOf(area);
        if(i>=0&&i<list.length-1)area=list[i+1];
      }
    }

    if(!mounted)return;
    setState((){});
    show('บันทึกอัตโนมัติแล้ว • $old • สแกนครั้งที่ $n');
  }

  Future<void> addCustomArea()async{
    final c=TextEditingController();
    final result=await showDialog<String>(
      context:context,
      builder:(_)=>AlertDialog(
        title:const Text('เพิ่มหมวดพื้นที่'),
        content:TextField(
          controller:c,autofocus:true,
          decoration:const InputDecoration(
            hintText:'เช่น ขอบล่าง / หลังหู / จุดตำหนิ',
            border:OutlineInputBorder()),
        ),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context),
            child:const Text('ยกเลิก')),
          ElevatedButton(
            onPressed:(){
              final v=c.text.trim();
              if(v.isNotEmpty)Navigator.pop(context,v);
            },
            child:const Text('เพิ่ม')),
        ],
      ),
    );
    c.dispose();
    if(result!=null&&result.isNotEmpty)setState(()=>area=result);
  }

  @override void dispose(){
    camera?.dispose();super.dispose();
  }

  @override Widget build(BuildContext c){
    final list=areas();
    final completed=list.where((e)=>count(e)>0).length;

    return Scaffold(
      appBar:AppBar(title:const Text('รายการสแกน')),
      body:ListView(
        padding:const EdgeInsets.all(16),
        children:[
          Card(child:ListTile(
            title:Text('ลำดับอ้างอิงที่ ${widget.item.realItemNumber}',
              style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
            subtitle:Text('${widget.item.name}'
              '${widget.item.model.isEmpty?'':'\nรุ่น: ${widget.item.model}'}'),
          )),
          Card(child:ListTile(
            title:const Text('สถานะการสแกน',
              style:TextStyle(fontWeight:FontWeight.bold)),
            subtitle:Text(
              'สแกนแล้ว $completed/${list.length} รายการ\n'
              '${completed==list.length?'ครบรายการหลักแล้ว':'ยังไม่ครบ ${list.length-completed} รายการ'}'),
          )),
          const SizedBox(height:10),
          const Text('วิธีสแกน',style:TextStyle(
            fontSize:18,fontWeight:FontWeight.bold)),
          const SizedBox(height:8),
          SegmentedButton<bool>(
            segments:const[
              ButtonSegment(value:true,icon:Icon(Icons.camera_alt),
                label:Text('สแกนองค์จริง')),
              ButtonSegment(value:false,icon:Icon(Icons.photo_library),
                label:Text('จากตัวเครื่อง')),
            ],
            selected:{realObject},
            onSelectionChanged:(v)=>setState(()=>realObject=v.first),
          ),
          const SizedBox(height:16),
          Card(child:ListTile(
            title:const Text('พื้นที่ที่เลือก'),
            subtitle:Text('$area\nสแกนแล้ว ${count(area)} ครั้ง',
              style:const TextStyle(fontSize:18)),
          )),
          const SizedBox(height:10),
          const Text('รายการสแกน',style:TextStyle(
            fontSize:18,fontWeight:FontWeight.bold)),
          ...list.map((a)=>Card(
            color:a==area?Theme.of(c).colorScheme.primaryContainer:null,
            child:ListTile(
              leading:Icon(
                count(a)>0?Icons.check_circle:Icons.radio_button_unchecked,
                color:count(a)>0?Colors.green:null),
              title:Text(a,style:const TextStyle(fontWeight:FontWeight.bold)),
              subtitle:Text(
                count(a)==0?'ยังไม่ได้สแกน':
                'สแกนแล้ว ${count(a)} ครั้ง • บันทึกแล้ว'),
              trailing:const Icon(Icons.chevron_right),
              onTap:()=>start(a),
            ),
          )),
          Card(child:ListTile(
            leading:const Icon(Icons.add),
            title:const Text('เพิ่มหมวดเอง',
              style:TextStyle(fontWeight:FontWeight.bold)),
            subtitle:const Text('สำหรับรายละเอียดเฉพาะของพระหรือเหรียญ'),
            onTap:addCustomArea,
          )),
          if(history) ...[
            const SizedBox(height:16),
            Card(child:Padding(
              padding:const EdgeInsets.all(12),
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  const Text('ประวัติการสแกน',
                    style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
                  const SizedBox(height:8),
                  if(widget.item.scans.isEmpty)
                    const Text('ยังไม่มีข้อมูลการสแกน'),
                  ...widget.item.scans.map((s)=>ListTile(
                    dense:true,
                    leading:const Icon(Icons.check_circle_outline,
                      color:Colors.green),
                    title:Text('${s.area} • สแกน ${s.scanNumber}'),
                    subtitle:Text(
                      '${s.method}\nบันทึกแล้ว • AI: '
                      '${s.details['aiStatus']??'pending'}'),
                    isThreeLine:true,
                  )),
                ],
              ),
            )),
          ],
          const SizedBox(height:16),
          OutlinedButton.icon(
            onPressed:()=>Navigator.pop(c,true),
            icon:const Icon(Icons.arrow_back),
            label:const Text('กลับรายการบันทึก',
              style:TextStyle(fontSize:16)),
          ),
        ],
      ),
    );
  }
}
