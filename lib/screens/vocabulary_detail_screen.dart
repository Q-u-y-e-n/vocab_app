import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:vocab_app/services/tts_service.dart';
import '../models/vocabulary_model.dart';
import '../utils/string_utils.dart'; // Import để tách phiên âm
import 'add_word_screen.dart';

class VocabularyDetailScreen extends StatelessWidget {
  final Vocabulary vocabulary;

  const VocabularyDetailScreen({super.key, required this.vocabulary});

  @override
  Widget build(BuildContext context) {
    final tts = TtsService();
    final audioPlayer = AudioPlayer();

    // 1. Theme Logic
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    // 2. Tách dữ liệu (Phiên âm, Nghĩa)
    String fullMeaning = vocabulary.meaning;
    String phonetic = VocabParser.getPhonetic(fullMeaning);
    // Loại bỏ phiên âm khỏi chuỗi nghĩa để hiển thị sạch sẽ hơn
    if (phonetic.isNotEmpty) {
      fullMeaning = fullMeaning.replaceAll(phonetic, "").trim();
    }

    return Scaffold(
      backgroundColor: bgColor,
      // AppBar trong suốt để tôn lên Hero Card
      appBar: AppBar(
        title: const Text(
          "Chi Tiết",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: textColor,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddWordScreen(vocabulary: vocabulary),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. HERO CARD (TỪ VỰNG CHÍNH) ---
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                // Gradient nền xanh -> Nút trắng sẽ nổi bật
                gradient: const LinearGradient(
                  colors: [Color(0xFF0061ff), Color(0xFF60efff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Họa tiết trang trí
                  Positioned(
                    top: -20,
                    right: -20,
                    child: _buildDecorationCircle(100),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -20,
                    child: _buildDecorationCircle(80),
                  ),

                  // Nội dung chính
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          vocabulary.word,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (phonetic.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                phonetic,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Nút Loa (Đặt nổi ở góc dưới phải của Card)
                  Positioned(
                    bottom: 15,
                    right: 15,
                    child: FloatingActionButton.small(
                      heroTag: "speak_btn",
                      backgroundColor: Colors.white,
                      elevation: 4,
                      onPressed: () => tts.speak(vocabulary.word),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 2. ĐỊNH NGHĨA (Giao diện sạch) ---
            _buildSectionHeader(
              "Định nghĩa",
              Icons.menu_book_rounded,
              Colors.orange,
            ),
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 25),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                fullMeaning,
                style: TextStyle(fontSize: 18, height: 1.6, color: textColor),
              ),
            ),

            // --- 3. VÍ DỤ ---
            if (vocabulary.example.isNotEmpty) ...[
              Row(
                children: [
                  _buildSectionHeader(
                    "Ví dụ minh họa",
                    Icons.lightbulb_rounded,
                    Colors.amber,
                  ),
                  const Spacer(),
                  // Nút loa nhỏ cho ví dụ
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, size: 20),
                    color: subTextColor,
                    onPressed: () => tts.speak(vocabulary.example),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 5, bottom: 25),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.amber.withValues(alpha: 0.1)
                      : Colors.amber[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  vocabulary.example,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.amber[100] : Colors.grey[800],
                  ),
                ),
              ),
            ],

            // --- 4. AUDIO PLAYER (GHI ÂM CỦA BẠN) ---
            if (vocabulary.audioPath != null) ...[
              _buildSectionHeader(
                "Ghi âm của bạn",
                Icons.mic_rounded,
                Colors.redAccent,
              ),
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(
                    50,
                  ), // Bo tròn như viên thuốc
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    // Nút Play to rõ
                    GestureDetector(
                      onTap: () => audioPlayer.play(
                        DeviceFileSource(vocabulary.audioPath!),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.green, // Nền xanh lá
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Waveform giả lập (cho đẹp)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Click để nghe lại",
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget tiêu đề section
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  // Widget hình tròn trang trí cho Hero Card
  Widget _buildDecorationCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }
}
