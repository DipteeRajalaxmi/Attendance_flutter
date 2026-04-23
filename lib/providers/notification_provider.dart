import 'package:flutter/foundation.dart';

class AppNotification {
  final String message;
  final bool isApproved;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.message,
    required this.isApproved,
    required this.time,
    this.isRead = false,
  });
}

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  final Set<int> _notifiedIds = {};

  static const _maxNotifications = 5;
  static const _months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotificationIfNew(int requestId, String leaveName, String status, String startDate) {
    if (_notifiedIds.contains(requestId)) return;
    if (status != 'approved' && status != 'rejected') return;

    _notifiedIds.add(requestId);

    // Format: "Your 25 Apr Casual Leave has been approved"
    final date = _formatDate(startDate);
    final isApproved = status == 'approved';
    final message = 'Your $date $leaveName has been ${isApproved ? 'approved' : 'rejected'}';

    _notifications.insert(0, AppNotification(
      message:    message,
      isApproved: isApproved,
      time:       DateTime.now(),
    ));

    // Keep only latest 20
    if (_notifications.length > _maxNotifications) {
      _notifications.removeRange(_maxNotifications, _notifications.length);
    }

    notifyListeners();
  }

  String _formatDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '';
    return '${dt.day} ${_months[dt.month]}';
  }

  void markAllRead() {
    for (final n in _notifications) n.isRead = true;
    notifyListeners();
  }
}