import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main()async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App(await availableCameras()));
}

const areas=['ด้านหน้า','ด้านหลัง','ด้านข้าง','ก้นพระ'];
const typeOptions=[
  'เหรียญ','เหรียญหล่อ','พระสมเด็จ','รูปหล่อ','พระกริ่ง',
  'พระปิดตาเนื้อผง/หว้าน','พระปิดตาเนื้อโลหะ','พระเนื้อผง',
  'พระเนื้อดิน','นางพญา','ผงสุพรรณ','พระรอด','พระซุ้มกอ',
  'พระขุนแผน','หลวงปู่ทวดเนื้อหว้าน','หลวงปู่ทวดหลังเตารีด',
  'เขี้ยวแกะ','งาแกะ','ตะกรุด','อื่น ๆ'
];

class ScanResult{
  final String area,details;
  ScanResult({required this.area,this.details=''});
  Map<String,dynamic> toMap()=>{'area':area,'details':details};
  factory ScanResult.fromMap(Map<String,dynamic> m)=>ScanResult(
    area:m['area']??'',details:m['details']??'');
}

class ReferenceData{
  final String id,createdAt,updatedAt;
  final int referenceNumber;
  final List<ScanResult> scans;
  ReferenceData({
    required this.id,required this.referenceNumber,
    required this.createdAt,required this.updatedAt,this.scans=const[],
  });
  ReferenceData copyWith({
    int? referenceNumber,String? updatedAt,List<ScanResult>? scans,
  })=>ReferenceData(
    id:id,referenceNumber:referenceNumber??this.referenceNumber,
    createdAt:createdAt,updatedAt:updatedAt??this.updatedAt,
    scans:scans??this.scans,
  );
  Map<String,dynamic> toMap()=>{
    'id':id,'referenceNumber':referenceNumber,'createdAt':createdAt,
    'updatedAt':updatedAt,'scans':scans.map((e)=>e.toMap()).toList(),
  };
  factory ReferenceData.fromMap(Map<String,dynamic> m)=>ReferenceData(
    id:m['id']??Storage.id(),referenceNumber:m['referenceNumber']??1,
    createdAt:m['createdAt']??Storage.now(),
    updatedAt:m['updatedAt']??Storage.now(),
    scans:(m['scans'] as List? ?? [])
      .map((e)=>ScanResult.fromMap(Map<String,dynamic>.from(e))).toList(),
  );
}

class TypeData{
  final String id,name,createdAt,updatedAt;
  final List<ReferenceData> references;
  TypeData({
    required this.id,required this.name,required this.createdAt,
    required this.updatedAt,this.references=const[],
  });
  Map<String,dynamic> toMap()=>{
    'id':id,'name':name,'createdAt':createdAt,'updatedAt':updatedAt,
    'references':references.map((e)=>e.toMap()).toList(),
  };
  factory TypeData.fromMap(Map<String,dynamic> m)=>TypeData(
    id:m['id']??Storage.id(),name:m['name']??'',
    createdAt:m['createdAt']??Storage.now(),
    updatedAt:m['updatedAt']??Storage.now(),
    references:(m['references'] as List? ?? [])
      .map((e)=>ReferenceData.fromMap(Map<String,dynamic>.from(e))).toList(),
  );
}

class ModelData{
  final String id,name,createdAt,updatedAt;
  final List<TypeData> types;
  ModelData({
    required this.id,required this.name,required this.createdAt,
    required this.updatedAt,this.types=const[],
  });
  Map<String,dynamic> toMap()=>{
    'id':id,'name':name,'createdAt':createdAt,'updatedAt':updatedAt,
    'types':types.map((e)=>e.toMap()).toList(),
  };
  factory ModelData.fromMap(Map<String,dynamic> m)=>ModelData(
    id:m['id']??Storage.id(),name:m['name']??'',
    createdAt:m['createdAt']??Storage.now(),
    updatedAt:m['updatedAt']??Storage.now(),
    types:(m['types'] as List? ?? [])
      .map((e)=>TypeData.fromMap(Map<String,dynamic>.from(e))).toList(),
  );
}

