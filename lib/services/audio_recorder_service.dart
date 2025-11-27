import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<String?> startRecording() async {
    if (!await hasPermission()) return null;

    final directory = await getApplicationDocumentsDirectory();
    String filePath =
        '${directory.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

    // Sửa lại config cho record 5.x
    const config = RecordConfig();
    await _audioRecorder.start(config, path: filePath);
    return filePath;
  }

  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }
}
