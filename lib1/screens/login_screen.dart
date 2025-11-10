import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/employee.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

 Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  final id = int.tryParse(_employeeIdController.text);
  if (id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid Employee ID')),
    );
    return;
  }

  try {
    // ✅ Wait for login AND token save to complete
    final result = await ApiService.login(id, _passwordController.text);
    if (result['success'] == true) {
      // ✅ Parse employee from 'employee' sub-object
      final user = Employee.fromJson(result['employee']!); // 👈 Critical!

      // ✅ Get token from result (already saved by ApiService.login)
      final token = result['token'] as String;

      // ✅ Pass token to AuthService to avoid delay
      Provider.of<AuthService>(context, listen: false).loginWithToken(user, token);

      // Now safe to navigate
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Login failed')),
      );
    }
  } on DioException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Network or server error. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ssgcOrange = Color(0xFFFF7A00);
    const ssgcDeepOrange = Color(0xFFCC5500);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [ssgcOrange, ssgcDeepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                  ),
                  const Text(
                    'SSGC Employee Portal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _employeeIdController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.badge_outlined, color: ssgcOrange),
                                labelText: 'Employee ID',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Please enter Employee ID' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline, color: ssgcOrange),
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              validator: (v) => v!.isEmpty ? 'Please enter Password' : null,
                            ),
                            const SizedBox(height: 22),
                            ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ssgcOrange,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '© 2025 SSGC | Secure Access',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}