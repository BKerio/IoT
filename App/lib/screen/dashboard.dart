import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kanisaapp/config/server.dart';
import 'package:kanisaapp/method/api.dart';
import 'package:kanisaapp/screen/member_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  SharedPreferences? preferences;
  String username = '';
  String email = '';
  int userId = 0;
  bool isLoading = true;
  bool hasError = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
    _loadUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      preferences = await SharedPreferences.getInstance();
      setState(() {
        username = preferences?.getString('name') ?? '';
        email = preferences?.getString('email') ?? '';
        userId = preferences?.getInt('user_id') ?? 0;
      });

      await _fetchUserData();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final result = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/users/me'),
      );

      if (result.statusCode == 200) {
        final response = jsonDecode(result.body);

        if (response['status'] == 200 && response['user'] != null) {
          final user = response['user'];
          setState(() {
            username = user['full_name'] ?? username;
            email = user['email'] ?? email;
          });
          if (preferences != null) {
            await preferences!.setString('name', username);
            await preferences!.setString('email', email);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingUI();
    }

    if (hasError) {
      return _buildErrorUI();
    }

    return const MemberDashboard();
  }

  Widget _buildLoadingUI() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: Colors.white),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon.png',
                width: 90,
                height: 90,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),

              const Text(
                'Arvo',
                style: TextStyle(
                  color: Color(0xFF0A1F44),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bringing Intelligence Into Everyday Life',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 90,
                child: Center(
                  child: SpinKitFadingCircle(
                    size: 108,
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
              ),

              SizedBox(height: 40),
              Text(
                'Loading your dashboard, $username',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorUI() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 70,
            ),
            const SizedBox(height: 20),
            const Text(
              "Oops! Connection Issue",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "We couldn’t load your dashboard.\nPlease check your connection and try again.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Retry",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0A1F44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
