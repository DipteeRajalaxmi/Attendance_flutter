import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../providers/attendance_provider.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/repositories/attendance_repository.dart';

// ── Navy · Cyan · White Palette ────────────────────────────────────────────────
const _navy       = Color(0xFF0D1B3E);
const _navyMid    = Color(0xFF152347);
const _navyLight  = Color(0xFF1E3060);
const _navyAccent = Color(0xFF243880);
const _cyan       = Color(0xFF00B4D8);
const _cyanLight  = Color(0xFF48CAE4);
const _cyanPale   = Color(0xFFE0F7FA);
const _cyanDeep   = Color(0xFF0096C7);
const _white      = Color(0xFFFFFFFF);
const _offWhite   = Color(0xFFF0F4FF);
const _cardWhite  = Color(0xFFFFFFFF);
const _green      = Color(0xFF00C897);
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

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  late DateTime _displayMonth;
  late AnimationController _fadeCtrl;

  static const _monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCalendar());
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  void _loadCalendar() {
    _fadeCtrl.reset();
    context.read<AttendanceProvider>().loadCalendar(month: _displayMonth.month, year: _displayMonth.year)
      .then((_) { if (mounted) _fadeCtrl.forward(); });
  }

  void _changeMonth(int delta) {
    setState(() { _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + delta); });
    _loadCalendar();
  }

  void _showDayDetail(CalendarDay day) =>
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => _DayDetailSheet(day: day));

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<AttendanceProvider>();
    final calendar  = provider.calendar;
    final isLoading = provider.calendarLoading;
    final holidays  = calendar?.days.where((d) => d.status == 'holiday' && d.holidayName != null).toList() ?? [];

    // Stats for ring
    final total   = calendar?.days.length ?? 0;
    final present = calendar?.present ?? 0;
    final rate    = total > 0 ? present / total : 0.0;

    return Scaffold(
      backgroundColor: _offWhite,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeCtrl,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Navy top panel ──────────────────────────────────────────
              _buildNavyHeader(rate, calendar),
              // ── White content ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildCalendarCard(isLoading, calendar),
                  const SizedBox(height: 16),
                  if (calendar != null) ...[
                    _buildSummaryRow(calendar),
                    const SizedBox(height: 16),
                  ],
                  _buildLegend(),
                  const SizedBox(height: 16),
                  if (holidays.isNotEmpty) ...[
                    _buildHolidaySection(holidays),
                  ],
                  const SizedBox(height: 80),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildNavyHeader(double rate, MonthlyCalendar? calendar) {
    return Container(
      decoration: const BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Title row
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: _navyLight, borderRadius: BorderRadius.circular(13), border: Border.all(color: _cyan.withOpacity(0.3))),
            child: const Icon(Icons.calendar_month_rounded, color: _cyan, size: 22),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Attendance', style: TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w800)),
            Text('${_monthNames[_displayMonth.month - 1]} ${_displayMonth.year}',
              style: TextStyle(color: _white.withOpacity(0.5), fontSize: 12)),
          ]),
          const Spacer(),
          // Month nav chips
          _monthNavBtn(Icons.chevron_left_rounded, () => _changeMonth(-1)),
          const SizedBox(width: 6),
          _monthNavBtn(
            Icons.chevron_right_rounded,
            _displayMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month)) ? () => _changeMonth(1) : null,
          ),
        ]),

        const SizedBox(height: 24),

        // Overall ring + stats
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Big ring
          _OverallRing(rate: rate),
          const SizedBox(width: 24),
          // Mini stats
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Overall Attendance', style: TextStyle(color: _white.withOpacity(0.6), fontSize: 11, letterSpacing: 0.4)),
            const SizedBox(height: 4),
            Text('${(rate * 100).toStringAsFixed(0)}%', style: const TextStyle(color: _white, fontSize: 28, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 12),
            Row(children: [
              _miniStat('${calendar?.present ?? 0}', 'Present', _green),
              const SizedBox(width: 16),
              _miniStat('${calendar?.absent ?? 0}', 'Absent', _red),
            ]),
          ])),
        ]),
      ]),
    );
  }

  Widget _monthNavBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: onTap != null ? _cyan.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: onTap != null ? Border.all(color: _cyan.withOpacity(0.35)) : null,
        ),
        child: Icon(icon, color: onTap != null ? _cyan : _white.withOpacity(0.25), size: 20),
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900, height: 1)),
      Text(label, style: TextStyle(color: _white.withOpacity(0.45), fontSize: 10)),
    ]);
  }

  Widget _buildCalendarCard(bool isLoading, MonthlyCalendar? calendar) {
    return Container(
      decoration: BoxDecoration(
        color: _cardWhite, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _shadowBlue, blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: Row(children: [
            Expanded(child: Center(child: Text(
              '${_monthNames[_displayMonth.month - 1]} ${_displayMonth.year}',
              style: const TextStyle(color: _textPri, fontSize: 15, fontWeight: FontWeight.w800),
            ))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: ['S','M','T','W','T','F','S'].map((d) => Expanded(
              child: Center(child: Text(d, style: const TextStyle(color: _textHint, fontSize: 11, fontWeight: FontWeight.w700))),
            )).toList(),
          ),
        ),
        Container(height: 1, color: _border, margin: const EdgeInsets.fromLTRB(12, 8, 12, 0)),
        if (isLoading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator(color: _cyan, strokeWidth: 2)))
        else if (calendar == null)
          const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: Text('No data', style: TextStyle(color: _textHint))))
        else
          _buildGrid(calendar),
        const SizedBox(height: 10),
      ]),
    );
  }

  Widget _buildGrid(MonthlyCalendar calendar) {
    final firstDay = DateTime(calendar.year, calendar.month, 1);
    final offset = firstDay.weekday % 7;
    final today = DateTime.now();
    final cells = <Widget>[];
    for (int i = 0; i < offset; i++) cells.add(const SizedBox());
    for (final day in calendar.days) {
      final isToday = day.day == today.day && calendar.month == today.month && calendar.year == today.year;
      cells.add(_DayCell(day: day, isToday: isToday, onTap: () => _showDayDetail(day)));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1, children: cells),
    );
  }

  Widget _buildSummaryRow(MonthlyCalendar calendar) {
    return Row(children: [
      _summaryCard('Present',  '${calendar.present}',  _green, _greenPale,  Icons.check_circle_rounded),
      const SizedBox(width: 10),
      _summaryCard('Half Day', '${calendar.halfDay}',  _amber, _amberPale,  Icons.timelapse_rounded),
      const SizedBox(width: 10),
      _summaryCard('On Leave', '${calendar.onLeave}',  _cyan,  _cyanPale,   Icons.event_busy_rounded),
      const SizedBox(width: 10),
      _summaryCard('Absent',   '${calendar.absent}',   _red,   _redPale,    Icons.cancel_rounded),
    ]);
  }

  Widget _summaryCard(String label, String count, Color color, Color pale, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _cardWhite, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: color, size: 15)),
          const SizedBox(height: 7),
          Text(count, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: _textHint, fontSize: 9, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildLegend() {
    final items = [(_green, 'Present'), (_amber, 'Half Day'), (_cyan, 'On Leave'), (_red, 'Absent')];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: item.$1, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(item.$2, style: const TextStyle(color: _textSec, fontSize: 10, fontWeight: FontWeight.w500)),
        ])).toList(),
      ),
    );
  }

  Widget _buildHolidaySection(List<CalendarDay> holidays) {
    const mn = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _amberPale, borderRadius: BorderRadius.circular(10), border: Border.all(color: _amber.withOpacity(0.25))),
          child: const Icon(Icons.celebration_rounded, color: _amber, size: 16)),
        const SizedBox(width: 10),
        const Text('Holidays This Month', style: TextStyle(color: _textPri, fontSize: 15, fontWeight: FontWeight.w700)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: _amberPale, borderRadius: BorderRadius.circular(8)),
          child: Text('${holidays.length}', style: const TextStyle(color: _amber, fontSize: 12, fontWeight: FontWeight.w800))),
      ]),
      const SizedBox(height: 12),
      ...holidays.map((h) {
        final dt = DateTime.tryParse(h.date);
        final mn2 = mn; final dayNames = ['','Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
        final dayName = dt != null ? dayNames[dt.weekday] : '';
        final dateStr = dt != null ? '${dt.day} ${mn2[dt.month]}, $dayName' : h.date;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _cardWhite, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _amber.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: _amber.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: _amberPale, borderRadius: BorderRadius.circular(12), border: Border.all(color: _amber.withOpacity(0.2))),
              child: Center(child: Text(dt != null ? '${dt.day}' : '', style: const TextStyle(color: _amber, fontSize: 16, fontWeight: FontWeight.w800)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.holidayName ?? 'Holiday', style: const TextStyle(color: _textPri, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(dateStr, style: const TextStyle(color: _textSec, fontSize: 12)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _amberPale, borderRadius: BorderRadius.circular(6)),
              child: const Text('Holiday', style: TextStyle(color: _amber, fontSize: 10, fontWeight: FontWeight.w700))),
          ]),
        );
      }),
    ]);
  }
}

