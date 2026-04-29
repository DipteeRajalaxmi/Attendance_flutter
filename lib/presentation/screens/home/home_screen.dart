import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../../providers/auth_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/services/location_service.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../auth/login_screen.dart';

// ── Navy · Cyan · White Palette ────────────────────────────────────────────────
const _navy       = Color(0xFF0D1B3E);   // deep navy
const _navyMid    = Color(0xFF152347);   // card navy
const _navyLight  = Color(0xFF1E3060);   // lighter navy
const _navyAccent = Color(0xFF243880);   // border/accent navy
const _cyan       = Color(0xFF00B4D8);   // primary cyan
const _cyanLight  = Color(0xFF48CAE4);   // lighter cyan
const _cyanPale   = Color(0xFFE0F7FA);   // pale cyan tint (on white)
const _cyanDeep   = Color(0xFF0096C7);   // deeper cyan
const _white      = Color(0xFFFFFFFF);
const _offWhite   = Color(0xFFF0F4FF);   // screen background
const _cardWhite  = Color(0xFFFFFFFF);
const _green      = Color(0xFF00C897);   // teal-green
const _greenPale  = Color(0xFFE6FBF5);
const _red        = Color(0xFFFF4D6D);
const _redPale    = Color(0xFFFFF0F3);
const _amber      = Color(0xFFFFB703);
const _amberPale  = Color(0xFFFFF8E1);
const _textPri    = Color(0xFF0D1B3E);
const _textSec    = Color(0xFF4A5680);
const _textHint   = Color(0xFF8F9BBF);
const _border     = Color(0xFFDDE3F5);
const _shadowBlue = Color(0x1A0D1B3E);

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
  late AnimationController _ringCtrl;

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final dPhi = (lat2 - lat1) * math.pi / 180;
    final dLam = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dPhi/2) * math.sin(dPhi/2) +
              math.cos(phi1) * math.cos(phi2) *
              math.sin(dLam/2) * math.sin(dLam/2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _ringCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().loadToday().then((_) => _startLiveTimer());
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
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
      if (mounted) setState(() => _liveDuration = DateTime.now().difference(clockIn));
    });
  }

  void _updateClock() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    if (mounted) setState(() {
      _currentTime = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
      _currentDate = '${days[now.weekday-1]}, ${now.day} ${months[now.month-1]} ${now.year}';
    });
  }

  Future<void> _handleClockAction(bool isClockedIn) async {
    final dbgLog = context.read<AttendanceProvider>().today.log;
    debugPrint('>>> LOG: workType=${dbgLog?.workType}, lat=${dbgLog?.clockInLatitude}, lon=${dbgLog?.clockInLongitude}');
    debugPrint('>>> isClockedIn: $isClockedIn');
    HapticFeedback.mediumImpact();
    _showLocationSheet(loading: true, address: '', lat: 0, lon: 0, isClockedIn: isClockedIn, geoInfo: null);
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    Navigator.pop(context);
    if (loc == null) { _showError('Could not get location. Enable GPS and retry.'); return; }
      Map<String, dynamic>? geoInfo;
      if (isClockedIn) {
        final log = context.read<AttendanceProvider>().today.log;
        if (log != null && log.workType == 'wfh' &&
            log.clockInLatitude != null && log.clockInLongitude != null) {
          
          final dist = _haversineDistance(loc.latitude, loc.longitude, log.clockInLatitude!, log.clockInLongitude!);
          debugPrint('>>> WFH distance from clock-in: ${dist.toInt()}m'); // ← add this
          
          geoInfo = {
            'is_inside':   false,
            'distance':    dist,
            'office_name': 'clock-in location',
            'is_wfh_out':  true,
          };
          if ((geoInfo['distance'] as double) <= 500) geoInfo = null;
        }
      } else {
        geoInfo = await AttendanceRepository.checkLocation(
          latitude: loc.latitude,
          longitude: loc.longitude,
        );
      }
    final confirmed = await _showLocationSheet(loading: false, address: loc.address, lat: loc.latitude, lon: loc.longitude, isClockedIn: isClockedIn, geoInfo: geoInfo);
    if (confirmed != true || !mounted) return;
    final provider = context.read<AttendanceProvider>();
    final success = isClockedIn
        ? await provider.clockOut(latitude: loc.latitude, longitude: loc.longitude)
        : await provider.clockIn(latitude: loc.latitude, longitude: loc.longitude);
    if (!mounted) return;
    if (success) {
      HapticFeedback.heavyImpact();
      if (!isClockedIn) {
        _startLiveTimer();
      } else {
        _liveTimer?.cancel();
        // ← show warning if WFH clocked out outside radius
        final warning = context.read<AttendanceProvider>().clockOutWarning;
        if (warning != null && mounted) {
          _showError(warning); // shows as red snackbar
          context.read<AttendanceProvider>().clearMessages();
          return; // skip success message
        }
      }
      _showSuccess(provider.successMessage ?? (isClockedIn ? 'Clocked out!' : 'Clocked in!'));
    } else {
      _showError(provider.errorMessage ?? 'Action failed');
      provider.clearMessages();
    }
  }

  Future<bool?> _showLocationSheet({required bool loading, required String address, required double lat, required double lon, required bool isClockedIn, required Map<String, dynamic>? geoInfo}) =>
  showModalBottomSheet<bool>(
    context: context,
    isDismissible: !loading,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,  // ← allows sheet to grow with keyboard/content
    useSafeArea: true,          // ← respects bottom safe area automatically
    builder: (_) => _LocationSheet(loading: loading, address: address, latitude: lat, longitude: lon, isClockedIn: isClockedIn, geoInfo: geoInfo));

  void _showSuccess(String msg) => _snack(msg, _green, Icons.check_circle_rounded);
  void _showError(String msg)   => _snack(msg, _red, Icons.error_rounded);
  void _snack(String msg, Color c, IconData icon) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [Icon(icon, color: _white, size: 18), const SizedBox(width: 10), Expanded(child: Text(msg, style: const TextStyle(color: _white, fontWeight: FontWeight.w600)))]),
    backgroundColor: c, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), margin: const EdgeInsets.all(16),
  ));

  @override
  Widget build(BuildContext context) {
    final auth       = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final member     = auth.member;
    final today      = attendance.today;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _offWhite,
      body: SafeArea(
        child: RefreshIndicator(
          color: _cyan,
          onRefresh: () => attendance.loadToday().then((_) => _startLiveTimer()),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // ── Navy top section ──────────────────────────────────────────
              _buildNavySection(member, today),
              // ── White bottom section ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _buildActionButton(attendance, today),
                  const SizedBox(height: 16),
                  _buildStatusStrip(today),
                  if (today.hasClockedIn && today.log != null) ...[
                    const SizedBox(height: 16),
                    _buildSessionCard(today.log!),
                  ],
                  const SizedBox(height: 100),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Navy hero section ──────────────────────────────────────────────────────
  Widget _buildNavySection(member, TodayStatus today) {
    final isActive = today.hasClockedIn && !today.hasClockedOut;

    return Container(
      decoration: const BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(children: [
        // Header row
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _navyLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cyan.withOpacity(0.4)),
            ),
            child: Center(child: Text(
              (member?.name?.isNotEmpty == true ? member!.name[0] : 'U').toUpperCase(),
              style: const TextStyle(color: _cyan, fontWeight: FontWeight.w800, fontSize: 18),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_greeting(), style: TextStyle(color: _white.withOpacity(0.55), fontSize: 12)),
            Text(member?.name ?? 'Employee', style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w800)),
          ])),
          if (member?.department != null) ...[
            Container(
              constraints: const BoxConstraints(maxWidth: 110),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _cyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _cyan.withOpacity(0.35)),
              ),
              child: Text(
                member!.department!,
                style: const TextStyle(color: _cyan, fontSize: 11, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _red.withOpacity(0.3)),
              ),
              child: const Icon(Icons.logout_rounded, color: _red, size: 16),
            ),
          ),
        ]),

        const SizedBox(height: 28),

        // Clock + ring
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? _green.withOpacity(0.15) : _white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? _green.withOpacity(0.4) : _white.withOpacity(0.15)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) =>
                  Container(width: 7, height: 7,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: isActive ? _green : _white.withOpacity(0.5),
                      boxShadow: isActive ? [BoxShadow(color: _green.withOpacity(_pulseCtrl.value * 0.7), blurRadius: 6, spreadRadius: 1)] : null,
                    ))),
                const SizedBox(width: 7),
                Text(isActive ? 'ACTIVE' : 'READY',
                  style: TextStyle(color: isActive ? _green : _white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              ]),
            ),
            const SizedBox(height: 14),
            Text(_currentTime, style: const TextStyle(color: _white, fontSize: 54, fontWeight: FontWeight.w200, letterSpacing: 4, height: 1)),
            const SizedBox(height: 6),
            Text(_currentDate, style: TextStyle(color: _white.withOpacity(0.5), fontSize: 12, letterSpacing: 0.3)),
            if (isActive) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: _cyan.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer_outlined, color: _cyan, size: 14),
                  const SizedBox(width: 6),
                  Text(_formatDuration(_liveDuration),
                    style: const TextStyle(color: _cyan, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  const SizedBox(width: 5),
                  Text('elapsed', style: TextStyle(color: _white.withOpacity(0.4), fontSize: 11)),
                ]),
              ),
            ],
          ])),

          // Circular progress ring
          _buildProgressRing(today),
        ]),
      ]),
    );
  }

  Widget _buildProgressRing(TodayStatus today) {
    // Show progress based on workday (9h = 540min)
    double progress = 0;
    if (_liveDuration.inMinutes > 0) {
      progress = (_liveDuration.inMinutes / 540).clamp(0, 1);
    }

    return AnimatedBuilder(
      animation: _ringCtrl,
      builder: (_, __) {
        final animated = Curves.easeOut.transform(_ringCtrl.value) * progress;
        return SizedBox(
          width: 100, height: 100,
          child: CustomPaint(
            painter: _RingPainter(progress: animated, ringColor: _cyan, trackColor: _white.withOpacity(0.08)),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${(progress * 100).toInt()}%',
                style: const TextStyle(color: _white, fontSize: 18, fontWeight: FontWeight.w800)),
              Text('today', style: TextStyle(color: _white.withOpacity(0.4), fontSize: 9, letterSpacing: 0.5)),
            ])),
          ),
        );
      },
    );
  }

  // ── Action Button ────────────────────────────────────────────────────────────
  Widget _buildActionButton(AttendanceProvider attendance, TodayStatus today) {
    if (today.hasClockedIn && today.hasClockedOut) {
      return Container(
        height: 58,
        decoration: BoxDecoration(
          color: _cardWhite, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _green.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: _shadowBlue, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_rounded, color: _green, size: 20),
          SizedBox(width: 10),
          Text('Attendance recorded for today', style: TextStyle(color: _textSec, fontSize: 14, fontWeight: FontWeight.w600)),
        ])),
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
            colors: isClockedIn ? [_red, const Color(0xFFFF2255)] : [_cyan, _cyanDeep],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color: (isClockedIn ? _red : _cyan).withOpacity(0.38),
            blurRadius: 18, offset: const Offset(0, 7),
          )],
        ),
        child: Center(child: isLoading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(isClockedIn ? Icons.logout_rounded : Icons.login_rounded, color: _white, size: 22),
              const SizedBox(width: 10),
              Text(isClockedIn ? 'Clock Out' : 'Clock In',
                style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
            ])),
      ),
    );
  }

  // ── Status strip ─────────────────────────────────────────────────────────────
  Widget _buildStatusStrip(TodayStatus today) {
    Color color; IconData icon; String label; String sub;
    if (!today.hasClockedIn)       { color = _textHint; icon = Icons.schedule_rounded;              label = 'Not checked in';   sub = 'Start your session'; }
    else if (!today.hasClockedOut) { color = _green;    icon = Icons.radio_button_checked_rounded;  label = 'Currently working'; sub = 'Session in progress'; }
    else                           { color = _cyan;     icon = Icons.check_circle_rounded;           label = 'Day complete';      sub = 'Great work today!'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardWhite, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: _shadowBlue, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Center(child: today.hasClockedIn && !today.hasClockedOut
            ? AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Icon(icon, color: color.withOpacity(0.4 + _pulseCtrl.value * 0.6), size: 19))
            : Icon(icon, color: color, size: 19))),
        const SizedBox(width: 13),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(sub, style: const TextStyle(color: _textHint, fontSize: 11)),
        ]),
        const Spacer(),
        if (today.log?.workType != null) _workBadge(today.log!.workType),
      ]),
    );
  }

  Widget _workBadge(String type) {
    final isWfo = type == 'wfo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: isWfo ? _navy.withOpacity(0.07) : _cyanPale,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: isWfo ? _navy.withOpacity(0.2) : _cyan.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isWfo ? Icons.business_rounded : Icons.home_rounded, size: 13, color: isWfo ? _navy : _cyan),
        const SizedBox(width: 4),
        Text(isWfo ? 'WFO' : 'WFH', style: TextStyle(color: isWfo ? _navy : _cyan, fontSize: 11, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  // ── Session card ──────────────────────────────────────────────────────────────
  Widget _buildSessionCard(AttendanceLog log) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite, borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _shadowBlue, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 3, height: 14,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [_cyan, _cyanDeep], begin: Alignment.topCenter, end: Alignment.bottomCenter), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          const Text("TODAY'S SESSION", style: TextStyle(color: _textHint, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const Spacer(),
          if (log.isLate) Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: _amberPale, borderRadius: BorderRadius.circular(7), border: Border.all(color: _amber.withOpacity(0.35))),
            child: Text('Late +${log.lateByMinutes}m', style: const TextStyle(color: _amber, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          _timeCell(label: 'Clock In',  time: _formatTime(log.clockInTime),  icon: Icons.login_rounded,  color: _green),
          _vDivider(),
          _timeCell(label: 'Clock Out', time: _formatTime(log.clockOutTime), icon: Icons.logout_rounded, color: _red),
          _vDivider(),
          _timeCell(label: log.isActive ? 'Elapsed' : 'Duration', time: log.isActive ? _formatDuration(_liveDuration) : log.durationFormatted, icon: Icons.timer_outlined, color: _cyan),
        ]),
      ]),
    );
  }

  Widget _timeCell({required String label, required String time, required IconData icon, required Color color}) =>
    Expanded(child: Column(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: color, size: 17)),
      const SizedBox(height: 8),
      Text(time, style: TextStyle(color: time == '--' ? _textHint : _textPri, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(color: _textHint, fontSize: 11)),
    ]));

  Widget _vDivider() => Container(width: 1, height: 52, color: _border);

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 👋';
    if (h < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }
  String _formatTime(String? iso) {
    if (iso == null) return '--';
    try { final dt = DateTime.parse(iso).toLocal(); return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}'; }
    catch (_) { return '--'; }
  }
  String _formatDuration(Duration d) {
    final h = d.inHours; final m = d.inMinutes % 60; final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2,'0')}m';
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }
}

