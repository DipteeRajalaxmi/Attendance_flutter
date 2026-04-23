import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../providers/leave_provider.dart';
import '../../../data/models/leave_model.dart';
import '../../../providers/notification_provider.dart';

// ── Navy · Cyan · White Palette ────────────────────────────────────────────────
const _navy       = Color(0xFF0D1B3E);
const _navyMid    = Color(0xFF152347);
const _navyLight  = Color(0xFF1E3060);
const _cyan       = Color(0xFF00B4D8);
const _cyanLight  = Color(0xFF48CAE4);
const _cyanPale   = Color(0xFFE0F7FA);
const _cyanDeep   = Color(0xFF0096C7);
const _white      = Color(0xFFFFFFFF);
const _offWhite   = Color(0xFFF0F4FF);
const _cardWhite  = Color(0xFFFFFFFF);
const _green      = Color(0xFF00C897);
const _greenPale  = Color(0xFFE6FBF5);
const _greenMid   = Color(0xFFB2F0E0);
const _red        = Color(0xFFFF4D6D);
const _redPale    = Color(0xFFFFF0F3);
const _redMid     = Color(0xFFFFD6DE);
const _amber      = Color(0xFFFFB703);
const _amberPale  = Color(0xFFFFF8E1);
const _amberMid   = Color(0xFFFFE082);
const _purple     = Color(0xFF7C4DFF);
const _purplePale = Color(0xFFF3EEFF);
const _purpleMid  = Color(0xFFD1C4E9);
const _teal       = Color(0xFF00ACC1);
const _tealPale   = Color(0xFFE0F7FA);
const _textPri    = Color(0xFF0D1B3E);
const _textSec    = Color(0xFF4A5680);
const _textHint   = Color(0xFF8F9BBF);
const _border     = Color(0xFFDDE3F5);
const _shadowBlue = Color(0x1A0D1B3E);

const _palette = [
  (_cyan,   _cyanPale,   _cyanLight),
  (_green,  _greenPale,  _greenMid),
  (_amber,  _amberPale,  _amberMid),
  (_purple, _purplePale, _purpleMid),
  (_teal,   _tealPale,   Color(0xFFB2EBF2)),
  (_red,    _redPale,    _redMid),
];

(Color, Color, Color) _cardColors(int i) => _palette[i % _palette.length];