// ── Overall ring ───────────────────────────────────────────────────────────────
class _OverallRing extends StatefulWidget {
  final double rate;
  const _OverallRing({required this.rate});
  @override
  State<_OverallRing> createState() => _OverallRingState();
}

class _OverallRingState extends State<_OverallRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = Tween<double>(begin: 0, end: widget.rate).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return SizedBox(
          width: 110, height: 110,
          child: CustomPaint(
            painter: _RingPainter2(progress: _anim.value, ringColor: _cyan, trackColor: _white.withOpacity(0.1)),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Text('${(_anim.value * 100).toStringAsFixed(0)}', style: const TextStyle(color: _white, fontSize: 26, fontWeight: FontWeight.w900, height: 1)),
              // Text('percent', style: TextStyle(color: _white.withOpacity(0.45), fontSize: 9, letterSpacing: 0.4)),
            ])),
          ),
        );
      },
    );
  }
}

class _RingPainter2 extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  const _RingPainter2({required this.progress, required this.ringColor, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final r = (size.width - 16) / 2;
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round;
    p.color = trackColor;
    canvas.drawCircle(Offset(cx, cy), r, p);
    if (progress > 0) {
      p.shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + math.pi * 2 * progress,
        colors: [ringColor, const Color(0xFF48CAE4)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -math.pi / 2, math.pi * 2 * progress, false, p);
    }
  }

  @override
  bool shouldRepaint(_RingPainter2 o) => o.progress != progress;
}

