import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // 1. Trạng thái Dark Mode
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // 2. Cỡ chữ (Scale Factor: 1.0 là bình thường)
  double _textScale = 1.0;
  double get textScale => _textScale;

  // 3. Màu chủ đạo Flashcard
  // Lưu dưới dạng int (value của Color) trong SharedPreferences
  int _flashcardColorValue = 0xFF2196F3; // Mặc định là màu Blue
  Color get flashcardColor => Color(_flashcardColorValue);

  SettingsProvider() {
    _loadSettings();
  }

  // Tải cài đặt từ bộ nhớ máy
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _textScale = prefs.getDouble('textScale') ?? 1.0;
    _flashcardColorValue = prefs.getInt('flashcardColor') ?? 0xFF2196F3;
    notifyListeners();
  }

  // Thay đổi Theme
  Future<void> toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isOn);
    notifyListeners();
  }

  // Thay đổi Cỡ chữ
  Future<void> setTextScale(double scale) async {
    _textScale = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScale', scale);
    notifyListeners();
  }

  // Thay đổi màu Flashcard
  Future<void> setFlashcardColor(Color color) async {
    _flashcardColorValue = color.toARGB32();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('flashcardColor', color.toARGB32());
    notifyListeners();
  }
}
