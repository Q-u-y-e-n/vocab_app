import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../models/vocabulary_model.dart';
import '../providers/settings_provider.dart';
import '../services/tts_service.dart';
import '../utils/string_utils.dart';

class FlashcardWidget extends StatefulWidget {
  final Vocabulary vocabulary;
  const FlashcardWidget({super.key, required this.vocabulary});

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final TtsService _tts = TtsService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
      _tts.speak(widget.vocabulary.word);
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: _animation.value < 0.5
                ? _buildFront()
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildBack(),
                  ),
          );
        },
      ),
    );
  }

  // --- HÀM VẼ BỌT BIỂN ĐẸP ---
  Widget _buildGlassBubble(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Gradient giúp bọt biển có chiều sâu 3D (Sáng -> Mờ dần)
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.2), // Điểm sáng
            Colors.white.withValues(alpha: 0.0), // Điểm trong suốt
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // Viền mỏng để bọt biển sắc nét hơn
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
    );
  }

  // --- MẶT TRƯỚC ---
  Widget _buildFront() {
    final settings = Provider.of<SettingsProvider>(context);
    final baseColor = settings.flashcardColor;

    return Container(
      width: double.infinity,
      height: 500,
      // ClipRect để cắt những phần bọt biển tràn ra ngoài
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        // Nền Gradient chính của thẻ
        gradient: LinearGradient(
          colors: [baseColor.withValues(alpha: 0.8), baseColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Bọt biển 1: To khổng lồ, góc trên phải
          Positioned(top: -80, right: -80, child: _buildGlassBubble(250)),

          // Bọt biển 2: Vừa, góc dưới trái
          Positioned(bottom: -50, left: -50, child: _buildGlassBubble(200)),

          // Bọt biển 3: Nhỏ, trôi lơ lửng ở giữa
          Positioned(top: 120, left: 40, child: _buildGlassBubble(40)),

          // Bọt biển 4: Nhỏ, góc dưới phải
          Positioned(bottom: 80, right: 40, child: _buildGlassBubble(20)),

          // Nội dung chính
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 40,
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.vocabulary.word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Chạm để lật",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MẶT SAU (Giữ nguyên cấu trúc sạch sẽ) ---
  Widget _buildBack() {
    String fullMeaning = widget.vocabulary.meaning;
    String phonetic = VocabParser.getPhonetic(fullMeaning);
    String vietnamese = VocabParser.getVietnamese(fullMeaning);
    String englishDef = fullMeaning;
    if (phonetic.isNotEmpty) englishDef = englishDef.replaceAll(phonetic, "");
    if (vietnamese.isNotEmpty) {
      englishDef = englishDef.split("🇻🇳").first.replaceAll("🇬🇧", "");
      englishDef = englishDef.trim();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      width: double.infinity,
      height: 500,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.vocabulary.word,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),

          if (phonetic.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                phonetic,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const Divider(height: 40, thickness: 1),

          Text(
            vietnamese,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 15),

          if (englishDef.isNotEmpty)
            Text(
              englishDef,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 25),

          if (widget.vocabulary.example.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.amber.withValues(alpha: 0.1)
                    : Colors.amber[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                  const SizedBox(height: 8),
                  Text(
                    widget.vocabulary.example,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

          const Spacer(),

          if (widget.vocabulary.audioPath != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.play_circle_fill),
              label: const Text("Ghi âm của bạn"),
              onPressed: () => _audioPlayer.play(
                DeviceFileSource(widget.vocabulary.audioPath!),
              ),
            ),
        ],
      ),
    );
  }
}
