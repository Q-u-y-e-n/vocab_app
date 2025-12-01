import 'package:flutter/material.dart';
import '../models/vocabulary_model.dart';
import '../models/topic_model.dart';
import '../database/database_helper.dart';

class VocabProvider with ChangeNotifier {
  List<Vocabulary> _originalList =
      []; // Danh sách gốc từ DB (Không bao giờ thay đổi khi lọc)
  List<Vocabulary> _displayList =
      []; // Danh sách hiển thị ra màn hình (Đã qua xử lý)
  List<Topic> _topics = [];

  // Getter để UI lấy dữ liệu
  List<Vocabulary> get vocabList => _displayList;
  List<Topic> get topics => _topics;

  // Các biến trạng thái bộ lọc
  String _searchQuery = "";
  int? _filterTopicId; // null = hiện tất cả
  bool _filterFavorite = false;

  // --- 1. LOAD DỮ LIỆU ---
  Future<void> loadData(int userId) async {
    _originalList = await DatabaseHelper.instance.getVocabularies(userId);
    _topics = await DatabaseHelper.instance.getTopics(userId);

    // Sau khi load xong, áp dụng ngay bộ lọc hiện tại để tạo _displayList
    _applyFilters();
  }

  // --- 2. CÁC HÀM NHẬN LỆNH TỪ UI ---

  // Khi người dùng nhập vào ô tìm kiếm
  void search(String query) {
    _searchQuery = query;
    _applyFilters(); // Tính toán lại danh sách hiển thị
  }

  // Khi người dùng chọn chủ đề
  void filterByTopic(int? topicId) {
    _filterTopicId = topicId;
    _applyFilters();
  }

  // Khi người dùng bấm nút tim (lọc yêu thích)
  void toggleShowFavorite(bool showOnlyFavorite) {
    _filterFavorite = showOnlyFavorite;
    _applyFilters();
  }

  // --- 3. CORE LOGIC: BỘ LỌC TRUNG TÂM (QUAN TRỌNG NHẤT) ---
  void _applyFilters() {
    _displayList = _originalList.where((vocab) {
      // Điều kiện 1: Tìm kiếm (Search)
      // Chuyển hết về chữ thường để so sánh không phân biệt hoa thường
      final query = _searchQuery.toLowerCase().trim();
      final wordLower = vocab.word.toLowerCase();
      final meaningLower = vocab.meaning.toLowerCase();

      // Nếu ô tìm kiếm trống -> Coi như thỏa mãn điều kiện tìm kiếm
      // Nếu có chữ -> Kiểm tra xem từ vựng HOẶC nghĩa có chứa từ khóa không
      bool matchSearch =
          query.isEmpty ||
          wordLower.contains(query) ||
          meaningLower.contains(query);

      // Điều kiện 2: Chủ đề (Topic)
      // Nếu _filterTopicId là null (Chọn "Tất cả") -> Thỏa mãn
      // Nếu không null -> Kiểm tra id có khớp không
      bool matchTopic =
          _filterTopicId == null || vocab.topicId == _filterTopicId;

      // Điều kiện 3: Yêu thích (Favorite)
      // Nếu không bật lọc yêu thích -> Thỏa mãn
      // Nếu bật -> Kiểm tra isFavorite có phải true không
      bool matchFavorite = !_filterFavorite || vocab.isFavorite;

      // KẾT LUẬN: Từ vựng phải thỏa mãn CẢ 3 điều kiện mới được hiện
      return matchSearch && matchTopic && matchFavorite;
    }).toList();

    // Thông báo cho UI cập nhật lại ListView
    notifyListeners();
  }

  // --- 4. CÁC HÀM CRUD (THÊM, SỬA, XÓA) ---

  Future<void> addVocabulary(Vocabulary vocab) async {
    await DatabaseHelper.instance.addVocabulary(vocab);
    await loadData(vocab.userId); // Load lại để cập nhật _originalList
  }

  Future<void> updateVocabulary(Vocabulary vocab) async {
    await DatabaseHelper.instance.updateVocabulary(vocab);
    await loadData(vocab.userId);
  }

  Future<void> toggleFavorite(Vocabulary vocab) async {
    final updatedVocab = vocab.copyWith(isFavorite: !vocab.isFavorite);
    await updateVocabulary(updatedVocab);
  }

  Future<void> deleteVocabulary(int id, int userId) async {
    await DatabaseHelper.instance.deleteVocabulary(id);
    await loadData(userId);
  }

  // Topic CRUD
  Future<void> addTopic(String name, int userId) async {
    final topic = Topic(userId: userId, name: name);
    await DatabaseHelper.instance.addTopic(topic);
    await loadData(userId);
  }
}
