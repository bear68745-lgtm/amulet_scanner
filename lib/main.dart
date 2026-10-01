import 'pages/home_page.dart';
import 'scan_page.dart';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'scan_data.dart';
import 'storage.dart';

import 'data/coin_shapes.dart';
import 'data/model_types.dart';

import 'common/app_helpers.dart'
    show
        textDialog,
        confirmDelete,
        now,
        newId,
        firstWhereOrNull;

import 'common/path_bar.dart';
import 'drawings/coin_shape_outline.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List cameras = [];

  try {
    cameras = await availableCameras();
  } catch (_) {}

  runApp(App(cameras));
}

// =====================================================
// APP
// =====================================================

class App extends StatelessWidget {
  final List cameras;

  const App(
    this.cameras, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'กล้องสแกนพระและเหรียญ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
        ),
        useMaterial3: true,
      ),

      // =================================================
      // เชื่อม HomePage ที่แยกไว้ใน pages/home_page.dart
      // =================================================

      home: HomePage(
        cameras: cameras,

        // ปุ่ม "สร้างข้อมูล"
        createReferencePageBuilder: () {
          return CreateReferencePage(
            cameras: cameras,
          );
        },

        // แตะกลุ่ม -> ไปหน้า ModelPage
        modelPageBuilder: (group) {
          return ModelPage(
            cameras: cameras,
            group: group,
          );
        },
      ),
    );
  }
}

// =====================================================
// CREATE REFERENCE
// =====================================================

class CreateReferencePage extends StatefulWidget {
  final List cameras;

  const CreateReferencePage({
    super.key,
    required this.cameras,
  });

  @override
  State createState() =>
      _CreateReferencePageState();
}