(Color, String) _statusConfig(String s) {
  switch (s) {
    case 'approved':  return (_green,    'Approved');
    case 'rejected':  return (_red,      'Rejected');
    case 'cancelled': return (_textHint, 'Cancelled');
    default:          return (_amber,    'Pending');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});
  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<LeaveProvider>().loadAll());
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  void _showApplySheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent, useSafeArea: true,
      builder: (_) => _ApplyLeaveSheet(types: context.read<LeaveProvider>().types),
    ).then((ok) { if (ok == true && mounted) _toast('Leave request submitted!', _green, Icons.check_circle_rounded); });
  }

  void _toast(String msg, Color c, IconData icon) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [Icon(icon, color: _white, size: 18), const SizedBox(width: 10), Text(msg, style: const TextStyle(color: _white, fontWeight: FontWeight.w600, fontSize: 13))]),
    backgroundColor: c, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    duration: const Duration(seconds: 3),
  ));

  void _showNotificationSheet(BuildContext context) {
    final notifications = context.read<NotificationProvider>().notifications;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: _white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Notifications', style: TextStyle(color: _textPri, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('No notifications yet', style: TextStyle(color: _textHint)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = notifications[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: n.isApproved ? _greenPale : _redPale,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: n.isApproved ? _green.withOpacity(0.25) : _red.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    Icon(
                      n.isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: n.isApproved ? _green : _red, size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        n.message,
                        style: TextStyle(
                          color: n.isApproved ? _green : _red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                );
              },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaveProvider>();
    return Scaffold(
      backgroundColor: _offWhite,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(children: [
            _buildNavyHeader(provider),
            // Tab bar (white bg)
            Container(
              color: _white,
              child: _buildTabBar(),
            ),
            Expanded(
              child: RefreshIndicator(
                color: _cyan, displacement: 20,
                onRefresh: () => provider.loadAll(),
                child: provider.loading
                    ? const Center(child: CircularProgressIndicator(color: _cyan, strokeWidth: 2))
                    : TabBarView(controller: _tabs, children: [
                        _OverviewTab(
                          provider: provider,
                          onApply: provider.types.isEmpty ? null : _showApplySheet,
                          onCancel: (id) async {
                            final ok = await context.read<LeaveProvider>().cancelLeave(id);
                            if (ok && mounted) _toast('Request cancelled', _amber, Icons.block_rounded);
                          },
                        ),
                        _HistoryTab(provider: provider),
                      ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildNavyHeader(LeaveProvider provider) {
    final total    = provider.balances.fold<double>(0, (s, b) => s + b.remainingDays);
    final totalAll = provider.balances.fold<double>(0, (s, b) => s + b.totalDays);
    final rate     = totalAll > 0 ? total / totalAll : 0.0;
    final pending  = provider.requests.where((r) => r.isPending).length;
    final approved = provider.requests.where((r) => r.status == 'approved').length;

    return Container(
      decoration: const BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Title + bell
        Row(children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Leave', style: TextStyle(color: _white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            Text('Balances & requests', style: TextStyle(color: Color(0xFF6B7FAF), fontSize: 12)),
          ]),
          const Spacer(),
          GestureDetector(
          onTap: () {
            context.read<NotificationProvider>().markAllRead();
            _showNotificationSheet(context);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: _cyan.withOpacity(0.12), borderRadius: BorderRadius.circular(11), border: Border.all(color: _cyan.withOpacity(0.25))),
                child: const Icon(Icons.notifications_none_rounded, color: _cyan, size: 20),
              ),
              if (context.watch<NotificationProvider>().unreadCount > 0)
                Positioned(
                  right: -4, top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                    child: Text(
                      '${context.watch<NotificationProvider>().unreadCount}',
                      style: const TextStyle(color: _white, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ]),
        const SizedBox(height: 20),
        // Stats row with ring
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Ring
          _LeaveRing(rate: rate),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Days Remaining', style: TextStyle(color: _white.withOpacity(0.5), fontSize: 11, letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text(total % 1 == 0 ? '${total.toInt()}' : total.toStringAsFixed(1),
              style: const TextStyle(color: _white, fontSize: 30, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 12),
            Row(children: [
              _navStat('$pending', 'Pending', _amber),
              const SizedBox(width: 20),
              _navStat('$approved', 'Approved', _green),
            ]),
          ])),
        ]),
      ]),
    );
  }

  Widget _navStat(String v, String l, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(v, style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.w900, height: 1)),
    Text(l, style: TextStyle(color: _white.withOpacity(0.45), fontSize: 10)),
  ]);

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: TabBar(
        controller: _tabs,
        labelColor: _navy,
        unselectedLabelColor: _textHint,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        indicatorColor: _cyan,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: _border,
        tabs: const [Tab(text: 'Overview'), Tab(text: 'History')],
      ),
    );
  }
}

// ── Leave ring ─────────────────────────────────────────────────────────────────
class _LeaveRing extends StatefulWidget {
  final double rate;
  const _LeaveRing({required this.rate});
  @override
  State<_LeaveRing> createState() => _LeaveRingState();
}

class _LeaveRingState extends State<_LeaveRing> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _a = Tween<double>(begin: 0, end: widget.rate).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _a, builder: (_, __) {
      return SizedBox(width: 100, height: 100,
        child: CustomPaint(
          painter: _LeaveRingPainter(progress: _a.value),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Text('${(_a.value * 100).toStringAsFixed(0)}%', style: const TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w900, height: 1)),
            // Text('left', style: TextStyle(color: _white.withOpacity(0.45), fontSize: 9)),
          ])),
        ),
      );
    });
  }
}

class _LeaveRingPainter extends CustomPainter {
  final double progress;
  const _LeaveRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2; final r = (size.width - 14) / 2;
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round;
    p.color = _white.withOpacity(0.08);
    canvas.drawCircle(Offset(cx, cy), r, p);
    if (progress > 0) {
      p.shader = SweepGradient(
        startAngle: -math.pi / 2, endAngle: -math.pi / 2 + math.pi * 2 * progress,
        colors: [_cyan, _cyanLight],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -math.pi / 2, math.pi * 2 * progress, false, p);
    }
  }

  @override
  bool shouldRepaint(_LeaveRingPainter o) => o.progress != progress;
}

