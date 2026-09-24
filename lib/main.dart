import 'scan_page.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models.dart';
import 'scan_data.dart';
import 'storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> cameras = [];

  try {
    cameras = await availableCameras();
  } catch (_) {}

  runApp(App(cameras));
}

// =====================================================
// TYPE OPTIONS
// =====================================================

const typeOptions = [
  'เหรียญ',
  'เหรียญหล่อ',
  'พระสมเด็จ',
  'รูปหล่อ',
  'พระกริ่ง',
  'พระปิดตาเนื้อผง/หว้าน',
  'พระปิดตาเนื้อโลหะ',
  'พระเนื้อผง',
  'พระเนื้อดิน',
  'พระนางพญา',
  'ผงสุพรรณ',
  'พระรอด',
  'พระซุ้มกอ',
  'พระขุนแผน',
  'หลวงปู่ทวดเนื้อหว้าน',
  'หลวงปู่ทวดหลังเตารีด',
  'เขี้ยวแกะ',
  'งาแกะ',
  'ตะกรุด',
  'อื่น ๆ',
];

// =====================================================
// HELPERS
// =====================================================

T? firstWhereOrNull<T>(
  Iterable<T> list,
  bool Function(T) test,
) {
  for (final e in list) {
    if (test(e)) return e;
  }

  return null;
}

Future<String?> textDialog(
  BuildContext context,
  String title,
  String value,
  Future<void> Function(String) save,
) async {
  final c = TextEditingController(text: value);

  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () async {
            final v = c.text.trim();

            if (v.isEmpty) return;

            await save(v);

            if (context.mounted) {
              Navigator.pop(context, true);
            }
          },
          child: const Text('บันทึก'),
        ),
      ],
    ),
  );

  final result = ok == true ? c.text.trim() : null;

  c.dispose();

  return result;
}

Future<bool> confirmDelete(
  BuildContext context,
  String name,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text(
            'ต้องการลบ "$name" หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                false,
              ),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                true,
              ),
              child: const Text('ลบ'),
            ),
          ],
        ),
      ) ??
      false;
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
      ),
    );
  }
}

// =====================================================
// PATH BAR
// =====================================================

class PathBar extends StatelessWidget {
  final String text;

  const PathBar(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: Colors.brown.shade50,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
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
  State<CreateReferencePage> createState() =>
      _CreateReferencePageState();
}

class _CreateReferencePageState
    extends State<CreateReferencePage> {
  final groupController = TextEditingController();
  final templeController = TextEditingController();
  final modelController = TextEditingController();
  final printController = TextEditingController();

  String selectedType = typeOptions.first;
  bool saving = false;

  @override
  void dispose() {
    groupController.dispose();
    templeController.dispose();
    modelController.dispose();
    printController.dispose();
    super.dispose();
  }

  Future<void> create() async {
    final groupName = groupController.text.trim();
    final temple = templeController.text.trim();
    final modelName = modelController.text.trim();
    final printName = printController.text.trim();

    if ([
      groupName,
      temple,
      modelName,
      printName,
    ].any((e) => e.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณากรอกข้อมูลให้ครบทุกช่อง',
          ),
        ),
      );
      return;
    }

    if (saving) return;

    setState(() => saving = true);

