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

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: const Text("Chi Tiết Từ Vựng"),
        centerTitle: true,
        actions: [
          // Nút Sửa
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushReplacement(
                // Dùng pushReplacement để khi sửa xong quay lại Home load lại
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
            // Card Từ vựng chính
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    vocabulary.word,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up_rounded,
                      size: 40,
                      color: Colors.orange,
                    ),
                    onPressed: () => tts.speak(vocabulary.word),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card Nghĩa
            _buildInfoCard(
              title: "Định nghĩa & Phiên âm",
              content: vocabulary.meaning,
              icon: Icons.menu_book,
            ),

            // Card Ví dụ
            if (vocabulary.example.isNotEmpty)
              _buildInfoCard(
                title: "Ví dụ minh họa",
                content: vocabulary.example,
                icon: Icons.lightbulb,
                onSpeak: () => tts.speak(vocabulary.example),
              ),

            // Card Ghi âm cá nhân
            if (vocabulary.audioPath != null)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.mic, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Ghi âm của bạn",
                      style: TextStyle(fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    VoidCallback? onSpeak,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onSpeak != null) ...[
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.blueGrey),
                  onPressed: onSpeak,
                ),
              ],
            ],
          ),
          const Divider(),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }
}