// ── Overview tab ───────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final LeaveProvider provider;
  final VoidCallback? onApply;
  final Future<void> Function(int id) onCancel;

  const _OverviewTab({required this.provider, required this.onApply, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (provider.balances.isNotEmpty) ...[
          _SectionLabel(label: 'LEAVE BALANCES', count: '${provider.balances.length}'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
            itemCount: provider.balances.length,
            itemBuilder: (_, i) {
              final (color, pale, mid) = _cardColors(i);
              return _BalanceCard(balance: provider.balances[i], color: color, pale: pale, mid: mid);
            },
          ),
          const SizedBox(height: 20),
        ],

        _ApplyButton(onTap: onApply),
        const SizedBox(height: 24),

        _SectionLabel(label: 'RECENT REQUESTS', count: provider.requests.isNotEmpty ? '${provider.requests.length}' : null),
        const SizedBox(height: 12),

        if (provider.requests.isEmpty)
          const _EmptyState()
        else
          ListView.separated(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final reqId = provider.requests[i].id;
              return _RequestCard(
                request: provider.requests[i],
                onCancel: () async {
                  final ok = await context.read<LeaveProvider>().cancelLeave(reqId);
                  if (ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Request cancelled', style: TextStyle(color: _white, fontWeight: FontWeight.w600)),
                    backgroundColor: _amber, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), margin: const EdgeInsets.all(16)));
                },
              );
            },
          ),
      ]),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final String? count;
  const _SectionLabel({required this.label, this.count});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 14, decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_cyan, _cyanDeep], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(color: _textSec, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    const Spacer(),
    if (count != null) Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _navy.withOpacity(0.07), borderRadius: BorderRadius.circular(20), border: Border.all(color: _navy.withOpacity(0.15))),
      child: Text(count!, style: const TextStyle(color: _navy, fontSize: 11, fontWeight: FontWeight.w700))),
  ]);
}

// ── Balance card ───────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final LeaveBalance balance;
  final Color color, pale, mid;
  const _BalanceCard({required this.balance, required this.color, required this.pale, required this.mid});

  @override
  Widget build(BuildContext context) {
    final used = balance.totalDays > 0 ? (balance.usedDays / balance.totalDays).clamp(0.0, 1.0) : 0.0;
    final rem  = balance.remainingDays;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardWhite, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Stack(children: [
        Positioned(right: -14, top: -14, child: Container(width: 58, height: 58,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.08)))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(7), border: Border.all(color: color.withOpacity(0.2))),
            child: Text(balance.leaveCode, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5))),
          const SizedBox(height: 3),
          Text(balance.leaveName, style: const TextStyle(color: _textHint, fontSize: 10), overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(rem % 1 == 0 ? '${rem.toInt()}' : '$rem',
              style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.w900, height: 1)),
            Padding(padding: const EdgeInsets.only(bottom: 3, left: 4),
              child: Text('/ ${balance.totalDays.toInt()}d', style: const TextStyle(color: _textHint, fontSize: 11))),
          ]),
          const SizedBox(height: 7),
          Container(height: 5, decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(3)),
            child: FractionallySizedBox(
              widthFactor: used, alignment: Alignment.centerLeft,
              child: Container(decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)],
              )),
            )),
        ]),
      ]),
    );
  }
}

// ── Apply button ───────────────────────────────────────────────────────────────
class _ApplyButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _ApplyButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: onTap != null ? null : _border,
            gradient: onTap != null ? const LinearGradient(colors: [_navy, _navyLight], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            borderRadius: BorderRadius.circular(18),
            boxShadow: onTap != null ? [BoxShadow(color: _navy.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))] : null,
          ),
          child: Container(alignment: Alignment.center, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 26, height: 26,
              decoration: BoxDecoration(color: _cyan.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.add_rounded, size: 18, color: onTap != null ? _cyan : _textHint)),
            const SizedBox(width: 10),
            Text('Apply for Leave', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: onTap != null ? _white : _textHint)),
          ])),
        ),
      ),
    );
  }
}

