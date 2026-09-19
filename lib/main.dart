import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

Future<void> main()async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App(await availableCameras()));
}

class App extends StatelessWidget{
  final List<CameraDescription> cameras;
  const App(this.cameras,{super.key});
  @override Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'กล้องสแกนพระและเหรียญ',
    theme:ThemeData(useMaterial3:true),
    home:HomePage(cameras),
  );
}

class HomePage extends StatelessWidget{
  final List<CameraDescription> cameras;
  const HomePage(this.cameras,{super.key});

  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('กล้องสแกนพระและเหรียญ')),
    body:Center(
      child:ElevatedButton.icon(
        icon:const Icon(Icons.camera_alt),
        label:const Text('เริ่มสแกน'),
        onPressed:()=>Navigator.push(
          c,MaterialPageRoute(builder:(_)=>AreaPage(cameras)),
        ),
      ),
    ),
  );
}

class AreaPage extends StatelessWidget{
  final List<CameraDescription> cameras;
  const AreaPage(this.cameras,{super.key});

  @override Widget build(BuildContext c){
    const areas=['ด้านหน้า','ด้านหลัง','ด้านข้าง','ก้นพระ'];
    return Scaffold(
      appBar:AppBar(title:const Text('เลือกด้านที่ต้องการสแกน')),
      body:ListView(
        padding:const EdgeInsets.all(16),
        children:[
          for(final area in areas)
            Padding(
              padding:const EdgeInsets.only(bottom:12),
              child:ElevatedButton.icon(
                icon:const Icon(Icons.camera_alt),
                label:Text('สแกน$area'),
                style:ElevatedButton.styleFrom(
                  padding:const EdgeInsets.all(18),
                ),
                onPressed:()=>Navigator.push(
                  c,
                  MaterialPageRoute(
                    builder:(_)=>ScanPage(cameras,area:area),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScanPage extends StatefulWidget{
  final List<CameraDescription> cameras;
  final String area;
  const ScanPage(this.cameras,{required this.area,super.key});

  @override State<ScanPage> createState()=>_ScanPageState();
}

class _ScanPageState extends State<ScanPage>{
  CameraController? controller;
  bool ready=false,scanning=false;
  int frameCount=0;

  @override void initState(){
    super.initState();
    startCamera();
  }

  Future<void> startCamera()async{
    if(widget.cameras.isEmpty)return;

    final cam=widget.cameras.firstWhere(
      (x)=>x.lensDirection==CameraLensDirection.back,
      orElse:()=>widget.cameras.first,
    );

    controller=CameraController(
      cam,ResolutionPreset.medium,enableAudio:false,
    );

    await controller!.initialize();
    if(mounted)setState(()=>ready=true);
  }

  Future<void> startScan()async{
    if(controller==null||
       !controller!.value.isInitialized||
       controller!.value.isStreamingImages)return;

    setState((){
      scanning=true;
      frameCount=0;
    });

    await controller!.startImageStream((CameraImage image){
      if(!scanning)return;
      frameCount++;
      if(frameCount%10==0&&mounted)setState((){});
    });
  }

  Future<void> stopScan()async{
    if(controller?.value.isStreamingImages??false){
      await controller!.stopImageStream();
    }
    if(mounted)setState(()=>scanning=false);
  }

  @override void dispose(){
    controller?.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext c){
    if(!ready||controller==null){
      return const Scaffold(
        body:Center(child:CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar:AppBar(title:Text('สแกน${widget.area}')),
      body:Column(
        children:[
          Expanded(
            child:Stack(
              children:[
                CameraPreview(controller!),
                if(scanning)
                  Positioned(
                    top:15,left:15,right:15,
                    child:Container(
                      padding:const EdgeInsets.all(10),
                      color:Colors.black54,
                      child:Text(
                        'กำลังรับภาพชั่วคราว\nเฟรม: $frameCount\n'
                        'ยังไม่มีการบันทึกรูป',
                        style:const TextStyle(
                          color:Colors.white,fontSize:16,
                        ),
                        textAlign:TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding:const EdgeInsets.all(12),
            child:Column(
              children:[
                const Text(
                  'ภาพใช้ชั่วคราวในหน่วยความจำ\n'
                  'ไม่มีการสร้างไฟล์รูปพระ',
                  textAlign:TextAlign.center,
                ),
                const SizedBox(height:10),
                ElevatedButton.icon(
                  icon:Icon(scanning?Icons.stop:Icons.camera),
                  label:Text(scanning?'หยุดสแกน':'เริ่มรับภาพ'),
                  onPressed:scanning?stopScan:startScan,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
