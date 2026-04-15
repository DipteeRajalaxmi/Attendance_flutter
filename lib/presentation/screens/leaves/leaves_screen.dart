import 'package:flutter/material.dart';

const _blue       = Color(0xFF2563EB);
const _blueLight  = Color(0xFFEFF6FF);
const _green      = Color(0xFF16A34A);
const _greenLight = Color(0xFFF0FDF4);
const _amber      = Color(0xFFD97706);
const _amberLight = Color(0xFFFFFBEB);
const _red        = Color(0xFFDC2626);
const _redLight   = Color(0xFFFEF2F2);
const _textPri    = Color(0xFF111827);
const _textSec    = Color(0xFF6B7280);
const _textHint   = Color(0xFF9CA3AF);
const _border     = Color(0xFFE5E7EB);
const _bg         = Color(0xFFF8FAFF);
const _white      = Color(0xFFFFFFFF);

class LeavesScreen extends StatelessWidget {
  const LeavesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Leave',
                  style: TextStyle(color: _textPri, fontSize: 22, fontWeight: FontWeight.w700)),
              const Text('Your leave balances & requests',
                  style: TextStyle(color: _textSec, fontSize: 13)),
              const SizedBox(height: 20),

              // Leave balance cards
              const Text('AVAILABLE BALANCE',
                  style: TextStyle(color: _textHint, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 10),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: const [
                  _LeaveBalanceCard(label: 'Annual Leave',  code: 'AL',  total: 18, used: 3,  color: _blue,  bg: _blueLight),
                  _LeaveBalanceCard(label: 'Sick Leave',    code: 'SL',  total: 12, used: 0,  color: _green, bg: _greenLight),
                  _LeaveBalanceCard(label: 'Casual Leave',  code: 'CL',  total: 6,  used: 1,  color: _amber, bg: _amberLight),
                  _LeaveBalanceCard(label: 'Loss of Pay',   code: 'LOP', total: 0,  used: 0,  color: _red,   bg: _redLight),
                ],
              ),

              const SizedBox(height: 24),

              // Apply leave button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Leave requests coming soon'),
                        behavior: SnackBarBehavior.floating),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Apply for Leave',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: _white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recent requests placeholder
              const Text('RECENT REQUESTS',
                  style: TextStyle(color: _textHint, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_note_outlined, color: _textHint, size: 36),
                      SizedBox(height: 10),
                      Text('No leave requests yet',
                          style: TextStyle(color: _textSec, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Your leave history will appear here',
                          style: TextStyle(color: _textHint, fontSize: 12)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  final String label;
  final String code;
  final int total;
  final int used;
  final Color color;
  final Color bg;

  const _LeaveBalanceCard({
    required this.label,
    required this.code,
    required this.total,
    required this.used,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - used;
    final progress  = total > 0 ? used / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(code,
                    style: TextStyle(color: color, fontSize: 10,
                        fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
              const Spacer(),
              Text(label,
                  style: const TextStyle(color: _textHint, fontSize: 9),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
          const Spacer(),
          Text('$remaining',
              style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w700)),
          Text('of $total days left',
              style: const TextStyle(color: _textSec, fontSize: 10)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}