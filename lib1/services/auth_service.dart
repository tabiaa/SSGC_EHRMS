// services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';

class AuthService with ChangeNotifier {
  Employee? _user;
  bool _isLoggedIn = false;

  Employee? get user => _user;
  bool get isLoggedIn => _isLoggedIn;

  void login(Employee user) {
    _user = user;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() async {
    _user = null;
    _isLoggedIn = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  void restoreLogin(String? token) {
    if (token != null && token.isNotEmpty) {
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  void loginWithToken(Employee user, String token) {
  _user = user;
  _isLoggedIn = true;
  // Token is already saved by ApiService.login()
  notifyListeners();
}
}
