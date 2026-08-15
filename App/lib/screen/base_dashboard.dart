import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kanisaapp/components/accessibility_dialog.dart';

import 'package:kanisaapp/config/server.dart';
import 'package:kanisaapp/method/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BaseDashboard extends StatefulWidget {
  const BaseDashboard({super.key});

  @override
  State<BaseDashboard> createState() => BaseDashboardState();

  // Abstract methods to be implemented by specific role dashboards
  String getRoleTitle();
  String getRoleDescription();
  List<DashboardCard> getDashboardCards(BuildContext context);
  Color getPrimaryColor();
  Color getSecondaryColor();
  IconData getRoleIcon();

  // Optional: Override to add circular action buttons (Learning App Style)
  List<CircularActionButton> getCircularActions(BuildContext context) {
    return []; // Default: no circular actions
  }
}

class BaseDashboardState extends State<BaseDashboard> {
  SharedPreferences? preferences;
  String username = '';
  String email = '';
  int userId = 0;
  bool isLoading = false;
  bool _showAllActions = false;
  final String? profileImageUrl = null;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

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
      // Keep whatever was already loaded from preferences.
    }
  }

  Widget _buildProfileImage({double size = 240}) {
    final double imageSize = size;

    String getInitials(String name) {
      if (name.isEmpty) return 'JD';
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty) return 'JD';

      String initials = '';
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials += parts[0][0];
      }
      if (parts.length > 1 && parts[1].isNotEmpty) {
        initials += parts[1][0];
      }
      return initials.toUpperCase();
    }

    Widget buildInitialsFallback() {
      return Container(
        height: imageSize,
        width: imageSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0A1F44),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFFD54F), // Amber/Gold color
            width: 4.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          getInitials(username),
          style: TextStyle(
            fontSize: imageSize * 0.35,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      );
    }

    if (profileImageUrl == null || profileImageUrl!.isEmpty) {
      return buildInitialsFallback();
    }

    String imageUrl = profileImageUrl!.trim();

    // Build full URL if necessary
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      final baseUrl = Config.baseUrl.replaceAll('/api', '');
      imageUrl = baseUrl + (imageUrl.startsWith('/') ? imageUrl : '/$imageUrl');
    }

    return Container(
      height: imageSize,
      width: imageSize,
      decoration: BoxDecoration(
        color: const Color(0xFFB2EBF2),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFFD54F), // Amber/Gold color
          width: 2.5, // Thinner border for dashboard avatar
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          key: ValueKey(imageUrl),
          fit: BoxFit.cover,
          width: imageSize,
          height: imageSize,
          errorBuilder: (context, error, stackTrace) {
            return buildInitialsFallback();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return SizedBox(
              width: imageSize,
              height: imageSize,
              child: Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }
            return Container(
              width: imageSize,
              height: imageSize,
              color: Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<bool> _onWillPop() async {
    const Color primaryColor = Color(0xFF0A1F44);

    final bool? result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: curved,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 26),
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 6),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Circular Icon Container
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.08),
                    ),
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      color: primaryColor,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Title
                  Text(
                    'Exit App',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Description
                  const Text(
                    'Do you want to close the application?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.35,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Action Buttons
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Stay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                            shadowColor: primaryColor.withOpacity(0.25),
                            backgroundColor: primaryColor,
                          ),
                          child: const Text(
                            'Exit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: SizedBox(
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
      );
    }

    return _buildDashboard();
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopBar(),
          _buildUserInfoCard(),
          _buildDashboardGrid(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            _buildProfileImage(size: 64),
            const SizedBox(width: 14),

            // Greeting Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${getGreeting()} 👋,',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    username.endsWith('.') ? username : '$username.',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Color(0xFF0A1F44),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Accessibility Icon
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.accessibility_new_rounded, size: 26, color: Color(0xFF0A1F44)),
                onPressed: () => showAccessibilityDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    const Color brand = Color(0xFF0A1F44);
    const Color tealAccent = Color(0xFF0D9488);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.black.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: brand.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Left gradient accent (M-Pesa style) – positioned so card height comes from content
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        brand,
                        Color(0xFF193D71),
                        tealAccent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content area (provides intrinsic height; pattern + watermark + text)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _NetworkPatternPainter(
                          color: brand.withOpacity(0.07),
                          cellSize: 32,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Opacity(
                        opacity: 0.02,
                        child: Image.asset(
                          'assets/icon.png',
                          height: 180,
                          width: 180,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Karibu, ${username.isEmpty ? 'there' : username}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A1F44),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            Icons.email_outlined,
                            email,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            Icons.person_outline,
                            'Role: ${widget.getRoleTitle()}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0A1F44).withOpacity(0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardGrid() {
    final circularActions = widget.getCircularActions(context);
    final cards = widget.getDashboardCards(context);

    // Separate featured cards from regular list items
    final featuredCards = cards.where((card) => card.isFeatured).toList();
    final listItems = cards.where((card) => !card.isFeatured).toList();

    // Apply show/hide logic
    final visibleListItems = _showAllActions ? listItems : listItems.take(3).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular Actions Grid (Learning App Style)
          if (circularActions.isNotEmpty) ...[
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: circularActions,
            ),
            const SizedBox(height: 16),
          ],

          // Section header for featured cards
          if (featuredCards.isNotEmpty) ...[
            const Text(
              'Featured',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Featured cards section - Horizontal scrollable row
            SizedBox(
              height: 130, // Fixed height for horizontal cards
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featuredCards.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.85, // 85% of screen width
                    margin: EdgeInsets.only(
                      right: index < featuredCards.length - 1 ? 12 : 0,
                    ),
                    child: featuredCards[index],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // More actions header with toggle
          if (listItems.isNotEmpty) ...[
            Row(
              children: [
                const Text(
                  'More Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllActions = !_showAllActions;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: widget.getPrimaryColor(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 0),
                    textStyle: const TextStyle(fontSize: 15),
                  ),
                  child: Text(_showAllActions ? 'Show less' : 'View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // List items in a container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: visibleListItems,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _buildBody(),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;
  final bool isFeatured;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return isFeatured ? _buildFeaturedCard() : _buildListItem();
  }

  Widget _buildFeaturedCard() {
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withOpacity(0.25),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: RadialGradient(
                              colors: [
                                color.withOpacity(0.15),
                                Colors.transparent,
                              ],
                              center: Alignment.topLeft,
                              radius: 1.2,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          icon,
                          size: 32,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withOpacity(0.55),
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withOpacity(0.08),
          highlightColor: color.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 24,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.black.withOpacity(0.5),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black.withOpacity(0.25),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Circular Action Button Widget (Learning App Style)
class CircularActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  const CircularActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Paints a subtle grid + diagonal "network linked" pattern for info cards.
class _NetworkPatternPainter extends CustomPainter {
  final Color color;
  final double cellSize;

  _NetworkPatternPainter({required this.color, this.cellSize = 32});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;

    final paintThin = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 0.25
      ..style = PaintingStyle.stroke;

    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;

    for (int i = 0; i <= cols; i++) {
      final x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int j = 0; j <= rows; j++) {
      final y = j * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (int i = 0; i <= cols; i++) {
      for (int j = 0; j <= rows; j++) {
        final x = i * cellSize;
        final y = j * cellSize;
        if (x < size.width && y < size.height) {
          canvas.drawLine(Offset(x, y), Offset(x + cellSize, y + cellSize), paintThin);
          canvas.drawLine(Offset(x + cellSize, y), Offset(x, y + cellSize), paintThin);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