// ── Request card ───────────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final LeaveRequest request;
  final Future<void> Function() onCancel;
  const _RequestCard({required this.request, required this.onCancel});

  static const _months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  String _fmt(String d) { final dt = DateTime.tryParse(d); return dt == null ? d : '${dt.day} ${_months[dt.month]}'; }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusConfig(request.status);
    return Container(
      decoration: BoxDecoration(
        color: _cardWhite, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: request.isPending ? _amber.withOpacity(0.3) : _border),
        boxShadow: [BoxShadow(color: _shadowBlue, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        if (request.isPending) Container(height: 3, decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_amber, Color(0xFFFFCA28)]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(request.leaveName ?? 'Leave', style: const TextStyle(color: _textPri, fontSize: 15, fontWeight: FontWeight.w700))),
              const SizedBox(width: 8),
              _StatusPill(label: label, color: color),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.calendar_today_rounded, size: 12, color: _textHint),
              const SizedBox(width: 6),
              Text('${_fmt(request.startDate)} – ${_fmt(request.endDate)}', style: const TextStyle(color: _textSec, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _navy.withOpacity(0.06), borderRadius: BorderRadius.circular(7), border: Border.all(color: _navy.withOpacity(0.12))),
                child: Text(request.isHalfDay ? '½ day' : '${request.totalDays.toInt()} day${request.totalDays > 1 ? "s" : ""}',
                  style: const TextStyle(color: _navy, fontSize: 11, fontWeight: FontWeight.w600))),
            ]),
            if (request.hasLop) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _amberPale, borderRadius: BorderRadius.circular(8), border: Border.all(color: _amber.withOpacity(0.25))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.warning_amber_rounded, size: 13, color: _amber), const SizedBox(width: 5),
                  Text('${request.lopDays} day${request.lopDays > 1 ? "s" : ""} Loss of Pay', style: const TextStyle(color: _amber, fontSize: 11, fontWeight: FontWeight.w600)),
                ])),
            ],
            if (request.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.reason, style: const TextStyle(color: _textSec, fontSize: 12, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (request.reviewComment != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _offWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                child: Text('Admin: ${request.reviewComment}', style: const TextStyle(color: _textHint, fontSize: 11, fontStyle: FontStyle.italic, height: 1.4))),
            ],
            if (request.isPending) ...[
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 40,
                child: OutlinedButton.icon(
                  onPressed: () async => await onCancel(),
                  icon: const Icon(Icons.close_rounded, size: 15),
                  label: const Text('Cancel Request', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _red, side: BorderSide(color: _red.withOpacity(0.3)),
                    backgroundColor: _redPale, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label; final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
    decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
    child: Column(children: [
      Container(width: 58, height: 58,
        decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(17)),
        child: const Icon(Icons.event_note_outlined, color: _cyan, size: 28)),
      const SizedBox(height: 14),
      const Text('No leave requests yet', style: TextStyle(color: _textPri, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 5),
      const Text('Your submitted requests will appear here', style: TextStyle(color: _textHint, fontSize: 12), textAlign: TextAlign.center),
    ]),
  );
}

class _HistoryTab extends StatelessWidget {
  final LeaveProvider provider;
  const _HistoryTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.requests.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: _EmptyState()));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: provider.requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RequestCard(
        request: provider.requests[i],
        onCancel: () async => await context.read<LeaveProvider>().cancelLeave(provider.requests[i].id)),
    );
  }
}

// ── Apply leave sheet ──────────────────────────────────────────────────────────
class _ApplyLeaveSheet extends StatefulWidget {
  final List<LeaveType> types;
  const _ApplyLeaveSheet({required this.types});
  @override
  State<_ApplyLeaveSheet> createState() => _ApplyLeaveSheetState();
}

class _ApplyLeaveSheetState extends State<_ApplyLeaveSheet> {
  LeaveType? _sel; DateTime? _start; DateTime? _end;
  bool _half = false; double? _lop;
  final _rc = TextEditingController();

  @override
  void initState() { super.initState(); if (widget.types.isNotEmpty) _sel = widget.types.first; }
  @override
  void dispose() { _rc.dispose(); super.dispose(); }

