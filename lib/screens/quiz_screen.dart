import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vocab_provider.dart';
import '../models/quiz_question.dart';
import '../services/quiz_service.dart';
import '../services/tts_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();
  final TtsService _tts = TtsService();

  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;

  bool _isAnswered = false;
  bool? _isCorrect;
  String? _selectedOption;

  List<String> _userSpelling = [];
  List<String> _poolLetters = [];
  List<int> _selectedIndices = [];

  @override
  void initState() {
    super.initState();
    final allVocabs = Provider.of<VocabProvider>(
      context,
      listen: false,
    ).vocabList;
    _questions = _quizService.generateQuiz(allVocabs);
    _initQuestionData();
  }

  void _initQuestionData() {
    if (_questions.isEmpty) return;

    _isAnswered = false;
    _isCorrect = null;
    _selectedOption = null;

    if (_questions[_currentIndex].type == QuizType.spelling) {
      _userSpelling = [];
      _selectedIndices = [];
      _poolLetters = List.from(_questions[_currentIndex].options);
    }
  }

  void _finishTurn(bool correct) {
    // 1. Đọc tiếng Anh
    final question = _questions[_currentIndex];
    String textToSpeak = question.type == QuizType.multipleChoice
        ? question.questionText
        : question.correctAnswer;
    _tts.speak(textToSpeak);

    if (correct) _score++;

    // 2. Cập nhật giao diện (Kích hoạt Animation màu sắc)
    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });

    // 3. Đợi lâu hơn (2.5 giây) để người dùng kịp nhìn kết quả
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        if (_currentIndex < _questions.length - 1) {
          setState(() {
            _currentIndex++;
            _initQuestionData();
          });
        } else {
          _showResultDialog();
        }
      }
    });
  }

  // --- CÁC HÀM XỬ LÝ SỰ KIỆN ---
  void _handleMultipleChoice(String option) {
    if (_isAnswered) return;
    _selectedOption = option;
    bool correct = option == _questions[_currentIndex].correctAnswer;
    _finishTurn(correct);
  }

  void _onLetterTap(int index, String char) {
    if (_isAnswered || _selectedIndices.contains(index)) return;

    setState(() {
      _userSpelling.add(char);
      _selectedIndices.add(index);
    });

    if (_userSpelling.length ==
        _questions[_currentIndex].correctAnswer.length) {
      String result = _userSpelling.join();
      bool correct =
          result.toLowerCase() ==
          _questions[_currentIndex].correctAnswer.toLowerCase();
      _finishTurn(correct);
    }
  }

  void _onSlotTap(int indexInUserList) {
    if (_isAnswered) return;
    setState(() {
      _userSpelling.removeAt(indexInUserList);
      _selectedIndices.removeAt(indexInUserList);
    });
  }

  void _showResultDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Kết Quả",
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _score > _questions.length / 2
                  ? Icons.emoji_events
                  : Icons.sentiment_dissatisfied,
              size: 60,
              color: _score > _questions.length / 2
                  ? Colors.amber
                  : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              "Bạn đúng $_score / ${_questions.length} câu",
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Thoát"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final allVocabs = Provider.of<VocabProvider>(
                  context,
                  listen: false,
                ).vocabList;
                _questions = _quizService.generateQuiz(allVocabs);
                _currentIndex = 0;
                _score = 0;
                _initQuestionData();
              });
            },
            child: const Text("Làm lại"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty)
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Cần ít nhất 4 từ vựng.")),
      );

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Câu hỏi ${_currentIndex + 1}/${_questions.length}",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          // Thanh tiến trình mượt mà
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            tween: Tween<double>(begin: 0, end: progress),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
              color: Colors.blueAccent,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  // --- KHUNG CÂU HỎI ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          question.type == QuizType.multipleChoice
                              ? "Từ này nghĩa là gì?"
                              : (question.type == QuizType.spelling
                                    ? "Ghép từ vào chỗ trống:"
                                    : "Điền từ vào chỗ trống:"),
                          style: TextStyle(color: subTextColor, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          question.questionText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueAccent,
                            height: 1.4,
                          ),
                        ),
                        // Giải thích hiện ra từ từ
                        if (_isAnswered)
                          AnimatedOpacity(
                            opacity: _isAnswered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            child: Container(
                              margin: const EdgeInsets.only(top: 20),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCorrect == true
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                question.explanation ?? "",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                  color: isCorrect == true
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // --- PHẦN TRẢ LỜI ---
                  if (question.type == QuizType.spelling)
                    _buildSpellingInterface(isDark)
                  else
                    _buildOptionsList(question, isDark),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. GIAO DIỆN TRẮC NGHIỆM & ĐIỀN TỪ ---
  Widget _buildOptionsList(QuizQuestion question, bool isDark) {
    return Column(
      children: question.options.map((option) {
        bool isCorrectAnswer = option == question.correctAnswer;
        bool isSelected = option == _selectedOption;

        Color bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
        Color borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
        Color textColor = isDark ? Colors.white : Colors.grey[800]!;
        IconData? icon;

        if (_isAnswered) {
          if (isCorrectAnswer) {
            bgColor = Colors.green.withOpacity(0.2); // Xanh nhạt nền
            borderColor = Colors.green; // Viền xanh đậm
            textColor = Colors.green[800]!; // Chữ xanh đậm (để dễ đọc)
            if (isDark)
              textColor = Colors.greenAccent; // Chữ sáng hơn trong Dark Mode
            icon = Icons.check_circle;
          } else if (isSelected) {
            bgColor = Colors.red.withOpacity(0.2); // Đỏ nhạt nền
            borderColor = Colors.red; // Viền đỏ đậm
            textColor = Colors.red[900]!; // Chữ đỏ đậm (để không bị chìm)
            if (isDark) textColor = Colors.redAccent;
            icon = Icons.cancel;
          }
        }

        return GestureDetector(
          onTap: () => _handleMultipleChoice(option),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 500,
            ), // Chuyển màu chậm rãi (500ms)
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, color: borderColor),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- 2. GIAO DIỆN GHÉP TỪ (SPELLING) ---
  Widget _buildSpellingInterface(bool isDark) {
    return Column(
      children: [
        // Ô điền kết quả
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_userSpelling.length + 1, (index) {
            if (index >= _userSpelling.length &&
                _userSpelling.length <
                    _questions[_currentIndex].correctAnswer.length) {
              return _buildSlotBox("", isEmpty: true, isDark: isDark);
            }
            if (index >= _userSpelling.length) return const SizedBox();
            return GestureDetector(
              onTap: () => _onSlotTap(index),
              child: _buildSlotBox(
                _userSpelling[index],
                isCorrect: _isCorrect,
                isDark: isDark,
              ),
            );
          }),
        ),
        const SizedBox(height: 40),

        // Bàn phím ký tự
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_poolLetters.length, (index) {
            bool isSelected = _selectedIndices.contains(index);
            // Dùng AnimatedOpacity để chữ biến mất/hiện lại mượt mà
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isSelected ? 0.0 : 1.0,
              child: GestureDetector(
                onTap: () => _onLetterTap(index, _poolLetters[index]),
                child: Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    _poolLetters[index],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Widget ô vuông chứa chữ cái (Đã sửa lỗi hiển thị màu)
  Widget _buildSlotBox(
    String char, {
    bool isEmpty = false,
    bool? isCorrect,
    required bool isDark,
  }) {
    Color borderColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
    Color bgColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    Color textColor = isDark ? Colors.white : Colors.black;

    if (!isEmpty) {
      bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
      borderColor = Colors.blueAccent;

      // LOGIC MÀU MỚI: Tương phản cao
      if (isCorrect == true) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.2);
        textColor = isDark ? Colors.greenAccent : Colors.green[800]!;
      }
      if (isCorrect == false) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.2);
        textColor = isDark
            ? Colors.redAccent
            : Colors.red[900]!; // Chữ đỏ đậm để dễ đọc trên nền đỏ nhạt
      }
    }

    // Dùng AnimatedContainer để màu chuyển mượt mà
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Text(
        char,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  // Getter helper
  bool get isCorrect => _isCorrect ?? false;
}
