import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../data/models/attendance_model.dart';

const _blue       = Color(0xFF2563EB);
const _cyan       = Color(0xFF0891B2);
const _blueLight  = Color(0xFFEFF6FF);
const _green      = Color(0xFF16A34A);
const _greenLight = Color(0xFFF0FDF4);
const _amber      = Color(0xFFD97706);
const _amberLight = Color(0xFFFFFBEB);
const _red        = Color(0xFFDC2626);
const _textPri    = Color(0xFF111827);
const _textSec    = Color(0xFF6B7280);
const _textHint   = Color(0xFF9CA3AF);
const _border     = Color(0xFFE5E7EB);
const _bg         = Color(0xFFF8FAFF);
const _white      = Color(0xFFFFFFFF);

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
    // figure out weekday offset: 0=Sun ... 6=Sat
    final firstDayOfMonth = DateTime(calendar.year, calendar.month, 1);
    final offset          = firstDayOfMonth.weekday % 7; // Mon=1→1, Sun=7→0
    final today           = DateTime.now();

    // build cells: blanks + days
    final cells = <Widget>[];

    // blank cells before first day
    for (int i = 0; i < offset; i++) {
      cells.add(const SizedBox());
    }

    for (final day in calendar.days) {
      final isToday = day.day == today.day &&
          calendar.month == today.month &&
          calendar.year == today.year;
      cells.add(_DayCell(day: day, isToday: isToday));
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
    return Row(
      children: [
        _summaryCard('Present',   calendar.present.toString(),  _green,  _greenLight, Icons.check_circle_rounded),
        const SizedBox(width: 10),
        _summaryCard('Half Day',  calendar.halfDay.toString(),  _amber,  _amberLight, Icons.timelapse_rounded),
        const SizedBox(width: 10),
        _summaryCard('On Leave',  calendar.onLeave.toString(),  _blue,   _blueLight,  Icons.event_busy_rounded),
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
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.w700)),
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
  const _DayCell({required this.day, required this.isToday});

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
      default:
        dotColor = null;
        bgColor  = null;
    }

    // Future dates: lighter text
    final now = DateTime.now();
    final dayDate = DateTime.tryParse(day.date);
    if (dayDate != null && dayDate.isAfter(now)) {
      textColor = const Color(0xFFD1D5DB);
    }

    return Container(
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
          // Status dot at bottom
          if (dotColor != null && !isToday)
            Positioned(
              bottom: 4,
              child: Container(
                width: 4, height: 4,
                decoration: BoxDecoration(
                  color: dotColor, shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}