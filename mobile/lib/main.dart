import 'package:flutter/material.dart';
import 'package:pyqachu/shared/navigation/main_navigation.dart';
import 'package:pyqachu/core/services/api_service.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the auth token from storage
  await ApiService.initializeToken();
  
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
        '/': (context) => WelcomePage(),
        '/auth': (context) => AuthPage(),
        '/main': (context) => const MainNavigation(),
      },
    );
  }
}
