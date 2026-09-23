import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../scan_data.dart';

T? firstWhereOrNull<T>(
  Iterable<T> list,
  bool Function(T) test,
) {
  for (final e in list) {
    if (test(e)) return e;
  }

  return null;
}

// =====================================================
// SCAN PAGE
// =====================================================

class ScanPage extends StatelessWidget {
  final List<CameraDescription> cameras;
  final String area;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;

  const ScanPage({
    super.key,
    required this.cameras,
    required this.area,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
  });

  Future<void> gallery(
    BuildContext context,
  ) async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (f == null) return;

    File? temp;

    try {
      temp = File(
        '${Directory.systemTemp.path}/'
        'amulet_scan_${newId()}.jpg',
      );

      await File(f.path).copy(
        temp.path,
      );

      final r = await Navigator.push<ScanResult>(
        context,
        MaterialPageRoute(
          builder: (_) => AiVisionPage(
            imageFile: XFile(temp!.path),
            area: area,
            group: group,
            model: model,
            type: type,
            print: print,
            reference: reference,
          ),
        ),
      );

      if (r != null && context.mounted) {
        Navigator.pop(context, r);
      }
    } finally {
      try {
        if (temp != null && await temp.exists()) {
          await temp.delete();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'สแกน $area',
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 70,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: cameras.isEmpty
                  ? null
                  : () async {
                      final r =
                          await Navigator.push<ScanResult>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CameraScanPage(
                            cameras: cameras,
                            area: area,
                            group: group,
                            model: model,
                            type: type,
                            print: print,
                            reference: reference,
                          ),
                        ),
                      );

                      if (r != null &&
                          context.mounted) {
                        Navigator.pop(
                          context,
                          r,
                        );
                      }
                    },
              icon: const Icon(
                Icons.camera,
              ),
              label: const Text(
                'เปิดกล้อง',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => gallery(context),
              icon: const Icon(
                Icons.photo_library,
              ),
              label: const Text(
                'เลือกจาก Gallery',
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'ภาพใช้ชั่วคราวเพื่อวิเคราะห์เท่านั้น\n'
                'แอปจะไม่เก็บรูปไว้ในฐานข้อมูล',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// CAMERA SCAN
// =====================================================

class CameraScanPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String area;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;

  const CameraScanPage({
    super.key,
    required this.cameras,
    required this.area,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
  });

  @override
  State<CameraScanPage> createState() =>
      _CameraScanPageState();
}

class _CameraScanPageState
    extends State<CameraScanPage> {
  CameraController? controller;
  Future<void>? initializeFuture;
  bool busy = false;

  @override
  void initState() {
    super.initState();

    if (widget.cameras.isEmpty) {
      return;
    }

    controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    initializeFuture =
        controller!.initialize();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> take() async {
    final c = controller;

    if (busy ||
        c == null ||
        !c.value.isInitialized) {
      return;
    }

    setState(() => busy = true);

    XFile? file;

    try {
      file = await c.takePicture();

      final r =
          await Navigator.push<ScanResult>(
        context,
        MaterialPageRoute(
          builder: (_) => AiVisionPage(
            imageFile: file!,
            area: widget.area,
            group: widget.group,
            model: widget.model,
            type: widget.type,
            print: widget.print,
            reference: widget.reference,
          ),
        ),
      );

      if (r != null && mounted) {
        Navigator.pop(
          context,
          r,
        );
      }
    } finally {
      try {
        if (file != null) {
          final f = File(file.path);

          if (await f.exists()) {
            await f.delete();
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(
          () => busy = false,
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final c = controller;

    if (c == null) {
      return const Scaffold(
        body: Center(
          child: Text('ไม่พบกล้อง'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'กล้อง - ${widget.area}',
        ),
      ),
      body: FutureBuilder<void>(
        future: initializeFuture,
        builder: (_, snap) {
          if (snap.connectionState !=
                  ConnectionState.done ||
              !c.value.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(c),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton(
                    onPressed:
                        busy ? null : take,
                    child: const Icon(
                      Icons.camera,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================
// AI VISION / DETAIL
// =====================================================

class AiVisionPage extends StatefulWidget {
  final XFile imageFile;
  final String area;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;

  const AiVisionPage({
    super.key,
    required this.imageFile,
    required this.area,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
  });

  @override
  State<AiVisionPage> createState() =>
      _AiVisionPageState();
}

class _AiVisionPageState
    extends State<AiVisionPage> {
  final controllers =
      <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();

    for (final h in aiHeads) {
      controllers[h] =
          TextEditingController();
    }

    final old = firstWhereOrNull(
      widget.reference.scans,
      (e) => e.area == widget.area,
    );

    if (old != null) {
      final lines = old.details.split('\n');

      for (final h in aiHeads) {
        final line = firstWhereOrNull(
          lines,
          (e) => e.startsWith('$h:'),
        );

        if (line != null) {
          controllers[h]!.text =
              line
                  .substring(
                    h.length + 1,
                  )
                  .trim();
        }
      }

      if (lines.isNotEmpty &&
          controllers.values.every(
            (e) => e.text.trim().isEmpty,
          )) {
        controllers[aiHeads.first]!.text =
            old.details;
      }
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }

    super.dispose();
  }

  String buildDetails() {
    final out = <String>[];

    for (final h in aiHeads) {
      final v =
          controllers[h]!.text.trim();

      if (v.isNotEmpty) {
        out.add('$h: $v');
      }
    }

    return out.join('\n');
  }

  void save() {
    Navigator.pop(
      context,
      ScanResult(
        area: widget.area,
        details: buildDetails(),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'รายละเอียด ${widget.area}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Image.file(
            File(widget.imageFile.path),
            height: 260,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
          ...aiHeads.map(
            (h) => Padding(
              padding: const EdgeInsets.only(
                bottom: 10,
              ),
              child: TextField(
                controller: controllers[h],
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: h,
                  border:
                      const OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: save,
              icon: const Icon(Icons.save),
              label: const Text(
                'บันทึกข้อมูล',
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