class GroupData{
  final String id,name,temple,createdAt,updatedAt;
  final List<ModelData> models;
  GroupData({
    required this.id,required this.name,required this.temple,
    required this.createdAt,required this.updatedAt,this.models=const[],
  });
  Map<String,dynamic> toMap()=>{
    'id':id,'name':name,'temple':temple,'createdAt':createdAt,
    'updatedAt':updatedAt,'models':models.map((e)=>e.toMap()).toList(),
  };
  factory GroupData.fromMap(Map<String,dynamic> m)=>GroupData(
    id:m['id']??Storage.id(),name:m['name']??'',temple:m['temple']??'',
    createdAt:m['createdAt']??Storage.now(),
    updatedAt:m['updatedAt']??Storage.now(),
    models:(m['models'] as List? ?? [])
      .map((e)=>ModelData.fromMap(Map<String,dynamic>.from(e))).toList(),
  );
}

class Storage{
  static const key='reference_groups';
  static Future<List<GroupData>> load()async{
    final p=await SharedPreferences.getInstance(),raw=p.getString(key);
    if(raw==null||raw.isEmpty)return[];
    try{return(jsonDecode(raw)as List)
      .map((e)=>GroupData.fromMap(Map<String,dynamic>.from(e))).toList();}
    catch(_){return[];}
  }
  static Future<void> save(List<GroupData> g)async{
    final p=await SharedPreferences.getInstance();
    await p.setString(key,jsonEncode(g.map((e)=>e.toMap()).toList()));
  }
  static String id()=>DateTime.now().microsecondsSinceEpoch.toString();
  static String now()=>DateTime.now().toIso8601String();
  static void renumber(TypeData t){
    for(var i=0;i<t.references.length;i++)
      t.references[i]=t.references[i].copyWith(referenceNumber:i+1);
  }
}

class App extends StatelessWidget{
  final List<CameraDescription> cameras;
  const App(this.cameras,{super.key});
  @override Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false,title:'กล้องสแกนพระ',
    theme:ThemeData(useMaterial3:true,colorSchemeSeed:Colors.brown),
    home:HomePage(cameras));
}

class HomePage extends StatefulWidget{
  final List<CameraDescription> cameras;
  const HomePage(this.cameras,{super.key});
  @override State<HomePage> createState()=>_HomePageState();
}

class _HomePageState extends State<HomePage>{
  int groupCount=0;
  @override void initState(){super.initState();load();}
  Future<void> load()async{
    final g=await Storage.load();
    if(mounted)setState(()=>groupCount=g.length);
  }
  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('กล้องสแกนพระ')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      _button('สร้างกลุ่มใหม่',Icons.create_new_folder,()async{
        await Navigator.push(c,MaterialPageRoute(
          builder:(_)=>CreateGroupPage(widget.cameras)));load();
      }),
      _button('รายการที่บันทึก ($groupCount รายการ)',Icons.folder,()async{
        await Navigator.push(c,MaterialPageRoute(
          builder:(_)=>GroupListPage(widget.cameras)));load();
      }),
      const SizedBox(height:20),
      const Card(child:Padding(
        padding:EdgeInsets.all(16),
        child:Text('ระบบเก็บข้อมูลวิเคราะห์และข้อมูลอ้างอิง โดยไม่เก็บรูปภาพถาวร'),
      )),
    ]));
  Widget _button(String t,IconData i,VoidCallback f)=>Card(
    child:ListTile(leading:Icon(i),title:Text(t),
      trailing:const Icon(Icons.chevron_right),onTap:f));
}