// ── Day cell ───────────────────────────────────────────────────────────────────
class _DayCell extends StatelessWidget {
  final CalendarDay day;
  final bool isToday;
  final VoidCallback? onTap;
  const _DayCell({required this.day, required this.isToday, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color? dotColor; Color? bgColor; Color textColor = _textSec;
    switch (day.status) {
      case 'present':  dotColor = _green;  bgColor = _greenPale; break;
      case 'half_day': dotColor = _amber;  bgColor = _amberPale; break;
      case 'on_leave': dotColor = _cyan;   bgColor = _cyanPale;  break;
      case 'absent':   dotColor = _red;    bgColor = _redPale;   break;
      case 'holiday':  dotColor = _amber;  bgColor = _amberPale; break;
      case 'weekend':  dotColor = null; bgColor = null; textColor = _border; break;
      default:         dotColor = null; bgColor = null;
    }
    final now = DateTime.now();
    final dayDate = DateTime.tryParse(day.date);
    if (dayDate != null && dayDate.isAfter(now) && day.status == 'no_record') textColor = _border;

    return GestureDetector(
      onTap: day.status != 'no_record' && day.status != 'weekend' ? onTap : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? _navy : bgColor,
          shape: BoxShape.circle,
          boxShadow: isToday ? [BoxShadow(color: _navy.withOpacity(0.4), blurRadius: 8)] : null,
        ),
        child: Stack(alignment: Alignment.center, children: [
          Text('${day.day}', style: TextStyle(
            color: isToday ? _cyan : (dotColor ?? textColor),
            fontSize: 12,
            fontWeight: isToday || dotColor != null ? FontWeight.w700 : FontWeight.w400,
          )),
          if (dotColor != null && !isToday)
            Positioned(bottom: 3, child: Container(width: 4, height: 4, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle))),
        ]),
      ),
    );
  }
}

