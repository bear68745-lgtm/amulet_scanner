import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../models.dart';
import '../../scan_data.dart';
import '../../storage.dart';

import '../../common/app_helpers.dart'
    show firstWhereOrNull;
import '../../common/path_bar.dart';

import '../../scan_page.dart'
    show ScanPage;

// =====================================================
// REFERENCE EDIT / VIEW
// =====================================================

class ReferenceEditPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;
  final ReferenceData reference;

  const ReferenceEditPage({
    super.key,
    required this.cameras,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
    required this.reference,
  });

  @override
  State<ReferenceEditPage> createState() =>
      _ReferenceEditPageState();
}

class _ReferenceEditPageState
    extends State<ReferenceEditPage> {
  final Map<String, bool> comparing = {};

  final Map<String, List> results = {};

  ScanResult? getScan(String area) {
    return firstWhereOrNull(
      widget.reference.scans,
      (s) => s.area == area,
    );
  }

  Future<void> scanArea(String area) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          cameras: widget.cameras,
          area: area,
          group: widget.group,
          model: widget.model,
          type: widget.type,
          print: widget.print,
          reference: widget.reference,
        ),
      ),
    );

    if (!mounted) return;

    try {
      widget.reference.updatedAt = now();

      await Storage.saveReference(
        groupId: widget.group.id,
        modelId: widget.model.id,
        typeId: widget.type.id,
        printId: widget.print.id,
        reference: widget.reference,
      );
    } catch (_) {}

    setState(() {});
  }

  Future<void> compareArea(String area) async {
    final scan = getScan(area);

    if (scan == null ||
        scan.details.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ด้าน $area ยังไม่มีข้อมูลสำหรับเปรียบเทียบ',
          ),
        ),
      );
      return;
    }

    if (comparing[area] == true) {
      return;
    }

    setState(
      () => comparing[area] = true,
    );

    try {
      await Storage.learnFromScan(
        groupId: widget.group.id,
        modelId: widget.model.id,
        typeId: widget.type.id,
        printId: widget.print.id,
        referenceId: widget.reference.id,
        area: area,
        content: scan.details,
      );

      final comparison =
          await Storage.compareAiMemory(
        groupId: widget.group.id,
        modelId: widget.model.id,
        typeId: widget.type.id,
        printId: widget.print.id,
        referenceId: widget.reference.id,
        area: area,
        currentContent: scan.details,
      );

      if (!mounted) return;

      setState(
        () => results[area] = comparison,
      );

      if (comparison.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ด้าน $area ยังไม่มีองค์อ้างอิงอื่นให้เปรียบเทียบ',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถเปรียบเทียบได้: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(
          () => comparing[area] = false,
        );
      }
    }
  }

  Widget resultCard(
    AiTestResult result,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        top: 8,
        left: 8,
        right: 8,
        bottom: 4,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'เปรียบเทียบกับข้อมูลอ้างอิง',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Memory ID: ${result.knowledgeId}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              result.result,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(result.reason),
          ],
        ),
      ),
    );
  }

  Widget areaCard(String area) {
    final scan = getScan(area);

    final hasData =
        scan != null &&
        scan.details.trim().isNotEmpty;

    final isComparing =
        comparing[area] == true;

    final areaResults =
        results[area] ?? [];

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    area,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: () => scanArea(area),
                  icon: const Icon(
                    Icons.camera_alt,
                  ),
                  label: Text(
                    hasData
                        ? 'สแกนใหม่'
                        : 'สแกน',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (!hasData)
              const Text(
                'ยังไม่มีข้อมูล',
                style: TextStyle(
                  color: Colors.grey,
                ),
              )
            else
              Text(
                scan!.details,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),

            if (hasData) ...[
              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: isComparing
                    ? null
                    : () => compareArea(area),
                icon: isComparing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.compare_arrows,
                      ),
                label: Text(
                  isComparing
                      ? 'กำลังเปรียบเทียบ'
                      : 'เปรียบเทียบ',
                ),
              ),
            ],

            if (areaResults.isNotEmpty) ...[
              const SizedBox(height: 10),

              const Divider(),

              Text(
                'ผลจาก AI Memory '
                '(${areaResults.length} รายการ)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              ...areaResults.map(
                (result) => resultCard(result),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final areas = scanAreasForType(
      widget.model.name,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'องค์อ้างอิง #'
          '${widget.reference.referenceNumber}',
        ),
      ),

      body: Column(
        children: [
          PathBar(
            '${widget.group.name} > '
            '${widget.model.name} > '
            '${widget.type.name} > '
            '${widget.print.name}',
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                Text(
                  'องค์อ้างอิง #'
                  '${widget.reference.referenceNumber}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'ข้อมูลจากการสแกนสามารถนำมาเปรียบเทียบกับ '
                  'AI Memory ขององค์อ้างอิงอื่นในพิมพ์เดียวกันได้',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 12),

                ...areas.map(
                  (area) => areaCard(area),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