  Future<void> _pickDates() async {
    final p = await showDateRangePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: _cyan, onPrimary: _white, surface: _white, onSurface: _navy)), child: child!));
    if (p != null) { setState(() { _start = p.start; _end = p.end; _half = false; _lop = null; }); _checkLop(); }
  }

  void _checkLop() {
    if (_sel == null || _start == null) return;
    final bal = context.read<LeaveProvider>().balances.firstWhere(
      (b) => b.leaveTypeId == _sel!.id,
      orElse: () => LeaveBalance(id: 0, leaveTypeId: 0, leaveName: '', leaveCode: '', isPaid: false, year: 0, totalDays: 0, usedDays: 0, pendingDays: 0, carriedForwardDays: 0, remainingDays: 0));
    final days = _half ? 0.5 : (_end != null ? (_end!.difference(_start!).inDays + 1).toDouble() : 1.0);
    final lop  = days - bal.remainingDays;
    setState(() => _lop = lop > 0 ? lop : null);
  }

  Future<void> _submit() async {
    if (_sel == null || _start == null || _end == null) { _snack('Select leave type and dates'); return; }
    if (_rc.text.trim().isEmpty) { _snack('Enter a reason'); return; }
    final ok = await context.read<LeaveProvider>().applyLeave(
      leaveTypeId: _sel!.id, startDate: _start!.toIso8601String().split('T')[0],
      endDate: _end!.toIso8601String().split('T')[0], reason: _rc.text.trim(), isHalfDay: _half);
    if (ok && mounted) Navigator.pop(context, true);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(m, style: const TextStyle(color: _white, fontWeight: FontWeight.w600, fontSize: 13)),
    backgroundColor: _amber, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), margin: const EdgeInsets.all(16)));

  bool get _isSingle => _start != null && _end != null && _start!.year == _end!.year && _start!.month == _end!.month && _start!.day == _end!.day;
  String get _dl {
    if (_start == null) return 'Select dates';
    const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    if (_isSingle) return '${_start!.day} ${m[_start!.month]} ${_start!.year}';
    return '${_start!.day} ${m[_start!.month]} – ${_end!.day} ${m[_end!.month]} ${_end!.year}';
  }

  @override
  Widget build(BuildContext context) {
    final applying = context.watch<LeaveProvider>().applying;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: _white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          // Navy header bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _cyan.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit_calendar_rounded, color: _cyan, size: 20)),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Apply for Leave', style: TextStyle(color: _white, fontSize: 17, fontWeight: FontWeight.w800)),
                Text('Fill in the details below', style: TextStyle(color: Color(0xFF6B7FAF), fontSize: 11)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          _FL('Leave Type'),
          const SizedBox(height: 8),
          _FB(child: DropdownButtonHideUnderline(child: DropdownButton<LeaveType>(
            value: _sel, isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textHint),
            style: const TextStyle(color: _textPri, fontSize: 14, fontWeight: FontWeight.w500),
            items: widget.types.map((t) => DropdownMenuItem(value: t, child: Text(t.leaveName))).toList(),
            onChanged: (t) { setState(() { _sel = t; _lop = null; }); _checkLop(); },
          ))),
          const SizedBox(height: 16),

          _FL('Date Range'),
          const SizedBox(height: 8),
          GestureDetector(onTap: _pickDates, child: _FB(
            child: Row(children: [
              Container(width: 30, height: 30, decoration: BoxDecoration(color: _cyanPale, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.calendar_month_rounded, color: _cyan, size: 16)),
              const SizedBox(width: 12),
              Expanded(child: Text(_dl, style: TextStyle(color: _start == null ? _textHint : _textPri, fontSize: 14, fontWeight: FontWeight.w500))),
              const Icon(Icons.chevron_right_rounded, color: _textHint, size: 18),
            ]), height: 52,
          )),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: _half ? _cyanPale : _offWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: _half ? _cyan.withOpacity(0.3) : _border)),
            child: Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: _half ? _cyan.withOpacity(0.15) : _border.withOpacity(0.5), borderRadius: BorderRadius.circular(9)), child: Icon(Icons.wb_sunny_outlined, color: _half ? _cyan : _textHint, size: 16)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Half Day', style: TextStyle(color: _textPri, fontSize: 13, fontWeight: FontWeight.w700)),
                Text('Single day only', style: TextStyle(color: _textHint, fontSize: 11)),
              ])),
              Switch.adaptive(value: _half, activeColor: _cyan, onChanged: _isSingle ? (v) { setState(() => _half = v); _checkLop(); } : null),
            ]),
          ),
          const SizedBox(height: 16),

          if (_lop != null && _lop! > 0) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _amberPale, borderRadius: BorderRadius.circular(14), border: Border.all(color: _amber.withOpacity(0.3))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(color: _amberPale, borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.warning_amber_rounded, color: _amber, size: 18)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Loss of Pay Alert', style: TextStyle(color: _amber, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('${_lop!.toStringAsFixed(1)} day(s) will be deducted as LOP.', style: TextStyle(color: _amber.withOpacity(0.85), fontSize: 12, height: 1.5)),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          _FL('Reason'),
          const SizedBox(height: 8),
          TextField(
            controller: _rc, maxLines: 3,
            style: const TextStyle(color: _textPri, fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Briefly describe your reason…', hintStyle: const TextStyle(color: _textHint, fontSize: 14),
              filled: true, fillColor: _offWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cyan, width: 1.5)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: applying ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_navy, _navyLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: _navy.withOpacity(0.38), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Container(alignment: Alignment.center, child: applying
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.send_rounded, size: 17, color: _cyan), SizedBox(width: 8),
                      Text('Submit Request', style: TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w800)),
                    ])),
              ),
            ),
          ),
        ])),
      ),
    );
  }
}

class _FL extends StatelessWidget {
  final String t; const _FL(this.t);
  @override
  Widget build(BuildContext context) => Text(t, style: const TextStyle(color: _textSec, fontSize: 13, fontWeight: FontWeight.w600));
}

class _FB extends StatelessWidget {
  final Widget child; final double height;
  const _FB({required this.child, this.height = 50});
  @override
  Widget build(BuildContext context) => Container(
    height: height, padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: _offWhite, border: Border.all(color: _border), borderRadius: BorderRadius.circular(14)),
    child: child);
}