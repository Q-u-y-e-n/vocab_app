import 'package:flutter/material.dart';
import '../models/vocabulary_model.dart';
import '../models/topic_model.dart';
import '../database/database_helper.dart';

class VocabProvider with ChangeNotifier {
  List<Vocabulary> _originalList = []; // Danh sách gốc từ DB
  List<Vocabulary> _displayList = []; // Danh sách hiển thị (đã qua lọc/search)
  List<Topic> _topics = [];

  List<Vocabulary> get vocabList => _displayList;
  List<Topic> get topics => _topics;

  String _searchQuery = "";
  int? _filterTopicId; // null = hiện tất cả
  bool _filterFavorite = false;

  // Load tất cả dữ liệu
  Future<void> loadData(int userId) async {
    _originalList = await DatabaseHelper.instance.getVocabularies(userId);
    _topics = await DatabaseHelper.instance.getTopics(userId);
    _applyFilters(); // Áp dụng bộ lọc để tạo displayList
  }

  // Logic Tìm kiếm & Lọc
  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByTopic(int? topicId) {
    _filterTopicId = topicId;
    _applyFilters();
  }

  void toggleShowFavorite(bool showOnlyFavorite) {
    _filterFavorite = showOnlyFavorite;
    _applyFilters();
  }

  void _applyFilters() {
    _displayList = _originalList.where((vocab) {
      // 1. Lọc theo Search text
      bool matchSearch =
          vocab.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vocab.meaning.toLowerCase().contains(_searchQuery.toLowerCase());
      // 2. Lọc theo Topic
      bool matchTopic =
          _filterTopicId == null || vocab.topicId == _filterTopicId;
      // 3. Lọc theo Favorite
      bool matchFavorite = !_filterFavorite || vocab.isFavorite;

      return matchSearch && matchTopic && matchFavorite;
    }).toList();
    notifyListeners();
  }

  // CRUD Từ vựng
  Future<void> addVocabulary(Vocabulary vocab) async {
    await DatabaseHelper.instance.addVocabulary(vocab);
    await loadData(vocab.userId);
  }

  Future<void> updateVocabulary(Vocabulary vocab) async {
    await DatabaseHelper.instance.updateVocabulary(vocab);
    await loadData(vocab.userId);
  }

  // Hàm nhanh để toggle yêu thích
  Future<void> toggleFavorite(Vocabulary vocab) async {
    final updatedVocab = vocab.copyWith(isFavorite: !vocab.isFavorite);
    await updateVocabulary(updatedVocab);
  }

  Future<void> deleteVocabulary(int id, int userId) async {
    await DatabaseHelper.instance.deleteVocabulary(id);
    await loadData(userId);
  }

  // CRUD Topic
  Future<void> addTopic(String name, int userId) async {
    final topic = Topic(userId: userId, name: name);
    await DatabaseHelper.instance.addTopic(topic);
    await loadData(userId);
  }
}
