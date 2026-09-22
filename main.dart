import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App(await availableCameras()));
}

const areas=['ด้านหน้า','ด้านหลัง','ด้านข้าง','ก้นพระ'];
const typeOptions=[
  'เหรียญ','เหรียญหล่อ','พระสมเด็จ','รูปหล่อ','พระกริ่ง',
  'พระปิดตาเนื้อผง/หว้าน','พระปิดตาเนื้อโลหะ','พระเนื้อผง','พระเนื้อดิน',
  'นางพญา','ผงสุพรรณ','พระรอด','พระซุ้มกอ','พระขุนแผน',
  'หลวงปู่ทวดเนื้อหว้าน','หลวงปู่ทวดหลังเตารีด','เขี้ยวแกะ','งาแกะ',
  'ตะกรุด','อื่น ๆ'
];
const aiHeads=[
  'พิมพ์ทรง','องค์ประกอบ','ลวดลาย','ตำหนิที่มองเห็น','ผิว',
  'ลักษณะเนื้อที่มองเห็น','ขอบ/ด้านข้าง','จุดสังเกต',
  'รายละเอียดอื่น','สิ่งที่อ่านไม่ได้'
];

String newId()=>DateTime.now().microsecondsSinceEpoch.toString();

/* ================= DATA ================= */

class ScanResult{
  String area,details;
  ScanResult({required this.area,this.details=''});

  Map<String,dynamic> toMap()=>{'area':area,'details':details};

  factory ScanResult.fromMap(Map<String,dynamic> m)=>ScanResult(
    area:m['area']??'',details:m['details']??'');
}

class ReferenceData{
  String id;
  int referenceNumber;
  DateTime createdAt,updatedAt;
  List<ScanResult> scans;

  ReferenceData({
    required this.id,required this.referenceNumber,
    required this.createdAt,DateTime? updatedAt,List<ScanResult>? scans})
    :updatedAt=updatedAt??createdAt,scans=scans??[];

  Map<String,dynamic> toMap()=>{
    'id':id,'referenceNumber':referenceNumber,
    'createdAt':createdAt.toIso8601String(),
    'updatedAt':updatedAt.toIso8601String(),
    'scans':scans.map((e)=>e.toMap()).toList()
  };

  factory ReferenceData.fromMap(Map<String,dynamic> m)=>ReferenceData(
    id:m['id']??newId(),
    referenceNumber:m['referenceNumber']??1,
    createdAt:DateTime.tryParse(m['createdAt']??'')??DateTime.now(),
    updatedAt:DateTime.tryParse(m['updatedAt']??'')??DateTime.now(),
    scans:(m['scans'] as List???[])
      .map((e)=>ScanResult.fromMap(Map<String,dynamic>.from(e))).toList());

  ReferenceData copyWith({int? referenceNumber,List<ScanResult>? scans})=>
    ReferenceData(
      id:id,referenceNumber:referenceNumber??this.referenceNumber,
      createdAt:createdAt,updatedAt:DateTime.now(),
      scans:scans??this.scans);
}

/* ================= AI DATA ================= */

class AiKnowledge{
  String id,groupId,modelId,typeId,printId,referenceId,area,content;
  DateTime createdAt,updatedAt;

  AiKnowledge({
    required this.id,required this.groupId,required this.modelId,
    required this.typeId,required this.printId,required this.referenceId,
    required this.area,required this.content,required this.createdAt,
    DateTime? updatedAt}):updatedAt=updatedAt??createdAt;

  Map<String,dynamic> toMap()=>{
    'id':id,'groupId':groupId,'modelId':modelId,'typeId':typeId,
    'printId':printId,'referenceId':referenceId,'area':area,
    'content':content,'createdAt':createdAt.toIso8601String(),
    'updatedAt':updatedAt.toIso8601String()
  };

