import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/models.dart';

class HrService {
  HrService._();

  static final HrService instance = HrService._();

  ApiClient get _api => ApiClient.instance;

  Future<Map<String, dynamic>> login(
    String username,
    String password, {
    String? deviceId,
  }) {
    return _api.post(
      '/auth/login',
      body: {
        'username': username,
        'password': password,
        if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
      },
      isAuthCall: true,
    );
  }

  Future<MyToday> getMyToday() async {
    final res = await _api.get('/api/hr/attendance/me');
    return MyToday(res['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> clockInOut(FormData formData) {
    return _api.postForm('/api/hr/attendance/clock', formData);
  }

  Future<PaginatedResult<Attendance>> getHistory(int page) async {
    final res = await _api.get('/api/hr/attendance/history', query: {'page': page, 'take': 15});
    return parseAttendancePage(res);
  }

  Future<PaginatedResult<LeaveRequest>> getLeaveRequests(int page) async {
    final res = await _api.get('/api/hr/leave-requests', query: {'page': page, 'take': 15});
    return parseLeavePage(res);
  }

  Future<Map<String, dynamic>> createLeaveRequest(FormData formData) {
    return _api.postForm('/api/hr/leave-requests', formData);
  }

  Future<PaginatedResult<OvertimeRequest>> getOvertimeRequests(int page) async {
    final res = await _api.get('/api/hr/overtime-requests', query: {'page': page, 'take': 15});
    return parseOvertimePage(res);
  }

  Future<Map<String, dynamic>> createOvertimeRequest(Map<String, dynamic> payload) {
    return _api.post('/api/hr/overtime-requests', body: payload);
  }

  Future<PaginatedResult<CorrectionRequest>> getCorrections(int page) async {
    final res = await _api.get('/api/hr/attendance-corrections', query: {'page': page, 'take': 15});
    return parseCorrectionPage(res);
  }

  Future<Map<String, dynamic>> createCorrectionRequest(FormData formData) {
    return _api.postForm('/api/hr/attendance-corrections', formData);
  }

  Future<PaginatedResult<EmployeeLoan>> getLoans(int page) async {
    final res = await _api.get('/api/hr/loans', query: {'page': page, 'take': 15});
    return parseLoanPage(res);
  }

  Future<Map<String, dynamic>> createLoanRequest(Map<String, dynamic> payload) {
    return _api.post('/api/hr/loans', body: payload);
  }

  Future<PaginatedResult<Payslip>> getPayslips(int page) async {
    final res = await _api.get('/api/hr/payslips/me', query: {'page': page, 'take': 15});
    return parsePayslipPage(res);
  }
}
