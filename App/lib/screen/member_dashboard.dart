import 'package:flutter/material.dart';
import 'package:kanisaapp/screen/base_dashboard.dart';
import 'package:kanisaapp/screen/bin_status.dart';

class MemberDashboard extends BaseDashboard {
  const MemberDashboard({super.key});

  @override
  String getRoleTitle() => 'Member';

  @override
  String getRoleDescription() {
    return 'Access your contributions, church updates, groups, and events';
  }

  @override
  List<CircularActionButton> getCircularActions(BuildContext context) {
    return [];
  }

  @override
  List<DashboardCard> getDashboardCards(BuildContext context) {
    return [
      DashboardCard(
        icon: Icons.delete_outline_rounded,
        title: 'Bin Status',
        subtitle: 'Live fill level from the sensor',
        color: _accent,
        isFeatured: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BinStatusScreen()),
        ),
      ),
    ];
  }

  @override
  Color getPrimaryColor() => _primary;

  @override
  Color getSecondaryColor() => _accent;

  @override
  IconData getRoleIcon() => Icons.person_outline;

  static const Color _primary = Color(0xFF0A1F44);
  static const Color _accent = Color(0xFF20BBA6);
}