    try {
      final groups = await Storage.groups();
      final d = now();

      GroupData? group = firstWhereOrNull(
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

      ModelData? model = firstWhereOrNull(
        group.models,
        (m) => m.name.trim() == modelName,
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

      TypeData? type = firstWhereOrNull(
        model.types,
        (t) => t.name.trim() == selectedType,
      );

      if (type == null) {
        type = TypeData(
          id: newId(),
          name: selectedType,
          createdAt: d,
          updatedAt: d,
        );

        model.types.add(type);
      }

      PrintData? print = firstWhereOrNull(
        type.prints,
        (p) => p.name.trim() == printName,
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

      // =================================================
      // แก้ไขแล้ว:
      // เลของค์อ้างอิงนับแยกตามกลุ่ม
      // =================================================

      final reference = ReferenceData(
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
          builder: (_) => ReferenceEditPage(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถสร้างข้อมูลได้: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'สร้างองค์อ้างอิง',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const PathBar(
            'กรอกข้อมูลเพื่อสร้างองค์อ้างอิง',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: groupController,
            decoration: const InputDecoration(
              labelText: 'ชื่อพระ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: templeController,
            decoration: const InputDecoration(
              labelText: 'วัด',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: modelController,
            decoration: const InputDecoration(
              labelText: 'รุ่น',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedType,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'ชนิด',
              border: OutlineInputBorder(),
            ),
            items: typeOptions
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  selectedType = v;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: printController,
            decoration: const InputDecoration(
              labelText: 'พิมพ์',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: saving ? null : create,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(
                saving
                    ? 'กำลังสร้าง...'
                    : 'สร้างองค์อ้างอิง',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// HOME
// =====================================================

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage({
    super.key,
    required this.cameras,
  });

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  List<GroupData> data = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    data = await Storage.groups();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> createGroup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReferencePage(
          cameras: widget.cameras,
        ),
      ),
    );

    if (mounted) {
      await load();
    }
  }

  Future<void> editGroup(GroupData g) async {
    final name = TextEditingController(
      text: g.name,
    );

    final temple = TextEditingController(
      text: g.temple,
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('แก้ไขกลุ่ม'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'ชื่อกลุ่ม',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: temple,
              decoration: const InputDecoration(
                labelText: 'วัด',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
            ),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              true,
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (ok == true &&
        name.text.trim().isNotEmpty) {
      g.name = name.text.trim();
      g.temple = temple.text.trim();
      g.updatedAt = now();

      await Storage.updateGroup(g);
      await load();
    }

    name.dispose();
    temple.dispose();
  }

  Future<void> deleteGroup(GroupData g) async {
    if (!await confirmDelete(
      context,
      g.name,
    )) {
      return;
    }

    await Storage.deleteGroup(g.id);
    await load();
  }

  int countReferences(GroupData g) {
    return g.models.fold(
      0,
      (a, m) => a +
          m.types.fold(
            0,
            (b, t) => b +
                t.prints.fold(
                  0,
                  (c, p) =>
                      c + p.references.length,
                ),
          ),
    );
  }

  int countScans(GroupData g) {
    return g.models.fold(
      0,
      (a, m) => a +
          m.types.fold(
            0,
            (b, t) => b +
                t.prints.fold(
                  0,
                  (c, p) => c +
                      p.references.fold(
                        0,
                        (d, r) =>
                            d + r.scans.length,
                      ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'กล้องสแกนพระและเหรียญ',
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: createGroup,
        label: const Text(
          'สร้างองค์อ้างอิง',
        ),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const PathBar(
            'ฐานข้อมูลส่วนตัว',
          ),
          Expanded(
            child: data.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีข้อมูล',
                    ),
                  )
                : ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (_, i) {
                      final g = data[i];

                      return Card(
                        margin:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          title: Text(
                            g.name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${g.temple.isEmpty ? '' : 'วัด ${g.temple}\n'}'
                            'องค์อ้างอิง ${countReferences(g)} • '
                            'สแกน ${countScans(g)}',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ModelPage(
                                  cameras:
                                      widget.cameras,
                                  group: g,
                                ),
                              ),
                            ).then(
                              (_) => load(),
                            );
                          },
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    editGroup(g),
                                icon: const Icon(
                                  Icons.edit,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    deleteGroup(g),
                                icon: const Icon(
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
// MODEL PAGE
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
      'เพิ่มรุ่น',
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
      'แก้ไขรุ่น',
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
        title: Text(widget.group.name),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: add,
        label: const Text('เพิ่มรุ่น'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          PathBar(
            '${widget.group.name} > รุ่น',
          ),
          Expanded(
            child: widget.group.models.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีรุ่น',
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
                          title: Text(m.name),
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
                                onPressed: () =>
                                    edit(m),
                                icon: const Icon(
                                  Icons.edit,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    delete(m),
                                icon: const Icon(
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
// TYPE PAGE
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
    String selected = typeOptions.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (c, set) =>
            AlertDialog(
          title: const Text(
            'เพิ่มชนิด',
          ),
          content:
              DropdownButtonFormField<String>(
            value: selected,
            isExpanded: true,
            items: typeOptions
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (v) {
              set(
                () => selected =
                    v ?? selected,
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(c),
              child:
                  const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                c,
                true,
              ),
              child:
                  const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      final d = now();

      widget.model.types.add(
        TypeData(
          id: newId(),
          name: selected,
          createdAt: d,
          updatedAt: d,
        ),
      );

      widget.group.updatedAt = d;

      await Storage.updateGroup(
        widget.group,
      );

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> edit(TypeData t) async {
    String selected = t.name;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (c, set) =>
            AlertDialog(
          title:
              const Text('แก้ไขชนิด'),
          content:
              DropdownButtonFormField<String>(
            value:
                typeOptions.contains(
              selected,
            )
                    ? selected
                    : typeOptions.first,
            isExpanded: true,
            items: typeOptions
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (v) {
              set(
                () => selected =
                    v ?? selected,
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(c),
              child:
                  const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                c,
                true,
              ),
              child:
                  const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );

    if (ok == true &&
        selected != t.name) {
      t.name = selected;
      t.updatedAt = now();
      widget.group.updatedAt = now();

      await Storage.updateGroup(
        widget.group,
      );
    }

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
        title: Text(widget.model.name),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: add,
        label: const Text('เพิ่มชนิด'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          PathBar(
            '${widget.group.name} > '
            '${widget.model.name} > ชนิด',
          ),
          Expanded(
            child: widget.model.types.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีชนิด',
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
                                onPressed: () =>
                                    edit(t),
                                icon:
                                    const Icon(
                                  Icons.edit,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    delete(t),
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
// PRINT PAGE
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
      'เพิ่มพิมพ์',
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
      'แก้ไขพิมพ์',
      p.name,
      (v) async {
        p.name = v;
        p.updatedAt = now();
        widget.type.updatedAt = now();
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
        title: Text(widget.type.name),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: add,
        label: const Text('เพิ่มพิมพ์'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          PathBar(
            '${widget.group.name} > '
            '${widget.model.name} > '
            '${widget.type.name} > พิมพ์',
          ),
          Expanded(
            child: widget.type.prints.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีพิมพ์',
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
                                onPressed: () =>
                                    edit(p),
                                icon:
                                    const Icon(
                                  Icons.edit,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    delete(p),
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
  State<ReferencePage> createState() =>
      _ReferencePageState();
}

class _ReferencePageState
    extends State<ReferencePage> {
  Future<void> addReference() async {
    // =================================================
    // แก้ไขแล้ว:
    // เลของค์อ้างอิงนับแยกตามกลุ่ม
    // =================================================

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
    final areas =
        scanAreasForType(
      widget.type.name,
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
        title: Text(widget.print.name),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addReference,
        label:
            const Text('เพิ่มองค์อ้างอิง'),
        icon: const Icon(Icons.add),
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
            child: widget
                    .print
                    .references
                    .isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีองค์อ้างอิง',
                    ),
                  )
                : ListView.builder(
                    itemCount: widget
                        .print
                        .references
                        .length,
                    itemBuilder: (_, i) {
                      final r = widget
                          .print
                          .references[i];

                      return Card(
                        margin:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child:
                            ExpansionTile(
                          title: Text(
                            'องค์อ้างอิง #'
                            '${r.referenceNumber}',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          subtitle:
                              Text(
                            status(r),
                          ),
                          children: [
                            ...scanAreasForType(
                              widget.type.name,
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
                                  MainAxisAlignment
                                      .end,
                              children: [
                                ElevatedButton
                                    .icon(
                                  onPressed: () =>
                                      editReference(
                                    r,
                                  ),
                                  icon:
                                      const Icon(
                                    Icons.edit,
                                  ),
                                  label:
                                      const Text(
                                    'ดูข้อมูล',
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                IconButton(
                                  onPressed: () =>
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

  final Map<String, List<AiTestResult>> results = {};

  ScanResult? getScan(String area) {
    return firstWhereOrNull(
      widget.reference.scans,
      (s) => s.area == area,
    );
  }

  // ===================================================
  // COMPARE ONE AREA
  // ===================================================

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

    if (comparing[area] == true) return;

    setState(() {
      comparing[area] = true;
    });

    try {
      // -----------------------------------------------
      // 1. นำข้อมูลปัจจุบันเข้า AI Memory
      // -----------------------------------------------

      await Storage.learnFromScan(
        groupId: widget.group.id,
        modelId: widget.model.id,
        typeId: widget.type.id,
        printId: widget.print.id,
        referenceId: widget.reference.id,
        area: area,
        content: scan.details,
      );

      // -----------------------------------------------
      // 2. เปรียบเทียบกับ AI Memory เดิม
      // -----------------------------------------------

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

      setState(() {
        results[area] = comparison;
      });

      // -----------------------------------------------
      // 3. แสดงผลกรณีไม่มี Memory อื่น
      // -----------------------------------------------

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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่สามารถเปรียบเทียบได้: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          comparing[area] = false;
        });
      }
    }
  }

  // ===================================================
  // RESULT CARD
  // ===================================================

  Widget resultCard(AiTestResult result) {
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
            Text(
              'เปรียบเทียบกับข้อมูลอ้างอิง',
              style: const TextStyle(
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

  // ===================================================
  // AREA CARD
  // ===================================================

  Widget areaCard(String area) {
    final scan = getScan(area);

    final hasData = scan != null &&
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
                if (hasData)
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
            ),
            const SizedBox(height: 8),

            // -----------------------------------------
            // SCAN DATA
            // -----------------------------------------

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

            // -----------------------------------------
            // AI RESULT
            // -----------------------------------------

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

  // ===================================================
  // BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {
    final areas = scanAreasForType(
      widget.type.name,
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
                  style: const TextStyle(
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
