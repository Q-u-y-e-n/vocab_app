import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vocab_provider.dart';
import '../widgets/flashcard_widget.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final vocabList = Provider.of<VocabProvider>(context).vocabList;

    // 1. Kiểm tra xem đang ở chế độ Tối hay Sáng
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. Định nghĩa màu chữ dựa trên chế độ (Trắng nếu tối, Đen nếu sáng)
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      // 3. Sử dụng màu nền theo Theme (để Dark Mode hoạt động đúng)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          "Flashcard",
          // Áp dụng màu chữ cho Tiêu đề
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Đổi màu nút Back (Mũi tên quay lại)
        iconTheme: IconThemeData(color: textColor),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                "${_currentIndex + 1}/${vocabList.length}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  // Áp dụng màu chữ cho số đếm
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: vocabList.isEmpty
          ? Center(
              child: Text(
                "Chưa có từ vựng nào để học.",
                style: TextStyle(color: textColor),
              ),
            )
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: LinearProgressIndicator(
                    value: (vocabList.isEmpty)
                        ? 0
                        : (_currentIndex + 1) / vocabList.length,
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[300],
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