// ── Ring painter ───────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  const _RingPainter({required this.progress, required this.ringColor, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final radius = (size.width - 14) / 2;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round;

    paint.color = trackColor;
    canvas.drawCircle(Offset(cx, cy), radius, paint);

    if (progress > 0) {
      paint.color = ringColor;
      paint.shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + math.pi * 2 * progress,
        colors: [ringColor, ringColor.withOpacity(0.7)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: radius), -math.pi / 2, math.pi * 2 * progress, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Location sheet ─────────────────────────────────────────────────────────────
class _LocationSheet extends StatelessWidget {
  final bool loading;
  final String address;
  final double latitude, longitude;
  final bool isClockedIn;
  final Map<String, dynamic>? geoInfo;

  const _LocationSheet({required this.loading, required this.address, required this.latitude, required this.longitude, required this.isClockedIn, this.geoInfo});

  @override
  Widget build(BuildContext context) {
    final isWfo    = geoInfo?['is_inside'] == true;
    final distance = geoInfo?['distance'] as num?;
    final office   = geoInfo?['office_name'] as String?;
    final dist     = distance == null ? '' : distance >= 1000 ? '${(distance/1000).toStringAsFixed(1)}km' : '${distance.toInt()}m';
    final isWfhOutWarning = geoInfo?['is_wfh_out'] == true; // ← add here


    return Container(
      decoration: const BoxDecoration(color: _white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 22),
        if (loading) ...[
          const CircularProgressIndicator(color: _cyan, strokeWidth: 2.5),
          const SizedBox(height: 16),
          const Text('Getting your location…', style: TextStyle(color: _textSec, fontSize: 14)),
          const SizedBox(height: 20),
        ] else ...[
          Text(isClockedIn ? 'Confirm Clock Out' : 'Confirm Clock In',
            style: const TextStyle(color: _textPri, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          if (geoInfo != null) ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isWfhOutWarning ? _redPale : (isWfo ? _greenPale : _amberPale),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isWfhOutWarning ? _red.withOpacity(0.3) : (isWfo ? _green.withOpacity(0.3) : _amber.withOpacity(0.3))),
              ),
              child: Row(children: [
                Icon(
                  isWfhOutWarning ? Icons.warning_rounded : (isWfo ? Icons.business_rounded : Icons.warning_amber_rounded),
                  color: isWfhOutWarning ? _red : (isWfo ? _green : _amber),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    isWfhOutWarning
                        ? '⚠️ Far from clock-in location'
                        : (isWfo ? 'Inside office radius' : 'Outside office radius'),
                    style: TextStyle(
                      color: isWfhOutWarning ? _red : (isWfo ? _green : _amber),
                      fontSize: 13, fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isWfhOutWarning
                        ? 'You are $dist from where you clocked in. This will mark today as Absent.'
                        : (office != null && dist.isNotEmpty
                            ? 'You are $dist from $office. Will be ${isWfo ? "WFO" : "WFH"}.'
                            : 'Will be marked as ${isWfo ? "WFO" : "WFH"}.'),
                    style: TextStyle(
                      color: (isWfhOutWarning ? _red : (isWfo ? _green : _amber)).withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ])),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _offWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: _cyanPale, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.location_on_rounded, color: _cyan, size: 20)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('YOUR LOCATION', style: TextStyle(color: _textHint, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 3),
                Text(address.isNotEmpty ? address : 'Fetching…', style: const TextStyle(color: _textPri, fontSize: 13, fontWeight: FontWeight.w500)),
                Text('${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}', style: const TextStyle(color: _textHint, fontSize: 11)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isClockedIn ? _red : _cyan, foregroundColor: _white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(isClockedIn ? 'Clock Out Now' : 'Clock In Now',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: _textSec, fontSize: 14))),
        ],
      ]),
    );
  }
}