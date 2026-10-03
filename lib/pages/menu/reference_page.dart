import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../models.dart';
import '../../scan_data.dart';
import '../../storage.dart';

import '../../common/app_helpers.dart';
import '../../common/path_bar.dart';

import 'reference_edit_page.dart';

// =====================================================
// REFERENCE PAGE
// =====================================================

class ReferencePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final GroupData group;
  final ModelData model;
  final TypeData type;
  final PrintData print;

  const ReferencePage({
    super.key,
    required this.cameras,
    required this.group,
    required this.model,
    required this.type,
    required this.print,
  });

  @override
  State<ReferencePage> createState() =>
      _ReferencePageState();
}

class _ReferencePageState
    extends State<ReferencePage> {
  Future<void> addReference() async {
    final n =
        await Storage.nextReferenceNumber(
      groupId: widget.group.id,
    );

    final d = now();

    final reference = ReferenceData(
      id: newId(),
      referenceNumber: n,
      createdAt: d,
      updatedAt: d,
    );

    widget.print.references.add(
      reference,
    );

    widget.print.updatedAt = d;
    widget.type.updatedAt = d;
    widget.model.updatedAt = d;
    widget.group.updatedAt = d;

    await Storage.saveReference(
      groupId: widget.group.id,
      modelId: widget.model.id,
      typeId: widget.type.id,
      printId: widget.print.id,
      reference: reference,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> editReference(
    ReferenceData r,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReferenceEditPage(
          cameras: widget.cameras,
          group: widget.group,
          model: widget.model,
          type: widget.type,
          print: widget.print,
          reference: r,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> deleteReference(
    ReferenceData r,
  ) async {
    if (!await confirmDelete(
      context,
      'องค์อ้างอิง #${r.referenceNumber}',
    )) {
      return;
    }

    await Storage.deleteReference(
      groupId: widget.group.id,
      modelId: widget.model.id,
      typeId: widget.type.id,
      printId: widget.print.id,
      referenceId: r.id,
    );

    if (mounted) {
      setState(() {});
    }
  }

  String status(ReferenceData r) {
    final areas = scanAreasForType(
      widget.model.name,
    );

    final done = areas
        .where(
          (a) => r.scans.any(
            (s) =>
                s.area == a &&
                s.details.trim().isNotEmpty,
          ),
        )
        .length;

    return '$done/${areas.length} ด้าน';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.print.name,
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addReference,
        label: const Text(
          'เพิ่มองค์อ้างอิง',
        ),
        icon: const Icon(
          Icons.add,
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
            child:
                widget.print.references.isEmpty
                    ? const Center(
                        child: Text(
                          'ยังไม่มีองค์อ้างอิง',
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            widget.print.references.length,
                        itemBuilder: (_, i) {
                          final r =
                              widget.print.references[i];

                          return Card(
                            child: ExpansionTile(
                              title: Text(
                                'องค์อ้างอิง #'
                                '${r.referenceNumber}',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              subtitle: Text(
                                status(r),
                              ),

                              children: [
                                ...scanAreasForType(
                                  widget.model.name,
                                ).map(
                                  (a) {
                                    final s =
                                        firstWhereOrNull(
                                      r.scans,
                                      (e) =>
                                          e.area == a,
                                    );

                                    return ListTile(
                                      title: Text(a),
                                      subtitle: Text(
                                        s == null ||
                                                s.details
                                                    .trim()
                                                    .isEmpty
                                            ? 'ยังไม่มีข้อมูล'
                                            : 'มีข้อมูลแล้ว',
                                      ),
                                    );
                                  },
                                ),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          editReference(r),
                                      icon: const Icon(
                                        Icons.edit,
                                      ),
                                      label: const Text(
                                        'แก้ไข',
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 8,
                                    ),

                                    IconButton(
                                      onPressed: () =>
                                          deleteReference(r),
                                      icon: const Icon(
                                        Icons.delete,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 8,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                ),
                child: const Text(
                  'กลับหน้ากลุ่ม',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
