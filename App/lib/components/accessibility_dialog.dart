import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kanisaapp/theme/theme_controller.dart';

/// Shows a premium accessibility settings dialog.
void showAccessibilityDialog(BuildContext context) {
  const Color primaryColor = Color(0xFF0A1F44);
  const Color accentColor = Color(0xFF0D9488); // Teal accent

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Accessibility Settings',
    barrierColor: Colors.black.withOpacity(0.4),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );

      return ScaleTransition(
        scale: curvedAnimation,
        child: FadeTransition(
          opacity: animation,
          child: Center(
            child: AccessibilityDialogContent(
              primaryColor: primaryColor,
              accentColor: accentColor,
            ),
          ),
        ),
      );
    },
  );
}

class AccessibilityDialogContent extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;

  const AccessibilityDialogContent({
    super.key,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<AccessibilityDialogContent> createState() => _AccessibilityDialogContentState();
}

class _AccessibilityDialogContentState extends State<AccessibilityDialogContent> {
  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                  decoration: BoxDecoration(
                         color: Color(0xFF0A1F44),
                       ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.accessibility_new_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Accessibility',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Dark Mode Toggle
                      _buildOptionTile(
                        icon: Icons.dark_mode_rounded,
                        title: 'Dark Mode',
                        subtitle: 'Use darker colors for late night',
                        trailing: Switch.adaptive(
                          value: themeController.isDarkMode,
                          activeColor: widget.accentColor,
                          onChanged: (val) async {
                            await themeController.setDarkMode(val);
                            setState(() {});
                          },
                        ),
                      ),

                      const Divider(height: 32, thickness: 0.8),

                      // Accessibility Mode Toggle
                      _buildOptionTile(
                        icon: Icons.settings_accessibility_rounded,
                        title: 'Accessibility Mode',
                        subtitle: 'Simplified UI & High Contrast',
                        trailing: Switch.adaptive(
                          value: themeController.accessibilityEnabled,
                          activeColor: widget.accentColor,
                          onChanged: (val) async {
                            await themeController.setAccessibilityEnabled(val);
                            setState(() {});
                          },
                        ),
                      ),

                      const Divider(height: 32, thickness: 0.8),

                      // Text Size Slider
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.format_size_rounded, color: widget.primaryColor, size: 20),
                              const SizedBox(width: 12),
                              const Text(
                                'Text Size',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(themeController.textScaleFactor * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: widget.accentColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: widget.accentColor,
                              inactiveTrackColor: widget.accentColor.withOpacity(0.1),
                              thumbColor: widget.accentColor,
                              overlayColor: widget.accentColor.withOpacity(0.2),
                              valueIndicatorColor: widget.primaryColor,
                              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                            ),
                            child: Slider(
                              value: themeController.textScaleFactor,
                              min: 0.9,
                              max: 1.8,
                              divisions: 9,
                              label: '${(themeController.textScaleFactor * 100).toInt()}%',
                              onChanged: (v) async {
                                await themeController.setTextScale(v);
                                setState(() {});
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Aa', style: TextStyle(fontSize: 12 * 0.9, color: Colors.black45)),
                              Text('Aa', style: TextStyle(fontSize: 12 * 1.8, color: Colors.black45, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),

                      const Divider(height: 32, thickness: 0.8),

                      // Bold Text Toggle
                      _buildOptionTile(
                        icon: Icons.format_bold_rounded,
                        title: 'Bold Text',
                        subtitle: 'Heavier font weight',
                        trailing: Switch.adaptive(
                          value: themeController.boldText,
                          activeColor: widget.accentColor,
                          onChanged: (val) async {
                            await themeController.setBoldText(val);
                            setState(() {});
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // High Contrast Toggle (Independent)
                      _buildOptionTile(
                        icon: Icons.contrast_rounded,
                        title: 'High Contrast',
                        subtitle: 'Easier to read colors',
                        trailing: Switch.adaptive(
                          value: themeController.highContrast,
                          activeColor: widget.accentColor,
                          onChanged: (val) async {
                            await themeController.setHighContrast(val);
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Preview Area
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: widget.primaryColor.withOpacity(0.04),
                  child: Column(
                    children: [
                      const Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black45,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This is how your text will look.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16 * themeController.textScaleFactor,
                          fontWeight: themeController.boldText ? FontWeight.bold : FontWeight.normal,
                          color: widget.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    final themeController = ThemeController.instance;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: widget.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: themeController.boldText ? FontWeight.w900 : FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: themeController.boldText ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
