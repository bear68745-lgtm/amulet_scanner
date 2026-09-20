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
  double brightness=0,sharpness=0;
  String quality='ยังไม่ได้ตรวจ';

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

  void checkQuality(CameraImage image){
    if(image.planes.isEmpty)return;

    final bytes=image.planes.first.bytes;
    if(bytes.isEmpty)return;

    int step=bytes.length~/1000;
    if(step<1)step=1;

    double total=0;
    int count=0;

    for(int i=0;i<bytes.length;i+=step){
      total+=bytes[i];
      count++;
    }

    final b=total/count;
    final w=image.width;
    final h=image.height;
    final row=image.planes.first.bytesPerRow;
    final sx=w~/40<1?1:w~/40;
    final sy=h~/30<1?1:h~/30;

    double edge=0;
    int ec=0;

    for(int y=sy;y<h;y+=sy){
      for(int x=sx;x<w;x+=sx){
        final p=y*row+x;
        final l=y*row+x-sx;
        final u=(y-sy)*row+x;

        if(p<bytes.length&&l>=0&&u>=0){
          edge+=(bytes[p]-bytes[l]).abs();
          edge+=(bytes[p]-bytes[u]).abs();
          ec+=2;
        }
      }
    }

    final s=ec==0?0:edge/ec;

    brightness=b;
    sharpness=s;

    String q;

    if(w<640||h<480){
      q='ความละเอียดต่ำ';
    }else if(b<45){
      q='ภาพมืดเกินไป';
    }else if(b>235){
      q='ภาพสว่างเกินไป';
    }else if(s<5){
      q='ภาพเบลอหรือไม่คม';
    }else if(s<10){
      q='ภาพค่อนข้างไม่คม';
    }else{
      q='คุณภาพภาพเบื้องต้นใช้ได้';
    }

    if(mounted)setState(()=>quality=q);
  }

  Future<void> startScan()async{
    if(controller==null||
       !controller!.value.isInitialized||
       controller!.value.isStreamingImages)return;

    setState((){
      scanning=true;
      frameCount=0;
      brightness=0;
      sharpness=0;
      quality='กำลังตรวจ...';
    });

    await controller!.startImageStream((CameraImage image){
      if(!scanning)return;
      frameCount++;

      if(frameCount%10==0){
        checkQuality(image);
      }
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
              fit:StackFit.expand,
              children:[
                CameraPreview(controller!),

                Center(
                  child:Container(
                    width:260,
                    height:360,
                    decoration:BoxDecoration(
                      border:Border.all(
                        color:Colors.white,
                        width:3,
                      ),
                      borderRadius:BorderRadius.circular(12),
                    ),
                    child:const Center(
                      child:Text(
                        'จัดพระให้อยู่ในกรอบ',
                        style:TextStyle(
                          color:Colors.white,
                          fontSize:18,
                          fontWeight:FontWeight.bold,
                          shadows:[
                            Shadow(
                              blurRadius:4,
                              offset:Offset(1,1),
                            ),
                          ],
                        ),
                        textAlign:TextAlign.center,
                      ),
                    ),
                  ),
                ),

                if(scanning)
                  Positioned(
                    top:15,
                    left:15,
                    right:15,
                    child:Container(
                      padding:const EdgeInsets.all(10),
                      color:Colors.black54,
                      child:Text(
                        'รับภาพชั่วคราว\n'
                        'เฟรม: $frameCount\n'
                        'ความสว่าง: ${brightness.toStringAsFixed(0)}\n'
                        'ความคม: ${sharpness.toStringAsFixed(1)}\n'
                        '$quality',
                        style:const TextStyle(
                          color:Colors.white,
                          fontSize:16,
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
                  'จัดพระให้อยู่ในกรอบสีขาว\n'
                  'ภาพใช้ชั่วคราวในหน่วยความจำ\n'
                  'ไม่มีการสร้างไฟล์รูปพระ',
                  textAlign:TextAlign.center,
                ),

                const SizedBox(height:10),

                ElevatedButton.icon(
                  icon:Icon(
                    scanning?Icons.stop:Icons.camera,
                  ),
                  label:Text(
                    scanning?'หยุดสแกน':'เริ่มรับภาพ',
                  ),
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
