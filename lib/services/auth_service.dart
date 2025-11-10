import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _user;
  String? _token;
  bool _isLoggedIn = false;
  bool _isInitialized = false;

  String? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _user = prefs.getString('user');
    _token = prefs.getString('token');
    _isLoggedIn = _token != null && _user != null;
    _isInitialized = true;
    notifyListeners(); 
  }

  Future<void> login(String username, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', username);
    await prefs.setString('token', token);

    _user = username;
    _token = token;
    _isLoggedIn = true;
    notifyListeners(); 
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _user = null;
    _token = null;
    _isLoggedIn = false;
    notifyListeners(); 
  }
}