  factory AiKnowledge.fromMap(Map<String,dynamic> m)=>AiKnowledge(
    id:m['id']??newId(),groupId:m['groupId']??'',
    modelId:m['modelId']??'',typeId:m['typeId']??'',
    printId:m['printId']??'',referenceId:m['referenceId']??'',
    area:m['area']??'',content:m['content']??'',
    createdAt:DateTime.tryParse(m['createdAt']??'')??DateTime.now(),
    updatedAt:DateTime.tryParse(m['updatedAt']??'')??DateTime.now());
}

class AiLearningHistory{
  String id,groupId,modelId,typeId,printId,referenceId,area,content;
  DateTime learnedAt;

  AiLearningHistory({
    required this.id,required this.groupId,required this.modelId,
    required this.typeId,required this.printId,required this.referenceId,
    required this.area,required this.content,required this.learnedAt});

  Map<String,dynamic> toMap()=>{
    'id':id,'groupId':groupId,'modelId':modelId,'typeId':typeId,
    'printId':printId,'referenceId':referenceId,'area':area,
    'content':content,'learnedAt':learnedAt.toIso8601String()
  };

  factory AiLearningHistory.fromMap(Map<String,dynamic> m)=>
    AiLearningHistory(
      id:m['id']??newId(),groupId:m['groupId']??'',
      modelId:m['modelId']??'',typeId:m['typeId']??'',
      printId:m['printId']??'',referenceId:m['referenceId']??'',
      area:m['area']??'',content:m['content']??'',
      learnedAt:DateTime.tryParse(m['learnedAt']??'')??DateTime.now());
}

class AiMemoryTest{
  String id,knowledgeId,referenceId,area,question,answer;
  DateTime testedAt;

  AiMemoryTest({
    required this.id,required this.knowledgeId,required this.referenceId,
    required this.area,required this.question,required this.answer,
    required this.testedAt});

  Map<String,dynamic> toMap()=> {
    'id':id,'knowledgeId':knowledgeId,'referenceId':referenceId,
    'area':area,'question':question,'answer':answer,
    'testedAt':testedAt.toIso8601String()
  };

  factory AiMemoryTest.fromMap(Map<String,dynamic> m)=>AiMemoryTest(
    id:m['id']??newId(),knowledgeId:m['knowledgeId']??'',
    referenceId:m['referenceId']??'',area:m['area']??'',
    question:m['question']??'',answer:m['answer']??'',
    testedAt:DateTime.tryParse(m['testedAt']??'')??DateTime.now());
}

class AiTestResult{
  String id,testId,knowledgeId,referenceId,area,mode,result,
      answer,referenceAnswer,reason;
  DateTime checkedAt;

  AiTestResult({
    required this.id,required this.testId,required this.knowledgeId,
    required this.referenceId,required this.area,required this.mode,
    required this.result,required this.answer,required this.referenceAnswer,
    required this.reason,required this.checkedAt});

  Map<String,dynamic> toMap()=> {
    'id':id,'testId':testId,'knowledgeId':knowledgeId,
    'referenceId':referenceId,'area':area,'mode':mode,
    'result':result,'answer':answer,'referenceAnswer':referenceAnswer,
    'reason':reason,'checkedAt':checkedAt.toIso8601String()
  };

  factory AiTestResult.fromMap(Map<String,dynamic> m)=>AiTestResult(
    id:m['id']??newId(),testId:m['testId']??'',
    knowledgeId:m['knowledgeId']??'',referenceId:m['referenceId']??'',
    area:m['area']??'',mode:m['mode']??'',result:m['result']??'',
    answer:m['answer']??'',referenceAnswer:m['referenceAnswer']??'',
    reason:m['reason']??'',
    checkedAt:DateTime.tryParse(m['checkedAt']??'')??DateTime.now());
}

/* ================= MAIN DATA ================= */

class PrintData{
  String id,name;
  DateTime createdAt,updatedAt;
  List<ReferenceData> references;

