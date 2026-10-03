import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../models.dart';
import '../../storage.dart';

import '../../common/app_helpers.dart';
import '../../common/path_bar.dart';

import 'reference_page.dart';

// =====================================================
// PRINT PAGE = รูปทรง
// =====================================================

class PrintPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final GroupData group;
  final ModelData model;
  final TypeData type;

  const PrintPage({
    super.key,
    required this.cameras,
    required this.group,
    required this.model,
    required this.type,
  });

  @override
  State<PrintPage> createState() =>
      _PrintPageState();
}

class _PrintPageState
    extends State<PrintPage> {
  Future<void> add() async {
    await textDialog(
      context,
      'เพิ่มรูปทรง',
      '',
      (v) async {
        final d = now();

        widget.type.prints.add(
          PrintData(
            id: newId(),
            name: v,
            createdAt: d,
            updatedAt: d,
          ),
        );

        widget.type.updatedAt = d;
        widget.model.updatedAt = d;
        widget.group.updatedAt = d;

        await Storage.updateGroup(
          widget.group,
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> edit(PrintData p) async {
    await textDialog(
      context,
      'แก้ไขรูปทรง',
      p.name,
      (v) async {
        p.name = v;
        p.updatedAt = now();
        widget.type.updatedAt = now();
        widget.model.updatedAt = now();
        widget.group.updatedAt = now();

        await Storage.updateGroup(
          widget.group,
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> delete(PrintData p) async {
    if (!await confirmDelete(
      context,
      p.name,
    )) {
      return;
    }

    await Storage.deletePrint(
      groupId: widget.group.id,
      modelId: widget.model.id,
      typeId: widget.type.id,
      printId: p.id,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type.name,
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: add,
        label: const Text(
          'เพิ่มรูปทรง',
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
            '${widget.type.name} > รูปทรง',
          ),

          Expanded(
            child:
                widget.type.prints.isEmpty
                    ? const Center(
                        child: Text(
                          'ยังไม่มีรูปทรง',
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            widget.type.prints.length,
                        itemBuilder: (_, i) {
                          final p =
                              widget.type.prints[i];

                          return Card(
                            child: ListTile(
                              title: Text(
                                p.name,
                              ),

                              subtitle: Text(
                                'องค์อ้างอิง '
                                '${p.references.length}',
                              ),

                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReferencePage(
                                      cameras:
                                          widget.cameras,
                                      group:
                                          widget.group,
                                      model:
                                          widget.model,
                                      type:
                                          widget.type,
                                      print: p,
                                    ),
                                  ),
                                ).then(
                                  (_) => mounted
                                      ? setState(
                                          () {},
                                        )
                                      : null,
                                );
                              },

                              trailing: Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed:
                                        () => edit(p),
                                    icon:
                                        const Icon(
                                      Icons.edit,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        () => delete(p),
                                    icon:
                                        const Icon(
                                      Icons.delete,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
