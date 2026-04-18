import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/leave_provider.dart';
import '../../../data/models/leave_model.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _blue        = Color(0xFF2563EB);
const _blueDark    = Color(0xFF1D4ED8);
const _blueLight   = Color(0xFFEFF6FF);
const _blueMid     = Color(0xFFDBEAFE);
const _green       = Color(0xFF16A34A);
const _greenLight  = Color(0xFFF0FDF4);
const _greenMid    = Color(0xFFDCFCE7);
const _amber       = Color(0xFFD97706);
const _amberLight  = Color(0xFFFFFBEB);
const _amberMid    = Color(0xFFFEF3C7);
const _red         = Color(0xFFDC2626);
const _redLight    = Color(0xFFFEF2F2);
const _redMid      = Color(0xFFFEE2E2);
const _purple      = Color(0xFF7C3AED);
const _purpleLight = Color(0xFFF5F3FF);
const _purpleMid   = Color(0xFFEDE9FE);
const _teal        = Color(0xFF0D9488);
const _tealLight   = Color(0xFFF0FDFA);
const _tealMid     = Color(0xFFCCFBF1);
const _textPri     = Color(0xFF0F172A);
const _textSec     = Color(0xFF475569);
const _textHint    = Color(0xFF94A3B8);
const _border      = Color(0xFFE2E8F0);
const _borderLight = Color(0xFFF1F5F9);
const _bg          = Color(0xFFF8FAFF);
const _surface     = Color(0xFFFCFDFF);
const _white       = Color(0xFFFFFFFF);

// ── Color sets per leave type index ──────────────────────────────────────────
const _cardSets = [
  (_blue,   _blueLight,  _blueMid,   Color(0xFF1E40AF)),
  (_green,  _greenLight, _greenMid,  Color(0xFF166534)),
  (_amber,  _amberLight, _amberMid,  Color(0xFF92400E)),
  (_purple, _purpleLight,_purpleMid, Color(0xFF5B21B6)),
  (_teal,   _tealLight,  _tealMid,   Color(0xFF134E4A)),
  (_red,    _redLight,   _redMid,    Color(0xFF991B1B)),
];

(Color, Color, Color, Color) _cardColors(int i) {
  final s = _cardSets[i % _cardSets.length];
  return (s.$1, s.$2, s.$3, s.$4);
}

