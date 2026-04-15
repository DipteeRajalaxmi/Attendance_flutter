import '../services/api_service.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  static Future<Map<String, dynamic>> clockIn({
    required double latitude,
    required double longitude,
  }) async {
    final response = await ApiService.clockIn(
      latitude: latitude,
      longitude: longitude,
    );
    // returns { log: AttendanceLog, geofence: GeofenceInfo }
    final data = response['data'];
    return {
      'log':      AttendanceLog.fromJson(data['log']),
      'geofence': GeofenceInfo.fromJson(data['geofence']),
      'message':  response['message'],
    };
  }

  static Future<AttendanceLog> clockOut({
    required double latitude,
    required double longitude,
  }) async {
    final response = await ApiService.clockOut(
      latitude: latitude,
      longitude: longitude,
    );
    return AttendanceLog.fromJson(response['data']['log']);
  }

  static Future<TodayStatus> getTodayStatus() async {
    final response = await ApiService.getTodayAttendance();
    return TodayStatus.fromJson(response['data']);
  }

  static Future<MonthlyCalendar> getMonthlyCalendar({
    required int month,
    required int year,
  }) async {
    final response = await ApiService.getMonthlyCalendar(month: month, year: year);
    return MonthlyCalendar.fromJson(response['data']);
  }

  static Future<Map<String, dynamic>> getHistory({
    int limit = 30,
    int offset = 0,
  }) async {
    final response = await ApiService.getAttendanceHistory();
    final data = response['data'];
    final logs = (data['logs'] as List)
        .map((l) => AttendanceLog.fromJson(l))
        .toList();
    return {
      'logs':   logs,
      'total':  data['total'],
      'limit':  data['limit'],
      'offset': data['offset'],
    };
  }
}