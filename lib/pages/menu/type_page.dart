import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../models.dart';
import '../../storage.dart';

import '../../common/app_helpers.dart';
import '../../common/path_bar.dart';

import 'print_page.dart';

// =====================================================
// TYPE PAGE = รุ่น
// =====================================================

class TypePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final GroupData group;
  final ModelData model;

  const TypePage({
    super.key,
    required this.cameras,
    required this.group,
    required this.model,
  });

  @override
  State<TypePage> createState() =>
      _TypePageState();
}

class _TypePageState
    extends State<TypePage> {
  Future<void> add() async {
    await textDialog(
      context,
      'เพิ่มรุ่น',
      '',
      (v) async {
        final d = now();

        widget.model.types.add(
          TypeData(
            id: newId(),
            name: v,
            createdAt: d,
            updatedAt: d,
          ),
        );

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

  Future<void> edit(TypeData t) async {
    await textDialog(
      context,
      'แก้ไขรุ่น',
      t.name,
      (v) async {
        t.name = v;
        t.updatedAt = now();
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

  Future<void> delete(TypeData t) async {
    if (!await confirmDelete(
      context,
      t.name,
    )) {
      return;
    }

    await Storage.deleteType(
      groupId: widget.group.id,
      modelId: widget.model.id,
      typeId: t.id,
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
          widget.model.name,
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: add,
        label: const Text(
          'เพิ่มรุ่น',
        ),
        icon: const Icon(
          Icons.add,
        ),
      ),

      body: Column(
        children: [
          PathBar(
            '${widget.group.name} > '
            '${widget.model.name} > รุ่น',
          ),

          Expanded(
            child:
                widget.model.types.isEmpty
                    ? const Center(
                        child: Text(
                          'ยังไม่มีรุ่น',
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            widget.model.types.length,
                        itemBuilder: (_, i) {
                          final t =
                              widget.model.types[i];

                          return Card(
                            child: ListTile(
                              title: Text(
                                t.name,
                              ),

                              subtitle: Text(
                                '${t.prints.length} รูปทรง',
                              ),

                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PrintPage(
                                      cameras:
                                          widget.cameras,
                                      group:
                                          widget.group,
                                      model:
                                          widget.model,
                                      type: t,
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
                                        () => edit(t),
                                    icon:
                                        const Icon(
                                      Icons.edit,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        () => delete(t),
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