// ── Status config ─────────────────────────────────────────────────────────────
(Color, Color, Color, String) _statusConfig(String status) {
  switch (status) {
    case 'approved':  return (_green,  _greenLight,  _greenMid,  'Approved');
    case 'rejected':  return (_red,    _redLight,    _redMid,    'Rejected');
    case 'cancelled': return (_textHint, _borderLight, _border,  'Cancelled');
    default:          return (_amber,  _amberLight,  _amberMid,  'Pending');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});
  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<LeaveProvider>().loadAll());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _showApplySheet() {
    final types = context.read<LeaveProvider>().types;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _ApplyLeaveSheet(types: types),
    ).then((submitted) {
      if (submitted == true && mounted) {
        _showToast('Leave request submitted successfully', _green, Icons.check_circle_rounded);
      }
    });
  }

  void _showToast(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: _white, size: 18),
        const SizedBox(width: 10),
        Text(msg, style: const TextStyle(color: _white, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaveProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _Header(onApply: provider.types.isEmpty ? null : _showApplySheet),
              _TabBar(controller: _tabs),
              Expanded(
                child: RefreshIndicator(
                  color: _blue,
                  displacement: 20,
                  onRefresh: () => provider.loadAll(),
                  child: provider.loading
                      ? const _LoadingView()
                      : TabBarView(
                          controller: _tabs,
                          children: [
                            _OverviewTab(
                              provider: provider,
                              onApply: provider.types.isEmpty ? null : _showApplySheet,
                              onCancel: (id) async {
                                final ok = await context.read<LeaveProvider>().cancelLeave(id);
                                if (ok && mounted) {
                                  _showToast('Request cancelled', _amber, Icons.block_rounded);
                                }
                              },
                            ),
                            _HistoryTab(provider: provider),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback? onApply;
  const _Header({this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Leave',
                    style: TextStyle(
                        color: _textPri,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 2),
                const Text('Balances & requests',
                    style: TextStyle(color: _textSec, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Notification icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _blueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: _blue, size: 20),
          ),
          const SizedBox(width: 8),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _blueDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('AR',
                  style: TextStyle(
                      color: _white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _white,
      child: Column(
        children: [
          const SizedBox(height: 4),
          TabBar(
            controller: controller,
            labelColor: _blue,
            unselectedLabelColor: _textHint,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            indicatorColor: _blue,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: _border,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'History'),
              
            ],
          ),
        ],
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _blue, strokeWidth: 2),
    );
  }
}

// ── Overview tab ──────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final LeaveProvider provider;
  final VoidCallback? onApply;
  final Future<void> Function(int id) onCancel;

  const _OverviewTab({
    required this.provider,
    required this.onApply,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary bar
          _SummaryBar(provider: provider),
          const SizedBox(height: 24),

          // Balance section
          if (provider.balances.isNotEmpty) ...[
            _SectionHeader(
              label: 'AVAILABLE BALANCE',
              trailing: Text('${provider.balances.length} types',
                  style: const TextStyle(color: _textHint, fontSize: 11)),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
              ),
              itemCount: provider.balances.length,
              itemBuilder: (_, i) {
                final (color, bg, mid, dark) = _cardColors(i);
                return _BalanceCard(
                  balance: provider.balances[i],
                  color: color, bg: bg, mid: mid, dark: dark,
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Apply button
          _ApplyButton(onTap: onApply),
          const SizedBox(height: 28),

          // Recent requests
          _SectionHeader(
            label: 'RECENT REQUESTS',
            trailing: provider.requests.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _blueMid,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${provider.requests.length}',
                        style: const TextStyle(
                            color: _blue, fontSize: 11, fontWeight: FontWeight.w700)),
                  )
                : null,
          ),
          const SizedBox(height: 12),

          if (provider.requests.isEmpty)
            const _EmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _RequestCard(
                request: provider.requests[i],
                onCancel: () => onCancel(provider.requests[i].id),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final LeaveProvider provider;
  const _SummaryBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final totalRemaining = provider.balances
        .fold<double>(0, (s, b) => s + b.remainingDays);
    final pending = provider.requests.where((r) => r.isPending).length;
    final approved = provider.requests.where((r) => r.status == 'approved').length;

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _SummaryItem(
              value: totalRemaining % 1 == 0
                  ? totalRemaining.toInt().toString()
                  : totalRemaining.toStringAsFixed(1),
              label: 'Days left',
              color: _blue,
              isFirst: true,
            ),
            const VerticalDivider(width: 1, color: _borderLight),
            _SummaryItem(
              value: '$pending',
              label: 'Pending',
              color: _amber,
            ),
            const VerticalDivider(width: 1, color: _borderLight),
            _SummaryItem(
              value: '$approved',
              label: 'Approved',
              color: _green,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isFirst;
  final bool isLast;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(20) : Radius.zero,
            right: isLast ? const Radius.circular(20) : Radius.zero,
          ),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                    color: _textSec, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const _SectionHeader({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                color: _textHint,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Balance card ──────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final LeaveBalance balance;
  final Color color, bg, mid, dark;

  const _BalanceCard({
    required this.balance,
    required this.color,
    required this.bg,
    required this.mid,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final used = balance.totalDays > 0
        ? (balance.usedDays / balance.totalDays).clamp(0.0, 1.0)
        : 0.0;
    final remaining = balance.remainingDays;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background watermark circle
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code badge + name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: mid,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(balance.leaveCode,
                        style: TextStyle(
                            color: dark,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(balance.leaveName,
                  style: const TextStyle(
                      color: _textHint, fontSize: 10, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
              const Spacer(),
              // Remaining number
              Text(
                remaining % 1 == 0
                    ? '${remaining.toInt()}'
                    : '$remaining',
                style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1),
              ),
              Text('of ${balance.totalDays.toInt()} days',
                  style: const TextStyle(color: _textSec, fontSize: 10)),
              const SizedBox(height: 8),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: used,
                  backgroundColor: mid,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Apply button ──────────────────────────────────────────────────────────────
class _ApplyButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _ApplyButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: _white,
          disabledBackgroundColor: _border,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded, size: 18, color: _white),
            ),
            const SizedBox(width: 10),
            const Text('Apply for Leave',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1)),
          ],
        ),
      ),
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final LeaveRequest request;
  final VoidCallback onCancel;
  const _RequestCard({required this.request, required this.onCancel});

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _fmt(String d) {
    final dt = DateTime.tryParse(d);
    if (dt == null) return d;
    return '${dt.day} ${_months[dt.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final (color, bg, mid, label) = _statusConfig(request.status);

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top accent bar for pending
          if (request.isPending)
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: _amber,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(request.leaveName ?? 'Leave',
                          style: const TextStyle(
                              color: _textPri,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(label: label, color: color, bg: bg, mid: mid),
                  ],
                ),
                const SizedBox(height: 10),

                // Date + days row
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: _textHint),
                    const SizedBox(width: 6),
                    Text(
                      '${_fmt(request.startDate)} – ${_fmt(request.endDate)}',
                      style: const TextStyle(
                          color: _textSec,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        request.isHalfDay
                            ? '½ day'
                            : '${request.totalDays.toInt()} day${request.totalDays > 1 ? "s" : ""}',
                        style: const TextStyle(
                            color: _textSec,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),

                // LOP warning
                if (request.hasLop) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _amberMid,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _amber.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 13, color: _amber),
                        const SizedBox(width: 5),
                        Text(
                          '${request.lopDays} day${request.lopDays > 1 ? "s" : ""} Loss of Pay',
                          style: const TextStyle(
                              color: _amber,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],

                // Reason
                if (request.reason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(request.reason,
                      style: const TextStyle(
                          color: _textSec,
                          fontSize: 12,
                          height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],

                // Admin comment
                if (request.reviewComment != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(color: _border, width: 3),
                      ),
                    ),
                    child: Text(
                      'Admin: ${request.reviewComment}',
                      style: const TextStyle(
                          color: _textHint,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          height: 1.4),
                    ),
                  ),
                ],

                // Cancel button
                if (request.isPending) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close_rounded, size: 15),
                      label: const Text('Cancel Request',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: BorderSide(color: _red.withOpacity(0.35)),
                        backgroundColor: _redLight,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color, bg, mid;
  const _StatusPill({
    required this.label,
    required this.color,
    required this.bg,
    required this.mid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: mid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _blueLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.event_note_outlined,
                color: _blue, size: 28),
          ),
          const SizedBox(height: 14),
          const Text('No leave requests yet',
              style: TextStyle(
                  color: _textPri,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Your submitted requests will appear here',
              style: TextStyle(color: _textHint, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── History tab ───────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final LeaveProvider provider;
  const _HistoryTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.requests.isEmpty) {
      return const Center(child: _EmptyState());
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: provider.requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RequestCard(
        request: provider.requests[i],
        onCancel: () async {
          await context
              .read<LeaveProvider>()
              .cancelLeave(provider.requests[i].id);
        },
      ),
    );
  }
}


// ── Apply leave bottom sheet ──────────────────────────────────────────────────
class _ApplyLeaveSheet extends StatefulWidget {
  final List<LeaveType> types;
  const _ApplyLeaveSheet({required this.types});
  @override
  State<_ApplyLeaveSheet> createState() => _ApplyLeaveSheetState();
}

class _ApplyLeaveSheetState extends State<_ApplyLeaveSheet> {
  LeaveType? _selectedType;
  DateTime?  _startDate;
  DateTime?  _endDate;
  bool       _isHalfDay = false;
  double?    _lopDays;
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.types.isNotEmpty) _selectedType = widget.types.first;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _blue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate   = picked.end;
        _isHalfDay = false;
        _lopDays   = null;
      });
      _checkLop();
    }
  }

  void _checkLop() {
    if (_selectedType == null || _startDate == null) return;
    final balances = context.read<LeaveProvider>().balances;
    final bal = balances.firstWhere(
      (b) => b.leaveTypeId == _selectedType!.id,
      orElse: () => LeaveBalance(
        id: 0, leaveTypeId: 0, leaveName: '', leaveCode: '',
        isPaid: false, year: 0, totalDays: 0, usedDays: 0,
        pendingDays: 0, carriedForwardDays: 0, remainingDays: 0,
      ),
    );
    final days = _isHalfDay
        ? 0.5
        : (_endDate != null
            ? (_endDate!.difference(_startDate!).inDays + 1).toDouble()
            : 1.0);
    final lop = days - bal.remainingDays;
    setState(() => _lopDays = lop > 0 ? lop : null);
  }

  Future<void> _submit() async {
    if (_selectedType == null || _startDate == null || _endDate == null) {
      _snack('Please select leave type and dates');
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      _snack('Please enter a reason for your leave');
      return;
    }
    final ok = await context.read<LeaveProvider>().applyLeave(
          leaveTypeId: _selectedType!.id,
          startDate: _startDate!.toIso8601String().split('T')[0],
          endDate:   _endDate!.toIso8601String().split('T')[0],
          reason:    _reasonCtrl.text.trim(),
          isHalfDay: _isHalfDay,
        );
    if (ok && mounted) Navigator.pop(context, true);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  bool get _isSingleDay =>
      _startDate != null &&
      _endDate != null &&
      _startDate!.year == _endDate!.year &&
      _startDate!.month == _endDate!.month &&
      _startDate!.day == _endDate!.day;

  String get _dateLabel {
    if (_startDate == null) return 'Select dates';
    const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    if (_isSingleDay) {
      return '${_startDate!.day} ${m[_startDate!.month]} ${_startDate!.year}';
    }
    return '${_startDate!.day} ${m[_startDate!.month]} – ${_endDate!.day} ${m[_endDate!.month]} ${_endDate!.year}';
  }

  @override
  Widget build(BuildContext context) {
    final applying = context.watch<LeaveProvider>().applying;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              // Title row
              Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _blueLight,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.edit_calendar_rounded,
                        color: _blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Apply for Leave',
                          style: TextStyle(
                              color: _textPri,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      Text('Fill in the details below',
                          style: TextStyle(color: _textHint, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Leave type ────────────────────────────────────────────
              _FieldLabel('Leave Type'),
              const SizedBox(height: 8),
              _FieldBox(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LeaveType>(
                    value: _selectedType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _textHint),
                    style: const TextStyle(
                        color: _textPri, fontSize: 14, fontWeight: FontWeight.w500),
                    items: widget.types
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.leaveName),
                            ))
                        .toList(),
                    onChanged: (t) {
                      setState(() {
                        _selectedType = t;
                        _lopDays = null;
                      });
                      _checkLop();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Date range ────────────────────────────────────────────
              _FieldLabel('Date Range'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDateRange,
                child: _FieldBox(
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: _blueLight,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.calendar_month_rounded,
                            color: _blue, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_dateLabel,
                            style: TextStyle(
                                color: _startDate == null ? _textHint : _textPri,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: _textHint, size: 18),
                    ],
                  ),
                  height: 52,
                ),
              ),
              const SizedBox(height: 16),

              // ── Half day toggle ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _isSingleDay ? _surface : _borderLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _isHalfDay ? _blueMid : _borderLight,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(Icons.wb_sunny_outlined,
                          color: _isHalfDay ? _blue : _textHint, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Half Day',
                              style: TextStyle(
                                  color: _textPri,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          Text('Single day only',
                              style: TextStyle(
                                  color: _textHint, fontSize: 11)),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isHalfDay,
                      activeColor: _blue,
                      onChanged: _isSingleDay
                          ? (v) {
                              setState(() => _isHalfDay = v);
                              _checkLop();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── LOP warning ───────────────────────────────────────────
              if (_lopDays != null && _lopDays! > 0) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _amberMid,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: _amberLight,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: _amber, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Loss of Pay Alert',
                                style: TextStyle(
                                    color: _amber,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(
                              '${_lopDays!.toStringAsFixed(1)} day(s) will be deducted as LOP due to insufficient balance.',
                              style: const TextStyle(
                                  color: _amber,
                                  fontSize: 12,
                                  height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Reason ────────────────────────────────────────────────
              _FieldLabel('Reason'),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonCtrl,
                maxLines: 3,
                style: const TextStyle(
                    color: _textPri, fontSize: 14, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'Briefly describe your reason...',
                  hintStyle: const TextStyle(
                      color: _textHint, fontSize: 14),
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: _blue, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 24),

              // ── Submit ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: applying ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: _white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: applying
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: _white, strokeWidth: 2.5))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 17),
                            SizedBox(width: 8),
                            Text('Submit Request',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: _textSec, fontSize: 13, fontWeight: FontWeight.w600));
}

class _FieldBox extends StatelessWidget {
  final Widget child;
  final double height;
  const _FieldBox({required this.child, this.height = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}