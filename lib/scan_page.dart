import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../scan_data.dart';

// =====================================================
// HELPER
// =====================================================

T? firstWhereOrNull<T>(
  Iterable<T> list,
  bool Function(T) test,
) {
  for (final e in list) {
    if (test(e)) {
      return e;
    }
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

  // ===================================================
  // GALLERY
  // ===================================================

  Future<void> gallery(BuildContext context) async {
    final picker = ImagePicker();

    final XFile? selected = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (selected == null) {
      return;
    }

    File? tempFile;

    try {
      // -----------------------------------------------
      // สร้างไฟล์ชั่วคราว
      // -----------------------------------------------

      tempFile = File(
        '${Directory.systemTemp.path}/'
        'amulet_scan_${newId()}.jpg',
      );

      await File(selected.path).copy(
        tempFile.path,
      );

      if (!context.mounted) {
        return;
      }

      // -----------------------------------------------
      // ส่งรูปชั่วคราวไปหน้าวิเคราะห์
      // -----------------------------------------------

      final result = await Navigator.push<ScanResult>(
        context,
        MaterialPageRoute(
          builder: (_) => AiVisionPage(
            imageFile: XFile(tempFile!.path),
            area: area,
            group: group,
            model: model,
            type: type,
            print: print,
            reference: reference,
          ),
        ),
      );

      // -----------------------------------------------
      // ส่งผลการสแกนกลับ
      // -----------------------------------------------

      if (result != null && context.mounted) {
        Navigator.pop(
          context,
          result,
        );
      }
    } finally {
      // -----------------------------------------------
      // ลบรูปชั่วคราว
      // -----------------------------------------------

      try {
        if (tempFile != null &&
            await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
  }

  // ===================================================
  // BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'สแกน $area',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.document_scanner,
                size: 80,
              ),

              const SizedBox(height: 20),

              Text(
                'องค์อ้างอิง #${reference.referenceNumber}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                area,
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: 25),

              // -----------------------------------------
              // เปิดกล้อง
              // -----------------------------------------

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: cameras.isEmpty
                      ? null
                      : () async {
                          final result =
                              await Navigator.push<
                                  ScanResult>(
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

                          if (result != null &&
                              context.mounted) {
                            Navigator.pop(
                              context,
                              result,
                            );
                          }
                        },
                  icon: const Icon(
                    Icons.camera_alt,
                  ),
                  label: const Text(
                    'เปิดกล้องสแกน',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // -----------------------------------------
              // Gallery
              // -----------------------------------------

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      gallery(context),
                  icon: const Icon(
                    Icons.photo_library,
                  ),
                  label: const Text(
                    'เลือกภาพชั่วคราว',
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // -----------------------------------------
              // คำอธิบาย
              // -----------------------------------------

              const Text(
                'ภาพใช้ชั่วคราวเพื่ออ่านรายละเอียดเท่านั้น\n'
                'เมื่อเสร็จแล้วระบบจะลบไฟล์ภาพ\n'
                'ฐานข้อมูลจะเก็บเฉพาะข้อมูลรายละเอียด',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// CAMERA SCAN PAGE
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

    // -----------------------------------------------
    // ใช้กล้องตัวแรกก่อน
    // -----------------------------------------------

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

  // =================================================
  // TAKE PHOTO
  // =================================================

  Future<void> take() async {
    final c = controller;

    if (busy ||
        c == null ||
        !c.value.isInitialized) {
      return;
    }

    setState(() {
      busy = true;
    });

    XFile? file;

    try {
      // ---------------------------------------------
      // ถ่ายภาพ
      // ---------------------------------------------

      file = await c.takePicture();

      if (!mounted) {
        return;
      }

      // ---------------------------------------------
      // ส่งภาพชั่วคราวไปหน้ารายละเอียด
      // ---------------------------------------------

      final result =
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

      // ---------------------------------------------
      // ถ้ามีข้อมูล ให้ส่งกลับ
      // ---------------------------------------------

      if (result != null && mounted) {
        Navigator.pop(
          context,
          result,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถสแกนได้: $e',
            ),
          ),
        );
      }
    } finally {
      // ---------------------------------------------
      // ลบไฟล์ภาพทันทีหลังใช้งาน
      // ---------------------------------------------

      try {
        if (file != null) {
          final temp = File(file.path);

          if (await temp.exists()) {
            await temp.delete();
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  // =================================================
  // CAMERA SCREEN
  // =================================================

  @override
  Widget build(BuildContext context) {
    final c = controller;

    if (c == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'ไม่พบกล้อง',
          ),
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
        builder: (_, snapshot) {
          if (snapshot.connectionState !=
                  ConnectionState.done ||
              !c.value.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // ---------------------------------------
              // Camera
              // ---------------------------------------

              CameraPreview(c),

              // ---------------------------------------
              // กรอบแนะนำ
              // ---------------------------------------

              Center(
                child: Container(
                  width: 260,
                  height: 340,
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 2,
                      color: Colors.white,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              // ---------------------------------------
              // ชื่อด้าน
              // ---------------------------------------

              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.area,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // ---------------------------------------
              // ปุ่มถ่าย
              // ---------------------------------------

              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton(
                    onPressed:
                        busy ? null : take,
                    child: busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
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
// AI VISION / DETAIL PAGE
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
  final Map<String, TextEditingController>
      controllers = {};

  bool saving = false;

  // =================================================
  // INIT
  // =================================================

  @override
  void initState() {
    super.initState();

    // -----------------------------------------------
    // สร้างช่องข้อมูลตาม aiHeads
    // -----------------------------------------------

    for (final head in aiHeads) {
      controllers[head] =
          TextEditingController();
    }

    // -----------------------------------------------
    // ถ้ามีข้อมูลด้านนี้อยู่แล้ว
    // ให้โหลดมาแก้ไขต่อ
    // -----------------------------------------------

    final old = firstWhereOrNull(
      widget.reference.scans,
      (scan) => scan.area == widget.area,
    );

    if (old != null) {
      _loadOldData(old.details);
    }
  }

  // =================================================
  // LOAD OLD DATA
  // =================================================

  void _loadOldData(String details) {
    final lines = details.split('\n');

    bool loadedByHead = false;

    for (final head in aiHeads) {
      final line = firstWhereOrNull(
        lines,
        (value) => value.startsWith(
          '$head:',
        ),
      );

      if (line != null) {
        controllers[head]!.text =
            line
                .substring(head.length + 1)
                .trim();

        loadedByHead = true;
      }
    }

    // -----------------------------------------------
    // รองรับข้อมูลรูปแบบเก่า
    // -----------------------------------------------

    if (!loadedByHead &&
        details.trim().isNotEmpty) {
      controllers[aiHeads.first]!.text =
          details.trim();
    }
  }

  // =================================================
  // DISPOSE
  // =================================================

  @override
  void dispose() {
    for (final controller
        in controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  // =================================================
  // BUILD DETAILS
  // =================================================

  String buildDetails() {
    final output = <String>[];

    for (final head in aiHeads) {
      final value =
          controllers[head]!.text.trim();

      // ---------------------------------------------
      // ถ้าไม่มีข้อมูล ไม่ต้องบันทึกหัวข้อนั้น
      // ---------------------------------------------

      if (value.isNotEmpty) {
        output.add(
          '$head: $value',
        );
      }
    }

    return output.join('\n');
  }

  // =================================================
  // SAVE
  // =================================================

  Future<void> save() async {
    if (saving) {
      return;
    }

    final details = buildDetails();

    if (details.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณาใส่รายละเอียดอย่างน้อย 1 รายการ',
          ),
        ),
      );

      return;
    }

    setState(() {
      saving = true;
    });

    // -----------------------------------------------
    // เก็บเฉพาะ ScanResult
    // ไม่มีการเก็บ path ของรูป
    // -----------------------------------------------

    final result = ScanResult(
      area: widget.area,
      details: details,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      result,
    );
  }

  // =================================================
  // CLEAR ALL
  // =================================================

  void clearAll() {
    for (final controller
        in controllers.values) {
      controller.clear();
    }

    setState(() {});
  }

  // =================================================
  // BUILD
  // =================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'รายละเอียด ${widget.area}',
        ),
        actions: [
          IconButton(
            onPressed: clearAll,
            tooltip: 'ล้างข้อมูล',
            icon: const Icon(
              Icons.clear_all,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          // -----------------------------------------
          // ภาพชั่วคราว
          // -----------------------------------------

          Container(
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
              ),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child: Image.file(
                File(widget.imageFile.path),
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) {
                  return const Center(
                    child: Text(
                      'ไม่สามารถแสดงภาพชั่วคราวได้',
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'ภาพนี้ใช้ชั่วคราวเท่านั้น\n'
            'ระบบจะไม่บันทึกภาพลงฐานข้อมูล',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 18),

          // -----------------------------------------
          // หัวข้อข้อมูล
          // -----------------------------------------

          const Text(
            'รายละเอียดที่สแกนได้',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // -----------------------------------------
          // 10 หัวข้อ
          // -----------------------------------------

          ...aiHeads.map(
            (head) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: TextField(
                  controller:
                      controllers[head],
                  maxLines: 3,
                  textInputAction:
                      TextInputAction.newline,
                  decoration:
                      InputDecoration(
                    labelText: head,
                    alignLabelWithHint:
                        true,
                    border:
                        const OutlineInputBorder(),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 5),

          // -----------------------------------------
          // SAVE
          // -----------------------------------------

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  saving ? null : save,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.save,
                    ),
              label: Text(
                saving
                    ? 'กำลังบันทึก...'
                    : 'บันทึกข้อมูล',
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