// ── Day detail sheet ───────────────────────────────────────────────────────────
class _DayDetailSheet extends StatelessWidget {
  final CalendarDay day;
  const _DayDetailSheet({required this.day});

  void _showCorrectionSheet(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _CorrectionSheet(day: day));
  }

  @override
  Widget build(BuildContext context) {
    Color sc; String sl; IconData si;
    switch (day.status) {
      case 'present':  sc = _green;     sl = 'Present';                   si = Icons.check_circle_rounded;    break;
      case 'half_day': sc = _amber;     sl = 'Half Day';                   si = Icons.timelapse_rounded;       break;
      case 'on_leave': sc = _cyan;      sl = 'On Leave';                   si = Icons.event_busy_rounded;      break;
      case 'absent':   sc = _red;       sl = 'Absent';                    si = Icons.cancel_rounded;          break;
      case 'holiday':  sc = _amber;     sl = day.holidayName ?? 'Holiday'; si = Icons.celebration_rounded;     break;
      case 'weekend':  sc = _textHint;  sl = 'Weekend';                   si = Icons.weekend_rounded;         break;
      default:         sc = _textHint;  sl = 'No Record';                 si = Icons.remove_circle_outline_rounded;
    }
    const mn = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final pd = DateTime.tryParse(day.date);
    final dl = pd != null ? '${pd.day} ${mn[pd.month]} ${pd.year}' : day.date;
    final isHW = day.status == 'holiday' || day.status == 'weekend';
    final canCorrect = !isHW && day.status != 'no_record' && day.status != 'present';

    return Container(
      decoration: const BoxDecoration(color: _white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 44),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        // Top navy accent strip
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dl, style: const TextStyle(color: _white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: sc.withOpacity(0.2), borderRadius: BorderRadius.circular(7), border: Border.all(color: sc.withOpacity(0.4))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(si, size: 12, color: sc), const SizedBox(width: 5),
                  Text(sl, style: TextStyle(color: sc, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
            const Spacer(),
            if (day.workType != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: _white.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: _white.withOpacity(0.15))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(day.workType == 'wfo' ? Icons.business_rounded : Icons.home_rounded, size: 14, color: _cyan),
                  const SizedBox(width: 5),
                  Text(day.workType == 'wfo' ? 'WFO' : 'WFH', style: const TextStyle(color: _cyan, fontSize: 12, fontWeight: FontWeight.w800)),
                ]),
              ),
          ]),
        ),
        if (!isHW) ...[
          const SizedBox(height: 22),
          Row(children: [
            _dc(Icons.login_rounded, _green, 'Clock In', _fmt(day.clockIn)),
            Container(width: 1, height: 56, color: _border),
            _dc(Icons.logout_rounded, _red, 'Clock Out', _fmt(day.clockOut)),
            Container(width: 1, height: 56, color: _border),
            _dc(Icons.timer_outlined, _cyan, 'Duration', _dur(day.durationMinutes)),
          ]),
          if (day.isLate) ...[
            const SizedBox(height: 14),
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(color: _amberPale, borderRadius: BorderRadius.circular(12), border: Border.all(color: _amber.withOpacity(0.3))),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.schedule_rounded, color: _amber, size: 16), SizedBox(width: 7),
                Text('Checked in late', style: TextStyle(color: _amber, fontSize: 13, fontWeight: FontWeight.w700)),
              ])),
          ],
          if (canCorrect) ...[
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _showCorrectionSheet(context),
                icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                label: const Text('Request Correction', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(foregroundColor: _navy, side: BorderSide(color: _navy.withOpacity(0.3)), backgroundColor: _offWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              )),
          ],
        ] else ...[
          const SizedBox(height: 20),
          Container(width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: sc.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: sc.withOpacity(0.2))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(si, color: sc, size: 20), const SizedBox(width: 10),
              Text(day.status == 'holiday' ? 'Enjoy your holiday! 🎉' : "It's a weekend — rest up! 😊", style: TextStyle(color: sc, fontSize: 14, fontWeight: FontWeight.w700)),
            ])),
        ],
      ]),
    );
  }

  Widget _dc(IconData icon, Color color, String label, String value) =>
    Expanded(child: Column(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 17)),
      const SizedBox(height: 7),
      Text(value, style: TextStyle(color: value == '--' ? _textHint : _textPri, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: _textHint, fontSize: 11)),
    ]));

  String _fmt(String? iso) {
    if (iso == null) return '--';
    try { final dt = DateTime.parse(iso).toLocal(); return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}'; }
    catch (_) { return '--'; }
  }
  String _dur(int? mins) {
    if (mins == null) return '--'; final h = mins ~/ 60; final m = mins % 60;
    if (h == 0) return '${m}m'; if (m == 0) return '${h}h'; return '${h}h ${m}m';
  }
}

