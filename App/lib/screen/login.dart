import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kanisaapp/components/responsive_layout.dart';
import 'package:kanisaapp/config/server.dart';
import 'package:kanisaapp/method/api.dart';
import 'package:kanisaapp/screen/dashboard.dart';
import 'package:kanisaapp/screen/member_onboard.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  String _loginMode = 'Use your email address';
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _isCheckingAutoLogin = true;
  bool _showLoginPicker = false;

  final primaryColor = const Color(0xFF0A1F44);

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  // ---- Auto Login Check ----
  Future<void> _checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        // Validate token by making an authenticated request
        try {
          final result = await API().getRequest(
            url: Uri.parse('${Config.baseUrl}/users/me'),
          );

          if (result.statusCode == 200) {
            final response = jsonDecode(result.body) as Map<String, dynamic>;
            if ((response['status'] ?? 200) == 200) {
              // Token is valid, auto-login
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Home()),
                );
                return;
              }
            }
          }
        } catch (e) {
          // Token is invalid or expired, clear it and show login form
          await prefs.remove('token');
        }
      }
    } catch (e) {
      // Error checking auto-login, just show login form
      debugPrint('Auto-login check error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAutoLogin = false;
        });
      }
    }
  }

  // ---- Login API ----
  void loginUser() async {
    final identifier = _loginMode == 'Use your phone number'
        ? phoneController.text.trim()
        : email.text.trim();
    final pass = password.text.trim();

    if (identifier.isEmpty || pass.isEmpty) {
      API.showSnack(context, 'Please enter both email and password',
          success: false);
      return;
    }

    setState(() => isLoading = true);

    final data = {'identifier': identifier, 'password': pass};

    try {
      final result = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/login'),
        data: data,
      );
      final response = jsonDecode(result.body);

      if (response['status'] == 200 && response['token'] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', response['user']['id']);
        await prefs.setString('name', response['user']['name']);
        await prefs.setString('email', response['user']['email']);
        await prefs.setString('token', response['token']);

        if (mounted) {
          // Upload device token - Commented out until Firebase is configured
          // NotificationService().uploadToken(isLogin: true);
          
          API.showSnack(context, response['message'] ?? 'Login successful',
              success: true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Home()),
          );
        }
      } else {
        if (mounted) {
          API.showSnack(context, response['message'] ?? 'Authentication failed',
              success: false);
        }
      }
    } catch (e) {
      if (mounted) {
        API.showSnack(context, 'An error occurred during login',
            success: false);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ---- Login Option Picker ----
  IconData _loginIcon(String v) {
    switch (v) {
      case 'Use your email address':
        return Icons.email_outlined;
      case 'Use your phone number':
        return Icons.phone_android_rounded;
      default:
        return Icons.lock_outline;
    }
  }

  void _openLoginPicker() {
    setState(() => _showLoginPicker = true);
  }

  void _closeLoginPicker() {
    setState(() => _showLoginPicker = false);
  }

  Widget _buildLoginOption({
    required String label,
    required IconData icon,
  }) {
    final isSelected = _loginMode == label;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _loginMode = label;
            _showLoginPicker = false;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? primaryColor.withOpacity(0.2)
                  : Colors.grey.shade100,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isSelected ? primaryColor : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryColor : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 24,
                  color: primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ClipOval(
                child: Image.asset("assets/icon.png", fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Welcome back to Arvo",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Login using",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _openLoginPicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade100),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _loginIcon(_loginMode),
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _loginMode,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _loginMode == 'Use your phone number'
                  ? phoneController
                  : email,
              keyboardType: _loginMode == 'Use your phone number'
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: _loginMode == 'Use your phone number'
                    ? "Enter your phone number"
                    : "Enter your email address",
                border: InputBorder.none,
                prefixIcon: Icon(
                  _loginMode == 'Use your phone number'
                      ? Icons.phone_android_rounded
                      : Icons.email,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: "Enter your password",
                border: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.lock,
                  color: Colors.grey,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.black,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (isLoading)
            SizedBox(
              width: double.infinity,
              height: 70,
              child: Center(
                child: SpinKitFadingCircle(
                  size: 108,
                  duration: const Duration(milliseconds: 3200),
                  itemBuilder: (context, index) {
                    final palette = [
                      Colors.black,
                      Color(0xFF0A1F44),
                      Colors.red,
                      Colors.green,
                    ];
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette[index % palette.length],
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: loginUser,
                child: const Text(
                  "Login to your account",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider(color: Colors.grey)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Or",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              const Expanded(child: Divider(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Register()),
                ),
                child: const Text(
                  "Register",
                  style: TextStyle(
                    color: Color(0xFF0A1F44),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
              ),
            ),
            if (_showLoginPicker) _buildLoginPickerOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPickerOverlay() {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: _closeLoginPicker,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 50,
                      offset: Offset(0, -20),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Login using',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildLoginOption(
                          label: 'Use your email address',
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildLoginOption(
                          label: 'Use your phone number',
                          icon: Icons.phone_android_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildLoginCard(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return DesktopScaffoldFrame(
      title: 'Login Page',
      primaryColor: const Color(0xFF35C2C1),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: _buildLoginCard(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking auto-login
    if (_isCheckingAutoLogin) {
      return Scaffold(
        backgroundColor: const Color(0xFFE8F4FD),
        body: Center(
          child: SpinKitFadingCircle(
            size: 64,
            duration: const Duration(milliseconds: 3200),
            itemBuilder: (context, index) {
              final palette = [
                Colors.black,
                const Color(0xFF0A1F44),
                Colors.red,
                Colors.green,
              ];
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: palette[index % palette.length],
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }
}
