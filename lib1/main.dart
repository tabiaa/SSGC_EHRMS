import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dependents_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('auth_token');

  runApp(MyApp(savedToken: savedToken));
}

class MyApp extends StatelessWidget {
  final String? savedToken;
  const MyApp({super.key, this.savedToken});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final authService = AuthService();
        authService.restoreLogin(savedToken);
        return authService;
      },
      child: MaterialApp(
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
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    // This ensures that logout works cleanly
    if (!auth.isLoggedIn) {
      return LoginScreen();
    }

    return DependentsScreen();
  }
}
