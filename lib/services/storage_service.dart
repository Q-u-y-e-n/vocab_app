import 'dart:io';

class StorageService {
  // Xóa file ghi âm khỏi bộ nhớ máy khi xóa từ vựng
  Future<void> deleteAudioFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
