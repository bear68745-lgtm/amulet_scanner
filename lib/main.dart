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
        confirmDelete;

import 'common/path_bar.dart';
import 'drawings/coin_shape_outline.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> cameras = [];

  try {
    cameras = await availableCameras();
  } catch (_) {}

  runApp(App(cameras));
}

// =====================================================
// APP
// =====================================================

class App extends StatelessWidget {
  final List<CameraDescription> cameras;

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

      home: HomePage(
        cameras: cameras,

        createReferencePageBuilder: () {
          return CreateReferencePage(
            cameras: cameras,
          );
        },

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
  final List<CameraDescription> cameras;

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
                return DropdownMenuItem<String>(
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
                  return DropdownMenuItem<String>(
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

              const Text(
                'โครงร่างเหรียญ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const IntegratedEarOvalOutline(),
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
  final List<CameraDescription> cameras;
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
                      )
                    : ListView.builder(
                        itemCount:
                            widget.model.types.length,
                        itemBuilder: (_, i) {
                          final t =
                              widget.model.types[i];

                          return Card(
                            child: ListTile(
                              title:
                                  Text(t.name),

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
  State createState() =>
      _PrintPageState();
}

class _PrintPageState
    extends State<PrintPage> {
  Future add() async {
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

  Future edit(PrintData p) async {
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

  Future delete(PrintData p) async {
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
                              title:
                                  Text(p.name),

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
  State createState() =>
      _ReferencePageState();
}

class _ReferencePageState
    extends State<ReferencePage> {
  Future addReference() async {
    final n =
        await Storage.nextReferenceNumber(
      groupId: widget.group.id,
    );

    final d = now();

    final reference =
        ReferenceData(
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

  Future editReference(
    ReferenceData r,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReferenceEditPage(
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

  Future deleteReference(
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
    final areas =
        scanAreasForType(
      widget.model.name,
    );

    final done = areas
        .where(
          (a) => r.scans.any(
            (s) =>
                s.area == a &&
                s.details
                    .trim()
                    .isNotEmpty,
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

                              subtitle:
                                  Text(
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
                                          e.area ==
                                          a,
                                    );

                                    return ListTile(
                                      title:
                                          Text(a),
                                      subtitle:
                                          Text(
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
                                      onPressed:
                                          () =>
                                              editReference(
                                        r,
                                      ),
                                      icon:
                                          const Icon(
                                        Icons.edit,
                                      ),
                                      label:
                                          const Text(
                                        'แก้ไข',
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 8,
                                    ),

                                    IconButton(
                                      onPressed:
                                          () =>
                                              deleteReference(
                                        r,
                                      ),
                                      icon:
                                          const Icon(
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
            padding:
                const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.popUntil(
                  context,
                  (route) =>
                      route.isFirst,
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

// =====================================================
// REFERENCE EDIT / VIEW
// =====================================================

class ReferenceEditPage
    extends StatefulWidget {
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
  State createState() =>
      _ReferenceEditPageState();
}

class _ReferenceEditPageState
    extends State<ReferenceEditPage> {
  final Map<String, bool> comparing =
      {};

  final Map<String, List> results =
      {};

  ScanResult? getScan(String area) =>
      firstWhereOrNull(
        widget.reference.scans,
        (s) => s.area == area,
      );

  Future scanArea(String area) async {
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
      widget.reference.updatedAt =
          now();

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

  Future compareArea(String area) async {
    final scan = getScan(area);

    if (scan == null ||
        scan.details.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
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
        () => results[area] =
            comparison,
      );

      if (comparison.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'ด้าน $area ยังไม่มีองค์อ้างอิงอื่นให้เปรียบเทียบ',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
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
        padding:
            const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'เปรียบเทียบกับข้อมูลอ้างอิง',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Memory ID: '
              '${result.knowledgeId}',
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
                fontWeight:
                    FontWeight.bold,
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
    final scan =
        getScan(area);

    final hasData =
        scan != null &&
        scan.details.trim().isNotEmpty;

    final isComparing =
        comparing[area] == true;

    final areaResults =
        results[area] ?? [];

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    area,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: () =>
                      scanArea(area),
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
                style:
                    const TextStyle(
                  fontSize: 15,
                ),
              ),

            if (hasData) ...[
              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: isComparing
                    ? null
                    : () =>
                        compareArea(area),
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
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              ...areaResults.map(
                (result) =>
                    resultCard(result),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final areas =
        scanAreasForType(
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
              padding:
                  const EdgeInsets.all(10),
              children: [
                Text(
                  'องค์อ้างอิง #'
                  '${widget.reference.referenceNumber}',
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
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
                  (area) =>
                      areaCard(area),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}