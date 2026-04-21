import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/leave_provider.dart';
import '../../../data/models/leave_model.dart';

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
const _greenMid   = Color(0xFFD1FAE5);
const _red        = Color(0xFFE11D48);
const _redLight   = Color(0xFFFFF1F2);
const _amber      = Color(0xFFD97706);
const _amberLight = Color(0xFFFFFBEB);
const _amberMid   = Color(0xFFFEF3C7);
const _teal       = Color(0xFF0891B2);
const _tealLight  = Color(0xFFE0F2FE);
const _purple     = Color(0xFF9333EA);
const _purpleLight= Color(0xFFF3E8FF);
const _textPri    = Color(0xFF0F172A);
const _textSec    = Color(0xFF475569);
const _textHint   = Color(0xFF94A3B8);
const _border     = Color(0xFFE8EEFF);
const _borderMid  = Color(0xFFCDD5FF);
const _shadow     = Color(0x193B5BDB);

// ── Card color palette ─────────────────────────────────────────────────────────
const _palette = [
  (_blue,   _blueLight,  _blueMid),
  (_green,  _greenLight, _greenMid),
  (_amber,  _amberLight, _amberMid),
  (_violet, _violetLight,Color(0xFFEDE9FE)),
  (_teal,   _tealLight,  Color(0xFFCCFBF1)),
  (_red,    _redLight,   Color(0xFFFEE2E2)),
];

(Color, Color, Color) _cardColors(int i) => _palette[i % _palette.length];

(Color, String) _statusConfig(String status) {
  switch (status) {
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
    final types = context.read<LeaveProvider>().types;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent, useSafeArea: true,
      builder: (_) => _ApplyLeaveSheet(types: types),
    ).then((submitted) {
      if (submitted == true && mounted) {
        _toast('Leave request submitted successfully', _green, Icons.check_circle_rounded);
      }
    });
  }

  void _toast(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [Icon(icon, color: _white, size: 18), const SizedBox(width: 10), Text(msg, style: const TextStyle(color: _white, fontWeight: FontWeight.w600, fontSize: 13))]),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          child: Column(children: [
            _buildHeader(provider),
            const SizedBox(height: 6),
            _buildTabBar(),
            const SizedBox(height: 4),
            Expanded(
              child: RefreshIndicator(
                color: _blue, displacement: 20,
                onRefresh: () => provider.loadAll(),
                child: provider.loading
                    ? const Center(child: CircularProgressIndicator(color: _blue, strokeWidth: 2))
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

  Widget _buildHeader(LeaveProvider provider) {
    return Container(
      color: _white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Leave', style: TextStyle(color: _textPri, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
          const Text('Balances & requests', style: TextStyle(color: _textSec, fontSize: 13)),
        ])),
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: _blueLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: _blueMid)),
          child: const Icon(Icons.notifications_none_rounded, color: _blue, size: 20),
        ),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        TabBar(
          controller: _tabs,
          labelColor: _blue,
          unselectedLabelColor: _textHint,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          indicatorColor: _blue,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: _border,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'History')],
        ),
      ]),
    );
  }
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SummaryBar(provider: provider),
        const SizedBox(height: 22),

        if (provider.balances.isNotEmpty) ...[
          _SectionLabel(label: 'LEAVE BALANCES', count: '${provider.balances.length} types'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3,
            ),
            itemCount: provider.balances.length,
            itemBuilder: (_, i) {
              final (color, bg, mid) = _cardColors(i);
              return _BalanceCard(balance: provider.balances[i], color: color, bg: bg, mid: mid);
            },
          ),
          const SizedBox(height: 22),
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
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Request cancelled',
                          style: TextStyle(color: _white, fontWeight: FontWeight.w600)),
                      backgroundColor: _amber, behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.all(16),
                    ));
                  }
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
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 14,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_blue, _violet], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(2),
        )),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: _textSec, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      const Spacer(),
      if (count != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _blueLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: _blueMid)),
          child: Text(count!, style: const TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
    ]);
  }
}