class _CreateReferencePageState
    extends State<CreateReferencePage> {
  final groupController =
      TextEditingController();

  final templeController =
      TextEditingController();

  final typeController =
      TextEditingController();

  final printController =
      TextEditingController();

  String? selectedModelName;
  String? selectedCoinShape;

  bool saving = false;

  @override
  void dispose() {
    groupController.dispose();
    templeController.dispose();
    typeController.dispose();
    printController.dispose();

    super.dispose();
  }

  Future create() async {
    final groupName =
        groupController.text.trim();

    final temple =
        templeController.text.trim();

    final modelName =
        selectedModelName?.trim() ?? '';

    final typeName =
        typeController.text.trim();

    final printName =
        selectedModelName == 'เหรียญ'
            ? (selectedCoinShape?.trim() ?? '')
            : printController.text.trim();

    if ([groupName, modelName, typeName, printName]
        .any((e) => e.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณากรอกข้อมูลให้ครบ',
          ),
        ),
      );
      return;
    }

    if (saving) return;

    setState(() => saving = true);

    try {
      final groups =
          await Storage.groups();

      final d = now();

      GroupData? group =
          firstWhereOrNull(
        groups,
        (g) =>
            g.name.trim() == groupName &&
            g.temple.trim() == temple,
      );

      if (group == null) {
        group = GroupData(
          id: newId(),
          name: groupName,
          temple: temple,
          createdAt: d,
          updatedAt: d,
        );

        groups.add(group);
      }

      ModelData? model =
          firstWhereOrNull(
        group.models,
        (m) =>
            m.name.trim() == modelName,
      );

      if (model == null) {
        model = ModelData(
          id: newId(),
          name: modelName,
          createdAt: d,
          updatedAt: d,
        );

        group.models.add(model);
      }

      TypeData? type =
          firstWhereOrNull(
        model.types,
        (t) =>
            t.name.trim() == typeName,
      );

      if (type == null) {
        type = TypeData(
          id: newId(),
          name: typeName,
          createdAt: d,
          updatedAt: d,
        );

        model.types.add(type);
      }

      PrintData? print =
          firstWhereOrNull(
        type.prints,
        (p) =>
            p.name.trim() == printName,
      );

      if (print == null) {
        print = PrintData(
          id: newId(),
          name: printName,
          createdAt: d,
          updatedAt: d,
        );

        type.prints.add(print);
      }

      final reference =
          ReferenceData(
        id: newId(),
        referenceNumber:
            await Storage.nextReferenceNumber(
          groupId: group.id,
        ),
        createdAt: d,
        updatedAt: d,
      );

      print.references.add(reference);

      group.updatedAt = d;
      model.updatedAt = d;
      type.updatedAt = d;
      print.updatedAt = d;

      await Storage.saveGroups(groups);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ReferenceEditPage(
            cameras: widget.cameras,
            group: group!,
            model: model!,
            type: type!,
            print: print!,
            reference: reference,
          ),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถสร้างข้อมูลได้: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(
          () => saving = false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'สร้างข้อมูลอ้างอิง',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const PathBar(
            'หลวงปู่ / รุ่น / ชนิดพระ / รูปทรง',
          ),

          const SizedBox(height: 12),

          TextField(
            controller: groupController,
            decoration:
                const InputDecoration(
              labelText: 'ชื่อพระ / หลวงปู่',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: templeController,
            decoration:
                const InputDecoration(
              labelText: 'วัด',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedModelName,
            decoration:
                const InputDecoration(
              labelText: 'ชนิดพระ',
              border:
                  OutlineInputBorder(),
            ),
            items:
                standardModelNames.map(
              (name) {
                return DropdownMenuItem<
                    String>(
                  value: name,
                  child: Text(name),
                );
              },
            ).toList(),
            onChanged: saving
                ? null
                : (value) {
                    setState(() {
                      selectedModelName =
                          value;
                      selectedCoinShape =
                          null;
                    });
                  },
          ),

          const SizedBox(height: 12),

          TextField(
            controller: typeController,
            decoration:
                const InputDecoration(
              labelText: 'รุ่น',
              hintText: 'เช่น รุ่น 8',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          if (selectedModelName == 'เหรียญ') ...[
            DropdownButtonFormField<String>(
              value: selectedCoinShape,
              decoration:
                  const InputDecoration(
                labelText: 'รูปทรงเหรียญ',
                border:
                    OutlineInputBorder(),
              ),
              items:
                  coinShapeNames.map(
                (name) {
                  return DropdownMenuItem<
                      String>(
                    value: name,
                    child: Text(name),
                  );
                },
              ).toList(),
              onChanged: saving
                  ? null
                  : (value) {
                      setState(() {
                        selectedCoinShape =
                            value;
                      });
                    },
            ),

            if (selectedCoinShape == 'รูปไข่') ...[
              const SizedBox(height: 12),
              const OvalOutline(),
            ],
          ] else
            TextField(
              controller: printController,
              decoration:
                  const InputDecoration(
                labelText: 'รูปทรง',
                hintText:
                    'เช่น รูปไข่, ทรงเสมา',
                border:
                    OutlineInputBorder(),
              ),
            ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  saving ? null : create,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.add,
                    ),
              label: Text(
                saving
                    ? 'กำลังสร้าง...'
                    : 'สร้างข้อมูล',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// MODEL PAGE = ชนิดพระ
// =====================================================

class ModelPage extends StatefulWidget {
  final List cameras;
  final GroupData group;

  const ModelPage({
    super.key,
    required this.cameras,
    required this.group,
  });

  @override
  State createState() =>
      _ModelPageState();
}

class _ModelPageState
    extends State<ModelPage> {
  Future add() async {
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

  Future edit(ModelData m) async {
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

  Future delete(ModelData m) async {
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
                              title:
                                  Text(m.name),

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

// =====================================================
// TYPE PAGE = รุ่น
// =====================================================

class TypePage extends StatefulWidget {
  final List cameras;
  final GroupData group;
  final ModelData model;

  const TypePage({
    super.key,
    required this.cameras,
    required this.group,
    required this.model,
  });

  @override
  State createState() =>
      _TypePageState();
}

class _TypePageState
    extends State<TypePage> {
  Future add() async {
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

  Future edit(TypeData t) async {
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

  Future delete(TypeData t) async {
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
                     