import 'package:flutter/material.dart';
import 'auth_page.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/navigation/main_navigation.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    print('=== WELCOME PAGE: Checking auth status ===');
    
    // Show splash for 2 seconds minimum
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      final isLoggedIn = await AuthService.isLoggedIn();
      print('User logged in: $isLoggedIn');
      
      if (isLoggedIn) {
        print('Navigating to MainNavigation');
        // User is already logged in, go to main navigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        print('Navigating to AuthPage');
        // User is not logged in, go to auth page
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AuthPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo with animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 250,
                        height: 250,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              const SizedBox(height: 20),
              
              // Loading indicator
              const CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension TweenAnimationBuilderExtension on TweenAnimationBuilder<double> {
  TweenAnimationBuilder<double> get delayed => TweenAnimationBuilder<double>(
        tween: tween,
        duration: duration,
        curve: curve,
        builder: (context, value, child) {
          return builder(context, value, child);
        },
      );
}
