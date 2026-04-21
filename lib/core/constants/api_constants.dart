class ApiConstants {
  // Base URL - UPDATE THIS TO YOUR BACKEND URL
  static const String baseUrl = 'http://localhost:10000'; // Change to your IP

  // Auth Endpoints
  static const String register = '/api/mobile/auth/register';
  static const String login = '/api/mobile/auth/login';
  static const String verifyToken = '/api/mobile/auth/verify-token';
  static const String me = '/api/mobile/auth/me';

  // Attendance Endpoints
  static const String clockIn = '/api/mobile/attendance/clock-in';
  static const String clockOut = '/api/mobile/attendance/clock-out';
  static const String todayAttendance = '/api/mobile/attendance/today';
  static const String attendanceHistory = '/api/mobile/attendance/history';
  static const String calendar           = '/api/mobile/attendance/calendar';
  static const String checkLocation     = '/api/mobile/attendance/check-location'; 
  // Leave Endpoints
  static const String leaveTypes    = '/api/mobile/leave/types';
  static const String leaveBalances = '/api/mobile/leave/balances';
  static const String leaveRequests = '/api/mobile/leave/requests';
  static const String leaveApply    = '/api/mobile/leave/apply';
  static const String leaveCancel   = '/api/mobile/leave/cancel';
  // Correction endpoints
  static const String correctionRequests = '/api/mobile/attendance/correction';
  static const String correctionCancel   = '/api/mobile/attendance/correction/cancel';


}