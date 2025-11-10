import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> handleExpiredToken(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');

  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Session expired. Please log in again.')),
  );
}