// ── Summary bar ────────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final LeaveProvider provider;
  const _SummaryBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.balances.fold<double>(0, (s, b) => s + b.remainingDays);
    final pending = provider.requests.where((r) => r.isPending).length;
    final approved = provider.requests.where((r) => r.status == 'approved').length;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_blue, _violet], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _blue.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 7))],
      ),
      child: Stack(children: [
        // decorative circle
        Positioned(right: -20, top: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: _white.withOpacity(0.06)))),
        Row(children: [
          _SummaryItem(value: total % 1 == 0 ? total.toInt().toString() : total.toStringAsFixed(1), label: 'Days Left', isFirst: true),
          Container(width: 1, height: 50, color: _white.withOpacity(0.2)),
          _SummaryItem(value: '$pending', label: 'Pending'),
          Container(width: 1, height: 50, color: _white.withOpacity(0.2)),
          _SummaryItem(value: '$approved', label: 'Approved', isLast: true),
        ]),
      ]),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value, label;
  final bool isFirst, isLast;
  const _SummaryItem({required this.value, required this.label, this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(children: [
        Text(value, style: const TextStyle(color: _white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: _white.withOpacity(0.75), fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    ));
  }
}

// ── Balance card ───────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final LeaveBalance balance;
  final Color color, bg, mid;
  const _BalanceCard({required this.balance, required this.color, required this.bg, required this.mid});

  @override
  Widget build(BuildContext context) {
    final used = balance.totalDays > 0 ? (balance.usedDays / balance.totalDays).clamp(0.0, 1.0) : 0.0;
    final remaining = balance.remainingDays;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.09), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Stack(children: [
        Positioned(right: -12, top: -12, child: Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.07)))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: mid, borderRadius: BorderRadius.circular(7)),
            child: Text(balance.leaveCode, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
          ),
          const SizedBox(height: 3),
          Text(balance.leaveName, style: const TextStyle(color: _textHint, fontSize: 10), overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(remaining % 1 == 0 ? '${remaining.toInt()}' : '$remaining',
              style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.w900, height: 1)),
            Padding(padding: const EdgeInsets.only(bottom: 3, left: 4),
              child: Text('/ ${balance.totalDays.toInt()}d', style: const TextStyle(color: _textHint, fontSize: 11))),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: used, backgroundColor: mid, minHeight: 5,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
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
          backgroundColor: onTap != null ? _blue : _border,
          foregroundColor: _white,
          disabledBackgroundColor: _border,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ).copyWith(
          shadowColor: MaterialStateProperty.all(onTap != null ? _blue.withOpacity(0.35) : Colors.transparent),
          elevation: MaterialStateProperty.all(onTap != null ? 8 : 0),
          overlayColor: MaterialStateProperty.all(_white.withOpacity(0.12)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 26, height: 26,
            decoration: BoxDecoration(color: _white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.add_rounded, size: 18, color: _white)),
          const SizedBox(width: 10),
          Text('Apply for Leave', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800,
            color: onTap != null ? _white : _textHint,
          )),
        ]),
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
  String _fmt(String d) { final dt = DateTime.tryParse(d); if (dt == null) return d; return '${dt.day} ${_months[dt.month]}'; }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusConfig(request.status);
    return Container(
      decoration: BoxDecoration(
        color: _bgCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: request.isPending ? _amber.withOpacity(0.3) : _border),
        boxShadow: [BoxShadow(color: _shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        if (request.isPending)
          Container(height: 3, decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_amber, Color(0xFFF59E0B)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          )),
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
                decoration: BoxDecoration(color: _blueLight, borderRadius: BorderRadius.circular(7), border: Border.all(color: _blueMid)),
                child: Text(
                  request.isHalfDay ? '½ day' : '${request.totalDays.toInt()} day${request.totalDays > 1 ? "s" : ""}',
                  style: const TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
            if (request.hasLop) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _amberMid, borderRadius: BorderRadius.circular(8), border: Border.all(color: _amber.withOpacity(0.25))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.warning_amber_rounded, size: 13, color: _amber),
                  const SizedBox(width: 5),
                  Text('${request.lopDays} day${request.lopDays > 1 ? "s" : ""} Loss of Pay', style: const TextStyle(color: _amber, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
            if (request.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.reason, style: const TextStyle(color: _textSec, fontSize: 12, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (request.reviewComment != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                child: Text('Admin: ${request.reviewComment}', style: const TextStyle(color: _textHint, fontSize: 11, fontStyle: FontStyle.italic, height: 1.4)),
              ),
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
                    backgroundColor: _redLight, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
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
    decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
    child: Column(children: [
      Container(width: 58, height: 58,
        decoration: BoxDecoration(color: _blueLight, borderRadius: BorderRadius.circular(17), border: Border.all(color: _blueMid)),
        child: const Icon(Icons.event_note_outlined, color: _blue, size: 28)),
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
    if (provider.requests.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: _EmptyState()));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: provider.requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RequestCard(
        request: provider.requests[i],
        onCancel: () async {
          await context.read<LeaveProvider>().cancelLeave(provider.requests[i].id);
        },
      ),
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
  LeaveType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isHalfDay = false;
  double? _lopDays;
  final _reasonCtrl = TextEditingController();

  @override
  void initState() { super.initState(); if (widget.types.isNotEmpty) _selectedType = widget.types.first; }
  @override
  void dispose() { _reasonCtrl.dispose(); super.dispose(); }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _blue)), child: child!),
    );
    if (picked != null) {
      setState(() { _startDate = picked.start; _endDate = picked.end; _isHalfDay = false; _lopDays = null; });
      _checkLop();
    }
  }

  void _checkLop() {
    if (_selectedType == null || _startDate == null) return;
    final balances = context.read<LeaveProvider>().balances;
    final bal = balances.firstWhere(
      (b) => b.leaveTypeId == _selectedType!.id,
      orElse: () => LeaveBalance(id: 0, leaveTypeId: 0, leaveName: '', leaveCode: '', isPaid: false, year: 0, totalDays: 0, usedDays: 0, pendingDays: 0, carriedForwardDays: 0, remainingDays: 0),
    );
    final days = _isHalfDay ? 0.5 : (_endDate != null ? (_endDate!.difference(_startDate!).inDays + 1).toDouble() : 1.0);
    final lop = days - bal.remainingDays;
    setState(() => _lopDays = lop > 0 ? lop : null);
  }

  Future<void> _submit() async {
    if (_selectedType == null || _startDate == null || _endDate == null) { _snack('Please select leave type and dates'); return; }
    if (_reasonCtrl.text.trim().isEmpty) { _snack('Please enter a reason'); return; }
    final ok = await context.read<LeaveProvider>().applyLeave(
      leaveTypeId: _selectedType!.id, startDate: _startDate!.toIso8601String().split('T')[0],
      endDate: _endDate!.toIso8601String().split('T')[0], reason: _reasonCtrl.text.trim(), isHalfDay: _isHalfDay,
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    backgroundColor: _amber, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), margin: const EdgeInsets.all(16),
  ));

  bool get _isSingleDay => _startDate != null && _endDate != null &&
      _startDate!.year == _endDate!.year && _startDate!.month == _endDate!.month && _startDate!.day == _endDate!.day;

  String get _dateLabel {
    if (_startDate == null) return 'Select dates';
    const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    if (_isSingleDay) return '${_startDate!.day} ${m[_startDate!.month]} ${_startDate!.year}';
    return '${_startDate!.day} ${m[_startDate!.month]} – ${_endDate!.day} ${m[_endDate!.month]} ${_endDate!.year}';
  }

  @override
  Widget build(BuildContext context) {
    final applying = context.watch<LeaveProvider>().applying;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: _white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 22),

            // Header with gradient icon
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_blue, _violet]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: _blue.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.edit_calendar_rounded, color: _white, size: 21),
              ),
              const SizedBox(width: 14),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Apply for Leave', style: TextStyle(color: _textPri, fontSize: 18, fontWeight: FontWeight.w800)),
                Text('Fill in the details below', style: TextStyle(color: _textHint, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 24),

            _FieldLabel('Leave Type'),
            const SizedBox(height: 8),
            _FieldBox(child: DropdownButtonHideUnderline(
              child: DropdownButton<LeaveType>(
                value: _selectedType, isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textHint),
                style: const TextStyle(color: _textPri, fontSize: 14, fontWeight: FontWeight.w500),
                items: widget.types.map((t) => DropdownMenuItem(value: t, child: Text(t.leaveName))).toList(),
                onChanged: (t) { setState(() { _selectedType = t; _lopDays = null; }); _checkLop(); },
              ),
            )),
            const SizedBox(height: 16),

            _FieldLabel('Date Range'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDateRange,
              child: _FieldBox(
                child: Row(children: [
                  Container(width: 30, height: 30, decoration: BoxDecoration(color: _blueLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.calendar_month_rounded, color: _blue, size: 16)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_dateLabel, style: TextStyle(color: _startDate == null ? _textHint : _textPri, fontSize: 14, fontWeight: FontWeight.w500))),
                  const Icon(Icons.chevron_right_rounded, color: _textHint, size: 18),
                ]),
                height: 52,
              ),
            ),
            const SizedBox(height: 16),

            // Half day toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _isSingleDay ? (_isHalfDay ? _blueLight : _bg) : _bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _isHalfDay ? _blueMid : _border),
              ),
              child: Row(children: [
                Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: _isHalfDay ? _blueMid : _border.withOpacity(0.5), borderRadius: BorderRadius.circular(9)),
                  child: Icon(Icons.wb_sunny_outlined, color: _isHalfDay ? _blue : _textHint, size: 16)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Half Day', style: TextStyle(color: _textPri, fontSize: 13, fontWeight: FontWeight.w700)),
                  Text('Single day only', style: TextStyle(color: _textHint, fontSize: 11)),
                ])),
                Switch.adaptive(
                  value: _isHalfDay, activeColor: _blue,
                  onChanged: _isSingleDay ? (v) { setState(() => _isHalfDay = v); _checkLop(); } : null,
                ),
              ]),
            ),
            const SizedBox(height: 16),

            if (_lopDays != null && _lopDays! > 0) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _amberMid, borderRadius: BorderRadius.circular(14), border: Border.all(color: _amber.withOpacity(0.3))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(color: _amberLight, borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.warning_amber_rounded, color: _amber, size: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Loss of Pay Alert', style: TextStyle(color: _amber, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('${_lopDays!.toStringAsFixed(1)} day(s) will be deducted as LOP due to insufficient balance.', style: TextStyle(color: _amber.withOpacity(0.85), fontSize: 12, height: 1.5)),
                  ])),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            _FieldLabel('Reason'),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl, maxLines: 3,
              style: const TextStyle(color: _textPri, fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Briefly describe your reason…',
                hintStyle: const TextStyle(color: _textHint, fontSize: 14),
                filled: true, fillColor: _bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _blue, width: 1.5)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: applying ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, foregroundColor: _white, elevation: 0,
                  shadowColor: _blue.withOpacity(0.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: applying
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.send_rounded, size: 17), SizedBox(width: 8),
                        Text('Submit Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Small helpers ──────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: _textSec, fontSize: 13, fontWeight: FontWeight.w600));
}

class _FieldBox extends StatelessWidget {
  final Widget child;
  final double height;
  const _FieldBox({required this.child, this.height = 50});
  @override
  Widget build(BuildContext context) => Container(
    height: height, padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: _bg, border: Border.all(color: _border), borderRadius: BorderRadius.circular(14)),
    child: child,
  );
}