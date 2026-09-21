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
  'พระปิดตาเนื้อผง/หว้าน','พระปิดตาเนื้อโลหะ','พระเนื้อผง',
  'พระเนื้อดิน','นางพญา','ผงสุพรรณ','พระรอด','พระซุ้มกอ',
  'พระขุนแผน','หลวงปู่ทวดเนื้อหว้าน','หลวงปู่ทวดหลังเตารีด',
  'เขี้ยวแกะ','งาแกะ','ตะกรุด','อื่น ๆ'
];

class ScanResult {
  final String area,details;
  ScanResult({required this.area,this.details=''});

  Map<String,dynamic> toMap()=>{'area':area,'details':details};

  factory ScanResult.fromMap(Map<String,dynamic> m)=>ScanResult(
    area:m['area']??'',details:m['details']??'');
}

class ReferenceData {
  final String id,createdAt,updatedAt;
  final int referenceNumber;
  final List<ScanResult> scans;

  ReferenceData({
    required this.id,required this.referenceNumber,
    required this.createdAt,required this.updatedAt,this.scans=const[]});

  ReferenceData copyWith({
    int? referenceNumber,String? updatedAt,List<ScanResult>? scans})=>
    ReferenceData(
      id:id,
      referenceNumber:referenceNumber??this.referenceNumber,
      createdAt:createdAt,
      updatedAt:updatedAt??this.updatedAt,
      scans:scans??this.scans);

  Map<String,dynamic> toMap()=>{
    'id':id,'referenceNumber':referenceNumber,
    'createdAt':createdAt,'updatedAt':updatedAt,
    'scans':scans.map((e)=>e.toMap()).toList()};

  factory ReferenceData.fromMap(Map<String,dynamic> m)=>ReferenceData(
    id:m['id']??Storage.id(),
    referenceNumber:m['referenceNumber']??1,
    createdAt:m['createdAt']??Storage.now(),
    updatedAt:m['updatedAt']??Storage.now(),
    scans:(m['scans'] as List???[]).map((e)=>
      ScanResult.fromMap(Map<String,dynamic>.from(e))).toList());
}

class PrintData {
  final String id,name,createdAt,updatedAt;
  final List<ReferenceData> references;

  PrintData({
    required this.id,required this.name,required this.createdAt,
    required this.updatedAt,this.references=const[]});

  Map<String,dynamic> toMap()=>{
    'id':id,'name':name,'createdAt':createdAt,'updatedAt':updatedAt,
    'references':references.map((e)=>e.toMap()).toList()};

  factory PrintData.fromMap(Map<String,dynamic> m)=>PrintData(
    id:m['id']??Storage.id(),name:m['name']??'',
    createdAt:m['createdAt']??Storage.now(),
    updatedAt:m['updatedAt']??Storage.now(),
    references:(m['references'] as List???[]).map((e)=>
      ReferenceData.fromMap(Map<String,dynamic>.from(e))).toList());
}

class TypeData {
  final String id,name,createdAt,updatedAt;
  final List<PrintData> prints;

  TypeData({
    required this.id,required this.name,required this.createdAt,
    required this.updatedAt,this.prints=const[]});

  Map<String,dynamic> toMap()=>{
    'id':id,'name':name,'createdAt':createdAt,'updatedAt':updatedAt,
    'prints':prints.map((e)=>e.toMap()).toList()};

  factory TypeData.fromMap(Map<String,dynamic> m)=>TypeData(
    id:m['id']??Storage.id(),name:m['name']??'',
    createdAt:m['createdAt']??Storage.now(),
    updatedAt:m['updatedAt']??Storage.now(),
    prints:(m['prints'] as List???[]).map((e)=>
      PrintData.fromMap(Map<String,dynamic>.from(e))).toList());
}

class ModelData {
  final String id,name,createdAt,updatedAt;
  final List<TypeData> types;

  ModelData({
    required this.id,required this.name,required this.createdAt,
    required this.updatedAt,this.types=const[]});

  Map<String,dynamic> toMap()=>{
    'id':id,'name':name,'createdAt':createdAt,'updatedAt':updatedAt,
    'types':types.map((e)=>e.toMap()).toList()};

  factory ModelData.fromMap(Map<String,dynamic> m)=>ModelData(
    id:m['id']??Storage.id(),name:m['name']??'',
    createdAt:m['createdAt']??Storage.now(),
    updatedAt:m['updatedAt']??Storage.now(),
    types:(m['types'] as List???[]).map((e)=>
      TypeData.fromMap(Map<String,dynamic>.from(e))).toList());
}

class GroupData {
  final String id,name,temple,createdAt,updatedAt;
  final List<ModelData> models;

  GroupData({
    required this.id,required this.name,required this.temple,
    required this.createdAt,required this.updatedAt,this.models=const[]});

  Map<String,dynamic> toMap()=>{
    'id':id,'name':name,'temple':temple,
    'createdAt':createdAt,'updatedAt':updatedAt,
    'models':models.map((e)=>e.toMap()).toList()};

  factory GroupData.fromMap(Map<String,dynamic> m)=>GroupData(
    id:m['id']??Storage.id(),name:m['name']??'',temple:m['temple']??'',
    createdAt:m['createdAt']??Storage.now(),
    updatedAt:m['updatedAt']??Storage.now(),
    models:(m['models'] as List???[]).map((e
