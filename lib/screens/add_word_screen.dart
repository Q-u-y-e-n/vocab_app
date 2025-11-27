import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../models/vocabulary_model.dart';
import '../providers/auth_provider.dart';
import '../providers/vocab_provider.dart';
import '../services/audio_recorder_service.dart';
import '../services/dictionary_service.dart';
import '../services/tts_service.dart';

class AddWordScreen extends StatefulWidget {
  // Tham số nhận dữ liệu khi muốn Sửa (null nếu là Thêm mới)
  final Vocabulary? vocabulary;

  const AddWordScreen({super.key, this.vocabulary});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  // --- CONTROLLERS ---
  final _wordController = TextEditingController();
  final _engDefController = TextEditingController();
  final _vieDefController = TextEditingController();

  // Tách biệt 2 loại ví dụ
  final _autoExampleController = TextEditingController(); // Ví dụ từ API
  final _customExampleController = TextEditingController(); // Ví dụ tự viết

  // QUAN TRỌNG: Khai báo rõ kiểu <String> để tránh lỗi Type Mismatch
  final SuggestionsController<String> _suggestionsController =
      SuggestionsController<String>();

  // --- SERVICES ---
  final DictionaryService _dictService = DictionaryService();
  final AudioRecorderService _recordService = AudioRecorderService();
  final TtsService _ttsService = TtsService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- STATE ---
  bool _isLoading = false;
  String _phonetic = "";
  String? _audioPath;
  bool _isRecording = false;
  bool _isPlayingRecording = false;

  @override
  void initState() {
    super.initState();
    // Nếu có dữ liệu truyền vào (Chế độ Sửa) -> Điền sẵn vào các ô
    if (widget.vocabulary != null) {
      _fillDataForEdit();
    }
  }

