import 'dart:math';
import '../models/vocabulary_model.dart';
import '../models/quiz_question.dart';
import '../utils/string_utils.dart'; // Đảm bảo bạn đã có file này để dùng VocabParser

class QuizService {
  /// Hàm chính để tạo ra bộ đề thi
  List<QuizQuestion> generateQuiz(
    List<Vocabulary> vocabList, {
    int limit = 10,
  }) {
    // Nếu ít hơn 4 từ thì không đủ để tạo 3 đáp án nhiễu -> Trả về rỗng
    if (vocabList.length < 4) return [];

    final random = Random();

    // 1. Trộn danh sách gốc để lấy ngẫu nhiên
    List<Vocabulary> shuffled = List.from(vocabList)..shuffle();

    // 2. Lấy số lượng câu hỏi theo giới hạn (mặc định 10)
    List<Vocabulary> selected = shuffled.take(limit).toList();

    List<QuizQuestion> questions = [];

    for (var vocab in selected) {
      // Kiểm tra xem từ vựng này có câu ví dụ hợp lệ không?
      // (Không rỗng và không phải chỉ có mỗi ví dụ tự viết "✍️")
      bool hasExample = vocab.example.isNotEmpty;

      // Random loại câu hỏi:
      // 0: Trắc nghiệm (Multiple Choice)
      // 1: Điền từ (Fill in blank) - Chỉ khi có ví dụ
      // 2: Ghép chữ (Spelling) - Chỉ khi có ví dụ

      int typeIndex = 0;
      if (hasExample) {
        typeIndex = random.nextInt(3); // Random từ 0 đến 2
      } else {
        typeIndex = 0; // Bắt buộc trắc nghiệm nếu không có ví dụ
      }

      if (typeIndex == 0) {
        questions.add(_createMultipleChoice(vocab, vocabList));
      } else if (typeIndex == 1) {
        questions.add(_createFillInBlank(vocab, vocabList));
      } else {
        questions.add(_createSpelling(vocab));
      }
    }
    return questions;
  }

  // --- DẠNG 1: TRẮC NGHIỆM ---
  // Hỏi: Từ tiếng Anh
  // Đáp án: Nghĩa tiếng Việt
  QuizQuestion _createMultipleChoice(
    Vocabulary target,
    List<Vocabulary> allVocabs,
  ) {
    // Lấy nghĩa tiếng Việt chuẩn
    String correct = VocabParser.getVietnamese(target.meaning);
    if (correct.isEmpty)
      correct = target.meaning; // Fallback nếu không parse được

    List<String> options = [correct];
    final random = Random();

    // Tạo 3 đáp án nhiễu
    while (options.length < 4) {
      var randomVocab = allVocabs[random.nextInt(allVocabs.length)];
      String wrong = VocabParser.getVietnamese(randomVocab.meaning);
      if (wrong.isEmpty) wrong = randomVocab.meaning;

      // Đảm bảo đáp án nhiễu không trùng với đáp án đúng và không trùng nhau
      if (randomVocab.id != target.id &&
          !options.contains(wrong) &&
          wrong.isNotEmpty) {
        options.add(wrong);
      }
    }

    // Trộn vị trí các đáp án
    options.shuffle();

    return QuizQuestion(
      type: QuizType.multipleChoice,
      questionText: target.word,
      correctAnswer: correct,
      options: options,
      explanation: "Nghĩa chính xác: $correct",
    );
  }

  // --- DẠNG 2: ĐIỀN TỪ ---
  // Hỏi: Câu ví dụ bị khuyết từ (_______)
  // Đáp án: Chọn từ tiếng Anh đúng
  QuizQuestion _createFillInBlank(
    Vocabulary target,
    List<Vocabulary> allVocabs,
  ) {
    // Lấy câu ví dụ (Chỉ lấy phần tự động nếu có phần custom)
    String rawExample = target.example.split("✍️").first.trim();
    if (rawExample.isEmpty) rawExample = target.example; // Fallback

    // Thay thế từ vựng trong câu bằng "_______" (Không phân biệt hoa thường)
    String maskedExample = rawExample.replaceAll(
      RegExp(RegExp.escape(target.word), caseSensitive: false),
      "_______",
    );

    List<String> options = [target.word];
    final random = Random();

    // Lấy 3 từ tiếng Anh khác làm nhiễu
    while (options.length < 4) {
      var randomVocab = allVocabs[random.nextInt(allVocabs.length)];
      if (randomVocab.id != target.id && !options.contains(randomVocab.word)) {
        options.add(randomVocab.word);
      }
    }
    options.shuffle();

    return QuizQuestion(
      type: QuizType.fillInBlank,
      questionText: maskedExample,
      correctAnswer: target.word,
      options: options,
      explanation: "Nghĩa: ${VocabParser.getVietnamese(target.meaning)}",
    );
  }

  // --- DẠNG 3: GHÉP TỪ (SPELLING) ---
  // Hỏi: Câu ví dụ bị khuyết từ
  // Đáp án: Các ký tự rời rạc để ghép thành từ
  QuizQuestion _createSpelling(Vocabulary target) {
    // Lấy câu ví dụ
    String rawExample = target.example.split("✍️").first.trim();
    if (rawExample.isEmpty) rawExample = target.example;

    // Che từ đi
    String maskedExample = rawExample.replaceAll(
      RegExp(RegExp.escape(target.word), caseSensitive: false),
      "_______",
    );

    // Tách từ thành các ký tự: "Cat" -> ['C', 'a', 't']
    List<String> chars = target.word.split('');
    chars.shuffle(); // Xáo trộn: ['t', 'C', 'a']

    return QuizQuestion(
      type: QuizType.spelling,
      questionText: maskedExample, // Hiển thị ngữ cảnh
      correctAnswer: target.word,
      options: chars, // Danh sách ký tự để hiển thị lên bàn phím
      explanation: "Nghĩa: ${VocabParser.getVietnamese(target.meaning)}",
    );
  }
}
