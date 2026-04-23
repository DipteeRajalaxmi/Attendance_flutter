import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../auth/login_screen.dart';

const _navy      = Color(0xFF0D1B3E);
const _navyLight = Color(0xFF1E3060);
const _cyan      = Color(0xFF00B4D8);
const _cyanPale  = Color(0xFFE0F7FA);
const _cyanDeep  = Color(0xFF0096C7);
const _green     = Color(0xFF00C897);
const _greenPale = Color(0xFFE6FBF5);
const _red       = Color(0xFFFF4D6D);
const _redPale   = Color(0xFFFFF0F3);
const _amber     = Color(0xFFFFB703);
const _amberPale = Color(0xFFFFF8E1);
const _white     = Color(0xFFFFFFFF);
const _offWhite  = Color(0xFFF0F4FF);
const _textPri   = Color(0xFF0D1B3E);
const _textSec   = Color(0xFF4A5680);
const _textHint  = Color(0xFF8F9BBF);
const _border    = Color(0xFFDDE3F5);
const _shadow    = Color(0x1A0D1B3E);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final member   = auth.member;
    final calendar = context.watch<AttendanceProvider>().calendar;

    // initials
    final initials = (member?.name.isNotEmpty == true)
        ? member!.name.trim().split(' ')
            .take(2).map((w) => w[0].toUpperCase()).join()
        : 'U';

    // joined date
    String joinedLabel = '—';
    if (member?.registeredAt != null) {
      final dt = DateTime.tryParse(member!.registeredAt!);
      if (dt != null) {
        const months = ['Jan','Feb','Mar','Apr','May','Jun',
                        'Jul','Aug','Sep','Oct','Nov','Dec'];
        joinedLabel = '${months[dt.month - 1]} ${dt.year}';
      }
    }

    return Scaffold(
      backgroundColor: _offWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Navy hero ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(36)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                child: Column(children: [
                  // Avatar
                  Container(
                    width: 84, height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_cyan, _cyanDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                          color: _white.withOpacity(0.2), width: 3),
                      boxShadow: [
                        BoxShadow(color: _cyan.withOpacity(0.4),
                            blurRadius: 20, offset: const Offset(0, 8))
                      ],
                    ),
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(
                              color: _white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Name
                  Text(member?.name ?? 'Employee',
                      style: const TextStyle(
                          color: _white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),

                  // Dept + position pills
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      if (member?.department != null)
                        _pill(member!.department!, _cyan),
                      if (member?.position != null)
                        _pill(member!.position!,
                            _white.withOpacity(0.7)),
                    ],
                  ),
                ]),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Info section ───────────────────────────────────
                    _sectionLabel('PERSONAL INFO'),
                    const SizedBox(height: 12),
                    _infoCard([
                      _infoRow(Icons.person_rounded,     'Full Name',   member?.name ?? '—'),
                      _infoRow(Icons.email_rounded,      'Email',       member?.email ?? '—'),
                      _infoRow(Icons.business_rounded,   'Department',  member?.department ?? '—'),
                      _infoRow(Icons.work_rounded,       'Position',    member?.position ?? '—'),
                      _infoRow(Icons.calendar_today_rounded, 'Joined',  joinedLabel),
                      if (member?.employeeId != null)
                        _infoRow(Icons.badge_rounded,    'Employee ID', member!.employeeId!),
                    ]),

                    const SizedBox(height: 24),

                    // ── This month stats ───────────────────────────────
                    _sectionLabel('THIS MONTH'),
                    const SizedBox(height: 12),
                    if (calendar != null)
                      Column(children: [
                        Row(children: [
                          _statCard('Present',  '${calendar.present}',
                              _green, _greenPale,
                              Icons.check_circle_rounded),
                          const SizedBox(width: 10),
                          _statCard('Absent',   '${calendar.absent}',
                              _red, _redPale,
                              Icons.cancel_rounded),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          _statCard('Half Day', '${calendar.halfDay}',
                              _amber, _amberPale,
                              Icons.wb_sunny_rounded),
                          const SizedBox(width: 10),
                          _statCard('On Leave', '${calendar.onLeave}',
                              _cyan, _cyanPale,
                              Icons.event_busy_rounded),
                        ]),
                      ])
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border),
                        ),
                        child: const Center(
                          child: Text('Load Attendance tab to see stats',
                              style: TextStyle(
                                  color: _textHint, fontSize: 13)),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // ── Logout ─────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          );
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Logout',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _redPale,
                          foregroundColor: _red,
                          elevation: 0,
                          side: BorderSide(
                              color: _red.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(text,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _sectionLabel(String label) => Row(children: [
    Container(width: 3, height: 14,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_cyan, _cyanDeep],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(2),
      )),
    const SizedBox(width: 8),
    Text(label,
        style: const TextStyle(
            color: _textSec,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2)),
  ]);

  Widget _infoCard(List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: _white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(color: _shadow, blurRadius: 10,
            offset: const Offset(0, 3))
      ],
    ),
    child: Column(children: [
      for (int i = 0; i < rows.length; i++) ...[
        rows[i],
        if (i < rows.length - 1)
          Divider(height: 1, color: _border,
              indent: 56, endIndent: 16),
      ],
    ]),
  );

  Widget _infoRow(IconData icon, String label, String value) =>
    Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _cyanPale,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _cyan, size: 17),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: _textHint,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: _textPri,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        )),
      ]),
    );

  Widget _statCard(String label, String value,
      Color color, Color bg, IconData icon) =>
    Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.08),
                blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  color: _textHint, fontSize: 11),
              textAlign: TextAlign.center),
        ]),
      ),
    );
}