// ── Correction sheet ───────────────────────────────────────────────────────────
class _CorrectionSheet extends StatefulWidget {
  final CalendarDay day;
  const _CorrectionSheet({required this.day});
  @override
  State<_CorrectionSheet> createState() => _CorrectionSheetState();
}

class _CorrectionSheetState extends State<_CorrectionSheet> {
  final _reasonCtrl = TextEditingController();
  TimeOfDay? _clockIn; TimeOfDay? _clockOut; bool _submitting = false;

  @override
  void dispose() { _reasonCtrl.dispose(); super.dispose(); }

  Future<void> _pickTime(bool isCi) async {
    final picked = await showTimePicker(context: context,
      initialTime: isCi ? const TimeOfDay(hour: 9, minute: 0) : const TimeOfDay(hour: 18, minute: 0),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: _cyan, onPrimary: _white, surface: _white)), child: child!));
    if (picked != null) setState(() { if (isCi) _clockIn = picked; else _clockOut = picked; });
  }

  String _fmtT(TimeOfDay? t) => t == null ? 'Select time' : '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  Future<void> _submit() async {
    if (_clockIn == null || _clockOut == null) { _snack('Select both times', _amber); return; }
    if (_reasonCtrl.text.trim().isEmpty) { _snack('Enter a reason', _amber); return; }
    setState(() => _submitting = true);
    try {
      await AttendanceRepository.submitCorrection(attendanceDate: widget.day.date, clockIn: _fmtT(_clockIn), clockOut: _fmtT(_clockOut), reason: _reasonCtrl.text.trim());
      if (mounted) { Navigator.pop(context); _snack('Correction submitted!', _green); }
    } catch (e) { if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''), _red); }
    if (mounted) setState(() => _submitting = false);
  }

  void _snack(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(m, style: const TextStyle(color: _white, fontWeight: FontWeight.w600)),
    backgroundColor: c, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));

  @override
  Widget build(BuildContext context) {
    const mn = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dt = DateTime.tryParse(widget.day.date);
    final dl = dt != null ? '${dt.day} ${mn[dt.month]} ${dt.year}' : widget.day.date;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: _white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.edit_calendar_rounded, color: _cyan, size: 20)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Request Correction', style: TextStyle(color: _textPri, fontSize: 17, fontWeight: FontWeight.w800)),
              Text(dl, style: const TextStyle(color: _textSec, fontSize: 12)),
            ]),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _tp('Clock In', _fmtT(_clockIn), Icons.login_rounded, _green, () => _pickTime(true), _clockIn != null)),
            const SizedBox(width: 12),
            Expanded(child: _tp('Clock Out', _fmtT(_clockOut), Icons.logout_rounded, _red, () => _pickTime(false), _clockOut != null)),
          ]),
          const SizedBox(height: 16),
          const Text('Reason', style: TextStyle(color: _textSec, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonCtrl, maxLines: 3,
            style: const TextStyle(color: _textPri, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Why do you need a correction?', hintStyle: const TextStyle(color: _textHint, fontSize: 14),
              filled: true, fillColor: _offWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cyan, width: 1.5)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: _white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _submitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                : const Text('Submit Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            )),
        ])),
      ),
    );
  }

  Widget _tp(String label, String value, IconData icon, Color color, VoidCallback onTap, bool hasVal) =>
    GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasVal ? color.withOpacity(0.06) : _offWhite,
        border: Border.all(color: hasVal ? color.withOpacity(0.3) : _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 13, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 7),
        Text(value, style: TextStyle(color: hasVal ? _textPri : _textHint, fontSize: 16, fontWeight: hasVal ? FontWeight.w700 : FontWeight.w400)),
      ]),
    ));
}