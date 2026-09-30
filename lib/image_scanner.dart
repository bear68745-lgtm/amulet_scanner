import 'dart:io';

// =====================================================
// IMAGE SCANNER
// =====================================================
//
// หน้าที่:
// รับภาพชั่วคราว
// ตรวจสอบข้อมูลพื้นฐานของภาพ
// คืนข้อมูลที่ระบบอ่านได้
//
// ยังไม่ใช้ AI
// ยังไม่บันทึกภาพ
// ไม่ตัดสินแท้ / เก๊
// =====================================================

class ImageScanData {
  final String imagePath;

  final int width;
  final int height;

  final String format;

  const ImageScanData({
    required this.imagePath,
    required this.width,
    required this.height,
    required this.format,
  });

  Map<String, dynamic> toMap() {
    return {
      'imagePath': imagePath,
      'width': width,
      'height': height,
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

    final extension =
        imagePath.split('.').last.toLowerCase();

    return ImageScanData(
      imagePath: imagePath,
      width: 0,
      height: 0,
      format: extension,
    );
  }
}
