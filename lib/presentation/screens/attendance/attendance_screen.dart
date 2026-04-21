import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/repositories/attendance_repository.dart';

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
const _borderMid  = Color(0xFFCDD5FF);
const _shadow     = Color(0x193B5BDB);

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  late DateTime _displayMonth;
  late AnimationController _fadeCtrl;

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCalendar());
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  void _loadCalendar() {
    _fadeCtrl.reset();
    context.read<AttendanceProvider>().loadCalendar(
      month: _displayMonth.month, year: _displayMonth.year,
    ).then((_) { if (mounted) _fadeCtrl.forward(); });
  }

  void _changeMonth(int delta) {
    setState(() { _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + delta); });
    _loadCalendar();
  }

  void _showDayDetail(CalendarDay day) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _DayDetailSheet(day: day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<AttendanceProvider>();
    final calendar  = provider.calendar;
    final isLoading = provider.calendarLoading;

    final holidays = calendar?.days
        .where((d) => d.status == 'holiday' && d.holidayName != null).toList() ?? [];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeCtrl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildCalendarCard(isLoading, calendar),
              const SizedBox(height: 14),
              if (calendar != null) ...[
                _buildSummaryGrid(calendar),
                const SizedBox(height: 14),
              ],
              _buildLegend(),
              const SizedBox(height: 14),
              if (holidays.isNotEmpty) ...[
                _buildHolidaySection(holidays),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_blue, _violet], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _blue.withOpacity(0.28), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: _white.withOpacity(0.18), borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.calendar_month_rounded, color: _white, size: 24),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Attendance', style: TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w800)),
          Text('${_monthNames[_displayMonth.month - 1]} ${_displayMonth.year}',
            style: TextStyle(color: _white.withOpacity(0.65), fontSize: 12)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: _white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
          child: Text('${_displayMonth.year}', style: const TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _buildCalendarCard(bool isLoading, MonthlyCalendar? calendar) {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _shadow, blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Month navigator
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
          child: Row(children: [
            _navBtn(Icons.chevron_left_rounded, () => _changeMonth(-1)),
            Expanded(
              child: Center(child: Text(
                '${_monthNames[_displayMonth.month - 1]} ${_displayMonth.year}',
                style: const TextStyle(color: _textPri, fontSize: 16, fontWeight: FontWeight.w800),
              )),
            ),
            _navBtn(
              Icons.chevron_right_rounded,
              _displayMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month)) ? () => _changeMonth(1) : null,
            ),
          ]),
        ),
        // Day labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: ['S','M','T','W','T','F','S'].map((d) => Expanded(
              child: Center(child: Text(d, style: const TextStyle(color: _textHint, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
            )).toList(),
          ),
        ),
        // Subtle separator
        Container(height: 1, color: _border, margin: const EdgeInsets.fromLTRB(10, 8, 10, 0)),

        if (isLoading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 50), child: Center(child: CircularProgressIndicator(color: _blue, strokeWidth: 2)))
        else if (calendar == null)
          const Padding(padding: EdgeInsets.symmetric(vertical: 50), child: Center(child: Text('No data', style: TextStyle(color: _textHint))))
        else
          _buildGrid(calendar),
        const SizedBox(height: 10),
      ]),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? _blueLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: onTap != null ? Border.all(color: _blueMid) : null,
        ),
        child: Icon(icon, color: onTap != null ? _blue : _textHint, size: 22),
      ),
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
      child: GridView.count(
        crossAxisCount: 7, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1, children: cells,
      ),
    );
  }

  Widget _buildSummaryGrid(MonthlyCalendar calendar) {
    return Row(children: [
      _summaryTile('Present', calendar.present.toString(), _green, _greenLight, Icons.check_circle_rounded),
      const SizedBox(width: 10),
      _summaryTile('Half Day', calendar.halfDay.toString(), _amber, _amberLight, Icons.timelapse_rounded),
      const SizedBox(width: 10),
      _summaryTile('On Leave', calendar.onLeave.toString(), _blue, _blueLight, Icons.event_busy_rounded),
      const SizedBox(width: 10),
      _summaryTile('Absent', calendar.absent.toString(), _red, _redLight, Icons.cancel_rounded),
    ]);
  }

  Widget _summaryTile(String label, String count, Color color, Color bg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _bgCard, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 16)),
          const SizedBox(height: 7),
          Text(count, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: _textSec, fontSize: 9, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildLegend() {
    final items = [(_green, 'Present'), (_amber, 'Half Day'), (_blue, 'On Leave'), (_red, 'Absent')];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bgCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _amberLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: _amber.withOpacity(0.25))),
          child: const Icon(Icons.celebration_rounded, color: _amber, size: 16),
        ),
        const SizedBox(width: 10),
        const Text('Holidays This Month', style: TextStyle(color: _textPri, fontSize: 15, fontWeight: FontWeight.w700)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: _amberLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: _amber.withOpacity(0.2))),
          child: Text('${holidays.length}', style: const TextStyle(color: _amber, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
      ]),
      const SizedBox(height: 12),
      ...holidays.map((h) {
        final dt = DateTime.tryParse(h.date);
        final dayNames = ['','Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
        final dayName = dt != null ? dayNames[dt.weekday] : '';
        final dateStr = dt != null ? '${dt.day} ${mn[dt.month]}, $dayName' : h.date;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _bgCard, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _amber.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: _amber.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: _amberLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: _amber.withOpacity(0.2))),
              child: Center(child: Text(dt != null ? '${dt.day}' : '', style: const TextStyle(color: _amber, fontSize: 16, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.holidayName ?? 'Holiday', style: const TextStyle(color: _textPri, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(dateStr, style: const TextStyle(color: _textSec, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _amberLight, borderRadius: BorderRadius.circular(6)),
              child: const Text('Holiday', style: TextStyle(color: _amber, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
        );
      }),
    ]);
  }
}

// ── Day Cell ───────────────────────────────────────────────────────────────────
class _DayCell extends StatelessWidget {
  final CalendarDay day;
  final bool isToday;
  final VoidCallback? onTap;
  const _DayCell({required this.day, required this.isToday, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color? dotColor;
    Color? bgColor;
    Color textColor = const Color(0xFF374151);

    switch (day.status) {
      case 'present':  dotColor = _green;  bgColor = _greenLight; break;
      case 'half_day': dotColor = _amber;  bgColor = _amberLight; break;
      case 'on_leave': dotColor = _blue;   bgColor = _blueLight;  break;
      case 'absent':   dotColor = _red;    bgColor = _redLight;   break;
      case 'holiday':  dotColor = _amber;  bgColor = _amberLight; break;
      case 'weekend':  dotColor = null; bgColor = null; textColor = const Color(0xFFCBD5E1); break;
      default:         dotColor = null; bgColor = null;
    }

    final now = DateTime.now();
    final dayDate = DateTime.tryParse(day.date);
    if (dayDate != null && dayDate.isAfter(now) && day.status == 'no_record') {
      textColor = const Color(0xFFCBD5E1);
    }

    return GestureDetector(
      onTap: day.status != 'no_record' && day.status != 'weekend' ? onTap : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? _blue : bgColor,
          shape: BoxShape.circle,
          boxShadow: isToday ? [BoxShadow(color: _blue.withOpacity(0.35), blurRadius: 8)] : null,
        ),
        child: Stack(alignment: Alignment.center, children: [
          Text('${day.day}', style: TextStyle(
            color: isToday ? _white : (dotColor != null ? dotColor : textColor),
            fontSize: 12,
            fontWeight: isToday || dotColor != null ? FontWeight.w700 : FontWeight.w400,
          )),
          if (dotColor != null && !isToday)
            Positioned(bottom: 3, child: Container(width: 4, height: 4,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle))),
        ]),
      ),
    );
  }
}

