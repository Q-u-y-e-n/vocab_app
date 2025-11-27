class Vocabulary {
  final int? id;
  final int userId;
  final int? topicId; // Mới: Thuộc chủ đề nào (null = chưa phân loại)
  final String word;
  final String meaning;
  final String example;
  final String? audioPath;
  final bool isFavorite; // Mới: Yêu thích

  Vocabulary({
    this.id,
    required this.userId,
    this.topicId,
    required this.word,
    required this.meaning,
    required this.example,
    this.audioPath,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'topicId': topicId,
    'word': word,
    'meaning': meaning,
    'example': example,
    'audioPath': audioPath,
    'isFavorite': isFavorite ? 1 : 0, // SQLite lưu bool dưới dạng int (0/1)
  };

  factory Vocabulary.fromMap(Map<String, dynamic> map) => Vocabulary(
    id: map['id'],
    userId: map['userId'],
    topicId: map['topicId'],
    word: map['word'],
    meaning: map['meaning'],
    example: map['example'],
    audioPath: map['audioPath'],
    isFavorite: (map['isFavorite'] ?? 0) == 1,
  );

  // Hàm copy để cập nhật trạng thái nhanh (immutable)
  Vocabulary copyWith({int? topicId, bool? isFavorite}) {
    return Vocabulary(
      id: id,
      userId: userId,
      topicId: topicId ?? this.topicId,
      word: word,
      meaning: meaning,
      example: example,
      audioPath: audioPath,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
