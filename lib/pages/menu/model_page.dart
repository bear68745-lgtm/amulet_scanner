import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../models.dart';
import '../../storage.dart';

import '../../common/app_helpers.dart';
import '../../common/path_bar.dart';

import 'type_page.dart';

// =====================================================
// MODEL PAGE = ชนิดพระ
// =====================================================

class ModelPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final GroupData group;

  const ModelPage({
    super.key,
    required this.cameras,
    required this.group,
  });

  @override
  State<ModelPage> createState() =>
      _ModelPageState();
}

class _ModelPageState
    extends State<ModelPage> {
  Future<void> add() async {
    await textDialog(
      context,
      'เพิ่มชนิดพระ',
      '',
      (v) async {
        final d = now();

        widget.group.models.add(
          ModelData(
            id: newId(),
            name: v,
            createdAt: d,
            updatedAt: d,
          ),
        );

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

  Future<void> edit(ModelData m) async {
    await textDialog(
      context,
      'แก้ไขชนิดพระ',
      m.name,
      (v) async {
        m.name = v;
        m.updatedAt = now();
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

  Future<void> delete(ModelData m) async {
    if (!await confirmDelete(
      context,
      m.name,
    )) {
      return;
    }

    await Storage.deleteModel(
      groupId: widget.group.id,
      modelId: m.id,
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
          widget.group.name,
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: add,
        label: const Text(
          'เพิ่มชนิดพระ',
        ),
        icon: const Icon(
          Icons.add,
        ),
      ),

      body: Column(
        children: [
          PathBar(
            '${widget.group.name} > ชนิดพระ',
          ),

          Expanded(
            child:
                widget.group.models.isEmpty
                    ? const Center(
                        child: Text(
                          'ยังไม่มีชนิดพระ',
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            widget.group.models.length,
                        itemBuilder: (_, i) {
                          final m =
                              widget.group.models[i];

                          return Card(
                            child: ListTile(
                              title: Text(
                                m.name,
                              ),

                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TypePage(
                                      cameras:
                                          widget.cameras,
                                      group:
                                          widget.group,
                                      model: m,
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
                                        () => edit(m),
                                    icon:
                                        const Icon(
                                      Icons.edit,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        () => delete(m),
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
