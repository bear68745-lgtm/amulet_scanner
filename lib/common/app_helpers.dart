import 'package:flutter/material.dart';

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
  Future Function(String) save,
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
          onPressed: () => Navigator.pop(context, false),
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
          content: Text('ต้องการลบ "$name" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ลบ'),
            ),
          ],
        ),
      ) ??
      false;
}
