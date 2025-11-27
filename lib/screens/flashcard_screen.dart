import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vocab_provider.dart';
import '../widgets/flashcard_widget.dart'; // Import widget vừa tạo

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final PageController _pageController = PageController(
    viewportFraction: 0.85,
  ); // Hiển thị 1 phần thẻ sau
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách từ vựng từ Provider
    final vocabList = Provider.of<VocabProvider>(context).vocabList;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: const Text("Flashcard"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Hiển thị số lượng: 1/10
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                "${_currentIndex + 1}/${vocabList.length}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
      body: vocabList.isEmpty
          ? const Center(child: Text("Chưa có từ vựng nào để học."))
          : Column(
              children: [
                const SizedBox(height: 20),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: vocabList.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: FlashcardWidget(vocabulary: vocabList[index]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Thanh tiến trình
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: LinearProgressIndicator(
                    value: (vocabList.isEmpty)
                        ? 0
                        : (_currentIndex + 1) / vocabList.length,
                    backgroundColor: Colors.grey[300],
                    color: Colors.blueAccent,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}
