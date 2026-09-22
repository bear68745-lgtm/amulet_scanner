import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const aiFields = [
  'พิมพ์ทรง',
  'องค์ประกอบ',
  'ลวดลาย',
  'ตำหนิที่มองเห็น',
  'ผิว',
  'ลักษณะเนื้อที่มองเห็น',
  'ขอบ/ด้านข้าง',
  'จุดสังเกต',
  'รายละเอียดอื่น',
  'สิ่งที่อ่านไม่ได้',
];

class AiVisionService {
  static const _channel = MethodChannel('amulet_ai');

  static Future<String> analyze({
    required String imagePath,
    required String area,
  }) async {
    final prompt = '''
คุณเป็น AI วิเคราะห์พระเครื่องจากภาพ

พื้นที่ที่กำลังตรวจ: $area

กฎสำคัญ:
1. บอกเฉพาะสิ่งที่มองเห็นจากภาพ
2. ห้ามเดารุ่น ปีสร้าง วัด หรือพิมพ์เฉพาะ หากภาพไม่แสดงข้อมูลนั้น
3. ห้ามตัดสินแท้หรือเก๊
4. ห้ามยืนยันชนิดโลหะหรือส่วนผสมทางวิทยาศาสตร์จากภาพเพียงอย่างเดียว
5. ถ้ามองไม่ชัด ให้เขียนว่า "ไม่สามารถระบุได้จากภาพ"
6. ร่องรอยสึก ห้ามสรุปเองว่าเกิดจากการใช้งาน ให้บอกเฉพาะลักษณะที่เห็น
7. ตอบเป็นภาษาไทย
8. ตอบตามหัวข้อด้านล่าง
9. แต่ละหัวข้อให้ตอบเป็นข้อความสั้น กระชับ แต่มีรายละเอียดที่มองเห็นได้
10. ห้ามสร้างข้อมูลที่ไม่มีในภาพ

ตอบตามรูปแบบนี้เท่านั้น:

พิมพ์ทรง: ...
องค์ประกอบ: ...
ลวดลาย: ...
ตำหนิที่มองเห็น: ...
ผิว: ...
ลักษณะเนื้อที่มองเห็น: ...
ขอบ/ด้านข้าง: ...
จุดสังเกต: ...
รายละเอียดอื่น: ...
สิ่งที่อ่านไม่ได้: ...
''';

    final result = await _channel.invokeMethod<String>(
      'analyzeImage',
      {
        'path': imagePath,
        'prompt': prompt,
      },
    );

    if (result == null || result.trim().isEmpty) {
      throw Exception('AI ไม่ได้ส่งผลวิเคราะห์กลับมา');
    }

    return result.trim();
  }
}

Map<String, String> parseAiResult(String text) {
  final result = <String, String>{};

  for (final field in aiFields) {
    final pattern = RegExp(
      '^${RegExp.escape(field)}\\s*:\\s*(.*)\$',
      multiLine: true,
    );

    final match = pattern.firstMatch(text);

    if (match != null) {
      result[field] = match.group(1)?.trim() ?? '';
    } else {
      result[field] = '';
    }
  }

  return result;
}

class AiVisionPage extends StatefulWidget {
  final String imagePath;
  final String area;
  final bool deleteImageAfter;

  const AiVisionPage({
    required this.imagePath,
    required this.area,
    this.deleteImageAfter = true,
    super.key,
  });

  @override
  State<AiVisionPage> createState() => _AiVisionPageState();
}

class _AiVisionPageState extends State<AiVisionPage> {
  bool loading = true;
  String? error;
  Map<String, String> fields = {};
  final Map<String, bool> selected = {};

  @override
  void initState() {
    super.initState();

    for (final f in aiFields) {
      selected[f] = true;
    }

    analyze();
  }

  Future<void> analyze() async {
    try {
      final text = await AiVisionService.analyze(
        imagePath: widget.imagePath,
        area: widget.area,
      );

      fields = parseAiResult(text);

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
    } finally {
      if (widget.deleteImageAfter) {
        try {
          await File(widget.imagePath).delete();
        } catch (_) {}
      }
    }
  }

  String selectedText() {
    final buffer = StringBuffer();

    for (final field in aiFields) {
      if (selected[field] == true) {
        final value = fields[field]?.trim() ?? '';

        if (value.isNotEmpty) {
          buffer.writeln('$field: $value');
        }
      }
    }

    return buffer.toString().trim();
  }

  Future<void> editField(String field) async {
    final controller = TextEditingController(
      text: fields[field] ?? '',
    );

    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('แก้ไข$field'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                controller.text.trim(),
              );
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value != null) {
      setState(() {
        fields[field] = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI วิเคราะห์${widget.area}'),
      ),
      body: loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI กำลังวิเคราะห์ภาพ...'),
                  SizedBox(height: 8),
                  Text(
                    'ครั้งแรกอาจใช้เวลานานเพราะต้องเตรียมโมเดล',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'วิเคราะห์ไม่สำเร็จ\n\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const Text(
                      'ตรวจสอบผล AI ก่อนบันทึก',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ติ๊กเฉพาะข้อมูลที่ต้องการเก็บ '
                      'และแก้ไขข้อความได้',
                    ),
                    const SizedBox(height: 12),

                    for (final field in aiFields)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              CheckboxListTile(
                                value: selected[field] ?? false,
                                onChanged: (v) {
                                  setState(() {
                                    selected[field] = v ?? false;
                                  });
                                },
                                title: Text(
                                  field,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    fields[field]?.isEmpty ?? true
                                        ? 'AI ไม่พบข้อมูลที่ระบุได้'
                                        : fields[field]!,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => editField(field),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('แก้ไข'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    FilledButton.icon(
                      onPressed: () {
                        final text = selectedText();

                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'กรุณาเลือกข้อมูลอย่างน้อย 1 หัวข้อ',
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(
                          context,
                          text,
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('บันทึกข้อมูลที่เลือก'),
                    ),
                  ],
                ),
    );
  }
}
