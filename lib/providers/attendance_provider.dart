import 'package:flutter/foundation.dart';
import '../data/models/attendance_model.dart';
import '../data/repositories/attendance_repository.dart';

enum AttendanceActionStatus { idle, loading, success, error }

class AttendanceProvider extends ChangeNotifier {
  TodayStatus _today       = TodayStatus.empty();
  GeofenceInfo? _lastGeo;
  MonthlyCalendar? _calendar;
  bool           _calendarLoading = false;
  List<AttendanceLog> _history = [];
  int _historyTotal            = 0;

  AttendanceActionStatus _status = AttendanceActionStatus.idle;
  String? _errorMessage;
  String? _successMessage;

  // ── getters ────────────────────────────────────────────────────────────────
  TodayStatus         get today          => _today;
  GeofenceInfo?       get lastGeo        => _lastGeo;
  MonthlyCalendar? get calendar        => _calendar;
  bool             get calendarLoading => _calendarLoading;
  List<AttendanceLog> get history        => _history;
  int                 get historyTotal   => _historyTotal;
  AttendanceActionStatus get status      => _status;
  String?             get errorMessage   => _errorMessage;
  String?             get successMessage => _successMessage;
  bool                get isLoading      => _status == AttendanceActionStatus.loading;

  // ── load today on home screen open ────────────────────────────────────────
  Future<void> loadToday() async {
    _status = AttendanceActionStatus.loading;
    notifyListeners();
    try {
      _today  = await AttendanceRepository.getTodayStatus();
      _status = AttendanceActionStatus.success;
    } catch (e) {
      _errorMessage = _clean(e);
      _status       = AttendanceActionStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadCalendar({required int month, required int year}) async {
    _calendarLoading = true;
    notifyListeners();
    try {
      _calendar = await AttendanceRepository.getMonthlyCalendar(
          month: month, year: year);
    } catch (_) {}
    _calendarLoading = false;
    notifyListeners();
  }

  // ── clock in ──────────────────────────────────────────────────────────────
  Future<bool> clockIn({
    required double latitude,
    required double longitude,
  }) async {
    _status       = AttendanceActionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result   = await AttendanceRepository.clockIn(
        latitude: latitude,
        longitude: longitude,
      );
      _lastGeo        = result['geofence'] as GeofenceInfo;
      _today          = TodayStatus(
        hasClockedIn:  true,
        hasClockedOut: false,
        log:           result['log'] as AttendanceLog,
      );
      _successMessage = result['message'] as String?;
      _status         = AttendanceActionStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _clean(e);
      _status       = AttendanceActionStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── clock out ─────────────────────────────────────────────────────────────
  Future<bool> clockOut({
    required double latitude,
    required double longitude,
  }) async {
    _status       = AttendanceActionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final log = await AttendanceRepository.clockOut(
        latitude: latitude,
        longitude: longitude,
      );
      _today  = TodayStatus(
        hasClockedIn:  true,
        hasClockedOut: true,
        log:           log,
      );
      _successMessage = 'Clocked out · ${log.durationFormatted} logged';
      _status         = AttendanceActionStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _clean(e);
      _status       = AttendanceActionStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── history ───────────────────────────────────────────────────────────────
  Future<void> loadHistory() async {
    try {
      final result   = await AttendanceRepository.getHistory();
      _history       = result['logs'] as List<AttendanceLog>;
      _historyTotal  = result['total'] as int;
      notifyListeners();
    } catch (_) {}
  }

  void clearMessages() {
    _errorMessage   = null;
    _successMessage = null;
    if (_status == AttendanceActionStatus.error) {
      _status = AttendanceActionStatus.idle;
    }
    notifyListeners();
  }

  String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}