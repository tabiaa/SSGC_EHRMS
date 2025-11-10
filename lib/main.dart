import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dependents_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize the AuthService singleton BEFORE starting the app
  final authService = AuthService();
  await authService.init(); // This loads saved token/user from SharedPreferences

  runApp(
    ChangeNotifierProvider<AuthService>.value(
      value: authService, // ✅ Provide the initialized instance
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSGC Employee Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFFF5722),
        scaffoldBackgroundColor: const Color(0xFFFFF8F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF5722),
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepOrange,
        ).copyWith(
          secondary: const Color(0xFFFF8A65),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFAB91)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF5722), width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.deepOrange),
        ),
      ),
      home: const AuthWrapper(), // ✅ This will show Login or Dependents based on auth state
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context); // ✅ This now WORKS — provider is at root

    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ If logged in → show DependentsScreen. Else → show LoginScreen
    return auth.isLoggedIn ? const DependentsScreen() : LoginScreen();
  }
}