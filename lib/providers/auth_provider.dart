import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../database/database_helper.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<bool> login(String username, String password) async {
    final user = await DatabaseHelper.instance.loginUser(username, password);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String username, String password) async {
    final user = User(username: username, password: password);
    int id = await DatabaseHelper.instance.registerUser(user);
    return id != -1;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
