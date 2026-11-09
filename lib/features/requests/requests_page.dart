import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../services/hr_service.dart';

const _leaveTypes = [
  ('SICK', 'Sakit'),
  ('ANNUAL_LEAVE', 'Cuti Tahunan'),
  ('UNPAID_LEAVE', 'Cuti Tanpa Gaji'),
  ('FIELD_DUTY', 'Dinas Luar'),
];

const _correctionTypes = [
  ('LATE_DISPENSATION', 'Dispensasi Terlambat'),
  ('MISSING_CHECKOUT', 'Lupa Absen Pulang'),
];

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengajuan'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.beach_access_outlined, size: 20),
                iconMargin: EdgeInsets.only(bottom: 2),
                text: 'Cuti',
              ),
              Tab(
                icon: Icon(Icons.schedule_outlined, size: 20),
                iconMargin: EdgeInsets.only(bottom: 2),
                text: 'Lembur',
              ),
              Tab(
                icon: Icon(Icons.edit_note_outlined, size: 20),
                iconMargin: EdgeInsets.only(bottom: 2),
                text: 'Koreksi',
              ),
              Tab(
                icon: Icon(Icons.account_balance_wallet_outlined, size: 20),
                iconMargin: EdgeInsets.only(bottom: 2),
                text: 'Kasbon',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LeaveTab(),
            _OvertimeTab(),
            _CorrectionTab(),
            _LoanTab(),
          ],
        ),
      ),
    );
  }
}

Future<XFile?> _pickImage(BuildContext context) async {
  try {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil dengan Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    return await ImagePicker().pickImage(source: source, imageQuality: 80);
  } catch (_) {
    return null;
  }
}

