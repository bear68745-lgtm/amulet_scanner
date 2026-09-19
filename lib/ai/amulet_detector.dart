class AmuletDetection{
  final bool found;
  final double confidence;
  final String message;

  const AmuletDetection({
    required this.found,
    this.confidence=0,
    this.message=''
  });
}

class AmuletDetector{
  bool ready=false;

  Future<void> initialize()async{
    // ขั้นต่อไปจะโหลดโมเดล TFLite ตรงนี้
    ready=false;
  }

  Future<AmuletDetection> detect(dynamic image)async{
    if(!ready){
      return const AmuletDetection(
        found:false,
        confidence:0,
        message:'ยังไม่มีโมเดลตรวจจับพระ'
      );
    }

    return const AmuletDetection(
      found:false,
      confidence:0,
      message:'ไม่พบพระในภาพ'
    );
  }

  Future<void> dispose()async{}
}
