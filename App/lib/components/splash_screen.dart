import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:kanisaapp/components/responsive_layout.dart';
import 'package:kanisaapp/components/welcome.dart';
import 'package:kanisaapp/config/server.dart';
import 'package:kanisaapp/method/api.dart';
import 'package:kanisaapp/screen/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Creates a smooth concave wave curve at the bottom (dips lowest in center).
class _WaveBottomClipper extends CustomClipper<Path> {
  final double dipDepth;
  final double cornerRadius;

  _WaveBottomClipper({this.dipDepth = 24, this.cornerRadius = 0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, 0);
    path.lineTo(0, h);

    if (dipDepth <= 0 && cornerRadius <= 0) {
      path.lineTo(w, h);
    } else {
      // Left corner curve
      if (cornerRadius > 0) {
        path.lineTo(0, h - cornerRadius);
        path.quadraticBezierTo(0, h, cornerRadius, h);
      }
      // Concave wave bottom (dips lowest at center)
      if (dipDepth > 0) {
        path.quadraticBezierTo(w / 2, h + dipDepth, w - cornerRadius, h);
      } else {
        path.lineTo(w - cornerRadius, h);
      }
      // Right corner curve
      if (cornerRadius > 0) {
        path.quadraticBezierTo(w, h, w, h - cornerRadius);
      }
    }

    path.lineTo(w, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _lottieController;
  bool copAnimated = false;
  bool animateCafeText = false;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _determineStartupDestination();

    // Fixed splash timing
    Future.delayed(const Duration(seconds: 2), () {
      copAnimated = true;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 800), () {
        animateCafeText = true;
        setState(() {});
      });
    });
  }

  Future<void> _determineStartupDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      setState(() => _checkingSession = false);
      return;
    }

    try {
      final response = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/users/me'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200) {
          final user = data['user'] ?? {};
          if (user['name'] != null) prefs.setString('name', user['name']);
          if (user['email'] != null) prefs.setString('email', user['email']);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Home()),
          );
          return;
        }
      }
    } catch (_) {}

    await prefs.remove('token');
    setState(() => _checkingSession = false);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  static const double _tabletBreakpoint = 768;

  Widget _buildSplashStack(BuildContext context, {double? heightOverride}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final containerHeight = heightOverride ?? screenHeight;

    final isTabletOrDesktop = screenWidth >= _tabletBreakpoint;

    final useWaveCurve = copAnimated;
    final dipDepth = isTabletOrDesktop ? 32.0 : 24.0;
    final cornerRadius = useWaveCurve
        ? (isTabletOrDesktop ? 48.0 : 32.0)
        : 0.0;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(seconds: 1),
          height: copAnimated ? containerHeight / 1.9 : containerHeight,
          child: ClipPath(
            clipper: _WaveBottomClipper(
              dipDepth: useWaveCurve ? dipDepth : 0,
              cornerRadius: cornerRadius,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: copAnimated
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Visibility(
                    visible: !copAnimated,
                    child: Lottie.asset(
                      'assets/Church.json',
                      controller: _lottieController,
                      height: isTabletOrDesktop
                          ? containerHeight * 0.6
                          : containerHeight * 0.45,
                      onLoaded: (composition) {
                        final fasterDuration = Duration(
                          milliseconds: (composition.duration.inMilliseconds / 1.5)
                              .round(),
                        );
                        _lottieController
                          ..duration = fasterDuration
                          ..forward();
                      },
                    ),
                  ),
                  Visibility(
                    visible: copAnimated,
                    child: Center(
                      child: Image.asset(
                        'assets/icon.png',
                        height: isTabletOrDesktop ? 380.0 : 280.0,
                        width: isTabletOrDesktop ? 380.0 : 280.0,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTabletOrDesktop ? 32.0 : 24.0,
                        vertical: isTabletOrDesktop ? 24.0 : 16.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedOpacity(
                            opacity: animateCafeText ? 1 : 0,
                            duration: const Duration(seconds: 1),
                            child: Text(
                              'Bringing Intelligence Into Everyday Life.',
                              style: TextStyle(
                                fontSize: isTabletOrDesktop ? 30.0 : 28.0,
                                color: const Color(0xFF0D2149),
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: isTabletOrDesktop ? 16 : 12),
                         
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: copAnimated && !_checkingSession,
          child: const _BottomPart(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F44),
      body: Stack(
        children: [
          ResponsiveLayout(
            desktopBreakpoint: _tabletBreakpoint,
            mobile: _buildSplashStack(context),
            desktop: _buildDesktopLayout(context),
          ),
          // Gradient glow at bottom (Hero-style)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.33,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 896),
        child: _buildSplashStack(context, heightOverride: 700),
      ),
    );
  }
}

class _BottomPart extends StatelessWidget {
  const _BottomPart({Key? key}) : super(key: key);

  static const double _tabletBreakpoint = 768;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth >= _tabletBreakpoint;

    final textSection = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isTabletOrDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          'Explore Arvo',
          style: TextStyle(
            fontSize: isTabletOrDesktop ? 40.0 : 28.0,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: isTabletOrDesktop ? TextAlign.left : TextAlign.center,
        ),
      ],
    );

    final actionButton = GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          ),
        );
      },
      child: Container(
        height: isTabletOrDesktop ? 96.0 : 80.0,
        width: isTabletOrDesktop ? 96.0 : 80.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 2.0,
          ),
        ),
        child: Icon(
          Icons.arrow_forward,
          size: isTabletOrDesktop ? 48.0 : 40.0,
          color: Colors.white,
        ),
      ),
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isTabletOrDesktop ? 40.0 : 32.0,
          0,
          isTabletOrDesktop ? 40.0 : 32.0,
          isTabletOrDesktop ? 80.0 : 48.0,
        ),
        child: isTabletOrDesktop
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: textSection,
                    ),
                  ),
                  actionButton,
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  textSection,
                  SizedBox(height: isTabletOrDesktop ? 40.0 : 32.0),
                  actionButton,
                  const SizedBox(height: 48),
                ],
              ),
      ),
    );
  }
}