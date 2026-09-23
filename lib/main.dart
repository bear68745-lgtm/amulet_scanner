import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<CameraDescription> c=[];
  try{c=await availableCameras();}catch(_){}
  runApp(App(c));
}

/* ================= RULES ================= */

const typeOptions=[
  'เหรียญ','เหรียญหล่อ','พระสมเด็จ','รูปหล่อ','พระกริ่ง',
  'พระปิดตาเนื้อผง/หว้าน','พระปิดตาเนื้อโลหะ','พระเนื้อผง',
  'พระเนื้อดิน','พระนางพญา','ผงสุพรรณ','พระรอด','พระซุ้มกอ',
  'พระขุนแผน','หลวงปู่ทวดเนื้อหว้าน','หลวงปู่ทวดหลังเตารีด',
  'เขี้ยวแกะ','งาแกะ','ตะกรุด','อื่น ๆ'
];

const allAreas=['ด้านหน้า','ด้านหลัง','ด้านข้าง','ก้นพระ'];

List<String> scanAreasForType(String t)=>
    ['เหรียญ','เหรียญหล่อ','พระขุนแผน'].contains(t)
        ?['ด้านหน้า','ด้านหลัง','ด้านข้าง']:allAreas;

const aiHeads=[
  'พิมพ์ทรง','องค์ประกอบ','ลวดลาย','ตำหนิที่มองเห็น','ผิว',
  'ลักษณะเนื้อที่มองเห็น','ขอบ/ด้านข้าง','จุดสังเกต',
  'รายละเอียดอื่น','สิ่งที่อ่านไม่ได้'
];

/* ================= HELPERS ================= */

String newId()=>
    '${DateTime.now().microsecondsSinceEpoch}_${UniqueKey().hashCode}';

String now()=>DateTime.now().toIso8601String();

Future<void> textDialog(
  BuildContext x,String title,String value,
  Future<void> Function(String) save,
)async{
  final c=TextEditingController(text:value);
  await showDialog(
    context:x,
    builder:(_)=>AlertDialog(
      title:Text(title),
      content:TextField(
        controller:c,
        autofocus:true,
        decoration:const InputDecoration(
          border:OutlineInputBorder()),
      ),
      actions:[
        TextButton(
          onPressed:()=>Navigator.pop(x),
          child:const Text('ยกเลิก')),
        ElevatedButton(
          onPressed:()async{
            final v=c.text.trim();
            if(v.isNotEmpty)await save(v);
            if(x.mounted)Navigator.pop(x);
          },
          child:const Text('บันทึก'),
        ),
      ],
    ),
  );
  c.dispose();
}

Future<bool> confirmDelete(
  BuildContext x,String title,String message,
)async{
  final r=await showDialog<bool>(
    context:x,
    builder:(_)=>AlertDialog(
      title:Text(title),
      content:Text(message),
      actions:[
        TextButton(
          onPressed:()=>Navigator.pop(x,false),
          child:const Text('ยกเลิก')),
        ElevatedButton(
          style:ElevatedButton.styleFrom(
            backgroundColor:Colors.red,
            foregroundColor:Colors.white),
          onPressed:()=>Navigator.pop(x,true),
          child:const Text('ลบ'),
        ),
      ],
    ),
  );
  return r==true;
}

List<T> mapList<T>(
  dynamic v,T Function(Map<String,dynamic>) f,
)=> (v is List?v:[])
    .map((e)=>f(Map<String,dynamic>.from(e)))
    .toList();

/* ================= DATA ================= */

class ScanResult{
  String area,details;
  ScanResult({required this.area,required this.details});

  Map<String,dynamic> toMap()=>{'area':area,'details':details};

  factory ScanResult.fromMap(Map<String,dynamic> m)=>ScanResult(
    area:m['area']??'',
    details:m['details']??'',
  );
}

class ReferenceData{
  String id,createdAt,updatedAt;
  int referenceNumber;
  List<ScanResult> scans;

  ReferenceData({
    required this.id,
    required this.referenceNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.scans,
  });

  Map<String,dynamic> toMap()=> {
    'id':id,
    'referenceNumber':referenceNumber,
    'createdAt':createdAt,
    'updatedAt':updatedAt,
    'scans':scans.map((e)=>e.toMap()).toList(),
  };

  factory ReferenceData.fromMap(Map<String,dynamic> m)=>ReferenceData(
    id:m['id']??newId(),
    referenceNumber:m['referenceNumber']??1,
    createdAt:m['createdAt']??now(),
    updatedAt:m['updatedAt']??now(),
    scans:mapList(m['scans'],ScanResult.fromMap),
  );
}

class PrintData{
  String id,name,createdAt,updatedAt;
  List<ReferenceData> references;

  PrintData({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.references,
  });

  Map<String,dynamic> toMap()=> {
    'id':id,'name':name,
    'createdAt':createdAt,
    'updatedAt':updatedAt,
    'references':references.map((e)=>e.toMap()).toList(),
  };

  factory PrintData.fromMap(Map<String,dynamic> m)=>PrintData(
    id:m['id']??newId(),
    name:m['name']??'',
    createdAt:m['createdAt']??now(),
    updatedAt:m['updatedAt']??now(),
    references:mapList(m['references'],ReferenceData.fromMap),
  );
}

class TypeData{
  String id,name,createdAt,updatedAt;
  List<PrintData> prints;

  TypeData({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.prints,
  });

  Map<String,dynamic> toMap()=> {
    'id':id,'name':name,
    'createdAt':createdAt,
    'updatedAt':updatedAt,
    'prints':prints.map((e)=>e.toMap()).toList(),
  };

  factory TypeData.fromMap(Map<String,dynamic> m)=>TypeData(
    id:m['id']??newId(),
    name:m['name']??'',
    createdAt:m['createdAt']??now(),
    updatedAt:m['updatedAt']??now(),
    prints:mapList(m['prints'],PrintData.fromMap),
  );
}

class ModelData{
  String id,name,createdAt,updatedAt;
  List<TypeData> types;

  ModelData({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.types,
  });

  Map<String,dynamic> toMap()=> {
    'id':id,'name':name,
    'createdAt':createdAt,
    'updatedAt':updatedAt,
    'types':types.map((e)=>e.toMap()).toList(),
  };

  factory ModelData.fromMap(Map<String,dynamic> m)=>ModelData(
    id:m['id']??newId(),
    name:m['name']??'',
    createdAt:m['createdAt']??now(),
    updatedAt:m['updatedAt']??now(),
    types:mapList(m['types'],TypeData.fromMap),
  );
}

