class AttendanceLog {
  final int id;
  final String workDate;
  final String workType; // 'wfo' | 'wfh'
  final String status;   // 'active' | 'completed' | 'auto_completed'
  final String? clockInTime;
  final String? clockOutTime;
  final int? durationMinutes;
  final bool isLate;
  final int lateByMinutes;
  final double? clockInLatitude;
  final double? clockInLongitude;
  final double? clockOutLatitude;
  final double? clockOutLongitude;
  final String? clockIn;
  final String? clockOut;

  AttendanceLog({
    required this.id,
    required this.workDate,
    required this.workType,
    required this.status,
    this.clockInTime,
    this.clockOutTime,
    this.durationMinutes,
    required this.isLate,
    required this.lateByMinutes,
    this.clockInLatitude,
    this.clockInLongitude,
    this.clockOutLatitude,
    this.clockOutLongitude,
    this.clockIn,
    this.clockOut,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      id:                 json['id'],
      workDate:           json['work_date'],
      workType:           json['work_type'],
      status:             json['status'],
      clockInTime:        json['clock_in_time'],
      clockOutTime:       json['clock_out_time'],
      durationMinutes:    json['duration_minutes'],
      isLate:             json['is_late'] ?? false,
      lateByMinutes:      json['late_by_minutes'] ?? 0,
      clockInLatitude:    (json['clock_in_latitude'] as num?)?.toDouble(),
      clockInLongitude:   (json['clock_in_longitude'] as num?)?.toDouble(),
      clockOutLatitude:   (json['clock_out_latitude'] as num?)?.toDouble(),
      clockOutLongitude:  (json['clock_out_longitude'] as num?)?.toDouble(),
      clockIn:  json['clock_in_time'],
      clockOut: json['clock_out_time'],
    );
  }

  bool get isActive    => status == 'active';
  bool get isCompleted => status == 'completed' || status == 'auto_completed';
  bool get isWfo       => workType == 'wfo';

  /// Duration formatted as "Xh Ym"
  String get durationFormatted {
    if (durationMinutes == null) return '--';
    final h = durationMinutes! ~/ 60;
    final m = durationMinutes! % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

class TodayStatus {
  final bool hasClockedIn;
  final bool hasClockedOut;
  final AttendanceLog? log;

  TodayStatus({
    required this.hasClockedIn,
    required this.hasClockedOut,
    this.log,
  });

  factory TodayStatus.fromJson(Map<String, dynamic> json) {
    return TodayStatus(
      hasClockedIn:  json['has_clocked_in']  ?? false,
      hasClockedOut: json['has_clocked_out'] ?? false,
      log: json['log'] != null ? AttendanceLog.fromJson(json['log']) : null,
    );
  }

  factory TodayStatus.empty() =>
      TodayStatus(hasClockedIn: false, hasClockedOut: false, log: null);
}

class GeofenceInfo {
  final String workType;
  final String? officeName;
  final double? distance;

  GeofenceInfo({
    required this.workType,
    this.officeName,
    this.distance,
  });

  factory GeofenceInfo.fromJson(Map<String, dynamic> json) {
    return GeofenceInfo(
      workType:   json['work_type'] ?? 'wfh',
      officeName: json['office_name'],
      distance:   (json['distance'] as num?)?.toDouble(),
    );
  }

  bool get isWfo => workType == 'wfo';
}

class CalendarDay {
  final String date;       // "2026-04-15"
  final int day;
  final String status;     // present | half_day | absent | on_leave | no_record
  final String? workType;
  final int? durationMinutes;
  final bool isLate;
  final String? clockIn;
  final String? clockOut;

  CalendarDay({
    required this.date,
    required this.day,
    required this.status,
    this.workType,
    this.durationMinutes,
    required this.isLate,
    this.clockIn,
  this.clockOut,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date:            json['date'],
      day:             json['day'],
      status:          json['status'],
      workType:        json['work_type'],
      durationMinutes: json['duration_minutes'],
      isLate:          json['is_late'] ?? false,
      clockIn: json['clock_in_time'],
      clockOut: json['clock_out_time'],
    );
  }
}

class MonthlyCalendar {
  final int year;
  final int month;
  final List<CalendarDay> days;
  final int present;
  final int halfDay;
  final int onLeave;
  final int absent;


  MonthlyCalendar({
    required this.year,
    required this.month,
    required this.days,
    required this.present,
    required this.halfDay,
    required this.onLeave,
    required this.absent,

  });

  factory MonthlyCalendar.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    return MonthlyCalendar(
      year:    json['year'],
      month:   json['month'],
      days:    (json['days'] as List).map((d) => CalendarDay.fromJson(d)).toList(),
      present: summary['present']  ?? 0,
      halfDay: summary['half_day'] ?? 0,
      onLeave: summary['on_leave'] ?? 0,
      absent:  summary['absent']   ?? 0,
    );
  }
}