class CreateGroupPage extends StatefulWidget{
  final List<CameraDescription> cameras;
  const CreateGroupPage(this.cameras,{super.key});
  @override State<CreateGroupPage> createState()=>_CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage>{
  final nameController=TextEditingController();
  final templeController=TextEditingController();
  @override void dispose(){
    nameController.dispose();templeController.dispose();super.dispose();
  }
  Future<void> create()async{
    final name=nameController.text.trim(),temple=templeController.text.trim();
    if(name.isEmpty||temple.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('กรุณากรอกข้อมูลให้ครบทุกช่อง')));return;
    }
    final groups=await Storage.load(),now=Storage.now();
    groups.add(GroupData(
      id:Storage.id(),name:name,temple:temple,createdAt:now,
      updatedAt:now,models:[]));
    await Storage.save(groups);
    if(!mounted)return;
    Navigator.of(context).popUntil((r)=>r.isFirst);
  }
  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('สร้างกลุ่ม')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      TextField(controller:nameController,decoration:const InputDecoration(
        labelText:'ชื่อพระ *',hintText:'เช่น หลวงปู่ทวด',
        border:OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller:templeController,decoration:const InputDecoration(
        labelText:'วัด / สำนัก *',hintText:'เช่น วัดช้างให้',
        border:OutlineInputBorder())),
      const SizedBox(height:24),
      SizedBox(width:double.infinity,child:FilledButton(
        onPressed:create,child:const Text('สร้างกลุ่ม'))),
    ]));
}

class GroupListPage extends StatefulWidget{
  final List<CameraDescription> cameras;
  const GroupListPage(this.cameras,{super.key});
  @override State<GroupListPage> createState()=>_GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage>{
  List<GroupData> groups=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{
    final d=await Storage.load();
    if(mounted)setState(()=>groups=d);
  }
  Future<void> deleteGroup(GroupData g)async{
    if(!await confirmDelete(context,'ลบรายการ',
      'ต้องการลบรายการนี้ใช่หรือไม่?'))return;
    groups.removeWhere((e)=>e.id==g.id);
    await Storage.save(groups);load();
  }
  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('รายการที่บันทึก')),
    body:groups.isEmpty?const Center(child:Text('ยังไม่มีรายการที่บันทึก')):
    ListView.builder(
      padding:const EdgeInsets.all(12),itemCount:groups.length,
      itemBuilder:(_,i){
        final g=groups[i];
        final models=g.models.isEmpty?'ยังไม่มีรุ่น':
          g.models.map((m)=>m.name).join(', ');
        final tc=g.models.fold<int>(0,(s,m)=>s+m.types.length);
        return Card(child:ListTile(
          title:Text(g.name),
          subtitle:Text('${g.temple}\nรุ่น: $models\nชนิด $tc รายการ'),
          isThreeLine:true,
          onTap:()=>Navigator.push(c,MaterialPageRoute(
            builder:(_)=>ModelListPage(
              cameras:widget.cameras,groupId:g.id))).then((_)=>load()),
          trailing:PopupMenuButton<String>(
            onSelected:(v){if(v=='delete')deleteGroup(g);},
            itemBuilder:(_)=>const[PopupMenuItem(
              value:'delete',child:Text('ลบรายการ'))])));
      }));
}

class ModelListPage extends StatefulWidget{
  final List<CameraDescription> cameras;
  final String groupId;
  const ModelListPage({
    required this.cameras,required this.groupId,super.key});
  @override State<ModelListPage> createState()=>_ModelListPageState();
}

