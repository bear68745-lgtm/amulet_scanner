import 'dart:io';

import 'package:image/image.dart' as img;

// =====================================================
// IMAGE SCANNER
// =====================================================
//
// หน้าที่:
// รับภาพชั่วคราว
// อ่านข้อมูลพื้นฐานของภาพจริง
// คืนข้อมูลให้ระบบส่วนอื่นนำไปใช้
//
// ยังไม่ใช้ AI
// ยังไม่บันทึกภาพ
// ไม่ตัดสินแท้ / เก๊
// =====================================================

class ImageScanData {
  final String imagePath;

  final int width;
  final int height;

  final int fileSize;

  final String format;

  const ImageScanData({
    required this.imagePath,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.format,
  });

  Map<String, dynamic> toMap() {
    return {
      'imagePath': imagePath,
      'width': width,
      'height': height,
      'fileSize': fileSize,
      'format': format,
    };
  }
}

class ImageScanner {
  const ImageScanner();

  Future<ImageScanData> scan({
    required String imagePath,
  }) async {
    final file = File(imagePath);

    if (!await file.exists()) {
      throw Exception(
        'ไม่พบไฟล์ภาพชั่วคราว',
      );
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception(
        'ไฟล์ภาพว่าง',
      );
    }

    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception(
        'ไม่สามารถอ่านข้อมูลภาพได้',
      );
    }

    final extension =
        imagePath.split('.').last.toLowerCase();

    return ImageScanData(
      imagePath: imagePath,
      width: decoded.width,
      height: decoded.height,
      fileSize: bytes.length,
      format: extension,
    );
  }
}