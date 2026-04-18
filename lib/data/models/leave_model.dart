class LeaveType {
  final int id;
  final String leaveName;
  final String leaveCode;
  final bool isPaid;
  final bool requiresApproval;
  final double maxDaysPerYear;
  final bool carryForwardAllowed;
  final String? description;

  LeaveType({
    required this.id,
    required this.leaveName,
    required this.leaveCode,
    required this.isPaid,
    required this.requiresApproval,
    required this.maxDaysPerYear,
    required this.carryForwardAllowed,
    this.description,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) => LeaveType(
        id:                  json['id'],
        leaveName:           json['leave_name'],
        leaveCode:           json['leave_code'],
        isPaid:              json['is_paid'] ?? true,
        requiresApproval:    json['requires_approval'] ?? true,
        maxDaysPerYear:      double.parse(json['max_days_per_year'].toString()),
        carryForwardAllowed: json['carry_forward_allowed'] ?? false,
        description:         json['description'],
      );
}

class LeaveBalance {
  final int id;
  final int leaveTypeId;
  final String leaveName;
  final String leaveCode;
  final bool isPaid;
  final int year;
  final double totalDays;
  final double usedDays;
  final double pendingDays;
  final double carriedForwardDays;
  final double remainingDays;

  LeaveBalance({
    required this.id,
    required this.leaveTypeId,
    required this.leaveName,
    required this.leaveCode,
    required this.isPaid,
    required this.year,
    required this.totalDays,
    required this.usedDays,
    required this.pendingDays,
    required this.carriedForwardDays,
    required this.remainingDays,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
        id:                 json['id'],
        leaveTypeId:        json['leave_type_id'],
        leaveName:          json['leave_name'],
        leaveCode:          json['leave_code'],
        isPaid:             json['is_paid'] ?? true,
        year:               json['year'],
        totalDays:          double.parse(json['total_days'].toString()),
        usedDays:           double.parse(json['used_days'].toString()),
        pendingDays:        double.parse(json['pending_days'].toString()),
        carriedForwardDays: double.parse(json['carried_forward_days'].toString()),
        remainingDays:      double.parse(json['remaining_days'].toString()),
      );
}

class LeaveRequest {
  final int id;
  final int leaveTypeId;
  final String? leaveName;
  final String? leaveCode;
  final bool? isPaid;
  final String startDate;
  final String endDate;
  final double totalDays;
  final bool isHalfDay;
  final String reason;
  final String status;
  final double lopDays;
  final String? appliedAt;
  final String? reviewedAt;
  final String? reviewComment;

  LeaveRequest({
    required this.id,
    required this.leaveTypeId,
    this.leaveName,
    this.leaveCode,
    this.isPaid,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.isHalfDay,
    required this.reason,
    required this.status,
    required this.lopDays,
    this.appliedAt,
    this.reviewedAt,
    this.reviewComment,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
        id:            json['id'],
        leaveTypeId:   json['leave_type_id'],
        leaveName:     json['leave_name'],
        leaveCode:     json['leave_code'],
        isPaid:        json['is_paid'],
        startDate:     json['start_date'],
        endDate:       json['end_date'],
        totalDays:     double.parse(json['total_days'].toString()),
        isHalfDay:     json['is_half_day'] ?? false,
        reason:        json['reason'],
        status:        json['status'],
        lopDays:       double.parse((json['lop_days'] ?? 0).toString()),
        appliedAt:     json['applied_at'],
        reviewedAt:    json['reviewed_at'],
        reviewComment: json['review_comment'],
      );

  bool get isPending   => status == 'pending';
  bool get isApproved  => status == 'approved';
  bool get isRejected  => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get hasLop      => lopDays > 0;
}