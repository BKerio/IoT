import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kanisaapp/components/responsive_layout.dart';
import 'package:kanisaapp/config/server.dart';
import 'package:kanisaapp/method/api.dart';
import 'package:kanisaapp/screen/login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final primaryColor = const Color(0xFF0A1F44);

  final fullName = TextEditingController();
  final email = TextEditingController();
  final telephone = TextEditingController();
  final password = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    fullName.dispose();
    email.dispose();
    telephone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (isLoading) return;

    if (!_formKey.currentState!.validate()) {
      _toast('Please check the highlighted required fields.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/users/register'),
        data: {
          'full_name': fullName.text.trim(),
          'email': email.text.trim(),
          'telephone': telephone.text.trim(),
          'password': password.text,
        },
      );

      final resp = jsonDecode(result.body);

      if (resp['status'] == 200) {
        API.showSnack(
          context,
          'Member Registered Successfully! Welcome to Our Church Community.',
          success: true,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
      } else {
        _toast(resp['message']?.toString() ?? 'Registration failed');
      }
    } catch (e) {
      _toast('Something went wrong: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _toast(String msg) {
    API.showSnack(context, msg, success: false);
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey, size: 20),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildRegisterCard() {
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
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
                  "Create your Kanisa Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3A59),
                  ),
                ),
                const SizedBox(height: 24),

                _buildInputField(
                  controller: fullName,
                  hintText: "Full name",
                  icon: Icons.person,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Full name is mandatory'
                      : null,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  controller: email,
                  hintText: "Email address",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Email is mandatory'
                      : null,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  controller: telephone,
                  hintText: "Phone number (0712345678)",
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Phone number is mandatory'
                      : null,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  controller: password,
                  hintText: "Create a password",
                  icon: Icons.lock_outlined,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is mandatory';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                if (isLoading)
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: Center(
                      child: SpinKitFadingCircle(
                        size: 90,
                        duration: const Duration(milliseconds: 3200),
                        itemBuilder: (context, index) {
                          final palette = [
                            Colors.black,
                            primaryColor,
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
                      onPressed: submit,
                      child: const Text(
                        "Register",
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const Login()),
                      ),
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: primaryColor,
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
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildRegisterCard(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return DesktopScaffoldFrame(
      title: 'Member Registration',
      primaryColor: const Color(0xFF35C2C1),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: _buildRegisterCard(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }
}
