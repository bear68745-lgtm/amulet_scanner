
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const dataKey='amulet_data_gz';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.load();
  runApp(const AmuletApp());
}

String newId()=>DateTime.now().microsecondsSinceEpoch.toString();

class AmuletData {
  String id,name,model,pim,type,temple;
  List<Map<String,dynamic>> scans;

  AmuletData({
    required this.id,
    required this.name,
    required this.model,
    required this.pim,
    required this.type,
    required this.temple,
    List<Map<String,dynamic>>? scans,
  }):scans=scans??[];

  Map<String,dynamic> toJson()=> {
    'id':id,'name':name,'model':model,'pim':pim,
    'type':type,'temple':temple,'scans':scans,
  };

  factory AmuletData.fromJson(Map<String,dynamic> j)=>AmuletData(
    id:j['id']??newId(),
    name:j['name']??'',
    model:j['model']??'',
    pim:j['pim']??'',
    type:j['type']??'อื่น ๆ',
    temple:j['temple']??'',
    scans:List<Map<String,dynamic>>.from(
      (j['scans']??[]).map((e)=>Map<String,dynamic>.from(e)),
    ),
  );
}

class Store {
  static List<AmuletData> data=[];

  static Future<void> load() async {
    final p=await SharedPreferences.getInstance();
    final s=p.getString(dataKey);
    if(s==null)return;
    try {
      data=(jsonDecode(s) as List)
          .map((e)=>AmuletData.fromJson(Map<String,dynamic>.from(e)))
          .toList();
    } catch(_) {}
  }

  static Future<void> save() async {
    final p=await SharedPreferences.getInstance();
    await p.setString(
      dataKey,
      jsonEncode(data.map((e)=>e.toJson()).toList()),
    );
  }
}

class AmuletApp extends StatelessWidget {
  const AmuletApp({super.key});

  @override
  Widget build(BuildContext context)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'กล้องสแกนพระและเหรียญ',
    theme:ThemeData(
      useMaterial3:true,
      colorSchemeSeed:Colors.brown,
    ),
    home:const HomePage(),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('กล้องสแกนพระและเหรียญ')),
    body:Center(
      child:Column(
        mainAxisAlignment:MainAxisAlignment.center,
        children:[
          const Icon(Icons.camera_alt,size:80),
          const SizedBox(height:20),
          const Text(
            'ระบบสแกนพระ',
            style:TextStyle(fontSize:24,fontWeight:FontWeight.bold),
          ),
          const SizedBox(height:30),
          FilledButton(
            onPressed:()=>Navigator.push(
              context,
              MaterialPageRoute(builder:(_)=>const CreatePage()),
            ),
            child:const Text('สร้าง / บันทึกข้อมูล'),
          ),
          const SizedBox(height:12),
          OutlinedButton(
            onPressed:()=>Navigator.push(
              context,
              MaterialPageRoute(builder:(_)=>const SavedPage()),
            ),
            child:const Text('รายการข้อมูลที่บันทึก'),
          ),
        ],
      ),
    ),
  );
}

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState()=>_CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final name=TextEditingController();
  final model=TextEditingController();
  final pim=TextEditingController();
  final temple=TextEditingController();

  @override
  void dispose(){
    name.dispose();
    model.dispose();
    pim.dispose();
    temple.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if(name.text.trim().isEmpty)return;

    Store.data.add(
      AmuletData(
        id:newId(),
        name:name.text.trim(),
        model:model.text.trim(),
        pim:pim.text.trim(),
        type:'อื่น ๆ',
        temple:temple.text.trim(),
      ),
    );

    await Store.save();

    if(mounted)Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('สร้าง / บันทึกข้อมูล')),
    body:ListView(
      padding:const EdgeInsets.all(16),
      children:[
        TextField(
          controller:name,
          decoration:const InputDecoration(
            labelText:'ชื่อพระ',
            border:OutlineInputBorder(),
          ),
        ),
        const SizedBox(height:12),
        TextField(
          controller:model,
          decoration:const InputDecoration(
            labelText:'รุ่น',
            border:OutlineInputBorder(),
          ),
        ),
        const SizedBox(height:12),
        TextField(
          controller:pim,
          decoration:const InputDecoration(
            labelText:'พิมพ์',
            border:OutlineInputBorder(),
          ),
        ),
        const SizedBox(height:12),
        TextField(
          controller:temple,
          decoration:const InputDecoration(
            labelText:'วัด',
            border:OutlineInputBorder(),
          ),
        ),
        const SizedBox(height:20),
        FilledButton(
          onPressed:save,
          child:const Text('บันทึกข้อมูล'),
        ),
      ],
    ),
  );
}

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('รายการข้อมูลที่บันทึก')),
    body:Store.data.isEmpty
        ?const Center(child:Text('ยังไม่มีข้อมูล'))
        :ListView.builder(
            itemCount:Store.data.length,
            itemBuilder:(context,i){
              final e=Store.data[i];
              return ListTile(
                leading:const Icon(Icons.folder),
                title:Text(e.name),
                subtitle:Text(
                  '${e.model}\nวัด: ${e.temple}',
                ),
              );
            },
          ),
  );
}
