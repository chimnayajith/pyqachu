// main.dart

import 'package:flutter/material.dart';
// 1. UPDATE IMPORT: Change 'search_page.dart' to 'dashboard_screen.dart'
import 'package:pyqachu/features/home/screens/dashboard_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/auth_page.dart';

void main() {
  runApp(const PyqachuApp());
}

class PyqachuApp extends StatelessWidget {
  const PyqachuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pyqachu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      // Start on the Welcome screen
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/auth': (context) => const AuthPage(),
        // 2. UPDATE ROUTE & CLASS: Change '/search' to '/dashboard'
        //    and SearchPage() to DashboardScreen()
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
