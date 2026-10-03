import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../models.dart';
import '../../storage.dart';

import '../../data/coin_shapes.dart';
import '../../data/model_types.dart';

import '../../common/path_bar.dart';
import '../../common/app_helpers.dart'
    show firstWhereOrNull, now, newId;

import '../../drawings/coin_shape_outline.dart';
import 'reference_edit_page.dart';

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
  final typeController = TextEditingController();
  final printController = TextEditingController();

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

  Future<void> create() async {
    final groupName = groupController.text.trim();
    final temple = templeController.text.trim();
    final modelName = selectedModelName?.trim() ?? '';
    final typeName = typeController.text.trim();

    final printName =
        selectedModelName == 'เหรียญ'
            ? (selectedCoinShape?.trim() ?? '')
            : printController.text.trim();

    if ([groupName, modelName, typeName, printName]
        .any((e) => e.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบ'),
        ),
      );
      return;
    }

    if (saving) return;

    setState(() {
      saving = true;
    });

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
        (t) => t.name.trim() == typeName,
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
          coinShape:
              selectedModelName == 'เหรียญ'
                  ? (selectedCoinShape?.trim() ?? '')
                  : '',
          earType:
              selectedModelName == 'เหรียญ' &&
                      selectedCoinShape == 'รูปไข่'
                  ? 'integratedEar'
                  : '',
        );

        type.prints.add(print);
      }

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
        setState(() {
          saving = false;
        });
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
            decoration: const InputDecoration(
              labelText: 'ชื่อพระ / หลวงปู่',
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

          DropdownButtonFormField<String>(
            value: selectedModelName,
            decoration: const InputDecoration(
              labelText: 'ชนิดพระ',
              border: OutlineInputBorder(),
            ),
            items: standardModelNames.map(
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
                      selectedModelName = value;
                      selectedCoinShape = null;
                    });
                  },
          ),

          const SizedBox(height: 12),

          TextField(
            controller: typeController,
            decoration: const InputDecoration(
              labelText: 'รุ่น',
              hintText: 'เช่น รุ่น 8',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          if (selectedModelName == 'เหรียญ') ...[
            DropdownButtonFormField<String>(
              value: selectedCoinShape,
              decoration: const InputDecoration(
                labelText: 'รูปทรงเหรียญ',
                border: OutlineInputBorder(),
              ),
              items: coinShapeNames.map(
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
                        selectedCoinShape = value;
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
              decoration: const InputDecoration(
                labelText: 'รูปทรง',
                hintText: 'เช่น รูปไข่, ทรงเสมา',
                border: OutlineInputBorder(),
              ),
            ),

          const SizedBox(height: 20),

          SizedBox(
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
