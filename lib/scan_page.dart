import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core_pipeline.dart';
import '../models.dart';
import '../scan_data.dart';
import '../core/image_object_detector.dart';
import '../core/shape_analyzer.dart';

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
// DETECTION BOX PAINTER
// =====================================================

class DetectionBoxPainter
    extends CustomPainter {
  final ImageObjectDetectionResult detection;

  DetectionBoxPainter({
    required this.detection,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final left =
        detection.left * size.width;

    final top =
        detection.top * size.height;

    final right =
        detection.right * size.width;

    final bottom =
        detection.bottom * size.height;

    final rect = Rect.fromLTRB(
      left,
      top,
      right,
      bottom,
    );

    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(
      rect,
      paint,
    );

    final fillPaint = Paint()
      ..color = Colors.red.withValues(
        alpha: 0.08,
      )
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      rect,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant DetectionBoxPainter oldDelegate,
  ) {
    return oldDelegate.detection.left !=
            detection.left ||
        oldDelegate.detection.top !=
            detection.top ||
        oldDelegate.detection.right !=
            detection.right ||
        oldDelegate.detection.bottom !=
            detection.bottom;
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

  ImageObjectDetectionResult?
      objectDetection;

  // =================================================
  // OUTLINE
  // =================================================

  ShapeOutlineSymbol?
      outlineSymbol;

  // =================================================
  // OUTLINE COMPARISON
  // =================================================

  ShapeOutlineComparison?
      outlineComparison;

  // =================================================
  // CORE OBSERVATION
  // ข้อมูลที่ Core ตรวจพบจากภาพจริง
  // =================================================

  String coreObservation = '';

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
  // BUILD CORE OBSERVATION
  // =================================================

  String _buildCoreObservation({
    required ImageObjectDetectionResult detected,
    required ShapeOutlineSymbol? outline,
  }) {
    final lines = <String>[];

    // -------------------------------------------------
    // วัตถุ
    // -------------------------------------------------

    lines.add(
      'Core ตรวจพบวัตถุแตกต่างจากพื้นหลัง',
    );

    lines.add(
      'พื้นที่ตรวจ: ${widget.area}',
    );

    // -------------------------------------------------
    // ตำแหน่งวัตถุ
    // -------------------------------------------------

    lines.add(
      'กรอบวัตถุ: '
      'ซ้าย ${detected.left.toStringAsFixed(3)}, '
      'บน ${detected.top.toStringAsFixed(3)}, '
      'ขวา ${detected.right.toStringAsFixed(3)}, '
      'ล่าง ${detected.bottom.toStringAsFixed(3)}',
    );

    lines.add(
      'สัดส่วนพื้นที่วัตถุ: '
      '${detected.objectRatio.toStringAsFixed(3)}',
    );

    // -------------------------------------------------
    // โครงร่าง
    // -------------------------------------------------

    if (outline != null &&
        outline.radialProfile.isNotEmpty) {
      lines.add(
        'โครงร่างภายนอก: สกัดได้ '
        '${outline.radialProfile.length} จุด',
      );

      lines.add(
        'ชื่อโครงร่างที่ระบบใช้วิเคราะห์: '
        '${outline.name}',
      );
    } else {
      lines.add(
        'โครงร่างภายนอก: ยังสกัดข้อมูลไม่ได้',
      );
    }

    // -------------------------------------------------
    // ผลเปรียบเทียบโครงร่าง
    // -------------------------------------------------

    final comparison = outlineComparison;

    if (comparison != null) {
      lines.add(
        'ผลเปรียบเทียบโครงร่าง: '
        '${comparison.result}',
      );

      if (comparison.hasReference) {
        lines.add(
          'ค่าความแตกต่างของโครงร่าง: '
          '${comparison.difference.toStringAsFixed(4)}',
        );
      }
    }

    // -------------------------------------------------
    // ข้อมูลโครงสร้างของรุ่นที่ผู้ใช้กำหนดไว้
    // ไม่ถือว่าเป็นผลยืนยันจากภาพ
    // -------------------------------------------------

    final coinShape =
        widget.print.coinShape.trim();

    final earType =
        widget.print.earType.trim();

    if (coinShape.isNotEmpty) {
      lines.add(
        'รูปทรงที่กำหนดไว้ในข้อมูลรุ่น: '
        '$coinShape',
      );
    }

    if (earType.isNotEmpty) {
      lines.add(
        'โครงสร้างหูที่กำหนดไว้ในข้อมูลรุ่น: '
        '$earType',
      );
    }

    // -------------------------------------------------
    // ขอบเขตของการวิเคราะห์
    // -------------------------------------------------

    lines.add(
      'หมายเหตุ: ข้อมูลข้างต้นเป็นสิ่งที่ Core '
      'ตรวจพบจากภาพและข้อมูลโครงสร้างที่กำหนดไว้',
    );

    lines.add(
      'ยังไม่ได้ใช้เพื่อตัดสินแท้หรือเก๊',
    );

    return lines.join('\n');
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
      outlineSymbol = null;
      outlineComparison = null;
      coreObservation = '';
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
      // CORE OUTLINE EXTRACTOR
      // ---------------------------------------------

      const shapeAnalyzer =
          ShapeAnalyzer();

      final extractedOutline =
          await shapeAnalyzer.extractOutlineSymbol(
        imagePath:
            widget.imageFile.path,
        shapeName:
            widget.print.coinShape.trim().isNotEmpty
                ? widget.print.coinShape.trim()
                : 'ไม่ระบุรูปทรง',
        left: detected.left,
        top: detected.top,
        right: detected.right,
        bottom: detected.bottom,
      );

      // ---------------------------------------------
      // OUTLINE COMPARISON
      // เปรียบเทียบกับโครงร่างอ้างอิงที่มีอยู่
      // ---------------------------------------------

      ShapeOutlineComparison? comparison;

      if (extractedOutline != null &&
          widget.reference.outlineProfile.isNotEmpty) {
        final referenceOutline =
            ShapeOutlineSymbol(
          name:
              widget.reference.outlineName.trim().isNotEmpty
                  ? widget.reference.outlineName
                  : widget.print.coinShape,
          radialProfile:
              List<double>.from(
            widget.reference.outlineProfile,
          ),
        );

        comparison =
            shapeAnalyzer.compareOutline(
          extractedOutline,
          referenceOutline,
        );
      } else {
        comparison =
            const ShapeOutlineComparison(
          hasReference: false,
          difference: 0,
          result: 'ยังไม่มีโครงร่างอ้างอิง',
        );
      }

      // ---------------------------------------------
      // CORE OBSERVATION
      // ---------------------------------------------

      final observation =
          _buildCoreObservation(
        detected: detected,
        outline: extractedOutline,
      );

      final scan = ScanResult(
        area: widget.area,
        details: observation,
      );

      // ---------------------------------------------
      // CORE PIPELINE
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
        outlineProfile:
            extractedOutline?.radialProfile ??
                const [],
        outlineName:
            extractedOutline?.name ?? '',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        pipelineResult = result;
        objectDetection = detected;
        outlineSymbol = extractedOutline;
        outlineComparison = comparison;
        coreObservation =
            _buildCoreObservation(
          detected: detected,
          outline: extractedOutline,
        );
        scanned = true;
        coreReceived = true;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            comparison.hasReference
                ? 'Core ตรวจวัตถุและเปรียบเทียบโครงร่างเสร็จแล้ว'
                : 'Core ตรวจวัตถุและสกัดโครงร่างแล้ว แต่ยังไม่มีโครงร่างอ้างอิง',
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
          outlineSymbol = null;
          outlineComparison = null;
          coreObservation = '';
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

    // -------------------------------------------------
    // CORE OBSERVATION
    // -------------------------------------------------

    if (coreObservation.trim().isNotEmpty) {
      output.add(
        '=== ข้อมูลที่ Core ตรวจพบจากภาพ ===',
      );

      output.add(
        coreObservation.trim(),
      );
    }

    // -------------------------------------------------
    // MANUAL / AI DETAILS
    // -------------------------------------------------

    for (final head in visibleAiHeads) {
      final value =
          controllers[head]!.text.trim();

      if (value.isNotEmpty) {
        output.add(
          '$head: $value',
        );
      }
    }

    // -------------------------------------------------
    // DETECTION DATA
    // -------------------------------------------------

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

    // -------------------------------------------------
    // OUTLINE DATA
    // -------------------------------------------------

    final outline = outlineSymbol;

    if (outline != null) {
      output.add(
        'Core สกัดโครงร่างภายนอก: '
        '${outline.radialProfile.length} จุด',
      );

      output.add(
        'Core ชื่อโครงร่างที่ใช้วิเคราะห์: '
        '${outline.name}',
      );
    }

    // -------------------------------------------------
    // OUTLINE COMPARISON DATA
    // -------------------------------------------------

    final comparison = outlineComparison;

    if (comparison != null) {
      output.add(
        'Core เปรียบเทียบโครงร่าง: '
        '${comparison.result}',
      );

      if (comparison.hasReference) {
        output.add(
          'ค่าความแตกต่างโครงร่าง: '
          '${comparison.difference.toStringAsFixed(4)}',
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

        // -------------------------------------------
        // ส่งโครงร่างจากภาพเข้า ReferenceData
        // ตอนบันทึก
        // -------------------------------------------

        outlineProfile:
            outlineSymbol?.radialProfile ??
                const [],
        outlineName:
            outlineSymbol?.name ?? '',
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

      // -------------------------------------------
      // บันทึกโครงร่างลง ReferenceData
      // -------------------------------------------

      widget.reference.outlineProfile =
          List<double>.from(
        result.reference.outlineProfile,
      );

      widget.reference.outlineName =
          result.reference.outlineName;

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
      outlineSymbol = null;
      outlineComparison = null;
      pipelineResult = null;
      coreObservation = '';
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
    final outline = outlineSymbol;
    final comparison = outlineComparison;

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
          // IMAGE + DETECTION BOX
          // -----------------------------------------

          Container(
            height: 300,
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
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

                  if (detected != null)
                    CustomPaint(
                      painter:
                          DetectionBoxPainter(
                        detection: detected,
                      ),
                    ),

                  if (detected != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                              BorderRadius.circular(
                            6,
                          ),
                        ),
                        child: const Text(
                          'ตำแหน่งที่ Core ตรวจพบ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'กรอบสีแดงคือบริเวณที่ Core ตรวจพบว่าแตกต่างจากพื้นหลัง\n'
            'ยังไม่ถือว่าเป็นการยืนยันว่าเป็นองค์พระหรือเหรียญ',
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
          // CORE RESULT
          // -----------------------------------------

          if (coreReceived &&
              detected != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green,
                ),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: Colors.green,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ผลที่ Core ตรวจพบ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'พื้นที่ตรวจ: ${widget.area}',
                  ),

                  const SizedBox(height: 10),

                  if (coreObservation
                      .trim()
                      .isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(10),
                      decoration:
                          BoxDecoration(
                        color: Colors.green
                            .withValues(
                          alpha: 0.06,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          6,
                        ),
                      ),
                      child: Text(
                        coreObservation,
                        style:
                            const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  Text(
                    'กรอบตรวจจับ: '
                    'ซ้าย ${detected.left.toStringAsFixed(3)}, '
                    'บน ${detected.top.toStringAsFixed(3)}, '
                    'ขวา ${detected.right.toStringAsFixed(3)}, '
                    'ล่าง ${detected.bottom.toStringAsFixed(3)}',
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'สัดส่วนพื้นที่วัตถุ: '
                    '${detected.objectRatio.toStringAsFixed(3)}',
                  ),

                  // ---------------------------------
                  // OUTLINE RESULT
                  // ---------------------------------

                  if (outline != null) ...[
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(12),
                      decoration:
                          BoxDecoration(
                        border: Border.all(
                          color: Colors.blue,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'โครงร่างภายนอก',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'ประเภทโครงร่าง: '
                            '${outline.name}',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'จุดโครงร่างที่สกัดได้: '
                            '${outline.radialProfile.length} จุด',
                          ),

                          // ---------------------------------
                          // COMPARISON RESULT
                          // ---------------------------------

                          if (comparison != null) ...[
                            const SizedBox(height: 12),

                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.all(10),
                              decoration:
                                  BoxDecoration(
                                color: Colors.indigo
                                    .withValues(
                                  alpha: 0.06,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  6,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'การเทียบโครงร่างกับรุ่นอ้างอิง',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    comparison.result,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),

                                  if (comparison
                                      .hasReference) ...[
                                    const SizedBox(height: 4),

                                    Text(
                                      'ค่าความแตกต่าง: '
                                      '${comparison.difference.toStringAsFixed(4)}',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 8),

                          const Text(
                            'โครงร่างนี้เป็นข้อมูลโครงสร้างภายนอก '
                            'ยังไม่ใช่การตัดสินว่าแท้หรือปลอม '
                            'และยังไม่ได้ใช้ยืนยันตัวตนของพระหรือเหรียญ',
                            style: TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ---------------------------------
                  // REFERENCE STRUCTURE
                  // ---------------------------------

                  if (widget.print.coinShape
                          .trim()
                          .isNotEmpty ||
                      widget.print.earType
                          .trim()
                          .isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(10),
                      decoration:
                          BoxDecoration(
                        color: Colors.blueGrey
                            .withValues(
                          alpha: 0.08,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          6,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ข้อมูลโครงสร้างของรุ่น',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          if (widget.print.coinShape
                              .trim()
                              .isNotEmpty)
                            Text(
                              'รูปทรง: '
                              '${widget.print.coinShape}',
                            ),

                          if (widget.print.earType
                              .trim()
                              .isNotEmpty)
                            Text(
                              'โครงสร้างหู: '
                              '${widget.print.earType}',
                            ),

                          const SizedBox(height: 6),

                          const Text(
                            'ข้อมูลส่วนนี้เป็นข้อมูลโครงสร้าง '
                            'ที่กำหนดไว้ของรุ่น ไม่ใช่ผลตัดสินจากภาพว่าแท้หรือเก๊',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(10),
                    decoration:
                        BoxDecoration(
                      color: Colors.orange
                          .withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        6,
                      ),
                    ),
                    child: const Text(
                      'กรุณาดูกรอบสีแดงบนภาพเพื่อยืนยันว่า '
                      'ตำแหน่งที่ Core ตรวจพบตรงกับวัตถุจริงหรือไม่',
                      textAlign:
                          TextAlign.center,
                    ),
                  ),

                  if (warnings.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Core แจ้งเตือน '
                      '${warnings.length} รายการ',
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