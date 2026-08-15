import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kanisaapp/components/responsive_layout.dart';
import 'package:kanisaapp/config/server.dart';
import 'package:kanisaapp/method/api.dart';

class BinStatusScreen extends StatefulWidget {
  const BinStatusScreen({super.key});

  @override
  State<BinStatusScreen> createState() => _BinStatusScreenState();
}

class _BinStatusScreenState extends State<BinStatusScreen> {
  static const Color primaryColor = Color(0xFF0A1F44);
  static const Color tealAccent = Color(0xFF0D9488);
  static const Duration _pollInterval = Duration(seconds: 30);

  bool _isLoading = true;
  bool _hasError = false;
  bool _hasReading = false;

  String deviceId = '';
  double distanceCm = 0;
  double fillPercent = 0;
  DateTime? updatedAt;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchReading();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _fetchReading(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchReading({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final result = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/bins/latest'),
      );

      final response = jsonDecode(result.body);

      if (result.statusCode == 200 && response['status'] == 200) {
        final reading = response['reading'];
        setState(() {
          deviceId = reading['device_id']?.toString() ?? '';
          distanceCm = (reading['distance_cm'] as num?)?.toDouble() ?? 0;
          fillPercent = (reading['fill_percent'] as num?)?.toDouble() ?? 0;
          updatedAt = DateTime.tryParse(reading['created_at']?.toString() ?? '');
          _hasReading = true;
          _hasError = false;
          _isLoading = false;
        });
      } else if (result.statusCode == 404) {
        setState(() {
          _hasReading = false;
          _hasError = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  String _relativeTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().toUtc().difference(time.toUtc());
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _levelColor(double percent) {
    if (percent >= 85) return Colors.red.shade600;
    if (percent >= 60) return Colors.orange.shade700;
    return tealAccent;
  }

  String _levelLabel(double percent) {
    if (percent >= 85) return 'Needs emptying';
    if (percent >= 60) return 'Filling up';
    return 'Plenty of room';
  }

  Widget _buildGauge() {
    final color = _levelColor(fillPercent);
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: (fillPercent / 100).clamp(0, 1),
              strokeWidth: 14,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${fillPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Full',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryColor.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.6)),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingCard() {
    final color = _levelColor(fillPercent);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildGauge(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _levelLabel(fillPercent),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          _buildDetailRow(Icons.straighten_rounded, 'Distance', '${distanceCm.toStringAsFixed(1)} cm'),
          _buildDetailRow(Icons.sensors_rounded, 'Device', deviceId),
          _buildDetailRow(Icons.schedule_rounded, 'Last updated', _relativeTime(updatedAt)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors_off_rounded, size: 56, color: Colors.black.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'No readings yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              'The bin sensor hasn\'t reported in. Make sure it\'s powered on and connected to WiFi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Couldn\'t load bin status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _fetchReading(),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: SpinKitFadingCircle(
          size: 80,
          duration: const Duration(milliseconds: 3200),
          itemBuilder: (context, index) {
            final palette = [Colors.black, primaryColor, tealAccent];
            return DecoratedBox(
              decoration: BoxDecoration(
                color: palette[index % palette.length],
                shape: BoxShape.circle,
              ),
            );
          },
        ),
      );
    }

    if (_hasError) return _buildErrorState();
    if (!_hasReading) return _buildEmptyState();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: _buildReadingCard(),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: () => _fetchReading(),
      color: primaryColor,
      child: _buildBody(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      appBar: AppBar(
        title: const Text('Bin Status'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildContent(),
          desktop: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }
}
