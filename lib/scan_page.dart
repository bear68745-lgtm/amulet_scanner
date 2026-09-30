import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core_pipeline.dart';
import '../models.dart';
import '../scan_data.dart';
import '../core/image_object_detector.dart';

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

      if (result != null && context.mounted) {
        Navigator.pop(
          context,
          result,
        );
      }
    } finally {
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
              // CAMERA
              // -----------------------------------------

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: cameras.isEmpty
                      ? null
                      : () async {
                          final result =
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
              // GALLERY
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
      file = await c.takePicture();

      if (!mounted) {
        return;
      }

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
              CameraPreview(c),

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
// SCAN DETAIL PAGE
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

  bool scanning = false;
  bool scanned = false;
  bool coreReceived = false;
  bool saving = false;

  CorePipelineResult? pipelineResult;

  // =================================================
  // ผลตรวจวัตถุจาก Core
  // =================================================

  ImageObjectDetectionResult?
      objectDetection;

  // =================================================
  // เฉพาะหัวข้อที่แสดงตามพื้นที่สแกน
  // =================================================

  List<String> get visibleAiHeads {
    final result = <String>[];

    for (final head in aiHeads) {
      if (widget.area == 'ด้านหน้า' &&
          head == 'ขอบ/ด้านข้าง') {
        continue;
      }

      if (widget.area == 'ด้านหลัง' &&
          head == 'ขอบ/ด้านข้าง') {
        continue;
      }

      if (widget.area == 'ด้านข้าง' &&
          head != 'ขอบ/ด้านข้าง') {
        continue;
      }

      if (widget.area == 'ก้นพระ' &&
          head == 'ขอบ/ด้านข้าง') {
        continue;
      }

      result.add(head);
    }

    return result;
  }

  // =================================================
  // INIT
  // =================================================

  @override
  void initState() {
    super.initState();

    for (final head in aiHeads) {
      controllers[head] =
          TextEditingController();
    }

    final old = firstWhereOrNull(
      widget.reference.scans,
      (scan) => scan.area == widget.area,
    );

    if (old != null) {
      _loadOldData(old.details);
    }
  }

  // =================================================
  // SCAN IMAGE WITH CORE
  // =================================================

  Future<void> _scanImage() async {
    if (scanning) {
      return;
    }

    setState(() {
      scanning = true;
      scanned = false;
      coreReceived = false;
      pipelineResult = null;
      objectDetection = null;
    });

    try {
      final imageFile =
          File(widget.imageFile.path);

      if (!await imageFile.exists()) {
        throw Exception(
          'ไม่พบไฟล์ภาพชั่วคราว',
        );
      }

      // ---------------------------------------------
      // CORE IMAGE OBJECT DETECTOR
      // ---------------------------------------------

      const detector =
          ImageObjectDetector();

      final detected =
          await detector.detect(
        imagePath:
            widget.imageFile.path,
        area: widget.area,
      );

      // ---------------------------------------------
      // สร้างข้อมูลที่ Core อ่านได้
      // ---------------------------------------------

      final details = [
        'พื้นที่วัตถุหลัก',
        'ซ้าย: '
            '${detected.left.toStringAsFixed(3)}',
        'บน: '
            '${detected.top.toStringAsFixed(3)}',
        'ขวา: '
            '${detected.right.toStringAsFixed(3)}',
        'ล่าง: '
            '${detected.bottom.toStringAsFixed(3)}',
        'สัดส่วนพื้นที่: '
            '${detected.objectRatio.toStringAsFixed(3)}',
      ].join('\n');

      final scan = ScanResult(
        area: widget.area,
        details: details,
      );

      // ---------------------------------------------
      // ส่งผลเข้า CORE PIPELINE
      // ---------------------------------------------

      const pipeline = CorePipeline();

      final result = pipeline.process(
        scans: [
          scan,
        ],
        id: widget.reference.id,
        referenceNumber:
            widget.reference.referenceNumber,
        createdAt:
            widget.reference.createdAt,
        width: widget.reference.width,
        height: widget.reference.height,
        thickness:
            widget.reference.thickness,
        unit: widget.reference.unit,
        sourceName:
            widget.reference.sourceName,
        sourceUrl:
            widget.reference.sourceUrl,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        pipelineResult = result;
        objectDetection = detected;
        scanned = true;
        coreReceived = true;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Core ตรวจหาพื้นที่วัตถุจากภาพแล้ว',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          scanned = false;
          coreReceived = false;
          pipelineResult = null;
          objectDetection = null;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถอ่านภาพด้วย Core ได้: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          scanning = false;
        });
      }
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

    for (final head in visibleAiHeads) {
      final value =
          controllers[head]!.text.trim();

      if (value.isNotEmpty) {
        output.add(
          '$head: $value',
        );
      }
    }

    // ---------------------------------------------
    // เพิ่มผลตรวจ Core ถ้ามี
    // ---------------------------------------------

    final detected = objectDetection;

    if (detected != null) {
      output.add(
        'Core ตรวจพื้นที่วัตถุ: '
        'ซ้าย ${detected.left.toStringAsFixed(3)}, '
        'บน ${detected.top.toStringAsFixed(3)}, '
        'ขวา ${detected.right.toStringAsFixed(3)}, '
        'ล่าง ${detected.bottom.toStringAsFixed(3)}, '
        'พื้นที่ ${detected.objectRatio.toStringAsFixed(3)}',
      );
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
            'ยังไม่มีข้อมูลสำหรับบันทึก',
          ),
        ),
      );

      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final scan = ScanResult(
        area: widget.area,
        details: details,
      );

      const pipeline = CorePipeline();

      final result = pipeline.process(
        scans: [
          scan,
        ],
        id: widget.reference.id,
        referenceNumber:
            widget.reference.referenceNumber,
        createdAt:
            widget.reference.createdAt,
        width: widget.reference.width,
        height: widget.reference.height,
        thickness:
            widget.reference.thickness,
        unit: widget.reference.unit,
        sourceName:
            widget.reference.sourceName,
        sourceUrl:
            widget.reference.sourceUrl,
      );

      widget.reference.frontDetails =
          result.reference.frontDetails;

      widget.reference.backDetails =
          result.reference.backDetails;

      widget.reference.edgeDetails =
          result.reference.edgeDetails;

      widget.reference.bottomDetails =
          result.reference.bottomDetails;

      widget.reference.surfaceDetails =
          result.reference.surfaceDetails;

      widget.reference.shapeDetails =
          result.reference.shapeDetails;

      widget.reference.materialDetails =
          result.reference.materialDetails;

      widget.reference.distinctivePoints =
          result.reference.distinctivePoints;

      widget.reference.defectPoints =
          result.reference.defectPoints;

      widget.reference.calculateRatio();

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        scan,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถประมวลผลข้อมูล Core ได้: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  // =================================================
  // CLEAR ALL
  // =================================================

  void clearAll() {
    for (final controller
        in controllers.values) {
      controller.clear();
    }

    setState(() {
      objectDetection = null;
      pipelineResult = null;
      scanned = false;
      coreReceived = false;
    });
  }

  // =================================================
  // BUILD
  // =================================================

  @override
  Widget build(BuildContext context) {
    final warnings =
        pipelineResult?.validation.warnings ??
            <String>[];

    final detected = objectDetection;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'รายละเอียด ${widget.area}',
        ),
        actions: [
          IconButton(
            onPressed:
                scanning ? null : clearAll,
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
          // IMAGE
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
          // SCAN BUTTON
          // -----------------------------------------

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  scanning ? null : _scanImage,
              icon: scanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.document_scanner,
                    ),
              label: Text(
                scanning
                    ? 'กำลังให้ Core อ่านภาพ...'
                    : scanned
                        ? 'สแกนอีกครั้ง'
                        : 'สแกนภาพ',
              ),
            ),
          ),

          const SizedBox(height: 12),

          // -----------------------------------------
          // CORE STATUS
          // -----------------------------------------

          if (coreReceived)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green,
                ),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 30,
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Core อ่านภาพเรียบร้อยแล้ว',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  if (detected != null) ...[
                    const SizedBox(height: 12),

                    const Text(
                      'ผลตรวจพื้นที่วัตถุหลัก',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'ซ้าย: '
                      '${detected.left.toStringAsFixed(3)}\n'
                      'บน: '
                      '${detected.top.toStringAsFixed(3)}\n'
                      'ขวา: '
                      '${detected.right.toStringAsFixed(3)}\n'
                      'ล่าง: '
                      '${detected.bottom.toStringAsFixed(3)}\n'
                      'สัดส่วนพื้นที่: '
                      '${detected.objectRatio.toStringAsFixed(3)}',
                      textAlign:
                          TextAlign.center,
                    ),
                  ],

                  if (warnings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Core แจ้งเตือน '
                      '${warnings.length} รายการ',
                      textAlign:
                          TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 18),

          // -----------------------------------------
          // DETAILS
          // -----------------------------------------

          Text(
            'รายละเอียดข้อมูล ${widget.area}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // -----------------------------------------
          // แสดงเฉพาะหัวข้อที่ตรงกับพื้นที่สแกน
          // -----------------------------------------

          ...visibleAiHeads.map(
            (head) {
              final value =
                  controllers[head]!
                      .text
                      .trim();

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                    ),
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        head,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        value.isEmpty
                            ? 'ยังไม่มีข้อมูล'
                            : value,
                        style:
                            const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
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