class _ModelListPageState extends State<ModelListPage>{
  GroupData? group;
  @override void initState(){super.initState();load();}
  Future<void> load()async{
    final gs=await Storage.load();
    for(final g in gs){
      if(g.id==widget.groupId&&mounted){
        setState(()=>group=g);return;
      }
    }
  }
  Future<void> addModel()async{
    final r=await Navigator.push(context,MaterialPageRoute(
      builder:(_)=>CreateDataPage(
        cameras:widget.cameras,groupId:widget.groupId)));
    if(r==true)load();
  }
  Future<void> deleteModel(ModelData model)async{
    final hasData=model.types.isNotEmpty;
    final refs=model.types.fold<int>(0,(s,t)=>s+t.references.length);
    final message=hasData
      ?'รุ่น "${model.name}" มี ${model.types.length} ชนิด และองค์อ้างอิง $refs องค์\n'
       'การลบจะลบข้อมูลทั้งหมดใต้รุ่นนี้ด้วย\n\nต้องการลบใช่หรือไม่?'
      :'ต้องการลบรุ่น "${model.name}" ใช่หรือไม่?';
    if(!await confirmDelete(context,'ลบรุ่น',message))return;
    final groups=await Storage.load();
    for(final g in groups){
      if(g.id!=widget.groupId)continue;
      g.models.removeWhere((e)=>e.id==model.id);
      await Storage.save(groups);load();return;
    }
  }
  @override Widget build(BuildContext c){
    final g=group;
    return Scaffold(
      appBar:AppBar(title:Text(g?.name??'รายการ'),actions:[
        FilledButton.icon(
          onPressed:addModel,
          icon:const Icon(Icons.add,size:22),
          label:const Text('รุ่น',style:TextStyle(
            fontSize:16,fontWeight:FontWeight.bold))),
      ]),
      body:g==null?const Center(child:CircularProgressIndicator()):
      g.models.isEmpty?const Center(child:Text('ยังไม่มีรุ่น')):
      ListView.builder(
        padding:const EdgeInsets.all(12),itemCount:g.models.length,
        itemBuilder:(_,i){
          final m=g.models[i];
          return Card(child:ListTile(
            title:Text('รุ่น ${m.name}'),
            subtitle:Text('${m.types.length} ชนิด'),
            trailing:Row(
              mainAxisSize:MainAxisSize.min,
              children:[
                IconButton(
                  icon:const Icon(Icons.remove_circle_outline),
                  tooltip:'ลบรุ่น',onPressed:()=>deleteModel(m)),
                const Icon(Icons.chevron_right),
              ]),
            onTap:()=>Navigator.push(c,MaterialPageRoute(
              builder:(_)=>TypeListPage(
                cameras:widget.cameras,
                groupId:widget.groupId,modelId:m.id))),
          ));
        }));
  }
}

class CreateDataPage extends StatefulWidget{
  final List<CameraDescription> cameras;
  final String groupId;
  const CreateDataPage({
    required this.cameras,required this.groupId,super.key});
  @override State<CreateDataPage> createState()=>_CreateDataPageState();
}

class _CreateDataPageState extends State<CreateDataPage>{
  final modelController=TextEditingController();
  @override void dispose(){modelController.dispose();super.dispose();}
  Future<void> saveData()async{
    final name=modelController.text.trim();
    if(name.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('กรุณากรอกชื่อรุ่น')));return;
    }
    final groups=await Storage.load();
    for(final g in groups){
      if(g.id!=widget.groupId)continue;
      final now=Storage.now();
      g.models.add(ModelData(
        id:Storage.id(),name:name,createdAt:now,updatedAt:now,types:[]));
      await Storage.save(groups);
      if(!mounted)return;
      Navigator.pop(context,true);return;
    }
  }
  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('เพิ่มรุ่น')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      TextField(controller:modelController,decoration:const InputDecoration(
        labelText:'รุ่น *',hintText:'เช่น รุ่นแรก / ปี 2505',
        border:OutlineInputBorder())),
      const SizedBox(height:24),
      SizedBox(width:double.infinity,child:FilledButton(
        onPressed:saveData,child:const Text('บันทึก'))),
    ]));
}

class TypeListPage extends StatefulWidget{
  final List<CameraDescription> cameras;
  final String groupId,modelId;
  const TypeListPage({
    required this.cameras,required this.groupId,
    required this.modelId,super.key});
  @override State<TypeListPage> createState()=>_TypeListPageState();
}

