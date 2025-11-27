import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:vocab_app/services/tts_service.dart';
import '../models/vocabulary_model.dart';
import 'add_word_screen.dart';

class VocabularyDetailScreen extends StatelessWidget {
  final Vocabulary vocabulary;

  const VocabularyDetailScreen({super.key, required this.vocabulary});

  @override
  Widget build(BuildContext context) {
    final tts = TtsService();
    final audioPlayer = AudioPlayer();

    // 1. Xác định chế độ Tối/Sáng
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. Định nghĩa bộ màu sắc
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    // Thêm dấu chấm than ! vào sau [400]
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Chi Tiết Từ Vựng",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor), // Đổi màu nút Back
        actions: [
          // Nút Sửa
          IconButton(
            icon: const Icon(Icons.edit),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CARD 1: TỪ VỰNG CHÍNH ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    vocabulary.word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueAccent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        size: 36,
                        color: Colors.orange,
                      ),
                      onPressed: () => tts.speak(vocabulary.word),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- CARD 2: NGHĨA ---
            _buildInfoCard(
              title: "Định nghĩa & Phiên âm",
              content: vocabulary.meaning,
              icon: Icons.menu_book,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            // --- CARD 3: VÍ DỤ ---
            if (vocabulary.example.isNotEmpty)
              _buildInfoCard(
                title: "Ví dụ minh họa",
                content: vocabulary.example,
                icon: Icons.lightbulb,
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                subTextColor: subTextColor,
                onSpeak: () => tts.speak(vocabulary.example),
              ),

            // --- CARD 4: GHI ÂM ---
            if (vocabulary.audioPath != null)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.redAccent),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Ghi âm của bạn",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.play_circle_fill,
                        size: 40,
                        color: Colors.green,
                      ),
                      onPressed: () => audioPlayer.play(
                        DeviceFileSource(vocabulary.audioPath!),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget con tái sử dụng
  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    VoidCallback? onSpeak,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
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
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: subTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              if (onSpeak != null) ...[
                const Spacer(),
                InkWell(
                  onTap: onSpeak,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: subTextColor,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Divider(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            height: 24,
          ),
          Text(
            content,
            style: TextStyle(
              fontSize: 17,
              height: 1.6,
              color: textColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
