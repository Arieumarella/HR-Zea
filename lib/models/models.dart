double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String? _toStr(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

class UserBrief {
  final int id;
  final String? username;
  final String? nama;
  final String? jabatan;
  final String? role;

  UserBrief(Map<String, dynamic> json)
      : id = (json['id'] as num?)?.toInt() ?? 0,
        username = _toStr(json['username']),
        nama = _toStr(json['nama']),
        jabatan = _toStr(json['jabatan']),
        role = _toStr(json['role']);
}

class MyShift {
  final int? id;
  final String? name;
  final String? workStartTime;
  final String? workEndTime;
  final int? gracePeriodMinutes;

  MyShift(Map<String, dynamic> json)
      : id = (json['id'] as num?)?.toInt(),
        name = _toStr(json['name']),
        workStartTime = _toStr(json['work_start_time']),
        workEndTime = _toStr(json['work_end_time']),
        gracePeriodMinutes = (json['grace_period_minutes'] as num?)?.toInt();
}

class HrStore {
  final int id;
  final String? namaToko;
  final double? latitude;
  final double? longitude;
  final int radiusMeters;
  final String workStartTime;
  final String workEndTime;
  final int gracePeriodMinutes;
  final String workDays;
  final bool locationConfigured;
  final MyShift? shift;

  HrStore(Map<String, dynamic> json)
      : id = (json['id'] as num?)?.toInt() ?? 0,
        namaToko = _toStr(json['nama_toko']),
        latitude = json['latitude'] == null ? null : _toDouble(json['latitude']),
        longitude = json['longitude'] == null ? null : _toDouble(json['longitude']),
        radiusMeters = (json['radius_meters'] as num?)?.toInt() ?? 50,
        workStartTime = _toStr(json['work_start_time']) ?? '08:00',
        workEndTime = _toStr(json['work_end_time']) ?? '17:00',
        gracePeriodMinutes = (json['grace_period_minutes'] as num?)?.toInt() ?? 15,
        workDays = _toStr(json['work_days']) ?? '1,2,3,4,5,6',
        locationConfigured = json['location_configured'] == true,
        shift = json['shift'] == null ? null : MyShift(json['shift'] as Map<String, dynamic>);
}

class EmployeeProfile {
  final int id;
  final int userId;
  final int storeId;
  final String? employeeCode;
  final String? position;
  final double baseSalary;
  final int annualLeaveQuota;
  final int annualLeaveEntitlement;
  final String? joinDate;
  final String? resignDate;
  final bool isActive;
  final UserBrief? user;

  EmployeeProfile(Map<String, dynamic> json)
      : id = (json['id'] as num?)?.toInt() ?? 0,
        userId = (json['user_id'] as num?)?.toInt() ?? 0,
        storeId = (json['store_id'] as num?)?.toInt() ?? 0,
        employeeCode = _toStr(json['employee_code']),
        position = _toStr(json['position']),
        baseSalary = _toDouble(json['base_salary']),
        annualLeaveQuota = (json['annual_leave_quota'] as num?)?.toInt() ?? 0,
        annualLeaveEntitlement = (json['annual_leave_entitlement'] as num?)?.toInt() ?? 0,
        joinDate = _toStr(json['join_date']),
        resignDate = _toStr(json['resign_date']),
        isActive = json['is_active'] == true,
        user = json['user'] == null ? null : UserBrief(json['user'] as Map<String, dynamic>);
}

class Attendance {
  final int id;
  final String attendanceDate;
  final String? checkInTime;
  final String? checkOutTime;
  final String? checkInPhoto;
  final String? checkOutPhoto;
  final double? checkInDistanceM;
  final String status;
  final int lateMinutes;
  final String? notes;

  Attendance(Map<String, dynamic> json)
      : id = (json['id'] as num?)?.toInt() ?? 0,
        attendanceDate = _toStr(json['attendance_date']) ?? '',
        checkInTime = _toStr(json['check_in_time']),
        checkOutTime = _toStr(json['check_out_time']),
        checkInPhoto = _toStr(json['check_in_photo']),
        checkOutPhoto = _toStr(json['check_out_photo']),
        checkInDistanceM = json['check_in_distance_m'] == null
            ? null
            : _toDouble(json['check_in_distance_m']),
        status = _toStr(json['status']) ?? 'ALPHA',
        lateMinutes = (json['late_minutes'] as num?)?.toInt() ?? 0,
        notes = _toStr(json['notes']);
}

class MyToday {
  final String serverTime;
  final String today;
  final Attendance? attendance;
  final EmployeeProfile profile;
  final HrStore hrStore;

  MyToday(Map<String, dynamic> json)
      : serverTime = _toStr(json['server_time']) ?? '',
        today = _toStr(json['today']) ?? '',
        attendance = json['attendance'] == null
            ? null
            : Attendance(json['attendance'] as Map<String, dynamic>),
        profile = EmployeeProfile(json['profile'] as Map<String, dynamic>),
        hrStore = HrStore(json['hr_store'] as Map<String, dynamic>);
}

class LeaveRequest {
  final int id;
  final String type;
  final String startDate;
  final String endDate;
  final String reason;
  final String? attachmentUrl;
  final String status;
  final String? adminNotes;
  final String? createdAt;

  LeaveRequest(Map<String, dynamic> json)
      : id = (json['id'] as num?)?.toInt() ?? 0,
        type = _toStr(json['type']) ?? '',
        startDate = _toStr(json['start_date']) ?? '',
        endDate = _toStr(json['end_date']) ?? '',
        reason = _toStr(json['reason']) ?? '',
        attachmentUrl = _toStr(json['attachment_url']),
        status = _toStr(json['status']) ?? 'PENDING',
        adminNotes = _toStr(json['admin_notes']),
        createdAt = _toStr(json['created_at']);
}

class OvertimeRequest {
  final int id;
  final String overtimeDate;
  final String startTime;
  final String endTime;
  final double durationHours;
  final String reason;
  final String status;
  final String? adminNotes;
  final String? createdAt;

  OvertimeRequest(Map<String, dynamic> json)
      : id = (json['id'] as num?)?.toInt() ?? 0,
        overtimeDate = _toStr(json['overtime_date']) ?? '',
        startTime = _toStr(json['start_time']) ?? '',
        endTime = _toStr(json['end_time']) ?? '',
        durationHours = _toDouble(json['duration_hours']),
        reason = _toStr(json['reason']) ?? '',
        status = _toStr(json['status']) ?? 'PENDING',
        adminNotes = _toStr(json['admin_notes']),
        createdAt = _toStr(json['created_at']);
}

class CorrectionRequest {
  final int id;
  final String attendanceDate;
  final String correctionType;
  final String? requestedCheckInTime;
  final String? requestedCheckOutTime;
  final String reason;
  final String? attachmentUrl;
  final String status;
  final String? adminNotes;
  final String? createdAt;

  CorrectionRequest(Map<String, dynamic> json)
      : id = (json['id'] as num?)?.toInt() ?? 0,
        attendanceDate = _toStr(json['attendance_date']) ?? '',
        correctionType = _toStr(json['correction_type']) ?? '',
        requestedCheckInTime = _toStr(json['requested_check_in_time']),
        requestedCheckOutTime = _toStr(json['requested_check_out_time']),
        reason = _toStr(json['reason']) ?? '',
        attachmentUrl = _toStr(json['attachment_url']),
        status = _toStr(json['status']) ?? 'PENDING',
        adminNotes = _toStr(json['admin_notes']),
        createdAt = _toStr(json['created_at']);
}

class EmployeeLoan {
  final int id;
  final double totalAmount;
  final double monthlyInstallment;
  final double remainingBalance;
  final String loanDate;
  final String reason;
  final String status;
  final String? adminNotes;
  final String? createdAt;

  EmployeeLoan(Map<String, dynamic> json)
      : id = (json['id'] as num?)?.toInt() ?? 0,
        totalAmount = _toDouble(json['total_amount']),
        monthlyInstallment = _toDouble(json['monthly_installment']),
        remainingBalance = _toDouble(json['remaining_balance']),
        loanDate = _toStr(json['loan_date']) ?? '',
        reason = _toStr(json['reason']) ?? '',
        status = _toStr(json['status']) ?? 'PENDING',
        adminNotes = _toStr(json['admin_notes']),
        createdAt = _toStr(json['created_at']);
}

class Payslip {
  final int id;
  final String periodStart;
  final String periodEnd;
  final String? employeeName;
  final String? position;
  final String? storeName;
  final String? bankName;
  final String? bankAccount;
  final double baseSalary;
  final int totalWorkingDays;
  final int totalPresentDays;
  final int totalLateCount;
  final int totalAbsentDays;
  final int totalUnpaidLeaveDays;
  final int totalMissingCheckoutCount;
  final double totalOvertimeHours;
  final double mealAllowanceAmount;
  final double transportAllowanceAmount;
  final double overtimePay;
  final double lateDeductionAmount;
  final double absenceDeductionAmount;
  final double unpaidLeaveDeductionAmount;
  final double missingCheckoutDeductionAmount;
  final double loanDeductionAmount;
  final double otherDeductionAmount;
  final double bonusAmount;
  final double grossSalary;
  final double totalDeduction;
  final double netSalary;
  final String? payrollPeriodName;

  Payslip(Map<String, dynamic> json)
      : id = (json['id'] as num?)?.toInt() ?? 0,
        periodStart = _toStr(json['period_start']) ?? '',
        periodEnd = _toStr(json['period_end']) ?? '',
        employeeName = _toStr(json['employee_name_snapshot']),
        position = _toStr(json['position_snapshot']),
        storeName = _toStr(json['store_name_snapshot']),
        bankName = _toStr(json['bank_name_snapshot']),
        bankAccount = _toStr(json['bank_account_snapshot']),
        baseSalary = _toDouble(json['base_salary']),
        totalWorkingDays = (json['total_working_days'] as num?)?.toInt() ?? 0,
        totalPresentDays = (json['total_present_days'] as num?)?.toInt() ?? 0,
        totalLateCount = (json['total_late_count'] as num?)?.toInt() ?? 0,
        totalAbsentDays = (json['total_absent_days'] as num?)?.toInt() ?? 0,
        totalUnpaidLeaveDays = (json['total_unpaid_leave_days'] as num?)?.toInt() ?? 0,
        totalMissingCheckoutCount =
            (json['total_missing_checkout_count'] as num?)?.toInt() ?? 0,
        totalOvertimeHours = _toDouble(json['total_overtime_hours']),
        mealAllowanceAmount = _toDouble(json['meal_allowance_amount']),
        transportAllowanceAmount = _toDouble(json['transport_allowance_amount']),
        overtimePay = _toDouble(json['overtime_pay']),
        lateDeductionAmount = _toDouble(json['late_deduction_amount']),
        absenceDeductionAmount = _toDouble(json['absence_deduction_amount']),
        unpaidLeaveDeductionAmount = _toDouble(json['unpaid_leave_deduction_amount']),
        missingCheckoutDeductionAmount = _toDouble(json['missing_checkout_deduction_amount']),
        loanDeductionAmount = _toDouble(json['loan_deduction_amount']),
        otherDeductionAmount = _toDouble(json['other_deduction_amount']),
        bonusAmount = _toDouble(json['bonus_amount']),
        grossSalary = _toDouble(json['gross_salary']),
        totalDeduction = _toDouble(json['total_deduction']),
        netSalary = _toDouble(json['net_salary']),
        payrollPeriodName = json['payroll'] is Map<String, dynamic>
            ? _toStr((json['payroll'] as Map<String, dynamic>)['period_name'])
            : null;
}

class PaginatedResult<T> {
  final List<T> data;
  final int page;
  final int total;
  final int totalPages;

  PaginatedResult({
    required this.data,
    required this.page,
    required this.total,
    required this.totalPages,
  });
}

List<T> _parseList<T>(dynamic value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) return [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(parser)
      .toList();
}

PaginatedResult<Attendance> parseAttendancePage(Map<String, dynamic> json) {
  return PaginatedResult(
    data: _parseList(json['data'], Attendance.new),
    page: (json['page'] as num?)?.toInt() ?? 1,
    total: (json['total'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
  );
}

PaginatedResult<LeaveRequest> parseLeavePage(Map<String, dynamic> json) {
  return PaginatedResult(
    data: _parseList(json['data'], LeaveRequest.new),
    page: (json['page'] as num?)?.toInt() ?? 1,
    total: (json['total'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
  );
}

PaginatedResult<OvertimeRequest> parseOvertimePage(Map<String, dynamic> json) {
  return PaginatedResult(
    data: _parseList(json['data'], OvertimeRequest.new),
    page: (json['page'] as num?)?.toInt() ?? 1,
    total: (json['total'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
  );
}

PaginatedResult<CorrectionRequest> parseCorrectionPage(Map<String, dynamic> json) {
  return PaginatedResult(
    data: _parseList(json['data'], CorrectionRequest.new),
    page: (json['page'] as num?)?.toInt() ?? 1,
    total: (json['total'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
  );
}

PaginatedResult<EmployeeLoan> parseLoanPage(Map<String, dynamic> json) {
  return PaginatedResult(
    data: _parseList(json['data'], EmployeeLoan.new),
    page: (json['page'] as num?)?.toInt() ?? 1,
    total: (json['total'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
  );
}

PaginatedResult<Payslip> parsePayslipPage(Map<String, dynamic> json) {
  return PaginatedResult(
    data: _parseList(json['data'], Payslip.new),
    page: (json['page'] as num?)?.toInt() ?? 1,
    total: (json['total'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
  );
}
