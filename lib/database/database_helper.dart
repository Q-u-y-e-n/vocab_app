import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/vocabulary_model.dart';
import '../models/topic_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('language_app_v3.db'); // Đổi tên DB v3
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Bảng User
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL
    )
    ''');

    // Bảng Topics (Chủ đề) - MỚI
    await db.execute('''
    CREATE TABLE topics (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER NOT NULL,
      name TEXT NOT NULL,
      FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');

    // Bảng Vocabularies (Cập nhật thêm topicId và isFavorite)
    await db.execute('''
    CREATE TABLE vocabularies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER NOT NULL,
      topicId INTEGER,
      word TEXT NOT NULL,
      meaning TEXT NOT NULL,
      example TEXT,
      audioPath TEXT,
      isFavorite INTEGER DEFAULT 0,
      FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
      FOREIGN KEY (topicId) REFERENCES topics (id) ON DELETE SET NULL
    )
    ''');
  }

  // --- CÁC HÀM CŨ GIỮ NGUYÊN (registerUser, loginUser, deleteVocabulary...) ---
  // Bạn copy lại các hàm cũ từ file trước vào đây
  Future<int> registerUser(User user) async {
    final db = await instance.database;
    try {
      return await db.insert('users', user.toMap());
    } catch (e) {
      return -1;
    }
  }

  Future<User?> loginUser(String username, String password) async {
    final db = await instance.database;
    final res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return res.isNotEmpty ? User.fromMap(res.first) : null;
  }

  Future<int> addVocabulary(Vocabulary vocab) async {
    final db = await instance.database;
    return await db.insert('vocabularies', vocab.toMap());
  }

  Future<int> deleteVocabulary(int id) async {
    final db = await instance.database;
    return await db.delete('vocabularies', where: 'id = ?', whereArgs: [id]);
  }

  // --- CÁC HÀM MỚI ---

  // 1. Lấy danh sách từ (kèm logic sắp xếp: Yêu thích lên đầu)
  Future<List<Vocabulary>> getVocabularies(int userId) async {
    final db = await instance.database;
    // Order by isFavorite DESC (1 trước 0), sau đó đến ID giảm dần
    final result = await db.query(
      'vocabularies',
      where: 'userId = ?',
      orderBy: "isFavorite DESC, id DESC",
      whereArgs: [userId],
    );
    return result.map((json) => Vocabulary.fromMap(json)).toList();
  }

  // 2. Cập nhật từ vựng (dùng cho cả Sửa nội dung, Toggle Favorite, Assign Topic)
  Future<int> updateVocabulary(Vocabulary vocab) async {
    final db = await instance.database;
    return await db.update(
      'vocabularies',
      vocab.toMap(),
      where: 'id = ?',
      whereArgs: [vocab.id],
    );
  }

  // 3. Quản lý Topic
  Future<int> addTopic(Topic topic) async {
    final db = await instance.database;
    return await db.insert('topics', topic.toMap());
  }

  Future<List<Topic>> getTopics(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'topics',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return result.map((json) => Topic.fromMap(json)).toList();
  }
}
