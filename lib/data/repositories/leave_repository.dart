import '../services/api_service.dart';
import '../models/leave_model.dart';
import '../../core/constants/api_constants.dart';

class LeaveRepository {
  static Future<List<LeaveType>> getLeaveTypes() async {
    final response = await ApiService.get(
      ApiConstants.leaveTypes,
      requiresAuth: true,
    );
    final data = response['data'] as List;
    return data.map((e) => LeaveType.fromJson(e)).toList();
  }

  static Future<List<LeaveBalance>> getLeaveBalances() async {
    final response = await ApiService.get(
      ApiConstants.leaveBalances,
      requiresAuth: true,
    );
    final data = response['data'] as List;
    return data.map((e) => LeaveBalance.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> getLeaveRequests({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await ApiService.get(
      '${ApiConstants.leaveRequests}?limit=$limit&offset=$offset',
      requiresAuth: true,
    );
    final data = response['data'];
    return {
      'requests': (data['requests'] as List)
          .map((e) => LeaveRequest.fromJson(e))
          .toList(),
      'total': data['total'],
    };
  }

  static Future<LeaveRequest> applyLeave({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    required bool isHalfDay,
  }) async {
    final response = await ApiService.post(
      ApiConstants.leaveApply,
      {
        'leave_type_id': leaveTypeId,
        'start_date':    startDate,
        'end_date':      endDate,
        'reason':        reason,
        'is_half_day':   isHalfDay,
      },
      requiresAuth: true,
    );
    return LeaveRequest.fromJson(response['data']);
  }

  static Future<LeaveRequest> cancelLeave(int requestId) async {
    final response = await ApiService.put(
      '${ApiConstants.leaveCancel}/$requestId',
      {},
      requiresAuth: true,
    );
    return LeaveRequest.fromJson(response['data']);
  }
}