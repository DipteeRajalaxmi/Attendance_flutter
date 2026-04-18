import 'package:flutter/foundation.dart';
import '../data/models/leave_model.dart';
import '../data/repositories/leave_repository.dart';

class LeaveProvider extends ChangeNotifier {
  List<LeaveBalance>  _balances  = [];
  List<LeaveType>     _types     = [];
  List<LeaveRequest>  _requests  = [];
  int                 _total     = 0;
  bool                _loading   = false;
  bool                _applying  = false;
  String?             _error;
  String?             _success;

  List<LeaveBalance>  get balances  => _balances;
  List<LeaveType>     get types     => _types;
  List<LeaveRequest>  get requests  => _requests;
  int                 get total     => _total;
  bool                get loading   => _loading;
  bool                get applying  => _applying;
  String?             get error     => _error;
  String?             get success   => _success;

  Future<void> loadAll() async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        LeaveRepository.getLeaveBalances(),
        LeaveRepository.getLeaveTypes(),
        LeaveRepository.getLeaveRequests(),
      ]);
      _balances = results[0] as List<LeaveBalance>;
      _types    = results[1] as List<LeaveType>;
      final reqResult = results[2] as Map<String, dynamic>;
      _requests = reqResult['requests'] as List<LeaveRequest>;
      _total    = reqResult['total'] as int;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> applyLeave({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    required bool isHalfDay,
  }) async {
    _applying = true;
    _error    = null;
    notifyListeners();
    try {
      final req = await LeaveRepository.applyLeave(
        leaveTypeId: leaveTypeId,
        startDate:   startDate,
        endDate:     endDate,
        reason:      reason,
        isHalfDay:   isHalfDay,
      );
      _requests.insert(0, req);
      _success = 'Leave request submitted successfully.';
      await loadAll(); // refresh balances
      _applying = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error    = e.toString().replaceFirst('Exception: ', '');
      _applying = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelLeave(int requestId) async {
    _error = null;
    notifyListeners();
    try {
      await LeaveRepository.cancelLeave(requestId);
      _success = 'Leave request cancelled.';
      await loadAll();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error   = null;
    _success = null;
    notifyListeners();
  }
}