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

  // Trạng thái chung
  bool _isAnswered = false;
  bool? _isCorrect;
  String? _selectedOption; // Lưu lại đáp án người dùng vừa chọn

  // Trạng thái riêng cho Spelling
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

  // --- XỬ LÝ LOGIC CHUNG ---

  // Hàm kết thúc lượt chơi (Dùng chung cho cả 3 loại câu hỏi)
  void _finishTurn(bool correct) {
    // 1. LUÔN LUÔN ĐỌC TIẾNG ANH (Bất kể đúng sai)
    final question = _questions[_currentIndex];
    String textToSpeak = "";

    if (question.type == QuizType.multipleChoice) {
      textToSpeak =
          question.questionText; // Trắc nghiệm: Câu hỏi là từ tiếng Anh
    } else {
      textToSpeak =
          question.correctAnswer; // Điền từ/Ghép từ: Đáp án là từ tiếng Anh
    }
    _tts.speak(textToSpeak);

    // 2. Cập nhật điểm và trạng thái
    if (correct) _score++;

    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });

    // 3. Chuyển câu sau 2 giây (tăng lên xíu để kịp nhìn đáp án đúng)
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _initQuestionData();
        });
      } else {
        _showResultDialog();
      }
    });
  }

  // --- XỬ LÝ TỪNG LOẠI CÂU HỎI ---

  // 1. Trắc nghiệm & Điền từ
  void _handleMultipleChoice(String option) {
    if (_isAnswered) return;
    _selectedOption = option; // Lưu lại cái mình vừa chọn
    bool correct = option == _questions[_currentIndex].correctAnswer;
    _finishTurn(correct);
  }

  // 2. Spelling: Chọn chữ
  void _onLetterTap(int index, String char) {
    if (_isAnswered || _selectedIndices.contains(index)) return;

    setState(() {
      _userSpelling.add(char);
      _selectedIndices.add(index);
    });

    // Kiểm tra khi đã điền đủ
    if (_userSpelling.length ==
        _questions[_currentIndex].correctAnswer.length) {
      String result = _userSpelling.join();
      bool correct =
          result.toLowerCase() ==
          _questions[_currentIndex].correctAnswer.toLowerCase();
      _finishTurn(correct);
    }
  }

  // 2. Spelling: Xóa chữ
  void _onSlotTap(int indexInUserList) {
    if (_isAnswered) return;
    setState(() {
      _userSpelling.removeAt(indexInUserList);
      _selectedIndices.removeAt(indexInUserList);
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Kết Quả", textAlign: TextAlign.center),
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
              style: const TextStyle(fontSize: 18),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: Text("Câu hỏi ${_currentIndex + 1}/${_questions.length}"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: Colors.blueAccent,
            minHeight: 6,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  // --- PHẦN CÂU HỎI ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
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
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          question.questionText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                            height: 1.4,
                          ),
                        ),
                        // Luôn hiện giải thích khi đã trả lời
                        if (_isAnswered) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              question.explanation ?? "",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),

                  // --- PHẦN TRẢ LỜI ---
                  if (question.type == QuizType.spelling)
                    _buildSpellingInterface()
                  else
                    _buildOptionsList(question),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI: TRẮC NGHIỆM & ĐIỀN TỪ (LOGIC MÀU SẮC Ở ĐÂY) ---
  Widget _buildOptionsList(QuizQuestion question) {
    return Column(
      children: question.options.map((option) {
        bool isCorrectAnswer = option == question.correctAnswer;
        bool isSelected = option == _selectedOption;

        Color bgColor = Colors.white;
        Color borderColor = Colors.grey[300]!;
        IconData? icon;

        if (_isAnswered) {
          // 1. Luôn hiển thị MÀU XANH cho đáp án đúng
          if (isCorrectAnswer) {
            bgColor = Colors.green[100]!;
            borderColor = Colors.green;
            icon = Icons.check_circle;
          }
          // 2. Nếu người dùng chọn SAI -> Hiển thị MÀU ĐỎ ở ô người dùng chọn
          else if (isSelected) {
            bgColor = Colors.red[100]!;
            borderColor = Colors.red;
            icon = Icons.cancel;
          }
        }

        return GestureDetector(
          onTap: () => _handleMultipleChoice(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isAnswered && (isCorrectAnswer || isSelected)
                          ? Colors.black
                          : Colors.grey[800],
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

  // --- UI: SPELLING ---
  Widget _buildSpellingInterface() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_userSpelling.length + 1, (index) {
            if (index >= _userSpelling.length &&
                _userSpelling.length <
                    _questions[_currentIndex].correctAnswer.length) {
              return _buildSlotBox("", isEmpty: true);
            }
            if (index >= _userSpelling.length) return const SizedBox();
            return GestureDetector(
              onTap: () => _onSlotTap(index),
              child: _buildSlotBox(_userSpelling[index], isCorrect: _isCorrect),
            );
          }),
        ),
        const SizedBox(height: 40),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_poolLetters.length, (index) {
            bool isSelected = _selectedIndices.contains(index);
            return GestureDetector(
              onTap: () => _onLetterTap(index, _poolLetters[index]),
              child: Opacity(
                opacity: isSelected ? 0.0 : 1.0,
                child: Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
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

  Widget _buildSlotBox(String char, {bool isEmpty = false, bool? isCorrect}) {
    Color borderColor = Colors.grey[400]!;
    Color bgColor = Colors.grey[200]!;

    if (!isEmpty) {
      bgColor = Colors.white;
      borderColor = Colors.blueAccent;
      // Logic màu cho spelling khi kết thúc
      if (isCorrect == true) {
        borderColor = Colors.green;
        bgColor = Colors.green[50]!;
      }
      if (isCorrect == false) {
        borderColor = Colors.red;
        bgColor = Colors.red[50]!;
      }
    }

    return Container(
      width: 45,
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Text(
        char,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: (isCorrect == false) ? Colors.red : Colors.black,
        ),
      ),
    );
  }
}