  PrintData({
    required this.id,required this.name,required this.createdAt,
    DateTime? updatedAt,List<ReferenceData>? references})
    :updatedAt=updatedAt??createdAt,references=references??[];

  Map<String,dynamic> toMap()=> {
    'id':id,'name':name,'createdAt':createdAt.toIso8601String(),
    'updatedAt':updatedAt.toIso8601String(),
    'references':references.map((e)=>e.toMap()).toList()
  };

  factory PrintData.fromMap(Map<String,dynamic> m)=>PrintData(
    id:m['id']??newId(),name:m['name']??'พิมพ์เดียว',
    createdAt:DateTime.tryParse(m['createdAt']??'')??DateTime.now(),
    updatedAt:DateTime.tryParse(m['updatedAt']??'')??DateTime.now(),
    references:(m['references'] as List???[])
      .map((e)=>ReferenceData.fromMap(Map<String,dynamic>.from(e))).toList());
}

class TypeData{
  String id,name;
  DateTime createdAt,updatedAt;
  List<PrintData> prints;

  TypeData({
    required this.id,required this.name,required this.createdAt,
    DateTime? updatedAt,List<PrintData>? prints})
    :updatedAt=updatedAt??createdAt,prints=prints??[];

  Map<String,dynamic> toMap()=> {
    'id':id,'name':name,'createdAt':createdAt.toIso8601String(),
    'updatedAt':updatedAt.toIso8601String(),
    'prints':prints.map((e)=>e.toMap()).toList()
  };

  factory TypeData.fromMap(Map<String,dynamic> m)=>TypeData(
    id:m['id']??newId(),name:m['name']??'',
    createdAt:DateTime.tryParse(m['createdAt']??'')??DateTime.now(),
    updatedAt:DateTime.tryParse(m['updatedAt']??'')??DateTime.now(),
    prints:(m['prints'] as List???[])
      .map((e)=>PrintData.fromMap(Map<String,dynamic>.from(e))).toList());
}

class ModelData{
  String id,name;
  DateTime createdAt,updatedAt;
  List<TypeData> types;

  ModelData({
    required this.id,required this.name,required this.createdAt,
    DateTime? updatedAt,List<TypeData>? types})
    :updatedAt=updatedAt??createdAt,types=types??[];

  Map<String,dynamic> toMap()=> {
    'id':id,'name':name,'createdAt':createdAt.toIso8601String(),
    'updatedAt':updatedAt.toIso8601String(),
    'types':types.map((e)=>e.toMap()).toList()
  };

  factory ModelData.fromMap(Map<String,dynamic> m)=>ModelData(
    id:m['id']??newId(),name:m['name']??'',
    createdAt:DateTime.tryParse(m['createdAt']??'')??DateTime.now(),
    updatedAt:DateTime.tryParse(m['updatedAt']??'')??DateTime.now(),
    types:(m['types'] as List???[])
      .map((e)=>TypeData.fromMap(Map<String,dynamic>.from(e))).toList());
}

class GroupData{
  String id,name,temple;
  DateTime createdAt,updatedAt;
  List<ModelData> models;

  GroupData({
    required this.id,required this.name,required this.temple,
    required this.createdAt,DateTime? updatedAt,List<ModelData>? models})
    :updatedAt=updatedAt??createdAt,models=models??[];

  Map<String,dynamic> toMap()=> {
    'id':id,'name':name,'temple':temple,
    'createdAt':createdAt.toIso8601String(),
    'updatedAt':updatedAt.toIso8601String(),
    'models':models.map((e)=>e.toMap()).toList()
  };

  factory GroupData.fromMap(Map<String,dynamic> m)=>GroupData(
    id:m['id']??newId(),name:m['name']??'',temple:m['temple']??'',
    createdAt:DateTime.tryParse(m['createdAt']??'')??DateTime.now(),
    updatedAt:DateTime.tryParse(m['updatedAt']??'')??DateTime.now(),
    models:(m['models'] as List???[])
      .map((e)=>ModelData.fromMap(Map<String,dynamic>.from(e))).toList());
}

