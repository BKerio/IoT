import 'package:flutter/material.dart';
import 'package:kanisaapp/components/responsive_layout.dart';
import 'package:kanisaapp/screen/login.dart';
import 'package:kanisaapp/screen/member_onboard.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  static const double _maxContentWidth = 448; // max-w-md

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    const Color darkBlue = Color(0xFF0A1F44);

    return Scaffold(
      backgroundColor: darkBlue,
      body: ResponsiveLayout(
        desktopBreakpoint: ResponsiveBreakpoints.tablet,
        mobile: _buildWelcomeContent(context, currentYear, false),
        desktop: _buildWelcomeContent(context, currentYear, true),
      ),
    );
  }

  Widget _buildWelcomeContent(
    BuildContext context,
    int year,
    bool isTabletOrDesktop,
  ) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Welcome.tsx: h-[40vh] md:h-[45vh], rounded-b-[4rem] md:rounded-b-[6rem]
    final imageHeight = isTabletOrDesktop
        ? screenHeight * 0.45
        : screenHeight * 0.40;
    final imageRadius = isTabletOrDesktop ? 96.0 : 64.0;

    // Logo: w-28 h-28 (112) mobile, w-32 h-32 (128) md, -mt-24 md:-mt-28
    final logoSize = isTabletOrDesktop ? 128.0 : 112.0;
    final logoOverlap = isTabletOrDesktop ? 112.0 : 96.0;

    return SafeArea(
      child: Column(
        children: [
          // Top image section (Welcome.tsx style)
          SizedBox(
            height: imageHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(imageRadius),
                bottomRight: Radius.circular(imageRadius),
              ),
              child: Image.asset(
                "assets/img-3.png",
                width: screenWidth,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Content section - centered, max-w-md (Welcome.tsx flex-1)
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTabletOrDesktop ? 32 : 24,
                    vertical: isTabletOrDesktop ? 40 : 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo - overlapping image (Welcome.tsx: -mt-24 md:-mt-28)
                        Transform.translate(
                          offset: Offset(0, -logoOverlap / 2),
                          child: Container(
                              width: logoSize + 24,
                              height: logoSize + 24,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF0A1F44),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                "assets/icon.png",
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          SizedBox(height: isTabletOrDesktop ? 32 : 24),

                          // Headline: text-xl md:text-2xl
                          Text(
                            "Arvo",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTabletOrDesktop ? 30 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),

                          SizedBox(height: isTabletOrDesktop ? 12 : 8),

                          // Subtitle: text-white/60 text-sm md:text-base
                          Text(
                            "Bringing Intelligence Into Everyday Life.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTabletOrDesktop ? 16 : 14,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),

                          SizedBox(height: isTabletOrDesktop ? 48 : 36),

                          // Buttons: border-white/20, bg-white/5, rounded-2xl
                          _buildWelcomeButton(
                            context: context,
                            label: "Login",
                            icon: Icons.login_rounded,
                            isTabletOrDesktop: isTabletOrDesktop,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const Login()),
                            ),
                          ),

                          SizedBox(height: 16),

                          _buildWelcomeButton(
                            context: context,
                            label: "Self registration",
                            icon: Icons.person_add_alt,
                            isTabletOrDesktop: isTabletOrDesktop,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const Register()),
                            ),
                          ),

                          SizedBox(height: isTabletOrDesktop ? 48 : 32),

                          // Footer: text-[10px] text-white/30 uppercase
                          _buildFooter(year),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isTabletOrDesktop,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isTabletOrDesktop ? 18 : 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.7),
                  size: isTabletOrDesktop ? 22 : 20,
                ),
                SizedBox(width: isTabletOrDesktop ? 14 : 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isTabletOrDesktop ? 17 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(int year) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        "© $year PCEA Church Application | All rights reserved",
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withOpacity(0.3),
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

}