Widget _chip(String status) {
  final info = requestStatus(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Color(info.color).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      info.label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(info.color),
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ZeaColors.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

Widget _requestCard({
  required String title,
  required String subtitle,
  required String status,
  required String footer,
  String? adminNotes,
}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              _chip(status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            footer,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          if (adminNotes != null && adminNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Catatan admin: $adminNotes',
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

abstract class _BaseTab extends StatefulWidget {
  const _BaseTab();
}

abstract class _BaseTabState<T> extends State<_BaseTab> {
  final List<T> _rows = [];
  int _page = 1;
  int _totalPages = 1;
  bool _loading = false;
  bool _initialLoading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<PaginatedResult<T>> fetch(int page);

  Future<void> _reload() async {
    _page = 1;
    _rows.clear();
    await _fetchPage();
  }

  Future<void> _fetchPage() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _initialLoading = _rows.isEmpty;
    });
    try {
      final result = await fetch(_page);
      if (!mounted) return;
      setState(() {
        _rows.addAll(result.data);
        _totalPages = result.totalPages == 0 ? 1 : result.totalPages;
      });
    } catch (error) {
      if (mounted) _toast(error.toString(), error: true);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_page >= _totalPages || _loading) return;
    _page += 1;
    await _fetchPage();
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? ZeaColors.danger : ZeaColors.success,
      ));
  }

  Future<void> submit(Future<Map<String, dynamic>> Function() action) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final res = await action();
      _toast((res['message'] as String?) ?? 'Pengajuan berhasil dikirim.');
      if (mounted) {
        FocusScope.of(context).unfocus();
        _reload();
      }
    } catch (error) {
      _toast(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<T> get rows => _rows;
  bool get submitting => _submitting;

  Widget buildTab(Widget formCard, Widget Function(T item) itemBuilder) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          formCard,
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Riwayat Pengajuan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_initialLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Belum ada pengajuan.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            )
          else ...[
            ..._rows.map(itemBuilder),
            if (_page < _totalPages)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: TextButton(
                    onPressed: _loadMore,
                    child: const Text('Muat Lebih Banyak'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LeaveTab extends _BaseTab {
  const _LeaveTab();

  @override
  State<_BaseTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends _BaseTabState<LeaveRequest> {
  String _type = 'ANNUAL_LEAVE';
  DateTime? _start;
  DateTime? _end;
  final _reasonController = TextEditingController();
  XFile? _attachment;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Future<PaginatedResult<LeaveRequest>> fetch(int page) {
    return HrService.instance.getLeaveRequests(page);
  }

  Future<void> _submit() async {
    if (_start == null || _end == null) {
      _toast('Pilih tanggal mulai dan selesai.', error: true);
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      _toast('Alasan wajib diisi.', error: true);
      return;
    }
    await submit(() async {
      final form = FormData.fromMap({
        'type': _type,
        'start_date': idShortDate(_start!.toIso8601String()),
        'end_date': idShortDate(_end!.toIso8601String()),
        'reason': _reasonController.text.trim(),
        if (_attachment != null)
          'attachment': await MultipartFile.fromFile(
            _attachment!.path,
            filename: 'lampiran.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
      });
      return HrService.instance.createLeaveRequest(form);
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildTab(
      _SectionCard(
        title: 'Pengajuan Cuti / Izin',
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Jenis'),
            items: _leaveTypes
                .map((type) => DropdownMenuItem(value: type.$1, child: Text(type.$2)))
                .toList(),
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Tanggal Mulai',
                  value: _start,
                  onChanged: (value) => setState(() => _start = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateField(
                  label: 'Tanggal Selesai',
                  value: _end,
                  onChanged: (value) => setState(() => _end = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Alasan'),
          ),
          const SizedBox(height: 12),
          _AttachmentField(
            label: _attachment == null ? 'Lampiran (opsional)' : 'Lampiran dipilih',
            onPick: () async {
              final file = await _pickImage(context);
              if (file != null) setState(() => _attachment = file);
            },
            onClear: _attachment == null
                ? null
                : () => setState(() => _attachment = null),
          ),
          if (_type == 'SICK')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '* Jenis Sakit wajib melampirkan surat keterangan sakit.',
                style: TextStyle(fontSize: 11, color: ZeaColors.danger),
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: submitting ? null : _submit,
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Kirim Pengajuan'),
            ),
          ),
        ],
      ),
      (item) => _requestCard(
        title: _leaveTypes
            .firstWhere((t) => t.$1 == item.type, orElse: () => (item.type, item.type))
            .$2,
        subtitle: '${idDate(item.startDate)} s/d ${idDate(item.endDate)}',
        status: item.status,
        footer: item.reason,
        adminNotes: item.adminNotes,
      ),
    );
  }
}

class _OvertimeTab extends _BaseTab {
  const _OvertimeTab();

  @override
  State<_BaseTab> createState() => _OvertimeTabState();
}

class _OvertimeTabState extends _BaseTabState<OvertimeRequest> {
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Future<PaginatedResult<OvertimeRequest>> fetch(int page) {
    return HrService.instance.getOvertimeRequests(page);
  }

  Future<void> _submit() async {
    if (_date == null || _start == null || _end == null) {
      _toast('Lengkapi tanggal dan jam lembur.', error: true);
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      _toast('Alasan wajib diisi.', error: true);
      return;
    }
    final startText =
        '${_start!.hour.toString().padLeft(2, '0')}:${_start!.minute.toString().padLeft(2, '0')}';
    final endText =
        '${_end!.hour.toString().padLeft(2, '0')}:${_end!.minute.toString().padLeft(2, '0')}';
    await submit(() {
      return HrService.instance.createOvertimeRequest({
        'overtime_date': idShortDate(_date!.toIso8601String()),
        'start_time': startText,
        'end_time': endText,
        'reason': _reasonController.text.trim(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildTab(
      _SectionCard(
        title: 'Pengajuan Lembur',
        children: [
          _DateField(
            label: 'Tanggal Lembur',
            value: _date,
            onChanged: (value) => setState(() => _date = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: 'Jam Mulai',
                  value: _start,
                  onChanged: (value) => setState(() => _start = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeField(
                  label: 'Jam Selesai',
                  value: _end,
                  onChanged: (value) => setState(() => _end = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Alasan Lembur'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: submitting ? null : _submit,
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Kirim Pengajuan'),
            ),
          ),
        ],
      ),
      (item) => _requestCard(
        title: 'Lembur ${item.durationHours} jam',
        subtitle: '${idDate(item.overtimeDate)} Â· ${item.startTime}-${item.endTime}',
        status: item.status,
        footer: item.reason,
        adminNotes: item.adminNotes,
      ),
    );
  }
}

class _CorrectionTab extends _BaseTab {
  const _CorrectionTab();

  @override
  State<_BaseTab> createState() => _CorrectionTabState();
}

class _CorrectionTabState extends _BaseTabState<CorrectionRequest> {
  String _type = 'LATE_DISPENSATION';
  DateTime? _date;
  TimeOfDay? _time;
  final _reasonController = TextEditingController();
  XFile? _attachment;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Future<PaginatedResult<CorrectionRequest>> fetch(int page) {
    return HrService.instance.getCorrections(page);
  }

  Future<void> _submit() async {
    if (_date == null) {
      _toast('Pilih tanggal absensi.', error: true);
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      _toast('Alasan wajib diisi.', error: true);
      return;
    }
    String? timeText;
    if (_time != null) {
      timeText =
          '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';
    }
    await submit(() async {
      final form = FormData.fromMap({
        'attendance_date': idShortDate(_date!.toIso8601String()),
        'correction_type': _type,
        'reason': _reasonController.text.trim(),
        if (_type == 'LATE_DISPENSATION' && timeText != null)
          'requested_check_in_time': timeText,
        if (_type == 'MISSING_CHECKOUT' && timeText != null)
          'requested_check_out_time': timeText,
        if (_attachment != null)
          'attachment': await MultipartFile.fromFile(
            _attachment!.path,
            filename: 'lampiran.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
      });
      return HrService.instance.createCorrectionRequest(form);
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildTab(
      _SectionCard(
        title: 'Koreksi Absensi',
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Jenis Koreksi'),
            items: _correctionTypes
                .map((type) => DropdownMenuItem(value: type.$1, child: Text(type.$2)))
                .toList(),
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 12),
          _DateField(
            label: 'Tanggal Absensi',
            value: _date,
            onChanged: (value) => setState(() => _date = value),
          ),
          const SizedBox(height: 12),
          _TimeField(
            label: _type == 'LATE_DISPENSATION'
                ? 'Jam Masuk yang Diajukan'
                : 'Jam Pulang yang Diajukan',
            value: _time,
            onChanged: (value) => setState(() => _time = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Alasan'),
          ),
          const SizedBox(height: 12),
          _AttachmentField(
            label: _attachment == null ? 'Lampiran (opsional)' : 'Lampiran dipilih',
            onPick: () async {
              final file = await _pickImage(context);
              if (file != null) setState(() => _attachment = file);
            },
            onClear: _attachment == null
                ? null
                : () => setState(() => _attachment = null),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: submitting ? null : _submit,
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Kirim Pengajuan'),
            ),
          ),
        ],
      ),
      (item) => _requestCard(
        title: _correctionTypes
            .firstWhere(
              (t) => t.$1 == item.correctionType,
              orElse: () => (item.correctionType, item.correctionType),
            )
            .$2,
        subtitle: idDate(item.attendanceDate),
        status: item.status,
        footer: item.reason,
        adminNotes: item.adminNotes,
      ),
    );
  }
}

class _LoanTab extends _BaseTab {
  const _LoanTab();

  @override
  State<_BaseTab> createState() => _LoanTabState();
}

class _LoanTabState extends _BaseTabState<EmployeeLoan> {
  final _totalController = TextEditingController();
  final _installmentController = TextEditingController();
  DateTime? _date;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _totalController.dispose();
    _installmentController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Future<PaginatedResult<EmployeeLoan>> fetch(int page) {
    return HrService.instance.getLoans(page);
  }

  Future<void> _submit() async {
    final total = double.tryParse(_totalController.text);
    final installment = double.tryParse(_installmentController.text);
    if (total == null || total <= 0) {
      _toast('Jumlah kasbon harus lebih dari 0.', error: true);
      return;
    }
    if (installment == null || installment <= 0 || installment > total) {
      _toast('Cicilan harus > 0 dan tidak melebihi jumlah kasbon.', error: true);
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      _toast('Alasan wajib diisi.', error: true);
      return;
    }
    await submit(() {
      return HrService.instance.createLoanRequest({
        'total_amount': total,
        'monthly_installment': installment,
        'loan_date': idShortDate(
          (_date ?? DateTime.now()).toIso8601String(),
        ),
        'reason': _reasonController.text.trim(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildTab(
      _SectionCard(
        title: 'Pengajuan Kasbon',
        children: [
          TextField(
            controller: _totalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Jumlah Kasbon (Rp)',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _installmentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cicilan per Bulan (Rp)',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 12),
          _DateField(
            label: 'Tanggal Kasbon',
            value: _date,
            onChanged: (value) => setState(() => _date = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Alasan Kasbon'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: submitting ? null : _submit,
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Kirim Pengajuan'),
            ),
          ),
        ],
      ),
      (item) => _requestCard(
        title: rupiah(item.totalAmount),
        subtitle:
            'Cicilan ${rupiah(item.monthlyInstallment)}/bln Â· Sisa ${rupiah(item.remainingBalance)}',
        status: item.status,
        footer: '${idDate(item.loanDate)} Â· ${item.reason}',
        adminNotes: item.adminNotes,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime(2035),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value == null ? 'Pilih tanggal' : idDate(value!.toIso8601String()),
          style: TextStyle(
            fontSize: 14,
            color: value == null ? Colors.grey : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value == null
              ? 'Pilih jam'
              : '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 14,
            color: value == null ? Colors.grey : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _AttachmentField extends StatelessWidget {
  final String label;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _AttachmentField({
    required this.label,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.attach_file),
            label: Text(label, overflow: TextOverflow.ellipsis),
          ),
        ),
        if (onClear != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, color: ZeaColors.danger),
          ),
        ],
      ],
    );
  }
}

