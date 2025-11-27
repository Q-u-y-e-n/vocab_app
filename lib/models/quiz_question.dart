// Thêm 'spelling' vào enum
enum QuizType { multipleChoice, fillInBlank, spelling }

class QuizQuestion {
  final QuizType type;
  final String questionText; // Câu hỏi hoặc câu ví dụ
  final String correctAnswer; // Đáp án đúng (Từ vựng)
  final List<String>
  options; // Với Spelling, đây là danh sách các ký tự đã bị xáo trộn
  final String? explanation;

  QuizQuestion({
    required this.type,
    required this.questionText,
    required this.correctAnswer,
    required this.options,
    this.explanation,
  });
}