/* ================= STORAGE ================= */

class Storage{
  static const key='reference_groups',
      aiKey='ai_knowledge',
      historyKey='ai_learning_history',
      testKey='ai_memory_tests',
      resultKey='ai_test_results';

  static Future<List<GroupData>> load()async{
    final p=await SharedPreferences.getInstance(),r=p.getString(key);
    if(r==null||r.isEmpty)return[];
    try{return(jsonDecode(r)as List)
      .map((e)=>GroupData.fromMap(Map<String,dynamic>.from(e))).toList();}
    catch(_){return[];}
  }

  static Future<void> save(List<GroupData> g)async{
    final p=await SharedPreferences.getInstance();
    await p.setString(key,jsonEncode(g.map((e)=>e.toMap()).toList()));
  }

  static Future<List<AiKnowledge>> loadAi()async{
    final p=await SharedPreferences.getInstance(),r=p.getString(aiKey);
    if(r==null||r.isEmpty)return[];
    try{return(jsonDecode(r)as List)
      .map((e)=>AiKnowledge.fromMap(Map<String,dynamic>.from(e))).toList();}
    catch(_){return[];}
  }

  static Future<void> saveAi(List<AiKnowledge> x)async{
    final p=await SharedPreferences.getInstance();
    await p.setString(aiKey,jsonEncode(x.map((e)=>e.toMap()).toList()));
  }

  static Future<List<AiLearningHistory>> loadHistory()async{
    final p=await SharedPreferences.getInstance(),r=p.getString(historyKey);
    if(r==null||r.isEmpty)return[];
    try{return(jsonDecode(r)as List)
      .map((e)=>AiLearningHistory.fromMap(Map<String,dynamic>.from(e))).toList();}
    catch(_){return[];}
  }

  static Future<void> saveHistory(List<AiLearningHistory> x)async{
    final p=await SharedPreferences.getInstance();
    await p.setString(historyKey,jsonEncode(x.map((e)=>e.toMap()).toList()));
  }

  static Future<List<AiMemoryTest>> loadTests()async{
    final p=await SharedPreferences.getInstance(),r=p.getString(testKey);
    if(r==null||r.isEmpty)return[];
    try{return(jsonDecode(r)as List)
      .map((e)=>AiMemoryTest.fromMap(Map<String,dynamic>.from(e))).toList();}
    catch(_){return[];}
  }

  static Future<void> saveTests(List<AiMemoryTest> x)async{
    final p=await SharedPreferences.getInstance();
    await p.setString(testKey,jsonEncode(x.map((e)=>e.toMap()).toList()));
  }

  static Future<void> addTest(AiMemoryTest x)async{
    final a=await loadTests();a.add(x);await saveTests(a);
  }

  static Future<List<AiTestResult>> loadResults()async{
    final p=await SharedPreferences.getInstance(),r=p.getString(resultKey);
    if(r==null||r.isEmpty)return[];
    try{return(jsonDecode(r)as List)
      .map((e)=>AiTestResult.fromMap(Map<String,dynamic>.from(e))).toList();}
    catch(_){return[];}
  }

  static Future<void> saveResults(List<AiTestResult> x)async{
    final p=await SharedPreferences.getInstance();
    await p.setString(resultKey,jsonEncode(x.map((e)=>e.toMap()).toList()));
  }

  static Future<void> addResult(AiTestResult x)async{
    final a=await loadResults();a.add(x);await saveResults(a);
  }

  static Future<void> addAi({
    required GroupData group,required ModelData model,required TypeData type,
    required PrintData print,required ReferenceData reference,
    required ScanResult scan})async{
    final text=scan.details.trim();
    if(text.isEmpty)return;

    final now=DateTime.now(),list=await loadAi();
    final i=list.indexWhere(
      (e)=>e.referenceId==
