import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../providers/auth_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/services/location_service.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../auth/login_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _blue       = Color(0xFF2563EB);
const _blueDark   = Color(0xFF1D4ED8);
const _blueLight  = Color(0xFFEFF6FF);
const _cyan       = Color(0xFF0891B2);
const _cyanLight  = Color(0xFFECFEFF);
const _green      = Color(0xFF16A34A);
const _greenLight = Color(0xFFF0FDF4);
const _red        = Color(0xFFDC2626);
const _redLight   = Color(0xFFFEF2F2);
const _amber      = Color(0xFFD97706);
const _amberLight = Color(0xFFFFFBEB);
const _textPri    = Color(0xFF111827);
const _textSec    = Color(0xFF6B7280);
const _textHint   = Color(0xFF9CA3AF);
const _border     = Color(0xFFE5E7EB);
const _bg         = Color(0xFFF8FAFF);
const _white      = Color(0xFFFFFFFF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Timer? _clockTimer;
  Timer? _liveTimer;
  String _currentTime = '';
  String _currentDate = '';
  Duration _liveDuration = Duration.zero;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().loadToday().then((_) {
        _startLiveTimer();
      });
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _clockTimer?.cancel();
    _liveTimer?.cancel();
    super.dispose();
  }

  void _startLiveTimer() {
    _liveTimer?.cancel();
    final log = context.read<AttendanceProvider>().today.log;
    if (log == null || !log.isActive || log.clockInTime == null) return;

    final clockIn = DateTime.tryParse(log.clockInTime!)?.toLocal();
    if (clockIn == null) return;

    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _liveDuration = DateTime.now().difference(clockIn));
      }
    });
  }

  void _updateClock() {
    final now    = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    if (mounted) {
      setState(() {
        _currentTime = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
        _currentDate = '${days[now.weekday-1]}, ${now.day} ${months[now.month-1]} ${now.year}';
      });
    }
  }

  // ── Clock In/Out with bottom sheet ────────────────────────────────────────
  Future<void> _handleClockAction(bool isClockedIn) async {
    HapticFeedback.mediumImpact();

    // Show loading sheet while getting GPS
    _showLocationSheet(
      loading: true, address: '', lat: 0, lon: 0,
      isClockedIn: isClockedIn, geoInfo: null,
    );

    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    Navigator.pop(context);

    if (loc == null) {
      _showError('Could not get location. Please enable GPS and try again.');
      return;
    }

    // Check geofence BEFORE showing confirmation sheet
    Map<String, dynamic>? geoInfo;
    if (!isClockedIn) {
      geoInfo = await AttendanceRepository.checkLocation(
        latitude:  loc.latitude,
        longitude: loc.longitude,
      );
    }

    final confirmed = await _showLocationSheet(
      loading:     false,
      address:     loc.address,
      lat:         loc.latitude,
      lon:         loc.longitude,
      isClockedIn: isClockedIn,
      geoInfo:     geoInfo,       // ← pass geo info to sheet
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<AttendanceProvider>();
    final success  = isClockedIn
        ? await provider.clockOut(latitude: loc.latitude, longitude: loc.longitude)
        : await provider.clockIn(latitude: loc.latitude, longitude: loc.longitude);

    if (!mounted) return;
    if (success) {
      HapticFeedback.heavyImpact();
      if (!isClockedIn) _startLiveTimer();
      else              _liveTimer?.cancel();
      _showSuccess(provider.successMessage ??
          (isClockedIn ? 'Clocked out successfully' : 'Clocked in successfully'));
    } else {
      _showError(provider.errorMessage ?? 'Action failed');
      provider.clearMessages();
    }
  }


  Future<bool?> _showLocationSheet({
  required bool loading,
  required String address,
  required double lat,
  required double lon,
  required bool isClockedIn,
  required Map<String, dynamic>? geoInfo,   
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isDismissible: !loading,
    backgroundColor: Colors.transparent,
    builder: (_) => _LocationBottomSheet(
      loading:     loading,
      address:     address,
      latitude:    lat,
      longitude:   lon,
      isClockedIn: isClockedIn,
      geoInfo:     geoInfo,              
    ),
  );
}

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: _white, fontWeight: FontWeight.w600)),
    backgroundColor: _green,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
  ));

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: _white, fontWeight: FontWeight.w600)),
    backgroundColor: _red,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
  ));

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth       = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final member     = auth.member;
    final today      = attendance.today;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _blue,
          onRefresh: () => attendance.loadToday().then((_) => _startLiveTimer()),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(member),
                const SizedBox(height: 20),
                _buildClockCard(today),
                const SizedBox(height: 16),
                _buildStatusBanner(today),
                const SizedBox(height: 16),
                _buildActionButton(attendance, today),
                if (today.hasClockedIn && today.log != null) ...[
                  const SizedBox(height: 16),
                  _buildSessionCard(today.log!),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(member) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_blue, _cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              (member?.name.isNotEmpty == true ? member!.name[0] : 'U').toUpperCase(),
              style: const TextStyle(color: _white, fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(),
                  style: const TextStyle(color: _textSec, fontSize: 12)),
              Text(
                member?.name ?? 'Employee',
                style: const TextStyle(
                  color: _textPri, fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (member?.department != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _blueLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _blue.withOpacity(0.2)),
            ),
            child: Text(
              member!.department!,
              style: const TextStyle(color: _blue, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            await context.read<AuthProvider>().logout();
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _redLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _red.withOpacity(0.2)),
            ),
            child: const Icon(Icons.logout_rounded, color: _red, size: 18),
          ),
        ),
      ],
    );
  }

  // ── Clock + live timer card ───────────────────────────────────────────────
  Widget _buildClockCard(TodayStatus today) {
    final isActive = today.hasClockedIn && !today.hasClockedOut;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_blue, _cyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _currentTime,
            style: const TextStyle(
              color: _white,
              fontSize: 52,
              fontWeight: FontWeight.w200,
              letterSpacing: 4,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(_currentDate,
              style: TextStyle(color: _white.withOpacity(0.8), fontSize: 13)),

          if (isActive) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _white.withOpacity(0.5 + _pulseCtrl.value * 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_liveDuration),
                    style: const TextStyle(
                      color: _white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('elapsed',
                      style: TextStyle(color: _white.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Status banner ─────────────────────────────────────────────────────────
  Widget _buildStatusBanner(TodayStatus today) {
    Color bg, border, dotColor;
    String label;
    Widget? trailing;

    if (!today.hasClockedIn) {
      bg = _white; border = _border; dotColor = _textHint;
      label = 'Not checked in';
    } else if (!today.hasClockedOut) {
      bg = _greenLight; border = _green.withOpacity(0.3); dotColor = _green;
      label = 'Currently working';
    } else {
      bg = _blueLight; border = _blue.withOpacity(0.3); dotColor = _blue;
      label = 'Day complete';
    }

    if (today.log?.workType != null) {
      trailing = _wfoBadge(today.log!.workType);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          if (today.hasClockedIn && !today.hasClockedOut)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _green.withOpacity(0.3 + _pulseCtrl.value * 0.7),
                  boxShadow: [BoxShadow(color: _green.withOpacity(0.4), blurRadius: 6, spreadRadius: 1)],
                ),
              ),
            )
          else
            Container(width: 10, height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                color: today.hasClockedIn ? _textPri : _textSec,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              )),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _wfoBadge(String type) {
    final isWfo = type == 'wfo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isWfo ? _blueLight : _cyanLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isWfo ? _blue : _cyan).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isWfo ? Icons.business_rounded : Icons.home_rounded,
              size: 12, color: isWfo ? _blue : _cyan),
          const SizedBox(width: 4),
          Text(isWfo ? 'WFO' : 'WFH',
              style: TextStyle(
                color: isWfo ? _blue : _cyan,
                fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }

  // ── Action button ─────────────────────────────────────────────────────────
  Widget _buildActionButton(AttendanceProvider attendance, TodayStatus today) {
    if (today.hasClockedIn && today.hasClockedOut) {
      return Container(
        height: 58,
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: _blue, size: 20),
              SizedBox(width: 10),
              Text('Attendance recorded for today',
                  style: TextStyle(color: _textSec, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    final isClockedIn = today.hasClockedIn;
    final isLoading   = attendance.isLoading;

    return GestureDetector(
      onTap: isLoading ? null : () => _handleClockAction(isClockedIn),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isClockedIn
                ? [const Color(0xFFDC2626), const Color(0xFFB91C1C)]
                : [_blue, _blueDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isClockedIn ? _red : _blue).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isClockedIn ? Icons.logout_rounded : Icons.login_rounded,
                      color: _white, size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isClockedIn ? 'Clock Out' : 'Clock In',
                      style: const TextStyle(
                        color: _white, fontSize: 16,
                        fontWeight: FontWeight.w700, letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Session card ──────────────────────────────────────────────────────────
  Widget _buildSessionCard(AttendanceLog log) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("TODAY'S SESSION",
                  style: TextStyle(color: _textHint, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 1)),
              const Spacer(),
              if (log.isLate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _amberLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _amber.withOpacity(0.4)),
                  ),
                  child: Text('Late +${log.lateByMinutes}m',
                      style: const TextStyle(color: _amber, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _timeCell(label: 'Clock In',  time: _formatTime(log.clockInTime),  icon: Icons.login_rounded,  color: _green),
              _vDivider(),
              _timeCell(label: 'Clock Out', time: _formatTime(log.clockOutTime), icon: Icons.logout_rounded, color: _red),
              _vDivider(),
              _timeCell(
                label: log.isActive ? 'Elapsed' : 'Duration',
                time:  log.isActive ? _formatDuration(_liveDuration) : log.durationFormatted,
                icon:  Icons.timer_outlined,
                color: _blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeCell({required String label, required String time, required IconData icon, required Color color}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(
              color: time == '--' ? _textHint : _textPri,
              fontSize: 16, fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: _textHint, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 52, color: _border);

  // ── Utils ─────────────────────────────────────────────────────────────────
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 👋';
    if (h < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  String _formatTime(String? iso) {
    if (iso == null) return '--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return '--'; }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2,'0')}m';
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }
}
class _LocationBottomSheet extends StatelessWidget {
  final bool                 loading;
  final String               address;
  final double               latitude;
  final double               longitude;
  final bool                 isClockedIn;
  final Map<String, dynamic>? geoInfo;     // ← new

  const _LocationBottomSheet({
    required this.loading,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isClockedIn,
    this.geoInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isWfo      = geoInfo?['is_inside'] == true;
    final distance   = geoInfo?['distance'] as num?;
    final officeName = geoInfo?['office_name'] as String?;
    final radius     = geoInfo?['radius'] as num?;

    String distanceLabel = '';
    if (distance != null) {
      distanceLabel = distance >= 1000
          ? '${(distance / 1000).toStringAsFixed(1)}km'
          : '${distance.toInt()}m';
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          if (loading) ...[
            const CircularProgressIndicator(
                color: Color(0xFF2563EB), strokeWidth: 2.5),
            const SizedBox(height: 16),
            const Text('Getting your location...',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          ] else ...[

            Text(
              isClockedIn ? 'Confirm Clock Out' : 'Confirm Clock In',
              style: const TextStyle(
                color: Color(0xFF111827), fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // ── WFH warning banner (only shown when clocking IN and outside) ──
            if (!isClockedIn && geoInfo != null && !isWfo) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFD97706).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Outside office radius',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            officeName != null && distanceLabel.isNotEmpty
                                ? 'You are $distanceLabel from $officeName. '
                                  'This will be marked as WFH.'
                                : 'You are outside the office. '
                                  'This will be marked as WFH.',
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── WFO confirmation banner ────────────────────────────────────
            if (!isClockedIn && geoInfo != null && isWfo) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF16A34A).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business_rounded,
                        color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inside office radius',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            officeName != null
                                ? 'You are ${distanceLabel.isNotEmpty ? "$distanceLabel from " : "at "}$officeName. '
                                  'This will be marked as WFO.'
                                : 'You are inside the office. Will be marked as WFO.',
                            style: const TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── GPS location row ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Color(0xFF2563EB), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your location',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 11,
                              fontWeight: FontWeight.w600, letterSpacing: 0.5,
                            )),
                        const SizedBox(height: 3),
                        Text(
                          address.isNotEmpty ? address : 'Fetching address...',
                          style: const TextStyle(
                            color: Color(0xFF111827), fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${latitude.toStringAsFixed(5)}, '
                          '${longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF), fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Confirm button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isClockedIn
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isClockedIn ? 'Clock Out Now' : 'Clock In Now',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Color(0xFF6B7280), fontSize: 14)),
            ),
          ],
        ],
      ),
    );
  }
}