import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(App(cameras));
}

class App extends StatelessWidget {
  final List<CameraDescription> cameras;
  const App(this.cameras,{super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:false,
      title:'กล้องสแกนพระและเหรียญ',
      theme:ThemeData(useMaterial3:true),
      home:HomePage(cameras),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;
  const HomePage(this.cameras,{super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(title:const Text('กล้องสแกนพระและเหรียญ')),
      body:Center(
        child:ElevatedButton.icon(
          icon:const Icon(Icons.camera_alt),
          label:const Text('เริ่มสแกน'),
          onPressed:(){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:(_)=>ScanPage(cameras),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ScanPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const ScanPage(this.cameras,{super.key});

  @override
  State<ScanPage> createState()=>_ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? controller;
  bool ready=false;

  @override
  void initState(){
    super.initState();
    startCamera();
  }

  Future<void> startCamera() async {
    if(widget.cameras.isEmpty)return;

    final camera=widget.cameras.firstWhere(
      (c)=>c.lensDirection==CameraLensDirection.back,
      orElse:()=>widget.cameras.first,
    );

    controller=CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio:false,
    );

    await controller!.initialize();

    if(mounted)setState(()=>ready=true);
  }

  @override
  void dispose(){
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    if(!ready){
      return const Scaffold(
        body:Center(
          child:CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar:AppBar(
        title:const Text('สแกนพระ'),
      ),
      body:Column(
        children:[
          Expanded(
            child:CameraPreview(controller!),
          ),
          const Padding(
            padding:EdgeInsets.all(12),
            child:Text(
              'วางภาพพระไว้ด้านหน้ากล้อง\n'
              'ระบบจะใช้ภาพชั่วคราวในการวิเคราะห์\n'
              'และจะไม่บันทึกรูปพระ',
              textAlign:TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