  // Hàm tách dữ liệu từ Database để điền vào form khi Sửa
  void _fillDataForEdit() {
    final v = widget.vocabulary!;
    _wordController.text = v.word;
    _audioPath = v.audioPath;

    // 1. Xử lý Nghĩa (Format lưu trữ: /phonetic/\n🇬🇧 Eng\n🇻🇳 Vie)
    String fullMeaning = v.meaning;

    // Tách Phiên âm
    RegExp phoneticExp = RegExp(r'/.+/');
    Match? match = phoneticExp.firstMatch(fullMeaning);
    if (match != null) {
      _phonetic = match.group(0)!;
      fullMeaning = fullMeaning.replaceAll(_phonetic, "").trim();
    }

    // Tách Anh - Việt
    if (fullMeaning.contains("🇻🇳")) {
      var parts = fullMeaning.split("🇻🇳");
      _vieDefController.text = parts.last.trim();
      String engPart = parts.first.replaceAll("🇬🇧", "").trim();
      _engDefController.text = engPart;
    } else {
      _engDefController.text = fullMeaning.replaceAll("🇬🇧", "").trim();
    }

    // 2. Xử lý Ví dụ (Format lưu trữ: Auto \n\n ✍️ Custom)
    String fullExample = v.example;
    if (fullExample.contains("✍️")) {
      var exParts = fullExample.split("✍️");
      _autoExampleController.text = exParts.first.trim();
      _customExampleController.text = exParts.last.trim();
    } else {
      _autoExampleController.text = fullExample;
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _engDefController.dispose();
    _vieDefController.dispose();
    _autoExampleController.dispose();
    _customExampleController.dispose();
    _suggestionsController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Hàm gọi API lấy chi tiết từ vựng
  void _fetchDetails(String word) async {
    if (word.isEmpty) return;
    FocusScope.of(context).unfocus(); // Ẩn bàn phím
    setState(() => _isLoading = true);

    final result = await _dictService.fetchWordDetails(word);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result != null) {
          _phonetic = result.phonetic;
          _engDefController.text = result.engMeaning;
          _vieDefController.text = result.vieMeaning;
          _autoExampleController.text = result.example; // Điền ví dụ tự động
        } else {
          _phonetic = ""; // Không tìm thấy
        }
      });
    }
  }

  // Hàm nghe lại ghi âm
  void _playRecording() async {
    if (_audioPath != null) {
      try {
        setState(() => _isPlayingRecording = true);
        await _audioPlayer.play(DeviceFileSource(_audioPath!));
        _audioPlayer.onPlayerComplete.listen((event) {
          if (mounted) setState(() => _isPlayingRecording = false);
        });
      } catch (e) {
        print("Lỗi phát âm thanh: $e");
        setState(() => _isPlayingRecording = false);
      }
    }
  }

  // Widget khung Card UI (Helper)
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 15),
            ],
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: Text(
          widget.vocabulary == null ? "Thêm Từ Mới" : "Sửa Từ Vựng",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- 1. TỪ VỰNG (Autocomplete) ---
            _buildSectionCard(
              title: "TỪ VỰNG (ENGLISH)",
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TypeAheadField<String>(
                        controller: _wordController,
                        suggestionsController: _suggestionsController,
                        builder: (context, controller, focusNode) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.blueAccent,
                            ),
                            decoration: const InputDecoration(
                              hintText: "Nhập từ...",
                              border: InputBorder.none,
                            ),
                          );
                        },
                        suggestionsCallback: (pattern) async =>
                            await _dictService.getSuggestions(pattern),
                        itemBuilder: (context, suggestion) => ListTile(
                          leading: const Icon(Icons.search, size: 18),
                          title: Text(suggestion),
                          dense: true,
                        ),
                        onSelected: (suggestion) {
                          _wordController.text = suggestion;
                          _fetchDetails(suggestion);
                        },
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(
                          Icons.volume_up_rounded,
                          color: Colors.orange,
                          size: 32,
                        ),
                        onPressed: () =>
                            _ttsService.speak(_wordController.text),
                      ),
                  ],
                ),
                if (_phonetic.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _phonetic,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),

            // --- 2. ĐỊNH NGHĨA ---
            _buildSectionCard(
              title: "ĐỊNH NGHĨA",
              children: [
                TextField(
                  controller: _engDefController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: "Định nghĩa (English)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag_circle, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _vieDefController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: "Nghĩa Tiếng Việt",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.translate, color: Colors.red),
                  ),
                ),
              ],
            ),

            // --- 3. VÍ DỤ ---
            _buildSectionCard(
              title: "CÂU VÍ DỤ",
              children: [
                // Ví dụ tự động (Auto)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _autoExampleController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          labelText: "Ví dụ gợi ý (Tự động)",
                          border: InputBorder.none,
                          icon: Icon(
                            Icons.smart_toy_outlined,
                            color: Colors.amber,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          _ttsService.speak(_autoExampleController.text),
                    ),
                  ],
                ),
                const Divider(height: 30, thickness: 1),
                // Ví dụ thủ công (Custom)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customExampleController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          labelText: "Ví dụ của bạn (Thêm)",
                          hintText: "Tự đặt câu ví dụ...",
                          border: InputBorder.none,
                          icon: Icon(
                            Icons.edit_note,
                            color: Colors.green,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          _ttsService.speak(_customExampleController.text),
                    ),
                  ],
                ),
              ],
            ),

            // --- 4. GHI ÂM ---
            _buildSectionCard(
              title: "LUYỆN NÓI (GHI ÂM)",
              children: [
                Column(
                  children: [
                    // Nút Mic
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          if (_isRecording) {
                            String? path = await _recordService.stopRecording();
                            setState(() {
                              _isRecording = false;
                              _audioPath = path;
                            });
                          } else {
                            String? path = await _recordService
                                .startRecording();
                            if (path != null)
                              setState(() => _isRecording = true);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? Colors.redAccent
                                : (_audioPath != null
                                      ? Colors.white
                                      : Colors.blueAccent),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isRecording
                                  ? Colors.red
                                  : Colors.blueAccent,
                              width: 3,
                            ),
                            boxShadow: [
                              if (_isRecording)
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                            ],
                          ),
                          child: Icon(
                            _isRecording
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            color: _isRecording
                                ? Colors.white
                                : (_audioPath != null
                                      ? Colors.blueAccent
                                      : Colors.white),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Trạng thái text (Đã sửa lỗi TextAlign)
                    Text(
                      _isRecording
                          ? "Đang ghi âm..."
                          : (_audioPath == null
                                ? "Nhấn mic để bắt đầu"
                                : "Nhấn mic để ghi âm lại"),
                      style: TextStyle(
                        color: _isRecording ? Colors.red : Colors.grey,
                        fontWeight: _isRecording
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center, // Sử dụng đúng TextAlign
                    ),

                    // Khung Nghe lại
                    if (_audioPath != null && !_isRecording) ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _playRecording,
                              icon: Icon(
                                _isPlayingRecording
                                    ? Icons.volume_up
                                    : Icons.play_circle_fill,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                "Nghe lại ghi âm",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _audioPath = null),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- NÚT LƯU ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                onPressed: _saveVocabulary,
                child: Text(
                  widget.vocabulary == null
                      ? "LƯU TỪ VỰNG"
                      : "CẬP NHẬT TỪ VỰNG",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- LOGIC LƯU VÀO DB ---
  void _saveVocabulary() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    if (_wordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng nhập từ vựng")));
      return;
    }

    // 1. Ghép chuỗi Nghĩa
    String finalMeaning = "";
    if (_phonetic.isNotEmpty) finalMeaning += "$_phonetic\n";
    if (_engDefController.text.isNotEmpty)
      finalMeaning += "🇬🇧 ${_engDefController.text}\n";
    if (_vieDefController.text.isNotEmpty)
      finalMeaning += "🇻🇳 ${_vieDefController.text}";

    // 2. Ghép chuỗi Ví dụ
    String finalExample = _autoExampleController.text.trim();
    if (_customExampleController.text.trim().isNotEmpty) {
      if (finalExample.isNotEmpty) finalExample += "\n\n";
      finalExample += "✍️ ${_customExampleController.text.trim()}";
    }

    final newVocab = Vocabulary(
      id: widget.vocabulary?.id, // Giữ ID nếu đang sửa
      userId: user.id!,
      // Giữ lại các thông tin cũ (Topic, Favorite) nếu đang sửa
      topicId: widget.vocabulary?.topicId,
      isFavorite: widget.vocabulary?.isFavorite ?? false,

      word: _wordController.text.trim(),
      meaning: finalMeaning.trim(),
      example: finalExample,
      audioPath: _audioPath,
    );

    // Gọi Provider
    if (widget.vocabulary == null) {
      await Provider.of<VocabProvider>(
        context,
        listen: false,
      ).addVocabulary(newVocab);
    } else {
      await Provider.of<VocabProvider>(
        context,
        listen: false,
      ).updateVocabulary(newVocab);
    }

    if (mounted) {
      Navigator.pop(context); // Quay về
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Thao tác thành công!")));
    }
  }
}
