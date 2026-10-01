import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../common/app_helpers.dart'
    show now, confirmDelete;
import '../common/path_bar.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  final Widget Function() createReferencePageBuilder;

  final Widget Function(GroupData group) modelPageBuilder;

  const HomePage({
    super.key,
    required this.cameras,
    required this.createReferencePageBuilder,
    required this.modelPageBuilder,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
        builder: (_) =>
            widget.createReferencePageBuilder(),
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
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
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

  int countReferences(GroupData g) =>
      g.models.fold(
        0,
        (a, m) =>
            a +
            m.types.fold(
              0,
              (b, t) =>
                  b +
                  t.prints.fold(
                    0,
                    (c, p) =>
                        c + p.references.length,
                  ),
            ),
      );

  int countScans(GroupData g) =>
      g.models.fold(
        0,
        (a, m) =>
            a +
            m.types.fold(
              0,
              (b, t) =>
                  b +
                  t.prints.fold(
                    0,
                    (c, p) =>
                        c +
                        p.references.fold(
                          0,
                          (d, r) =>
                              d + r.scans.length,
                        ),
                  ),
            ),
      );

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
        label: const Text('สร้างข้อมูล'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const PathBar('ฐานข้อมูลส่วนตัว'),
          Expanded(
            child: data.isEmpty
                ? const Center(
                    child: Text('ยังไม่มีข้อมูล'),
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
                                    widget
                                        .modelPageBuilder(
                                  g,
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