class _TypeListPageState extends State<TypeListPage>{
  ModelData? model;
  @override void initState(){super.initState();load();}
  Future<void> load()async{
    final gs=await Storage.load();
    for(final g in gs){
      if(g.id!=widget.groupId)continue;
      for(final m in g.models){
        if(m.id==widget.modelId&&mounted){
          setState(()=>model=m);return;
        }
      }
    }
  }

  Future<void> addType()async{
    final controller=TextEditingController();
    String selected=typeOptions.first;
    final result=await showDialog<String>(
      context:context,builder:(context)=>StatefulBuilder(
        builder:(context,setDialog){
          final other=selected=='อื่น ๆ';
          return AlertDialog(
            title:const Text('เพิ่มชนิด'),
            content:Column(mainAxisSize:MainAxisSize.min,children:[
              DropdownButtonFormField<String>(
                value:selected,isExpanded:true,
                decoration:const InputDecoration(
                  labelText:'ชนิด',border:OutlineInputBorder()),
                items:typeOptions.map((e)=>DropdownMenuItem(
                  value:e,child:Text(e))).toList(),
                onChanged:(v){if(v!=null)setDialog(()=>selected=v);}),
              if(other)...[
                const SizedBox(height:12),
                TextField(controller:controller,decoration:
                  const InputDecoration(
                    labelText:'ระบุชนิด',border:OutlineInputBorder())),
              ],
            ]),
            actions:[
              TextButton(
                onPressed:()=>Navigator.pop(context),
                child:const Text('ยกเลิก')),
              FilledButton(
                onPressed:(){
                  final name=other?controller.text.trim():selected;
                  if(name.isNotEmpty&&name!='อื่น ๆ')
                    Navigator.pop(context,name);
                },
                child:const Text('เพิ่ม')),
            ]);
        }));
    controller.dispose();
    if(result==null)return;
    final groups=await Storage.load();
    for(final g in groups){
      if(g.id!=widget.groupId)continue;
      for(final m in g.models){
        if(m.id!=widget.modelId)continue;
        final now=Storage.now();
        m.types.add(TypeData(
          id:Storage.id(),name:result,createdAt:now,updatedAt:now));
        await Storage.save(groups);load();return;
      }
    }
  }

  Future<void> deleteType(TypeData type)async{
    final hasData=type.references.isNotEmpty;
    final message=hasData
      ?'ชนิด "${type.name}" มีองค์อ้างอิง ${type.references.length} องค์\n'
       'การลบจะลบองค์อ้างอิงและข้อมูลสแกนทั้งหมดใต้ชนิดนี้ด้วย\n\n'
       'ต้องการลบใช่หรือไม่?'
      :'ต้องการลบชนิด "${type.name}" ใช่หรือไม่?';
    if(!await confirmDelete(context,'ลบชนิด',message))return;
    final groups=await Storage.load();
    for(final g in groups){
      if(g.id!=widget.groupId)continue;
      for(final m in g.models){
        if(m.id!=widget.modelId)continue;
        m.types.removeWhere((e)=>e.id==type.id);
        await Storage.save(groups);load();return;
      }
    }
  }

  @override Widget build(BuildContext c){
    final m=model;
    return Scaffold(
      appBar:AppBar(
        title:Text('รุ่น ${m?.name??''}'),
        actions:[
          FilledButton.icon(
            onPressed:addType,
            icon:const Icon(Icons.add,size:22),
            label:const Text('ชนิด',style:TextStyle(
              fontSize:16,fontWeight:FontWeight.bold))),
        ]),
      body:m==null?const Center(child:CircularProgressIndicator()):
      m.types.isEmpty?const Center(child:Text('ยังไม่มีชนิด\nกด + เพื่อเพิ่มชนิด')):
      ListView.builder(
        padding:const EdgeInsets.all(12),itemCount:m.types.length,
        itemBuilder:(_,i){
          final type=m.types[i];
          return Card(child:ListTile(
            title:Text(type.name),
            subtitle:Text('อ้างอิง ${type.references.length} องค์'),
            trailing:Row(
              mainAxisSize:MainAxisSize.min,
              children:[
                IconButton(
                  icon:const Icon(Icons.remove_circle_outline),
                  tooltip:'ลบชนิด',onPressed:()=>deleteType(type)),
                const Icon(Icons.chevron_right),
              ]),
            onTap:()=>Navigator.push(c,MaterialPageRoute(
              builder:(_)=>ReferenceListPage(
                cameras:widget.cameras,groupId:widget.groupId,
                modelId:widget.modelId,typeId:type.id))),
          ));
        }));
  }
}

