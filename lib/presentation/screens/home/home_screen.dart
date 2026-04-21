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

// ── Premium Light Palette ──────────────────────────────────────────────────────
const _white      = Color(0xFFFFFFFF);
const _bg         = Color(0xFFF5F7FF);
const _bgCard     = Color(0xFFFFFFFF);
const _blue       = Color(0xFF3B5BDB);
const _blueLight  = Color(0xFFEEF2FF);
const _blueMid    = Color(0xFFD0D9FF);
const _blueDark   = Color(0xFF2845C8);
const _violet     = Color(0xFF7048E8);
const _violetLight= Color(0xFFF3EEFF);
const _cyan       = Color(0xFF0EA5E9);
const _cyanLight  = Color(0xFFE0F2FE);
const _green      = Color(0xFF0D9488);
const _greenLight = Color(0xFFECFDF5);
const _red        = Color(0xFFE11D48);
const _redLight   = Color(0xFFFFF1F2);
const _amber      = Color(0xFFD97706);
const _amberLight = Color(0xFFFFFBEB);
const _textPri    = Color(0xFF0F172A);
const _textSec    = Color(0xFF475569);
const _textHint   = Color(0xFF94A3B8);
const _border     = Color(0xFFE8EEFF);
const _shadow     = Color(0x193B5BDB);

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
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().loadToday().then((_) => _startLiveTimer());
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
    HapticFeedback.mediumImpact();
    _showLocationSheet(loading: true, address: '', lat: 0, lon: 0, isClockedIn: isClockedIn, geoInfo: null);
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    Navigator.pop(context);
    if (loc == null) { _showError('Could not get location. Please enable GPS.'); return; }

    Map<String, dynamic>? geoInfo;
    if (!isClockedIn) {
      geoInfo = await AttendanceRepository.checkLocation(latitude: loc.latitude, longitude: loc.longitude);
    }
    final confirmed = await _showLocationSheet(
      loading: false, address: loc.address, lat: loc.latitude, lon: loc.longitude,
      isClockedIn: isClockedIn, geoInfo: geoInfo,
    );
    if (confirmed != true || !mounted) return;
    final provider = context.read<AttendanceProvider>();
    final success = isClockedIn
        ? await provider.clockOut(latitude: loc.latitude, longitude: loc.longitude)
        : await provider.clockIn(latitude: loc.latitude, longitude: loc.longitude);
    if (!mounted) return;
    if (success) {
      HapticFeedback.heavyImpact();
      if (!isClockedIn) _startLiveTimer(); else _liveTimer?.cancel();
      _showSuccess(provider.successMessage ?? (isClockedIn ? 'Clocked out!' : 'Clocked in!'));
    } else {
      _showError(provider.errorMessage ?? 'Action failed');
      provider.clearMessages();
    }
  }

  Future<bool?> _showLocationSheet({
    required bool loading, required String address,
    required double lat, required double lon,
    required bool isClockedIn, required Map<String, dynamic>? geoInfo,
  }) => showModalBottomSheet<bool>(
    context: context, isDismissible: !loading, backgroundColor: Colors.transparent,
    builder: (_) => _LocationSheet(loading: loading, address: address, latitude: lat, longitude: lon, isClockedIn: isClockedIn, geoInfo: geoInfo),
  );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(_bar(msg, _green, Icons.check_circle_rounded));
  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(_bar(msg, _red, Icons.error_rounded));
  SnackBar _bar(String msg, Color c, IconData icon) => SnackBar(
    content: Row(children: [Icon(icon, color: _white, size: 18), const SizedBox(width: 10), Expanded(child: Text(msg, style: const TextStyle(color: _white, fontWeight: FontWeight.w600)))]),
    backgroundColor: c, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), margin: const EdgeInsets.all(16),
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final member = auth.member;
    final today = attendance.today;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _blue,
          onRefresh: () => attendance.loadToday().then((_) => _startLiveTimer()),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _buildHeader(member),
              const SizedBox(height: 20),
              _buildHeroCard(today),
              const SizedBox(height: 14),
              _buildActionButton(attendance, today),
              const SizedBox(height: 14),
              _buildStatusStrip(today),
              if (today.hasClockedIn && today.log != null) ...[
                const SizedBox(height: 14),
                _buildSessionCard(today.log!),
              ],
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(member) {
    return Row(children: [
      Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_blue, _violet], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: _blue.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Center(child: Text(
          (member?.name.isNotEmpty == true ? member!.name[0] : 'U').toUpperCase(),
          style: const TextStyle(color: _white, fontWeight: FontWeight.w800, fontSize: 18),
        )),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_greeting(), style: const TextStyle(color: _textHint, fontSize: 12)),
        Text(member?.name ?? 'Employee', style: const TextStyle(color: _textPri, fontSize: 16, fontWeight: FontWeight.w800)),
      ])),
      if (member?.department != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: _blueLight, borderRadius: BorderRadius.circular(9), border: Border.all(color: _blueMid)),
          child: Text(member!.department!, style: const TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w700)),
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
          width: 38, height: 38,
          decoration: BoxDecoration(color: _redLight, borderRadius: BorderRadius.circular(11), border: Border.all(color: _red.withOpacity(0.18))),
          child: const Icon(Icons.logout_rounded, color: _red, size: 17),
        ),
      ),
    ]);
  }

  Widget _buildHeroCard(TodayStatus today) {
    final isActive = today.hasClockedIn && !today.hasClockedOut;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_blue, _violet], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: _blue.withOpacity(0.32), blurRadius: 28, offset: const Offset(0, 12)),
          BoxShadow(color: _violet.withOpacity(0.12), blurRadius: 40, spreadRadius: 4),
        ],
      ),
      child: Stack(children: [
        Positioned(right: -16, top: -16, child: Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: _white.withOpacity(0.07)))),
        Positioned(right: 24, bottom: -28, child: Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, color: _white.withOpacity(0.04)))),
        Column(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? const Color(0xFF4ADE80) : _white.withOpacity(0.5))),
                const SizedBox(width: 6),
                Text(isActive ? 'ACTIVE SESSION' : 'READY', style: TextStyle(color: _white.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Text(_currentTime, style: const TextStyle(color: _white, fontSize: 60, fontWeight: FontWeight.w200, letterSpacing: 5, height: 1)),
          const SizedBox(height: 6),
          Text(_currentDate, style: TextStyle(color: _white.withOpacity(0.65), fontSize: 13)),
          if (isActive) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(color: _white.withOpacity(0.15), borderRadius: BorderRadius.circular(50), border: Border.all(color: _white.withOpacity(0.2))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF4ADE80),
                    boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withOpacity(_pulseCtrl.value * 0.8), blurRadius: 8, spreadRadius: 2)]),
                )),
                const SizedBox(width: 9),
                Text(_formatDuration(_liveDuration), style: const TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(width: 6),
                Text('elapsed', style: TextStyle(color: _white.withOpacity(0.65), fontSize: 12)),
              ]),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _buildActionButton(AttendanceProvider attendance, TodayStatus today) {
    if (today.hasClockedIn && today.hasClockedOut) {
      return Container(
        height: 58,
        decoration: BoxDecoration(
          color: _bgCard, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(color: _shadow, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_rounded, color: _green, size: 20),
          SizedBox(width: 10),
          Text('Attendance recorded for today', style: TextStyle(color: _textSec, fontSize: 14, fontWeight: FontWeight.w600)),
        ])),
      );
    }
    final isClockedIn = today.hasClockedIn;
    final isLoading = attendance.isLoading;
    return GestureDetector(
      onTap: isLoading ? null : () => _handleClockAction(isClockedIn),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 58,
        decoration: BoxDecoration(
          color: isClockedIn ? _red : _blue,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: (isClockedIn ? _red : _blue).withOpacity(0.32), blurRadius: 18, offset: const Offset(0, 7))],
        ),
        child: Center(child: isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isClockedIn ? Icons.logout_rounded : Icons.login_rounded, color: _white, size: 21),
                const SizedBox(width: 10),
                Text(isClockedIn ? 'Clock Out' : 'Clock In', style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
              ])),
      ),
    );
  }

  Widget _buildStatusStrip(TodayStatus today) {
    Color color; IconData icon; String label; String sub;
    if (!today.hasClockedIn) { color = _textHint; icon = Icons.schedule_rounded; label = 'Not checked in'; sub = 'Start your session'; }
    else if (!today.hasClockedOut) { color = _green; icon = Icons.radio_button_checked_rounded; label = 'Currently working'; sub = 'Session in progress'; }
    else { color = _blue; icon = Icons.check_circle_rounded; label = 'Day complete'; sub = 'Great work!'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _bgCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: _shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
          child: Center(child: today.hasClockedIn && !today.hasClockedOut
            ? AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Icon(icon, color: color.withOpacity(0.4 + _pulseCtrl.value * 0.6), size: 18))
            : Icon(icon, color: color, size: 18))),
        const SizedBox(width: 12),
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
    final c = isWfo ? _blue : _cyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: isWfo ? _blueLight : _cyanLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isWfo ? Icons.business_rounded : Icons.home_rounded, size: 12, color: c),
        const SizedBox(width: 4),
        Text(isWfo ? 'WFO' : 'WFH', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _buildSessionCard(AttendanceLog log) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard, borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text("TODAY'S SESSION", style: TextStyle(color: _textHint, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const Spacer(),
          if (log.isLate) Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: _amberLight, borderRadius: BorderRadius.circular(7), border: Border.all(color: _amber.withOpacity(0.3))),
            child: Text('Late +${log.lateByMinutes}m', style: const TextStyle(color: _amber, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          _timeCell(label: 'Clock In', time: _formatTime(log.clockInTime), icon: Icons.login_rounded, color: _green),
          _vDivider(),
          _timeCell(label: 'Clock Out', time: _formatTime(log.clockOutTime), icon: Icons.logout_rounded, color: _red),
          _vDivider(),
          _timeCell(label: log.isActive ? 'Elapsed' : 'Duration', time: log.isActive ? _formatDuration(_liveDuration) : (log.durationFormatted ?? '--'), icon: Icons.timer_outlined, color: _blue),
        ]),
      ]),
    );
  }

  Widget _timeCell({required String label, required String time, required IconData icon, required Color color}) {
    return Expanded(child: Column(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.09), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 16)),
      const SizedBox(height: 7),
      Text(time, style: TextStyle(color: time == '--' ? _textHint : _textPri, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(color: _textHint, fontSize: 11)),
    ]));
  }

  Widget _vDivider() => Container(width: 1, height: 50, color: _border);

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

