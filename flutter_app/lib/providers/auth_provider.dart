import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('logged_in') ?? false;
    notifyListeners();
  }

  Future<String?> demoLogin() async {
    _isLoggedIn = true;
    _user = {'id': 1, 'username': 'admin', 'role': 'admin'};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', true);
    notifyListeners();
    return null;
  }

  Future<String?> login(String username, String password) async {
    _isLoggedIn = true;
    _user = {'id': 1, 'username': username, 'role': 'admin'};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', true);
    notifyListeners();
    return null;
  }

  Future<String?> register(String username, String password, String role) async {
    return null;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in');
    notifyListeners();
  }
}