class ReferenceListPage extends StatefulWidget{
  final List<CameraDescription> cameras;
  final String groupId,modelId,typeId;
  const ReferenceListPage({
    required this.cameras,required this.groupId,
    required this.modelId,required this.typeId,super.key});
  @override State<ReferenceListPage> createState()=>_ReferenceListPageState();
}

class _ReferenceListPageState extends State<ReferenceListPage>{
  GroupData? group;
  ModelData? model;
  TypeData? type;
  @override void initState(){super.initState();load();}

  Future<void> load()async{
    final groups=await Storage.load();
    for(final g in groups){
      if(g.id!=widget.groupId)continue;
      for(final m in g.models){
        if(m.id!=widget.modelId)continue;
        for(final t in m.types){
          if(t.id!=widget.typeId)continue;
          Storage.renumber(t);
          if(mounted)setState((){
            group=g;model=m;type=t;
          });
          await Storage.save(groups);return;
        }
      }
    }
  }

  Future<void> addReference()async{
    final t=type;if(t==null)return;
    final ref=ReferenceData(
      id:Storage.id(),referenceNumber:t.references.length+1,
      createdAt:Storage.now(),updatedAt:Storage.now());
    final groups=await Storage.load();
    for(final g in groups){
      if(g.id!=widget.groupId)continue;
      for(final m in g.models){
        if(m.id!=widget.modelId)continue;
        for(final savedType in m.types){
          if(savedType.id!=widget.typeId)continue;
          savedType.references.add(ref);Storage.renumber(savedType);
          await Storage.save(groups);
          if(!mounted)return;
          await Navigator.push(context,MaterialPageRoute(
            builder:(_)=>ScanPage(
              cameras:widget.cameras,groupId:widget.groupId,
              modelId:widget.modelId,typeId:widget.typeId,
              referenceId:ref.id)));
          load();return;
        }
      }
    }
  }

  Future<void> deleteReference(ReferenceData ref)async{
    if(!await confirmDelete(context,'ลบอ้างอิง',
      'ต้องการลบอ้างอิง ${ref.referenceNumber} ใช่หรือไม่?'))return;
    final groups=await Storage.load();
    for(final g in groups){
      if(g.id!=widget.groupId)continue;
      for(final m in g.models){
        if(m.id!=widget.modelId)continue;
        for(final t in m.types){
          if(t.id!=widget.typeId)continue;
          t.references.removeWhere((e)=>e.id==ref.id);
          Storage.renumber(t);await Storage.save(groups);load();return;
        }
      }
    }
  }

