import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../data/models/attendance_model.dart';

const _blue       = Color(0xFF2563EB);
const _cyan       = Color(0xFF0891B2);
const _blueLight  = Color(0xFFEFF6FF);
const _cyanLight  = Color(0xFFECFEFF);
const _green      = Color(0xFF16A34A);
const _greenLight = Color(0xFFF0FDF4);
const _amber      = Color(0xFFD97706);
const _amberLight = Color(0xFFFFFBEB);
const _red        = Color(0xFFDC2626);
const _textPri    = Color(0xFF111827);
const _textSec    = Color(0xFF6B7280);
const _textHint   = Color(0xFF9CA3AF);
const _border     = Color(0xFFE5E7EB);
const _redLight   = Color(0xFFFEF2F2);
const _bg         = Color(0xFFF8FAFF);
const _white      = Color(0xFFFFFFFF);
const _purple      = Color(0xFF7C3AED);
const _purpleLight = Color(0xFFF5F3FF);

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCalendar());
  }

  void _loadCalendar() {
    context.read<AttendanceProvider>().loadCalendar(
          month: _displayMonth.month,
          year:  _displayMonth.year,
        );
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + delta);
    });
    _loadCalendar();
  }

  // ── Day detail modal ───────────────────────────────────────────────────────
  void _showDayDetail(CalendarDay day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DayDetailSheet(day: day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<AttendanceProvider>();
    final calendar  = provider.calendar;
    final isLoading = provider.calendarLoading;

    final monthNames = ['January','February','March','April','May','June',
                        'July','August','September','October','November','December'];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text('Attendance',
                  style: TextStyle(color: _textPri, fontSize: 22, fontWeight: FontWeight.w700)),
              const Text('Your attendance calendar',
                  style: TextStyle(color: _textSec, fontSize: 13)),
              const SizedBox(height: 20),

              // Calendar card
              Container(
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    // Month navigator
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.chevron_left_rounded),
                            color: _textSec,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '${monthNames[_displayMonth.month - 1]} ${_displayMonth.year}',
                                style: const TextStyle(
                                  color: _textPri, fontSize: 16, fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _displayMonth.isBefore(
                                  DateTime(DateTime.now().year, DateTime.now().month))
                                ? () => _changeMonth(1)
                                : null,
                            icon: const Icon(Icons.chevron_right_rounded),
                            color: _displayMonth.isBefore(
                                    DateTime(DateTime.now().year, DateTime.now().month))
                                ? _textSec
                                : _textHint,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),

                    // Day-of-week headers
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: ['S','M','T','W','T','F','S']
                            .map((d) => Expanded(
                                  child: Center(
                                    child: Text(d,
                                        style: const TextStyle(
                                          color: _textHint,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Calendar grid
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator(color: _blue, strokeWidth: 2)),
                      )
                    else if (calendar == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: Text('No data', style: TextStyle(color: _textHint))),
                      )
                    else
                      _buildGrid(calendar),

                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Summary
              if (calendar != null) ...[
                const SizedBox(height: 16),
                _buildSummaryRow(calendar),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(MonthlyCalendar calendar) {
    final firstDayOfMonth = DateTime(calendar.year, calendar.month, 1);
    final offset = firstDayOfMonth.weekday % 7; 
    final today           = DateTime.now();

    final cells = <Widget>[];

    for (int i = 0; i < offset; i++) {
      cells.add(const SizedBox());
    }

    for (final day in calendar.days) {
      final isToday = day.day == today.day &&
          calendar.month == today.month &&
          calendar.year == today.year;
      cells.add(_DayCell(
        day:     day,
        isToday: isToday,
        onTap:   () => _showDayDetail(day),   // ← wired up
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1,
        children: cells,
      ),
    );
  }

Widget _buildSummaryRow(MonthlyCalendar calendar) {
  return Column(
    children: [
      Row(
        children: [
          _summaryCard('Present',  calendar.present.toString(),  _green,  _greenLight, Icons.check_circle_rounded),
          const SizedBox(width: 10),
          _summaryCard('Half Day', calendar.halfDay.toString(),  _amber,  _amberLight, Icons.timelapse_rounded),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          _summaryCard('On Leave', calendar.onLeave.toString(),  _blue,   _blueLight,  Icons.event_busy_rounded),
          const SizedBox(width: 10),
          _summaryCard('Absent',   calendar.absent.toString(),   _red,    Color(0xFFFEF2F2), Icons.cancel_rounded),
        ],
      ),
    ],
  );
}

  Widget _summaryCard(String label, String count, Color color, Color bg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(count,
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(color: _textSec, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Day cell ──────────────────────────────────────────────────────────────────
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
      case 'present':
        dotColor = const Color(0xFF16A34A);
        bgColor  = const Color(0xFFF0FDF4);
        break;
      case 'half_day':
        dotColor = const Color(0xFFD97706);
        bgColor  = const Color(0xFFFFFBEB);
        break;
      case 'on_leave':
        dotColor = const Color(0xFF2563EB);
        bgColor  = const Color(0xFFEFF6FF);
        break;
      case 'absent':
        dotColor = _red;
        bgColor  = _redLight;
        break;
      default:
        dotColor = null;
        bgColor  = null;
    }

    final now     = DateTime.now();
    final dayDate = DateTime.tryParse(day.date);
    if (dayDate != null && dayDate.isAfter(now)) {
      textColor = const Color(0xFFD1D5DB);
    }

    return GestureDetector(
      onTap: day.status != 'no_record' ? onTap : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFF2563EB) : bgColor,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isToday
                    ? Colors.white
                    : dotColor != null
                        ? dotColor
                        : textColor,
                fontSize: 13,
                fontWeight: isToday || dotColor != null
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
            if (dotColor != null && !isToday)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Day detail bottom sheet ───────────────────────────────────────────────────
class _DayDetailSheet extends StatelessWidget {
  final CalendarDay day;
  const _DayDetailSheet({required this.day});

  @override
  Widget build(BuildContext context) {
    // Status config
    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    debugPrint('>>> Sheet status: "${day.status}" workType: "${day.workType}"');

    switch (day.status) {
      case 'present':
        statusColor = _green; statusBg = _greenLight;
        statusLabel = 'Present'; statusIcon = Icons.check_circle_rounded;
        break;
      case 'half_day':
        statusColor = _amber; statusBg = _amberLight;
        statusLabel = 'Half Day'; statusIcon = Icons.timelapse_rounded;
        break;
      case 'on_leave':
        statusColor = _blue; statusBg = _blueLight;
        statusLabel = 'On Leave'; statusIcon = Icons.event_busy_rounded;
        break;
      case 'absent':
        statusColor = _red;      statusBg    = _redLight;
        statusLabel = 'Absent';  statusIcon  = Icons.cancel_rounded;
        break;
      default:
        statusColor = _textHint; statusBg = _bg;
        statusLabel = 'No Record'; statusIcon = Icons.remove_circle_outline_rounded;
    }

    const monthNames = ['','Jan','Feb','Mar','Apr','May','Jun',
                        'Jul','Aug','Sep','Oct','Nov','Dec'];
    final parsedDate = DateTime.tryParse(day.date);
    final dateLabel  = parsedDate != null
        ? '${parsedDate.day} ${monthNames[parsedDate.month]} ${parsedDate.year}'
        : day.date;

    return Container(
      decoration: const BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),

          // Date row + status badge + work type
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateLabel,
                      style: const TextStyle(
                          color: _textPri, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(statusLabel,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (day.workType != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: day.workType == 'wfo' ? _blueLight : _cyanLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: (day.workType == 'wfo' ? _blue : _cyan).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        day.workType == 'wfo'
                            ? Icons.business_rounded
                            : Icons.home_rounded,
                        size: 14,
                        color: day.workType == 'wfo' ? _blue : _cyan,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        day.workType == 'wfo' ? 'WFO' : 'WFH',
                        style: TextStyle(
                          color: day.workType == 'wfo' ? _blue : _cyan,
                          fontSize: 12, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),
          Container(height: 1, color: _border),
          const SizedBox(height: 24),

          // Clock In / Clock Out / Duration
          Row(
            children: [
              _detailCell(
                icon:  Icons.login_rounded,
                color: _green,
                label: 'Clock In',
                value: _fmt(day.clockIn),
              ),
              Container(width: 1, height: 56, color: _border),
              _detailCell(
                icon:  Icons.logout_rounded,
                color: _red,
                label: 'Clock Out',
                value: _fmt(day.clockOut),
              ),
              Container(width: 1, height: 56, color: _border),
              _detailCell(
                icon:  Icons.timer_outlined,
                color: _blue,
                label: 'Duration',
                value: _dur(day.durationMinutes),
              ),
            ],
          ),

          // Late banner
          if (day.isLate) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _amberLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _amber.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_rounded, color: _amber, size: 16),
                  SizedBox(width: 6),
                  Text('Checked in late',
                      style: TextStyle(
                          color: _amber, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailCell({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                color: value == '--' ? _textHint : _textPri,
                fontSize: 16, fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: _textHint, fontSize: 11)),
        ],
      ),
    );
  }

  String _fmt(String? iso) {
    if (iso == null) return '--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--';
    }
  }

  String _dur(int? mins) {
    if (mins == null) return '--';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}