// ── Day Detail Sheet ──────────────────────────────────────────────────────────
class _DayDetailSheet extends StatelessWidget {
  final CalendarDay day;
  const _DayDetailSheet({required this.day});

  void _showCorrectionSheet(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _CorrectionSheet(day: day));
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor; String statusLabel; IconData statusIcon;
    switch (day.status) {
      case 'present':  statusColor = _green;  statusLabel = 'Present';            statusIcon = Icons.check_circle_rounded;   break;
      case 'half_day': statusColor = _amber;  statusLabel = 'Half Day';            statusIcon = Icons.timelapse_rounded;      break;
      case 'on_leave': statusColor = _blue;   statusLabel = 'On Leave';            statusIcon = Icons.event_busy_rounded;     break;
      case 'absent':   statusColor = _red;    statusLabel = 'Absent';             statusIcon = Icons.cancel_rounded;         break;
      case 'holiday':  statusColor = _amber;  statusLabel = day.holidayName ?? 'Holiday'; statusIcon = Icons.celebration_rounded; break;
      case 'weekend':  statusColor = _textHint; statusLabel = 'Weekend';          statusIcon = Icons.weekend_rounded;        break;
      default:         statusColor = _textHint; statusLabel = 'No Record';        statusIcon = Icons.remove_circle_outline_rounded;
    }
    const mn = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final parsedDate = DateTime.tryParse(day.date);
    final dateLabel = parsedDate != null ? '${parsedDate.day} ${mn[parsedDate.month]} ${parsedDate.year}' : day.date;
    final isHolidayOrWeekend = day.status == 'holiday' || day.status == 'weekend';
    final canCorrect = !isHolidayOrWeekend && 
                       day.status != 'no_record' &&
                       day.status != 'present';