  @override Widget build(BuildContext c){
    final t=type;
    return Scaffold(
      appBar:AppBar(
        title:Text(t?.name??'อ้างอิง'),
        actions:[
          IconButton(onPressed:addReference,icon:const Icon(Icons.add),
            tooltip:'เพิ่มอ้างอิง'),
        ]),
      body:t==null?const Center(child:CircularProgressIndicator()):
      t.references.isEmpty?const Center(child:Text(
        'ยังไม่มีอ้างอิง\nกด + เพื่อเพิ่มองค์อ้างอิง',
        textAlign:TextAlign.center)):
      ListView.builder(
        padding:const EdgeInsets.all(12),
        itemCount:t.references.length,
        itemBuilder:(_,i){
          final ref=t.references[i];
          return Card(child:ListTile(
            leading:CircleAvatar(child:Text('${ref.referenceNumber}')),
            title:Text('อ้างอิง ${ref.referenceNumber}'),
            subtitle:Text('มีข้อมูล ${ref.scans.length}/${areas.length} ด้าน'),
            trailing:PopupMenuButton<String>(
              onSelected:(v){if(v=='delete')deleteReference(ref);},
              itemBuilder:(_)=>const[PopupMenuItem(
                value:'delete',child:Text('ลบอ้างอิง'))]),
            onTap:()=>Navigator.push(c,MaterialPageRoute(
              builder:(_)=>ScanPage(
                cameras:widget.cameras,groupId:widget.groupId,
                modelId:widget.modelId,typeId:widget.typeId,
                referenceId:ref.id))).then((_)=>load()),
          ));
        }));
  }
}

class ScanPage extends StatefulWidget{
  final List<CameraDescription> cameras;
  final String groupId,modelId,typeId,referenceId;
  const ScanPage({
    required this.cameras,required this.groupId,required this.modelId,
    required this.typeId,required this.referenceId,super.key});
  @override State<ScanPage> createState()=>_ScanPageState();
}

class _ScanPageState extends State<ScanPage>{
  String selectedArea=areas.first;
  bool saving=false;
  Map<String,ScanResult> scans={};

  @override void initState(){
    super.initState();loadReference();
  }

  Future<void> loadReference()async{
    final groups=await Storage.load();
    for(final g in groups){
      if(g.id!=widget.groupId)continue;
      for(final m in g.models){
        if(m.id!=widget.modelId)continue;
        for(final t in m.types){
          if(t.id!=widget.typeId)continue;
          for(final ref in t.references){
            if(ref.id==widget.referenceId&&mounted){
              setState(()=>scans={
                for(final s in ref.scans)s.area:s});
              return;
            }
          }
        }
      }
    }
  }

  Future<void> scanCamera()async{
    if(widget.cameras.isEmpty){
      showMessage('ไม่พบกล้องในเครื่อง');return;
    }
    setState(()=>saving=true);
    CameraController? controller;
    try{
      final camera=widget.cameras.firstWhere(
        (c)=>c.lensDirection==CameraLensDirection.back,
        orElse:()=>widget.cameras.first);
      controller=CameraController(
        camera,ResolutionPreset.medium,enableAudio:false);
      await controller.initialize();
      final file=await controller.takePicture();

      // ใช้ภาพชั่วคราวเพื่อส่งเข้าสู่ขั้นตอนวิเคราะห์
      await saveScan(file);

      // ไม่เก็บภาพจากกล้องถาวร
      try{await File(file.path).delete();}catch(_){}
    }catch(_){
      showMessage('ไม่สามารถสแกนจากกล้องได้');
    }finally{
      await controller?.dispose();
      if(mounted)setState(()=>saving=false);
    }
  }

  Future<void> scanGallery()async{
    setState(()=>saving=true);
    try{
      final file=await ImagePicker().pickImage(source:ImageSource.gallery);
      if(file==null)return;

      // ใช้ภาพชั่วคราวเพื่อส่งเข้าสู่ขั้นตอนวิเคราะห์
      await saveScan(file);
    }catch(_){
      showMessage('ไม่สามารถเลือกภาพได้');
    }finally{
      if(mounted)setState(()=>saving=false);
    }
  }

