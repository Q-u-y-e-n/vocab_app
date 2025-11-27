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
  final _autoExampleController = TextEditingController();
  final _customExampleController = TextEditingController();
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

  // --- CACHE (Tối ưu tốc độ) ---
  final Map<String, List<String>> _suggestionCache = {};

  @override
  void initState() {
    super.initState();
    if (widget.vocabulary != null) {
      _fillDataForEdit();
    }
  }

  void _fillDataForEdit() {
    final v = widget.vocabulary!;
    _wordController.text = v.word;
    _audioPath = v.audioPath;

    String fullMeaning = v.meaning;
    RegExp phoneticExp = RegExp(r'/.+/');
    Match? match = phoneticExp.firstMatch(fullMeaning);
    if (match != null) {
      _phonetic = match.group(0)!;
      fullMeaning = fullMeaning.replaceAll(_phonetic, "").trim();
    }

    if (fullMeaning.contains("🇻🇳")) {
      var parts = fullMeaning.split("🇻🇳");
      _vieDefController.text = parts.last.trim();
      String engPart = parts.first.replaceAll("🇬🇧", "").trim();
      _engDefController.text = engPart;
    } else {
      _engDefController.text = fullMeaning.replaceAll("🇬🇧", "").trim();
    }

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

  void _fetchDetails(String word) async {
    if (word.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final result = await _dictService.fetchWordDetails(word);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result != null) {
          _phonetic = result.phonetic;
          _engDefController.text = result.engMeaning;
          _vieDefController.text = result.vieMeaning;
          _autoExampleController.text = result.example;
        } else {
          _phonetic = "";
        }
      });
    }
  }

  void _playRecording() async {
    if (_audioPath != null) {
      try {
        setState(() => _isPlayingRecording = true);
        await _audioPlayer.play(DeviceFileSource(_audioPath!));
        _audioPlayer.onPlayerComplete.listen((event) {
          if (mounted) setState(() => _isPlayingRecording = false);
        });
      } catch (e) {
        print("Lỗi phát âm: $e");
        setState(() => _isPlayingRecording = false);
      }
    }
  }

  // --- UI COMPONENTS ---

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    required bool isDark,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: isDark ? Colors.blueAccent[100] : Colors.blueAccent,
      ),
      labelStyle: TextStyle(
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
      filled: true,
      fillColor: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.transparent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.vocabulary == null ? "Thêm Từ Mới" : "Sửa Từ Vựng",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- 1. TỪ VỰNG (THANH TÌM KIẾM ĐẸP & TỐI ƯU) ---
            _buildSectionCard(
              title: "TỪ VỰNG (ENGLISH)",
              isDark: isDark,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          // Hiệu ứng bóng đổ nhẹ cho thanh tìm kiếm
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.2 : 0.05,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TypeAheadField<String>(
                          controller: _wordController,
                          suggestionsController: _suggestionsController,
                          // TỐI ƯU 1: Debounce Duration (Đợi 500ms sau khi ngừng gõ mới gọi API)
                          debounceDuration: const Duration(milliseconds: 500),
                          // Hiệu ứng Animation khi hiện gợi ý
                          animationDuration: const Duration(milliseconds: 300),

                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                              decoration: InputDecoration(
                                hintText: "Nhập từ...",
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF2C2C2C)
                                    : const Color(0xFFF5F7FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.blueAccent,
                                ),
                                // Nút xóa nhanh
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        onPressed: () => controller.clear(),
                                      )
                                    : null,
                              ),
                            );
                          },

                          suggestionsCallback: (pattern) async {
                            if (pattern.trim().isEmpty) return [];
                            // TỐI ƯU 2: Caching (Kiểm tra xem đã tìm từ này chưa)
                            if (_suggestionCache.containsKey(pattern)) {
                              return _suggestionCache[pattern]!;
                            }
                            // Nếu chưa có cache, mới gọi API
                            var results = await _dictService.getSuggestions(
                              pattern,
                            );
                            _suggestionCache[pattern] =
                                results; // Lưu vào cache
                            return results;
                          },

                          itemBuilder: (context, suggestion) => ListTile(
                            leading: const Icon(
                              Icons.history,
                              size: 20,
                              color: Colors.grey,
                            ),
                            title: Text(
                              suggestion,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            tileColor: isDark
                                ? const Color(0xFF2C2C2C)
                                : Colors.white,
                          ),
                          onSelected: (suggestion) {
                            _wordController.text = suggestion;
                            _fetchDetails(suggestion);
                          },
                          decorationBuilder: (context, child) {
                            return Material(
                              type: MaterialType.card,
                              elevation: 8,
                              color: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              child: child,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    if (_isLoading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.volume_up_rounded,
                            color: Colors.orange,
                            size: 28,
                          ),
                          onPressed: () =>
                              _ttsService.speak(_wordController.text),
                        ),
                      ),
                  ],
                ),
                if (_phonetic.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      ),
                    ),
                    child: Text(
                      _phonetic,
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            // --- 2. ĐỊNH NGHĨA ---
            _buildSectionCard(
              title: "ĐỊNH NGHĨA",
              isDark: isDark,
              children: [
                TextField(
                  controller: _engDefController,
                  maxLines: null,
                  style: TextStyle(color: textColor),
                  decoration: _buildInputDecoration(
                    label: "Định nghĩa (English)",
                    icon: Icons.flag_circle,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _vieDefController,
                  maxLines: null,
                  style: TextStyle(color: textColor),
                  decoration: _buildInputDecoration(
                    label: "Nghĩa Tiếng Việt",
                    icon: Icons.translate,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            // --- 3. CÂU VÍ DỤ ---
            _buildSectionCard(
              title: "CÂU VÍ DỤ",
              isDark: isDark,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _autoExampleController,
                        maxLines: null,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: "Ví dụ gợi ý (Tự động)",
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.amber[200]
                                : Colors.amber[800],
                          ),
                          border: InputBorder.none,
                          icon: const Icon(
                            Icons.smart_toy_outlined,
                            color: Colors.amber,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.volume_up_rounded,
                        color: isDark ? Colors.grey[400] : Colors.grey,
                      ),
                      onPressed: () =>
                          _ttsService.speak(_autoExampleController.text),
                    ),
                  ],
                ),
                Divider(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  thickness: 1,
                  height: 30,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customExampleController,
                        maxLines: null,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: "Ví dụ của bạn (Thêm)",
                          hintText: "Tự đặt câu ví dụ...",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.green[200]
                                : Colors.green[800],
                          ),
                          border: InputBorder.none,
                          icon: const Icon(
                            Icons.edit_note,
                            color: Colors.green,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.volume_up_rounded,
                        color: isDark ? Colors.grey[400] : Colors.grey,
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
              title: "LUYỆN NÓI",
              isDark: isDark,
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
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
                                      ? (isDark
                                            ? Colors.grey[800]
                                            : Colors.white)
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
                      const SizedBox(height: 12),
                      Text(
                        _isRecording
                            ? "Đang ghi âm..."
                            : (_audioPath == null
                                  ? "Nhấn mic để bắt đầu"
                                  : "Nhấn mic để ghi lại"),
                        style: TextStyle(
                          color: _isRecording
                              ? Colors.red
                              : (isDark ? Colors.grey[400] : Colors.grey),
                          fontWeight: _isRecording
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_audioPath != null && !_isRecording)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.blueAccent.withOpacity(0.1)
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.blueAccent.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _playRecording,
                          icon: Icon(
                            _isPlayingRecording
                                ? Icons.volume_up
                                : Icons.play_circle_fill,
                            color: Colors.blueAccent,
                            size: 32,
                          ),
                        ),
                        Text(
                          "Nghe lại bản ghi",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.blue[200] : Colors.blueGrey,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _audioPath = null),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _saveVocabulary,
                child: Text(
                  widget.vocabulary == null ? "LƯU TỪ VỰNG" : "CẬP NHẬT",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _saveVocabulary() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;
    if (_wordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng nhập từ vựng")));
      return;
    }

    String finalMeaning = "";
    if (_phonetic.isNotEmpty) finalMeaning += "$_phonetic\n";
    if (_engDefController.text.isNotEmpty)
      finalMeaning += "🇬🇧 ${_engDefController.text}\n";
    if (_vieDefController.text.isNotEmpty)
      finalMeaning += "🇻🇳 ${_vieDefController.text}";

    String finalExample = _autoExampleController.text.trim();
    if (_customExampleController.text.trim().isNotEmpty) {
      if (finalExample.isNotEmpty) finalExample += "\n\n";
      finalExample += "✍️ ${_customExampleController.text.trim()}";
    }

    final newVocab = Vocabulary(
      id: widget.vocabulary?.id,
      userId: user.id!,
      topicId: widget.vocabulary?.topicId,
      isFavorite: widget.vocabulary?.isFavorite ?? false,
      word: _wordController.text.trim(),
      meaning: finalMeaning.trim(),
      example: finalExample,
      audioPath: _audioPath,
    );

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
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Thành công!")));
    }
  }
}
