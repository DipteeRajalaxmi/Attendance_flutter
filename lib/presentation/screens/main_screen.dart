import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home/home_screen.dart';
import 'attendance/attendance_screen.dart';
import 'leaves/leaves_screen.dart';

const _blue    = Color(0xFF2563EB);
const _textSec = Color(0xFF6B7280);
const _border  = Color(0xFFE5E7EB);
const _white   = Color(0xFFFFFFFF);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    AttendanceScreen(),
    LeavesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Force light status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:            Colors.transparent,
      statusBarIconBrightness:   Brightness.dark,
      statusBarBrightness:       Brightness.light,
    ));

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _white,
          border: Border(top: BorderSide(color: _border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon:       Icons.home_rounded,
                  label:      'Home',
                  isSelected: _currentIndex == 0,
                  onTap:      () => _onTap(0),
                ),
                _NavItem(
                  icon:       Icons.calendar_month_rounded,
                  label:      'Attendance',
                  isSelected: _currentIndex == 1,
                  onTap:      () => _onTap(1),
                ),
                _NavItem(
                  icon:       Icons.event_note_rounded,
                  label:      'Leaves',
                  isSelected: _currentIndex == 2,
                  onTap:      () => _onTap(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? _blue.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? _blue : _textSec,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _blue : _textSec,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}