// ── Location Sheet ─────────────────────────────────────────────────────────────
class _LocationSheet extends StatelessWidget {
  final bool loading;
  final String address;
  final double latitude, longitude;
  final bool isClockedIn;
  final Map<String, dynamic>? geoInfo;

  const _LocationSheet({required this.loading, required this.address, required this.latitude, required this.longitude, required this.isClockedIn, this.geoInfo});

  @override
  Widget build(BuildContext context) {
    final isWfo = geoInfo?['is_inside'] == true;
    final distance = geoInfo?['distance'] as num?;
    final officeName = geoInfo?['office_name'] as String?;
    String distLabel = '';
    if (distance != null) distLabel = distance >= 1000 ? '${(distance/1000).toStringAsFixed(1)}km' : '${distance.toInt()}m';

    return Container(
      decoration: const BoxDecoration(color: _white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        if (loading) ...[
          const CircularProgressIndicator(color: _blue, strokeWidth: 2.5),
          const SizedBox(height: 16),
          const Text('Getting your location…', style: TextStyle(color: _textSec, fontSize: 14)),
          const SizedBox(height: 20),
        ] else ...[
          Text(isClockedIn ? 'Confirm Clock Out' : 'Confirm Clock In', style: const TextStyle(color: _textPri, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          if (!isClockedIn && geoInfo != null) ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isWfo ? _greenLight : _amberLight, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isWfo ? _green.withOpacity(0.25) : _amber.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(isWfo ? Icons.business_rounded : Icons.warning_amber_rounded, color: isWfo ? _green : _amber, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isWfo ? 'Inside office radius' : 'Outside office radius', style: TextStyle(color: isWfo ? _green : _amber, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(officeName != null && distLabel.isNotEmpty ? 'You are $distLabel from $officeName. Will be marked as ${isWfo ? "WFO" : "WFH"}.' : 'Will be marked as ${isWfo ? "WFO" : "WFH"}.',
                    style: TextStyle(color: isWfo ? _green.withOpacity(0.8) : _amber.withOpacity(0.9), fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: _blueLight, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.location_on_rounded, color: _blue, size: 20)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('YOUR LOCATION', style: TextStyle(color: _textHint, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 3),
                Text(address.isNotEmpty ? address : 'Fetching address…', style: const TextStyle(color: _textPri, fontSize: 13, fontWeight: FontWeight.w500)),
                Text('${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}', style: const TextStyle(color: _textHint, fontSize: 11)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: isClockedIn ? _red : _blue, foregroundColor: _white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(isClockedIn ? 'Clock Out Now' : 'Clock In Now', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: _textSec, fontSize: 14))),
        ],
      ]),
    );
  }
}