class GroupData{
  String id,name,temple,createdAt,updatedAt;
  List<ModelData> models;

  GroupData({
    required this.id,
    required this.name,
    required this.temple,
    required this.createdAt,
    required this.updatedAt,
    required this.models,
  });

  Map<String,dynamic> toMap()=> {
    'id':id,'name':name,'temple':temple,
    'createdAt':createdAt,
    'updatedAt':updatedAt,
    'models':models.map((e)=>e.toMap()).toList(),
  };

  factory GroupData.fromMap(Map<String,dynamic> m)=>GroupData(
    id:m['id']??newId(),
    name:m['name']??'',
    temple:m['temple']??'',
    createdAt:m['createdAt']??now(),
    updatedAt:m['updatedAt']??now(),
    models:mapList(m['models'],ModelData.fromMap),
  );
}

/* ================= AI DATA ================= */

class AiKnowledge{
  String id,groupId,modelId,typeId,printId,referenceId,
      area,content,createdAt,updatedAt;

  AiKnowledge({
    required this.id,
    required this.groupId,
    required this.modelId,
    required this.typeId,
    required this.printId,
    required this.referenceId,
    required this.area,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String,dynamic> toMap()=> {
    'id':id,'groupId':groupId,'modelId':modelId,
    'typeId':typeId,'printId':printId,
    'referenceId':referenceId,'area':area,
    'content':content,'createdAt':createdAt,
    'updatedAt':updatedAt,
  };

  factory AiKnowledge.fromMap(Map<String,dynamic> m)=>AiKnowledge(
    id:m['id']??newId(),
    groupId:m['groupId']??'',
    modelId:m['modelId']??'',
    typeId:m['typeId']??'',
    printId:m['printId']??'',
    referenceId:m['referenceId']??'',
    area:m['area']??'',
    content:m['content']??'',
    createdAt:m['createdAt']??'',
    updatedAt:m['updatedAt']??'',
  );
}

class AiLearningHistory{
  String id,groupId,modelId,typeId,printId,referenceId,
      area,content,learnedAt;

  AiLearningHistory({
    required this.id,
    required this.groupId,
    required this.modelId,
    required this.typeId,
    required this.printId,
    required this.referenceId,
    required this.area,
    required this.content,
    required this.learnedAt,
  });

  Map<String,dynamic> toMap()=> {
    'id':id,'groupId':groupId,'modelId':modelId,
    'typeId':typeId,'printId':printId,
    'referenceId':referenceId,'area':area,
    'content':content,'learnedAt':learnedAt,
  };

  factory AiLearningHistory.fromMap(Map<String,dynamic> m)=>
      AiLearningHistory(
    id:m['id']??newId(),
    groupId:m['groupId']??'',
    modelId:m['modelId']??'',
    typeId:m['typeId']??'',
    printId:m['printId']??'',
    referenceId:m['referenceId']??'',
    area:m['area']??'',
    content:m['content']??'',
    learnedAt:m['learnedAt']??'',
  );
}

class AiMemoryTest{
  String id,knowledgeId,referenceId,area,question,answer,testedAt;

  AiMemoryTest({
    required this.id,
    required this.knowledgeId,
    required this.referenceId,
    required this.area,
    required this.question,
    required this.answer,
    required this.testedAt,
  });

  Map<String,dynamic> toMap()=> {
    'id':id,'knowledgeId':knowledgeId,
    'referenceId':referenceId,'area':area,
    'question':question,'answer':answer,
    'testedAt':testedAt,
  };

  factory AiMemoryTest.fromMap(Map<String,dynamic> m)=>AiMemoryTest(
    id:m['id']??newId(),
    knowledgeId:m['knowledgeId']??'',
    referenceId:m['referenceId']??'',
    area:m['area']??'',
    question:m['question']??'',
    answer:m['answer']??'',
    testedAt:m['testedAt']??'',
  );
}

class AiTestResult{
  String id,testId,knowledgeId,referenceId,area,mode,result,
      answer,referenceAnswer,reason,checkedAt;

  AiTestResult({
    required this.id,
    required this.testId,
    required this.knowledgeId,
    required this.referenceId,
    required this.area,
    required this.mode,
    required this.result,
    required this.answer,
    required this.referenceAnswer,
    required this.reason,
    required this.checkedAt,
  });

  Map<String,dynamic> toMap()=> {
    'id':id,'testId':testId,'knowledgeId':knowledgeId,
    'referenceId':referenceId,'area':area,'mode':mode,
    'result':result,'answer':answer,
    'referenceAnswer':referenceAnswer,'reason':reason,
    'checkedAt':checkedAt,
  };

  factory AiTestResult.fromMap(Map<String,dynamic> m)=>AiTestResult(
    id:m['id']??newId(),
    testId:m['testId']??'',
    knowledgeId:m['knowledgeId']??'',
    referenceId:m['referenceId']??'',
    area:m['area']??'',
    mode:m['mode']??'',
    result:m['result']??'',
    answer:m['answer']??'',
    referenceAnswer:m['referenceAnswer']??'',
    reason:m['reason']??'',
    checkedAt:m['checkedAt']??'',
  );
}

/* ================= STORAGE ================= */

class Storage{
  static const groupsKey='reference_groups',
      knowledgeKey='ai_knowledge',
      historyKey='ai_learning_history',
      testsKey='ai_memory_tests',
      resultsKey='ai_test_results';

  static Future<List<T>> _get<T>(
    String key,T Function(Map<String,dynamic>) f,
  )async{
    final p=await SharedPreferences.getInstance();
    final s=p.getString(key);
    if(s==null||s.isEmpty)return [];
    try{return mapList(jsonDecode(s),f);}catch(_){return [];}
  }

  static Future<void> _save<T>(
    String key,List<T> list,
    Map<String,dynamic> Function(T) f,
  )async{
    final p=await SharedPreferences.getInstance();
    await p.setString(key,jsonEncode(list.map(f).toList()));
  }

  static Future<List<GroupData>> groups()=>
      _get(groupsKey,GroupData.fromMap);

  static Future<void> saveGroups(List<GroupData> x)=>
      _save(groupsKey,x,(e)=>e.toMap());

  static Future<void> saveGroup(GroupData g)async{
    final x=await groups();
    final i=x.indexWhere((e)=>e.id==g.id);
    g.updatedAt=now();
    if(i>=0)x[i]=g;else x.add(g);
    await saveGroups(x);
  }

  static Future<List<AiKnowledge>> knowledge()=>
      _get(knowledgeKey,AiKnowledge.fromMap);

  static Future<void> saveKnowledge(List<AiKnowledge> x)=>
      _save(knowledgeKey,x,(e)=>e.toMap());

  static Future<List<AiLearningHistory>> history()=>
      _get(historyKey,AiLearningHistory.fromMap);

  static Future<void> saveHistory(List<AiLearningHistory> x)=>
      _save(historyKey,x,(e)=>e.toMap());

  static Future<List<AiMemoryTest>> tests()=>
      _get(testsKey,AiMemoryTest.fromMap);

  static Future<void> saveTests(List<AiMemoryTest> x)=>
      _save(testsKey,x,(e)=>e.toMap());

  static Future<List<AiTestResult>> results()=>
      _get(resultsKey,AiTestResult.fromMap);

  static Future<void> saveResults(List<AiTestResult> x)=>
      _save(resultsKey,x,(e)=>e.toMap());

  /* ===== เรียนรู้ข้อมูลสแกน ===== */

  static Future<void> learnScan({
    required GroupData group,
    required ModelData model,
    required TypeData type,
    required PrintData print,
    required ReferenceData reference,
    required ScanResult scan,
  })async{
    final k=await knowledge();
    final h=await history();
    final content=scan.details.trim();

    final same=k.where(
      (e)=>e.referenceId==reference.id&&e.area==scan.area,
    ).toList();

    k.removeWhere(
      (e)=>e.referenceId==reference.id&&e.area==scan.area);

    if(content.isEmpty){
      await saveKnowledge(k);
      return;
    }

    final old=same.isEmpty?null:same.last;

    if(old!=null&&old.content==content){
      k.add(old);
      await saveKnowledge(k);
      return;
    }

    final d=now();

    k.add(AiKnowledge(
      id:old?.id??newId(),
      groupId:group.id,
      modelId:model.id,
      typeId:type.id,
      printId:print.id,
      referenceId:reference.id,
      area:scan.area,
      content:content,
      createdAt:old?.createdAt??d,
      updatedAt:d,
    ));

    h.add(AiLearningHistory(
      id:newId(),
      groupId:group.id,
      modelId:model.id,
      typeId:type.id,
      printId:print.id,
      referenceId:reference.id,
      area:scan.area,
      content:content,
      learnedAt:d,
    ));

    await saveKnowledge(k);
    await saveHistory(h);
  }

  /* ===== ลบความจำองค์ ===== */

  static Future<void> deleteAiByReference(String id)async{
    final k=await knowledge();
    final h=await history();
    final t=await tests();
    final r=await results();

    final ids=k.where((e)=>e.referenceId==id)
        .map((e)=>e.id).toSet();

    await saveKnowledge(
      k.where((e)=>e.referenceId!=id).toList());

    await saveHistory(
      h.where((e)=>e.referenceId!=id).toList());

    await saveTests(
      t.where((e)=>
        e.referenceId!=id&&!ids.contains(e.knowledgeId)).toList());

    await saveResults(
      r.where((e)=>
        e.referenceId!=id&&!ids.contains(e.knowledgeId)).toList());
  }

  static Future<Set<String>> _refsBy(
    bool Function(ModelData) match,
  )async{
    final ids=<String>{};

    for(final g in await groups())
      for(final m in g.models)
        if(match(m))
          for(final t in m.types)
            for(final p in t.prints)
              for(final r in p.references)
                ids.add(r.id);

    return ids;
  }

  static Future<void> deleteAiByModel(String id)async{
    for(final r in await _refsBy((m)=>m.id==id))
      await deleteAiByReference(r);
  }

  static Future<void> deleteAiByType(String id)async{
    final ids=<String>{};

    for(final g in await groups())
      for(final m in g.models)
        for(final t in m.types)
          if(t.id==id)
            for(final p in t.prints)
              for(final r in p.references)
                ids.add(r.id);

    for(final r in ids)
      await deleteAiByReference(r);
  }

  static Future<void> deleteAiByPrint(String id)async{
    final ids=<String>{};

    for(final g in await groups())
      for(final m in g.models)
        for(final t in m.types)
          for(final p in t.prints)
            if(p.id==id)
              for(final r in p.references)
                ids.add(r.id);

    for(final r in ids)
      await deleteAiByReference(r);
  }

  static Future<void> deleteAiByGroup(String id)async{
    final k=await knowledge();
    final h=await history();
    final t=await tests();
    final r=await results();

    final gids=k.where((e)=>e.groupId==id)
        .map((e)=>e.id).toSet();

    final refs=<String>{};

    for(final g in await groups()){
      if(g.id!=id)continue;
      for(final m in g.models)
        for(final t in m.types)
          for(final p in t.prints)
            for(final r in p.references)
              refs.add(r.id);
    }

    await saveKnowledge(
      k.where((e)=>e.groupId!=id).toList());

    await saveHistory(
      h.where((e)=>e.groupId!=id).toList());

    await saveTests(
      t.where((e)=>
        !refs.contains(e.referenceId)&&
        !gids.contains(e.knowledgeId)).toList());

    await saveResults(
      r.where((e)=>
        !refs.contains(e.referenceId)&&
        !gids.contains(e.knowledgeId)).toList());
  }

  /* ===== เปลี่ยน A เป็นกลุ่มใหม่ B ===== */

  static Future<void> changeGroupToNew(
    GroupData g,
    String oldId,
  )async{
    /*
      1. ลบความจำ A ทั้งหมด
      2. เปลี่ยน groupId เป็นของ B
      3. บันทึกกลุ่มใหม่
      4. เรียนรู้ข้อมูลสแกนเดิมใหม่ทั้งหมด
    */

    await deleteAiByGroup(oldId);

    final x=await groups();
    final i=x.indexWhere((e)=>e.id==oldId);

    g.id=newId();
    g.updatedAt=now();

    if(i>=0)x[i]=g;
    else x.add(g);

    await saveGroups(x);

    for(final m in g.models)
      for(final t in m.types)
        for(final p in t.prints)
          for(final r in p.references)
            for(final s in r.scans){
              if(s.details.trim().isEmpty)continue;

              await learnScan(
                group:g,
                model:m,
                type:t,
                print:p,
                reference:r,
                scan:s,
              );
            }
  }
}

/* ================= APP ================= */

class App extends StatelessWidget{
  final List<CameraDescription> cameras;
  const App(this.cameras,{super.key});

  @override
  Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'กล้องสแกนพระและเหรียญ',
    theme:ThemeData(
      colorSchemeSeed:Colors.brown,
      useMaterial3:true,
    ),
    home:HomePage(cameras:cameras),
  );
}

class PathBar extends StatelessWidget{
  final List<String> items;
  const PathBar(this.items,{super.key});