    return Container(
      decoration: const BoxDecoration(color: _white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 44),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 22),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dateLabel, style: const TextStyle(color: _textPri, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 5),
                Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const Spacer(),
          if (day.workType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: day.workType == 'wfo' ? _blueLight : _cyanLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (day.workType == 'wfo' ? _blue : _cyan).withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(day.workType == 'wfo' ? Icons.business_rounded : Icons.home_rounded, size: 14, color: day.workType == 'wfo' ? _blue : _cyan),
                const SizedBox(width: 5),
                Text(day.workType == 'wfo' ? 'WFO' : 'WFH', style: TextStyle(color: day.workType == 'wfo' ? _blue : _cyan, fontSize: 12, fontWeight: FontWeight.w800)),
              ]),
            ),
        ]),
        if (!isHolidayOrWeekend) ...[
          const SizedBox(height: 24),
          Container(height: 1, color: _border),
          const SizedBox(height: 24),
          Row(children: [
            _detailCell(icon: Icons.login_rounded, color: _green, label: 'Clock In', value: _fmt(day.clockIn)),
            Container(width: 1, height: 56, color: _border),
            _detailCell(icon: Icons.logout_rounded, color: _red, label: 'Clock Out', value: _fmt(day.clockOut)),
            Container(width: 1, height: 56, color: _border),
            _detailCell(icon: Icons.timer_outlined, color: _blue, label: 'Duration', value: _dur(day.durationMinutes)),
          ]),
          if (day.isLate) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(color: _amberLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: _amber.withOpacity(0.3))),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.schedule_rounded, color: _amber, size: 16),
                SizedBox(width: 7),
                Text('Checked in late', style: TextStyle(color: _amber, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
          if (canCorrect) ...[
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _showCorrectionSheet(context),
                icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                label: const Text('Request Correction', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _blue,
                  side: BorderSide(color: _blue.withOpacity(0.35)),
                  backgroundColor: _blueLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ] else ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.07), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(statusIcon, color: statusColor, size: 20), const SizedBox(width: 10),
              Text(day.status == 'holiday' ? 'Enjoy your holiday! 🎉' : "It's a weekend — rest up! 😊",
                style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _detailCell({required IconData icon, required Color color, required String label, required String value}) {
    return Expanded(child: Column(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 17)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(color: value == '--' ? _textHint : _textPri, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(color: _textHint, fontSize: 11)),
    ]));
  }

  String _fmt(String? iso) {
    if (iso == null) return '--';
    try { final dt = DateTime.parse(iso).toLocal(); return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}'; }
    catch (_) { return '--'; }
  }

  String _dur(int? mins) {
    if (mins == null) return '--';
    final h = mins ~/ 60; final m = mins % 60;
    if (h == 0) return '${m}m'; if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

// ── Correction Sheet ───────────────────────────────────────────────────────────
class _CorrectionSheet extends StatefulWidget {
  final CalendarDay day;
  const _CorrectionSheet({required this.day});
  @override
  State<_CorrectionSheet> createState() => _CorrectionSheetState();
}

class _CorrectionSheetState extends State<_CorrectionSheet> {
  final _reasonCtrl = TextEditingController();
  TimeOfDay? _clockIn;
  TimeOfDay? _clockOut;
  bool _submitting = false;

  @override
  void dispose() { _reasonCtrl.dispose(); super.dispose(); }

  Future<void> _pickTime(bool isClockIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isClockIn ? const TimeOfDay(hour: 9, minute: 0) : const TimeOfDay(hour: 18, minute: 0),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _blue)), child: child!),
    );
    if (picked != null) setState(() { if (isClockIn) _clockIn = picked; else _clockOut = picked; });
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return 'Select time';
    return '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
  }

  Future<void> _submit() async {
    if (_clockIn == null || _clockOut == null) { _snack('Please select both times', _amber); return; }
    if (_reasonCtrl.text.trim().isEmpty) { _snack('Please enter a reason', _amber); return; }
    setState(() => _submitting = true);
    try {
      await AttendanceRepository.submitCorrection(attendanceDate: widget.day.date, clockIn: _fmtTime(_clockIn), clockOut: _fmtTime(_clockOut), reason: _reasonCtrl.text.trim());
      if (mounted) { Navigator.pop(context); _snack('Correction submitted!', _green); }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''), _red);
    }
    if (mounted) setState(() => _submitting = false);
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: _white, fontWeight: FontWeight.w600)),
    backgroundColor: color, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16),
  ));

  @override
  Widget build(BuildContext context) {
    const mn = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dt = DateTime.tryParse(widget.day.date);
    final dateLabel = dt != null ? '${dt.day} ${mn[dt.month]} ${dt.year}' : widget.day.date;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: _white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 22),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_blue, _violet]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_calendar_rounded, color: _white, size: 20),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Request Correction', style: TextStyle(color: _textPri, fontSize: 17, fontWeight: FontWeight.w800)),
                Text(dateLabel, style: const TextStyle(color: _textSec, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _timePicker(label: 'Clock In', value: _fmtTime(_clockIn), icon: Icons.login_rounded, color: _green, onTap: () => _pickTime(true), hasValue: _clockIn != null)),
              const SizedBox(width: 12),
              Expanded(child: _timePicker(label: 'Clock Out', value: _fmtTime(_clockOut), icon: Icons.logout_rounded, color: _red, onTap: () => _pickTime(false), hasValue: _clockOut != null)),
            ]),
            const SizedBox(height: 18),
            const Text('Reason', style: TextStyle(color: _textSec, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl, maxLines: 3,
              style: const TextStyle(color: _textPri, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Why do you need a correction?',
                hintStyle: const TextStyle(color: _textHint, fontSize: 14),
                filled: true, fillColor: _bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _blue, width: 1.5)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, foregroundColor: _white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _submitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                    : const Text('Submit Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _timePicker({required String label, required String value, required IconData icon, required Color color, required VoidCallback onTap, required bool hasValue}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasValue ? color.withOpacity(0.06) : _bg,
          border: Border.all(color: hasValue ? color.withOpacity(0.3) : _border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 13, color: color), const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 7),
          Text(value, style: TextStyle(color: hasValue ? _textPri : _textHint, fontSize: 16, fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400)),
        ]),
      ),
    );
  }
}