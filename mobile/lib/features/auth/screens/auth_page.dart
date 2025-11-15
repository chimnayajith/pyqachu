import 'package:flutter/material.dart';
import 'package:pyqachu/shared/navigation/main_navigation.dart';
import 'package:pyqachu/features/home/screens/search_page.dart';
import 'package:pyqachu/core/services/api_service.dart';
import 'package:pyqachu/core/services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  bool isLogin = true;
  bool _isLoading = false;

  // Password visibility state variables
  bool _isLoginPasswordVisible = false;
  bool _isRegisterPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Login controllers
  final TextEditingController _loginUsernameController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  // Register controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _registerEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void togglePage(bool loginSelected) {
    setState(() {
      isLogin = loginSelected;
      _pageController.animateToPage(
        loginSelected ? 0 : 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('=== ATTEMPTING LOGIN ===');
      final result = await ApiService.login(
        _loginUsernameController.text,
        _loginPasswordController.text,
      );

      if (result.success) {
        print('Login successful!');
        final token = result.token;
        final user = result.user;

        await AuthService.saveAuthData(token, user);

        if (mounted) {
          print('Navigating to MainNavigation after login');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
        }
      } else {
        print('Login failed: ${result.error}');
        _showErrorDialog(result.error ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      _showErrorDialog('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.register(
        username: _usernameController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _registerEmailController.text,
        password: _passwordController.text,
      );

      if (result.success) {
        _showSuccessDialog('Account created successfully! Please login.');
        togglePage(true); // Switch to login page
        _clearRegisterForm();
      } else {
        final errors = result.details ?? [];
        String errorMessage = 'Registration failed';
        
        if (errors is Map) {
          final errorList = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              errorList.addAll(value.cast<String>());
            } else {
              errorList.add(value.toString());
            }
          });
          errorMessage = errorList.join('\n');
        }
        
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      _showErrorDialog('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearRegisterForm() {
    _usernameController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _registerEmailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 80,
        title: const Text('Pyqachu', style: TextStyle(color: Colors.black, fontSize: 22)),
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Image.asset(
            'assets/images/logo.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),

              // Segmented buttons
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => togglePage(true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: isLogin ? Colors.white : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: isLogin
                                ? [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))]
                                : [],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: isLogin ? Colors.black : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => togglePage(false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: !isLogin ? Colors.white : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: !isLogin
                                ? [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))]
                                : [],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: Text(
                            'Register',
                            style: TextStyle(
                              color: !isLogin ? Colors.black : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildLoginForm(),
                    _buildRegisterForm(),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Username', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildTextField(
              hint: 'Username',
              controller: _loginUsernameController,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Username is required';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildTextField(
              hint: 'Password',
              obscure: !_isLoginPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Password is required';
                return null;
              },
              controller: _loginPasswordController,
              suffixIcon: IconButton(
                icon: Icon(
                  _isLoginPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isLoginPasswordVisible = !_isLoginPasswordVisible;
                  });
                },
              ),
            ),
            const SizedBox(height: 30),
            _buildBlackButton('Login', onPressed: _handleLogin),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Form(
        key: _registerFormKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabelAndField('Username', 'Username', controller: _usernameController),
              _buildLabelAndField('First Name', 'First Name', controller: _firstNameController),
              _buildLabelAndField('Last Name', 'Last Name', controller: _lastNameController),
              _buildLabelAndField(
                'Email',
                'Email',
                validator: emailValidator,
                controller: _registerEmailController,
              ),
              _buildLabelAndField(
                'Password',
                'Password',
                obscure: !_isRegisterPasswordVisible,
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password is required';
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _isRegisterPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isRegisterPasswordVisible = !_isRegisterPasswordVisible;
                    });
                  },
                ),
              ),
              _buildLabelAndField(
                'Confirm Password',
                'Confirm Password',
                obscure: !_isConfirmPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Confirm your password';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),
              _buildBlackButton('Create Account', onPressed: _handleRegister),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelAndField(
    String label,
    String hint, {
    bool obscure = false,
    String? Function(String?)? validator,
    TextEditingController? controller,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _buildTextField(
          hint: hint,
          obscure: obscure,
          validator: validator,
          controller: controller,
          suffixIcon: suffixIcon,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextField({
    required String hint,
    bool obscure = false,
    String? Function(String?)? validator,
    TextEditingController? controller,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildBlackButton(String text, {required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