  @override
  Widget build(BuildContext c)=>Container(
    width:double.infinity,
    padding:const EdgeInsets.all(10),
    color:Colors.brown.shade50,
    child:SingleChildScrollView(
      scrollDirection:Axis.horizontal,
      child:Text(items.join('  >  ')),
    ),
  );
}

/* ================= HOME ================= */

class HomePage extends StatefulWidget{
  final List<CameraDescription> cameras;
  const HomePage({required this.cameras,super.key});

  @override
  State<HomePage> createState()=>_HomePageState();
}

class _HomePageState extends State<HomePage>{
  List<GroupData> groups=[];

  @override
  void initState(){
    super.initState();
    load();
  }

  Future<void> load()async{
    groups=await Storage.groups();
    if(mounted)setState((){});
  }

  Future<void> addGroup()async{
    final n=TextEditingController();
    final t=TextEditingController();

    final ok=await showDialog<bool>(
      context:context,
      builder:(_)=>AlertDialog(
        title:const Text('สร้างกลุ่มพระ'),
        content:Column(
          mainAxisSize:MainAxisSize.min,
          children:[
            TextField(
              controller:n,
              decoration:const InputDecoration(
                labelText:'ชื่อพระ',
                border:OutlineInputBorder(),
              ),
            ),
            const SizedBox(height:10),
            TextField(
              controller:t,
              decoration:const InputDecoration(
                labelText:'วัด / เกจิ',
                border:OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions:[
          TextButton(
            onPressed:()=>Navigator.pop(context,false),
            child:const Text('ยกเลิก')),
          ElevatedButton(
            onPressed:()=>n.text.trim().isEmpty
                ?null
                :Navigator.pop(context,true),
            child:const Text('สร้าง'),
          ),
        ],
      ),
    );

    if(ok==true){
      final d=now();

      groups.add(GroupData(
        id:newId(),
        name:n.text.trim(),
        temple:t.text.trim(),
        createdAt:d,
        updatedAt:d,
        models:[],
      ));

      await Storage.saveGroups(groups);
      if(mounted)setState((){});
    }

    n.dispose();
    t.dispose();
  }

  Future<void> editGroup(GroupData g)async{
    final n=TextEditingController(text:g.name);
    final t=TextEditingController(text:g.temple);

    final ok=await showDialog<bool>(
      context:context,
      builder:(_)=>AlertDialog(
        title:const Text('แก้ไขกลุ่ม'),
        content:Column(
          mainAxisSize:MainAxisSize.min,
          children:[
            TextField(
              controller:n,
              decoration:const InputDecoration(
                labelText:'ชื่อพระ',
                border:OutlineInputBorder(),
              ),
            ),
            const SizedBox(height:10),
            TextField(
              controller:t,
              decoration:const InputDecoration(
                labelText:'วัด / เกจิ',
                border:OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions:[
          TextButton(
            onPressed:()=>Navigator.pop(context,false),
            child:const Text('ยกเลิก')),
          ElevatedButton(
            onPressed:()=>Navigator.pop(context,true),
            child:const Text('บันทึก'),
          ),
        ],
      ),
    );

    if(ok==true){
      final newName=n.text.trim();
      final newTemple=t.text.trim();

      final changed=
          newName!=g.name||newTemple!=g.temple;

      if(changed){
        /*
          ถือว่า A ถูกเปลี่ยนเป็นกลุ่มใหม่ B
          จึงล้างความจำ A แล้วสร้างความจำ B ใหม่
        */
        final oldId=g.id;

        g.name=newName;
        g.temple=newTemple;

        await Storage.changeGroupToNew(g,oldId);
      }else{
        await Storage.saveGroup(g);
      }

      await load();
    }

    n.dispose();
    t.dispose();
  }

  Future<void> deleteGroup(GroupData g)async{
    if(!await confirmDelete(
      context,
      'ลบทั้งกลุ่ม?',
      'ข้อมูลรุ่น ชนิด พิมพ์ องค์อ้างอิง ข้อมูลสแกน และความจำ AI ของกลุ่มนี้จะถูกลบทั้งหมด',
    ))return;

    await Storage.deleteAiByGroup(g.id);

    groups.removeWhere((e)=>e.id==g.id);
    await Storage.saveGroups(groups);

    if(mounted)setState((){});
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('ฐานข้อมูลส่วนตัว')),
    body:groups.isEmpty
        ?const Center(child:Text('ยังไม่มีข้อมูลกลุ่มพระ'))
        :ListView.builder(
            padding:const EdgeInsets.all(10),
            itemCount:groups.length,
            itemBuilder:(_,i){
              final g=groups[i];

              return Card(
                child:ListTile(
                  title:Text(
                    g.name,
                    style:const TextStyle(
                      fontWeight:FontWeight.bold),
                  ),
                  subtitle:Text(
                    g.temple.isEmpty
                        ?'ยังไม่ได้ระบุวัด':g.temple,
                  ),
                  trailing:PopupMenuButton<String>(
                    onSelected:(v){
                      if(v=='edit')editGroup(g);
                      if(v=='delete')deleteGroup(g);
                    },
                    itemBuilder:(_)=>const[
                      PopupMenuItem(
                        value:'edit',
                        child:Text('แก้ไข')),
                      PopupMenuItem(
                        value:'delete',
                        child:Text('ลบ')),
                    ],
                  ),
                  onTap:()async{
                    await Navigator.push(
                      c,
                      MaterialPageRoute(
                        builder:(_)=>ModelPage(
                          group:g,
                          cameras:widget.cameras,
                          autoCreate:true,
                        ),
                      ),
                    );
                    await load();
                  },
                ),
              );
            },
          ),
    floatingActionButton:FloatingActionButton.extended(
      onPressed:addGroup,
      icon:const Icon(Icons.add),
      label:const Text('สร้างกลุ่ม'),
    ),
  );
}

/* ================= MODEL ================= */

class ModelPage extends StatefulWidget{
  final GroupData group;
  final List<CameraDescription> cameras;
  final bool autoCreate;

  const ModelPage({
    required this.group,
    required this.cameras,
    this.autoCreate=false,
    super.key,
  });

  @override
  State<ModelPage> createState()=>_ModelPageState();
}

class _ModelPageState extends State<ModelPage>{
  bool opened=false;

  @override
  void initState(){
    super.initState();

    if(widget.autoCreate)
      WidgetsBinding.instance.addPostFrameCallback((_){
        if(mounted&&!opened){
          opened=true;
          add();
        }
      });
  }

  Future<void> add()=>textDialog(
    context,'สร้างรุ่น','',
    (v)async{
      final d=now();

      widget.group.models.add(ModelData(
        id:newId(),
        name:v,
        createdAt:d,
        updatedAt:d,
        types:[],
      ));

      await Storage.saveGroup(widget.group);
      if(mounted)setState((){});
    },
  );

  Future<void> edit(ModelData m)=>textDialog(
    context,'แก้ไขรุ่น',m.name,
    (v)async{
      m.name=v;
      await Storage.saveGroup(widget.group);
      if(mounted)setState((){});
    },
  );

  Future<void> remove(ModelData m)async{
    if(!await confirmDelete(
      context,'ลบรุ่น?',
      'ข้อมูลชนิด พิมพ์ องค์อ้างอิง และความจำ AI ของรุ่นนี้จะถูกลบ',
    ))return;

    await Storage.deleteAiByModel(m.id);

    widget.group.models.removeWhere((e)=>e.id==m.id);
    await Storage.saveGroup(widget.group);

    if(mounted)setState((){});
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('รุ่น')),
    body:Column(
      children:[
        PathBar([widget.group.name,'รุ่น']),
        Expanded(
          child:widget.group.models.isEmpty
              ?const Center(child:Text('ยังไม่มีรุ่น'))
              :ListView.builder(
                  padding:const EdgeInsets.all(8),
                  itemCount:widget.group.models.length,
                  itemBuilder:(_,i){
                    final m=widget.group.models[i];

                    return Card(
                      child:ListTile(
                        title:Text(
                          m.name,
                          style:const TextStyle(
                            fontWeight:FontWeight.bold),
                        ),
                        trailing:Row(
                          mainAxisSize:MainAxisSize.min,
                          children:[
                            IconButton(
                              tooltip:'แก้ไข',
                              onPressed:()=>edit(m),
                              icon:const Icon(Icons.edit)),
                            IconButton(
                              tooltip:'ลบ',
                              onPressed:()=>remove(m),
                              icon:const Icon(Icons.delete)),
                          ],
                        ),
                        onTap:()async{
                          await Navigator.push(
                            c,
                            MaterialPageRoute(
                              builder:(_)=>TypePage(
                                group:widget.group,
                                model:m,
                                cameras:widget.cameras,
                                autoCreate:true,
                              ),
                            ),
                          );
                          if(mounted)setState((){});
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
    floatingActionButton:FloatingActionButton.extended(
      onPressed:add,
      icon:const Icon(Icons.add),
      label:const Text('สร้างรุ่น'),
    ),
  );
}

/* ================= TYPE ================= */

class TypePage extends StatefulWidget{
  final GroupData group;
  final ModelData model;
  final List<CameraDescription> cameras;
  final bool autoCreate;

  const TypePage({
    required this.group,
    required this.model,
    required this.cameras,
    this.autoCreate=false,
    super.key,
  });

  @override
  State<TypePage> createState()=>_TypePageState();
}

class _TypePageState extends State<TypePage>{
  bool opened=false;

  @override
  void initState(){
    super.initState();

    if(widget.autoCreate)
      WidgetsBinding.instance.addPostFrameCallback((_){
        if(mounted&&!opened){
          opened=true;
          add();
        }
      });
  }

  Future<void> add()async{
    String? selected;

    selected=await showDialog<String>(
      context:context,
      builder:(_)=>AlertDialog(
        title:const Text('สร้างชนิด'),
        content:DropdownButtonFormField<String>(
          items:typeOptions.map(
            (e)=>DropdownMenuItem(
              value:e,
              child:Text(e),
            ),
          ).toList(),
          onChanged:(v)=>selected=v,
          decoration:const InputDecoration(
            border:OutlineInputBorder(),
            labelText:'ชนิดพระ',
          ),
        ),
        actions:[
          TextButton(
            onPressed:()=>Navigator.pop(context),
            child:const Text('ยกเลิก')),
          ElevatedButton(
            onPressed:()=>selected==null
                ?null
                :Navigator.pop(context,selected),
            child:const Text('สร้าง')),
        ],
      ),
    );

    if(selected==null)return;

    final d=now();

    widget.model.types.add(TypeData(
      id:newId(),
      name:selected!,
      createdAt:d,
      updatedAt:d,
      prints:[],
    ));

    await Storage.saveGroup(widget.group);

    if(mounted)setState((){});
  }

  Future<void> edit(TypeData t)=>textDialog(
    context,'แก้ไขชนิด',t.name,
    (v)async{
      t.name=v;
      await Storage.saveGroup(widget.group);
      if(mounted)setState((){});
    },
  );

  Future<void> remove(TypeData t)async{
    if(!await confirmDelete(
      context,'ลบชนิด?',
      'ข้อมูลพิมพ์ องค์อ้างอิง และความจำ AI ของชนิดนี้จะถูกลบ',
    ))return;

    await Storage.deleteAiByType(t.id);

    widget.model.types.removeWhere((e)=>e.id==t.id);
    await Storage.saveGroup(widget.group);

    if(mounted)setState((){});
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('ชนิด')),
    body:Column(
      children:[
        PathBar([
          widget.group.name,
          widget.model.name,
          'ชนิด',
        ]),
        Expanded(
          child:widget.model.types.isEmpty
              ?const Center(child:Text('ยังไม่มีชนิด'))
              :ListView.builder(
                  padding:const EdgeInsets.all(8),
                  itemCount:widget.model.types.length,
                  itemBuilder:(_,i){
                    final t=widget.model.types[i];

                    return Card(
                      child:ListTile(
                        title:Text(
                          t.name,
                          style:const TextStyle(
                            fontWeight:FontWeight.bold),
                        ),
                        trailing:Row(
                          mainAxisSize:MainAxisSize.min,
                          children:[
                            IconButton(
                              tooltip:'แก้ไข',
                              onPressed:()=>edit(t),
                              icon:const Icon(Icons.edit)),
                            IconButton(
                              tooltip:'ลบ',
                              onPressed:()=>remove(t),
                              icon:const Icon(Icons.delete)),
                          ],
                        ),
                        onTap:()async{
                          await Navigator.push(
                            c,
                            MaterialPageRoute(
                              builder:(_)=>PrintPage(
                                group:widget.group,
                                model:widget.model,
                                type:t,
                                cameras:widget.cameras,
                                autoCreate:true,
                              ),
                            ),
                          );
                          if(mounted)setState((){});
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
    floatingActionButton:FloatingActionButton.extended(
      onPressed:add,
      icon:const Icon(Icons.add),
      label:const Text('สร้างชนิด'),
    ),
  );
}

/* ================= PRINT ================= */

class PrintPage extends StatefulWidget{
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final List<CameraDescription> cameras;
  final bool autoCreate;

  const PrintPage({
    required this.group,
    required this.model,
    required this.type,
    required this.cameras,
    this.autoCreate=false,
    super.key,
  });

  @override
  State<PrintPage> createState()=>_PrintPageState();
}

class _PrintPageState extends State<PrintPage>{
  bool opened=false;

  @override
  void initState(){
    super.initState();

    if(widget.autoCreate)
      WidgetsBinding.instance.addPostFrameCallback((_){
        if(mounted&&!opened){
          opened=true;
          add();
        }
      });
  }

  Future<void> add()=>textDialog(
    context,'สร้างพิมพ์','',
    (v)async{
      final d=now();

      widget.type.prints.add(PrintData(
        id:newId(),
        name:v,
        createdAt:d,
        updatedAt:d,
        references:[],
      ));

      await Storage.saveGroup(widget.group);
      if(mounted)setState((){});
    },
  );

  Future<void> edit(PrintData p)=>textDialog(
    context,'แก้ไขพิมพ์',p.name,
    (v)async{
      p.name=v;
      await Storage.saveGroup(widget.group);
      if(mounted)setState((){});
    },
  );

  Future<void> remove(PrintData p)async{
    if(!await confirmDelete(
      context,'ลบพิมพ์?',
      'องค์อ้างอิงและความจำ AI ของพิมพ์นี้จะถูกลบ',
    ))return;

    await Storage.deleteAiByPrint(p.id);

    widget.type.prints.removeWhere((e)=>e.id==p.id);
    await Storage.saveGroup(widget.group);

    if(mounted)setState((){});
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('พิมพ์')),
    body:Column(
      children:[
        PathBar([
          widget.group.name,
          widget.model.name,
          widget.type.name,
          'พิมพ์',
        ]),
        Expanded(
          child:widget.type.prints.isEmpty
              ?const Center(child:Text('ยังไม่มีพิมพ์'))
              :ListView.builder(
                  padding:const EdgeInsets.all(8),
                  itemCount:widget.type.prints.length,
                  itemBuilder:(_,i){
                    final p=widget.type.prints[i];

                    return Card(
                      child:ListTile(
                        title:Text(
                          p.name,
                          style:const TextStyle(
                            fontWeight:FontWeight.bold),
                        ),
                        subtitle:Text(
                          'องค์อ้างอิง ${p.references.length} องค์'),
                        trailing:Row(
                          mainAxisSize:MainAxisSize.min,
                          children:[
                            IconButton(
                              tooltip:'แก้ไข',
                              onPressed:()=>edit(p),
                              icon:const Icon(Icons.edit)),
                            IconButton(
                              tooltip:'ลบ',
                              onPressed:()=>remove(p),
                              icon:const Icon(Icons.delete)),
                          ],
                        ),
                        onTap:()async{
                          await Navigator.push(
                            c,
                            MaterialPageRoute(
                              builder:(_)=>ReferencePage(
                                group:widget.group,
                                model:widget.model,
                                type:widget.type,
                                print:p,
                                cameras:widget.cameras,
                                autoCreate:true,
                              ),
                            ),
                          );
                          if(mounted)setState((){});
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
    floatingActionButton:FloatingActionButton.extended(
      onPressed:add,
      icon:const Icon(Icons.add),
      label:const Text('สร้างพิมพ์'),
    ),
  );
}

/* ================= REFERENCE ================= */

class ReferencePage extends StatefulWidget{
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final List<CameraDescription> cameras;
  final bool autoCreate;

  const ReferencePage({
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.cameras,
    this.autoCreate=false,
    super.key,
  });

  @override
  State<ReferencePage> createState()=>_ReferencePageState();
}

class _ReferencePageState extends State<ReferencePage>{
  bool opened=false;

  @override
  void initState(){
    super.initState();

    if(widget.autoCreate)
      WidgetsBinding.instance.addPostFrameCallback((_){
        if(mounted&&!opened){
          opened=true;
          addReference();
        }
      });
  }

  Future<void> addReference()async{
    var max=0;

    for(final r in widget.print.references)
      if(r.referenceNumber>max)
        max=r.referenceNumber;

    final d=now();

    widget.print.references.add(ReferenceData(
      id:newId(),
      referenceNumber:max+1,
      createdAt:d,
      updatedAt:d,
      scans:[],
    ));

    await Storage.saveGroup(widget.group);
    if(mounted)setState((){});
  }

  Future<void> deleteReference(ReferenceData r)async{
    if(!await confirmDelete(
      context,'ลบองค์อ้างอิง?',
      'ข้อมูลสแกนและความจำ AI ขององค์นี้จะถูกลบทั้งหมด',
    ))return;

    await Storage.deleteAiByReference(r.id);

    widget.print.references.removeWhere((e)=>e.id==r.id);
    await Storage.saveGroup(widget.group);

    if(mounted)setState((){});
  }

  Future<void> editReference(ReferenceData r)async{
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:(_)=>ReferenceEditPage(
          group:widget.group,
          model:widget.model,
          type:widget.type,
          print:widget.print,
          reference:r,
          cameras:widget.cameras,
        ),
      ),
    );

    await Storage.saveGroup(widget.group);

    if(mounted)setState((){});
  }

  Future<void> backToGroup()async{
    await Storage.saveGroup(widget.group);

    if(mounted)
      Navigator.popUntil(context,(r)=>r.isFirst);
  }

  @override
  Widget build(BuildContext c){
    final areas=scanAreasForType(widget.type.name);

    return Scaffold(
      appBar:AppBar(title:const Text('องค์อ้างอิง')),
      body:Column(
        children:[
          PathBar([
            widget.group.name,
            widget.model.name,
            widget.type.name,
            widget.print.name,
            'องค์อ้างอิง',
          ]),
          Expanded(
            child:widget.print.references.isEmpty
                ?const Center(
                    child:Text('ยังไม่มีองค์อ้างอิง'))
                :ListView.builder(
                    padding:const EdgeInsets.all(8),
                    itemCount:widget.print.references.length,
                    itemBuilder:(_,i){
                      final r=widget.print.references[i];

                      return Card(
                        child:ExpansionTile(
                          title:Text(
                            'องค์อ้างอิง #${r.referenceNumber}',
                            style:const TextStyle(
                              fontWeight:FontWeight.bold),
                          ),
                          subtitle:Text(
                            'บันทึกแล้ว ${r.scans.length}/${areas.length} ด้าน'),
                          trailing:Row(
                            mainAxisSize:MainAxisSize.min,
                            children:[
                              IconButton(
                                tooltip:'แก้ไข',
                                onPressed:()=>editReference(r),
                                icon:const Icon(Icons.edit)),
                              IconButton(
                                tooltip:'ลบ',
                                onPressed:()=>deleteReference(r),
                                icon:const Icon(Icons.delete)),
                            ],
                          ),
                          children:[
                            ...areas.map((a){
                              final s=r.scans
                                  .cast<ScanResult?>()
                                  .firstWhere(
                                    (e)=>e?.area==a,
                                    orElse:()=>null,
                                  );

                              return ListTile(
                                title:Text(a),
                                subtitle:Text(
                                  s==null||s.details.isEmpty
                                      ?'ยังไม่มีข้อมูล':'มีข้อมูลแล้ว'),
                                trailing:const Icon(
                                  Icons.chevron_right),
                                onTap:()=>editReference(r),
                              );
                            }),
                            Padding(
                              padding:const EdgeInsets.all(10),
                              child:SizedBox(
                                width:double.infinity,
                                child:ElevatedButton.icon(
                                  onPressed:()=>editReference(r),
                                  icon:const Icon(Icons.edit),
                                  label:const Text(
                                    'แก้ไขข้อมูลทุกด้าน'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton:FloatingActionButton.extended(
        onPressed:addReference,
        icon:const Icon(Icons.add),
        label:const Text('เพิ่มองค์อ้างอิง'),
      ),
      bottomNavigationBar:SafeArea(
        child:Padding(
          padding:const EdgeInsets.fromLTRB(10,6,10,10),
          child:OutlinedButton.icon(
            onPressed:backToGroup,
            icon:const Icon(Icons.arrow_back),
            label:const Text('กลับหน้ากลุ่ม'),
          ),
        ),
      ),
    );
  }
}

/* ================= REFERENCE EDIT ================= */

class ReferenceEditPage extends StatefulWidget{
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;
  final List<CameraDescription> cameras;

  const ReferenceEditPage({
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
    required this.cameras,
    super.key,
  });

  @override
  State<ReferenceEditPage> createState()=>_ReferenceEditPageState();
}

class _ReferenceEditPageState extends State<ReferenceEditPage>{

  ScanResult? getScan(String area){
    for(final s in widget.reference.scans)
      if(s.area==area)return s;
    return null;
  }

  Future<void> scanArea(String area)async{
    final r=await Navigator.push<ScanResult>(
      context,
      MaterialPageRoute(
        builder:(_)=>ScanPage(
          cameras:widget.cameras,
          area:area,
          group:widget.group,
          model:widget.model,
          type:widget.type,
          print:widget.print,
          reference:widget.reference,
        ),
      ),
    );

    if(r==null)return;

    final old=getScan(area);

    if(old==null)
      widget.reference.scans.add(r);
    else
      old.details=r.details;

    widget.reference.updatedAt=now();

    await Storage.saveGroup(widget.group);

    await Storage.learnScan(
      group:widget.group,
      model:widget.model,
      type:widget.type,
      print:widget.print,
      reference:widget.reference,
      scan:r,
    );

    if(mounted)setState((){});
  }

  @override
  Widget build(BuildContext c){
    final areas=scanAreasForType(widget.type.name);

    return Scaffold(
      appBar:AppBar(
        title:Text(
          'แก้ไของค์อ้างอิง #${widget.reference.referenceNumber}'),
      ),
      body:Column(
        children:[
          PathBar([
            widget.group.name,
            widget.model.name,
            widget.type.name,
            widget.print.name,
            'องค์อ้างอิง #${widget.reference.referenceNumber}',
            'แก้ไข',
          ]),
          Expanded(
            child:ListView(
              padding:const EdgeInsets.all(10),
              children:[
                Card(
                  child:Padding(
                    padding:const EdgeInsets.all(14),
                    child:Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children:[
                        Text(
                          'องค์อ้างอิง #${widget.reference.referenceNumber}',
                          style:const TextStyle(
                            fontSize:18,
                            fontWeight:FontWeight.bold),
                        ),
                        const SizedBox(height:5),
                        const Text(
                          'แก้ไขและสแกนข้อมูลขององค์เดิมได้ทุกด้าน'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height:8),

                ...areas.map((a){
                  final s=getScan(a);

                  return Card(
                    child:ListTile(
                      title:Text(
                        a,
                        style:const TextStyle(
                          fontWeight:FontWeight.bold),
                      ),
                      subtitle:Text(
                        s==null||s.details.trim().isEmpty
                            ?'ยังไม่มีข้อมูล':s.details,
                        maxLines:3,
                        overflow:TextOverflow.ellipsis,
                      ),
                      trailing:ElevatedButton(
                        onPressed:()=>scanArea(a),
                        child:Text(s==null?'สแกน':'แก้ไข'),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= SCAN PAGE ================= */

class ScanPage extends StatelessWidget{
  final List<CameraDescription> cameras;
  final String area;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;

  const ScanPage({
    required this.cameras,
    required this.area,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
    super.key,
  });

  Future<void> gallery(BuildContext c)async{
    final f=await ImagePicker().pickImage(
      source:ImageSource.gallery,
    );

    if(f==null)return;

    File? temp;

    try{
      final dir=Directory.systemTemp;

      temp=File(
        '${dir.path}/amulet_scan_${newId()}.jpg',
      );

      await File(f.path).copy(temp.path);

      final r=await Navigator.push<ScanResult>(
        c,
        MaterialPageRoute(
          builder:(_)=>AiVisionPage(
            imageFile:XFile(temp!.path),
            area:area,
            group:group,
            model:model,
            type:type,
            print:print,
            reference:reference,
          ),
        ),
      );

      if(r!=null&&c.mounted)
        Navigator.pop(c,r);
    }finally{
      try{
        if(temp!=null&&await temp.exists())
          await temp.delete();
      }catch(_){}
    }
  }

  Future<void> camera(BuildContext c)async{
    if(cameras.isEmpty)return;

    final f=await Navigator.push<XFile>(
      c,
      MaterialPageRoute(
        builder:(_)=>CameraScanPage(
          cameras:cameras,
          area:area,
        ),
      ),
    );

    if(f==null)return;

    try{
      final r=await Navigator.push<ScanResult>(
        c,
        MaterialPageRoute(
          builder:(_)=>AiVisionPage(
            imageFile:f,
            area:area,
            group:group,
            model:model,
            type:type,
            print:print,
            reference:reference,
          ),
        ),
      );

      if(r!=null&&c.mounted)
        Navigator.pop(c,r);
    }finally{
      try{
        final x=File(f.path);
        if(await x.exists())await x.delete();
      }catch(_){}
    }
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:Text('สแกน$area')),
    body:Padding(
      padding:const EdgeInsets.all(16),
      child:Column(
        children:[
          PathBar([
            group.name,
            model.name,
            type.name,
            print.name,
            'องค์อ้างอิง #${reference.referenceNumber}',
            area,
          ]),
          const SizedBox(height:20),

          SizedBox(
            width:double.infinity,
            child:ElevatedButton.icon(
              onPressed:()=>camera(c),
              icon:const Icon(Icons.camera_alt),
              label:const Text('เปิดกล้อง'),
            ),
          ),

          const SizedBox(height:10),

          SizedBox(
            width:double.infinity,
            child:OutlinedButton.icon(
              onPressed:()=>gallery(c),
              icon:const Icon(Icons.photo),
              label:const Text('เลือกภาพจากเครื่อง'),
            ),
          ),

          const SizedBox(height:20),

          const Text(
            'ภาพใช้ชั่วคราวสำหรับการวิเคราะห์เท่านั้น\n'
            'ไม่บันทึกรูปภาพลงฐานข้อมูล',
            textAlign:TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

/* ================= CAMERA ================= */

class CameraScanPage extends StatefulWidget{
  final List<CameraDescription> cameras;
  final String area;

  const CameraScanPage({
    required this.cameras,
    required this.area,
    super.key,
  });

  @override
  State<CameraScanPage> createState()=>_CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage>{
  CameraController? controller;
  bool busy=false;

  @override
  void initState(){
    super.initState();

    controller=CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio:false,
    );

    controller!.initialize().then((_){
      if(mounted)setState((){});
    });
  }

  @override
  void dispose(){
    controller?.dispose();
    super.dispose();
  }

  Future<void> capture()async{
    final x=controller;

    if(x==null||!x.value.isInitialized||busy)return;

    setState(()=>busy=true);

    try{
      final f=await x.takePicture();

      if(mounted)Navigator.pop(context,f);
    }catch(_){
      if(mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:Text('ไม่สามารถถ่ายภาพได้'),
          ),
        );
    }

    if(mounted)setState(()=>busy=false);
  }

  @override
  Widget build(BuildContext c){
    final x=controller;

    return Scaffold(
      appBar:AppBar(
        title:Text('ถ่ายภาพ${widget.area}'),
      ),
      body:x==null||!x.value.isInitialized
          ?const Center(
              child:CircularProgressIndicator())
          :Column(
              children:[
                Expanded(
                  child:CameraPreview(x),
                ),
                Padding(
                  padding:const EdgeInsets.all(20),
                  child:FloatingActionButton(
                    onPressed:busy?null:capture,
                    child:const Icon(Icons.camera),
                  ),
                ),
              ],
            ),
    );
  }
}

/* ================= AI VISION ================= */

class AiVisionPage extends StatefulWidget{
  final XFile imageFile;
  final String area;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;

  const AiVisionPage({
    required this.imageFile,
    required this.area,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
    super.key,
  });

  @override
  State<AiVisionPage> createState()=>_AiVisionPageState();
}

class _AiVisionPageState extends State<AiVisionPage>{
  final Map<String,TextEditingController> c={};

  @override
  void initState(){
    super.initState();

    String old='';

    for(final s in widget.reference.scans)
      if(s.area==widget.area)
        old=s.details;

    for(final h in aiHeads)
      c[h]=TextEditingController();

    if(old.isNotEmpty){
      for(final line in old.split('\n')){
        for(final h in aiHeads){
          if(line.startsWith('$h:'))
            c[h]!.text=line.substring(h.length+1).trim();
        }
      }
    }
  }

  @override
  void dispose(){
    for(final x in c.values)
      x.dispose();

    super.dispose();
  }

  String makeDetails()=>aiHeads
      .map((h){
        final v=c[h]!.text.trim();
        return v.isEmpty?'':'$h: $v';
      })
      .where((e)=>e.isNotEmpty)
      .join('\n');

  void save()=>Navigator.pop(
    context,
    ScanResult(
      area:widget.area,
      details:makeDetails(),
    ),
  );

  @override
  Widget build(BuildContext cxt)=>Scaffold(
    appBar:AppBar(
      title:Text('รายละเอียด${widget.area}'),
    ),
    body:Column(
      children:[
        Expanded(
          child:ListView(
            padding:const EdgeInsets.all(10),
            children:[
              SizedBox(
                height:240,
                child:Image.file(
                  File(widget.imageFile.path),
                  fit:BoxFit.contain,
                ),
              ),

              const SizedBox(height:10),

              const Text(
                'รายละเอียดการสแกน',
                style:TextStyle(
                  fontSize:18,
                  fontWeight:FontWeight.bold,
                ),
              ),

              const SizedBox(height:10),

              ...aiHeads.map((h)=>Padding(
                padding:const EdgeInsets.only(bottom:10),
                child:TextField(
                  controller:c[h],
                  maxLines:3,
                  decoration:InputDecoration(
                    labelText:h,
                    border:const OutlineInputBorder(),
                  ),
                ),
              )),
            ],
          ),
        ),

        SafeArea(
          child:Padding(
            padding:const EdgeInsets.all(10),
            child:SizedBox(
              width:double.infinity,
              child:ElevatedButton.icon(
                onPressed:save,
                icon:const Icon(Icons.save),
                label:const Text('บันทึกข้อมูล'),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