  Future<void> saveScan(XFile file)async{
    final groups=await Storage.load();
    for(final g in groups){
      if(g.id!=widget.groupId)continue;
      for(final m in g.models){
        if(m.id!=widget.modelId)continue;
        for(final t in m.types){
          if(t.id!=widget.typeId)continue;
          for(var i=0;i<t.references.length;i++){
            final ref=t.references[i];

            if(ref.id!=widget.referenceId)continue;

            // จุดนี้ในอนาคตจะส่งภาพชั่วคราวให้ AI วิเคราะห์
            // และเก็บเฉพาะสิ่งที่ AI มองเห็นจากภาพ
            final result=ScanResult(
              area:selectedArea,
              details:'รอระบบ AI วิเคราะห์สิ่งที่มองเห็นจากภาพ');

            t.references[i]=ref.copyWith(
              updatedAt:Storage.now(),
              scans:[
                ...ref.scans.where((e)=>e.area!=selectedArea),
                result,
              ]);

            await Storage.save(groups);

            if(mounted){
              setState(()=>scans[selectedArea]=result);
              showMessage('บันทึกข้อมูล $selectedArea แล้ว');
            }
            return;
          }
        }
      }
    }
  }

  void showMessage(String text){
    if(!mounted)return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content:Text(text)));
  }

  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('สแกนอ้างอิง')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(
        padding:const EdgeInsets.all(16),
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            const Text('เลือกด้านที่จะสแกน',
              style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
            const SizedBox(height:12),
            Wrap(
              spacing:8,runSpacing:8,
              children:areas.map((area){
                final scanned=scans.containsKey(area);
                return ChoiceChip(
                  label:Text(scanned?'$area ✓':area),
                  selected:selectedArea==area,
                  onSelected:(_)=>
                    setState(()=>selectedArea=area));
              }).toList(),
            ),
          ],
        ),
      )),
      const SizedBox(height:12),
      Card(child:Padding(
        padding:const EdgeInsets.all(16),
        child:Column(children:[
          Text(
            scans.containsKey(selectedArea)
              ?'ด้านนี้มีข้อมูลแล้ว':'ด้านนี้ยังไม่ได้สแกน',
            style:const TextStyle(
              fontSize:17,fontWeight:FontWeight.bold)),
          const SizedBox(height:8),
          Text(
            'เลือก $selectedArea แล้วใช้กล้อง '
            'หรือเลือกรูปจากแกลเลอรี',
            textAlign:TextAlign.center),
          const SizedBox(height:16),
          SizedBox(
            width:double.infinity,
            child:FilledButton.icon(
              onPressed:saving?null:scanCamera,
              icon:const Icon(Icons.camera_alt),
              label:const Text('สแกนด้วยกล้อง'))),
          const SizedBox(height:10),
          SizedBox(
            width:double.infinity,
            child:OutlinedButton.icon(
              onPressed:saving?null:scanGallery,
              icon:const Icon(Icons.photo_library),
              label:const Text('เลือกจากแกลเลอรี'))),
        ]))),
      const SizedBox(height:12),
      Card(child:Padding(
        padding:const EdgeInsets.all(16),
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            const Text('ข้อมูลที่เก็บ',
              style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
            const SizedBox(height:10),
            ...areas.map((area)=>ListTile(
              dense:true,
              leading:Icon(
                scans.containsKey(area)
                  ?Icons.check_circle
                  :Icons.radio_button_unchecked),
              title:Text(area),
              subtitle:scans.containsKey(area)
                ?Text(scans[area]!.details)
                :const Text('ยังไม่ได้สแกน'),
            )),
          ],
        ),
      )),
      const SizedBox(height:12),
      const Card(child:Padding(
        padding:EdgeInsets.all(16),
        child:Text(
          'รูปภาพใช้สำหรับการวิเคราะห์ชั่วคราว '
          'ระบบไม่เก็บไฟล์รูปภาพถาวร'),
      )),
    ]));
}

Future<bool> confirmDelete(
  BuildContext context,String title,String message)async{
  final result=await showDialog<bool>(
    context:context,
    builder:(_)=>AlertDialog(
      title:Text(title),content:Text(message),
      actions:[
        TextButton(
          onPressed:()=>Navigator.pop(context,false),
          child:const Text('ยกเลิก')),
        FilledButton(
          onPressed:()=>Navigator.pop(context,true),
          child:const Text('ลบ')),
      ]));
  return result??false;
}
