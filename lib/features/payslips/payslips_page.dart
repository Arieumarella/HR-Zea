import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../services/hr_service.dart';

class PayslipsPage extends StatefulWidget {
  const PayslipsPage({super.key});

  @override
  State<PayslipsPage> createState() => _PayslipsPageState();
}

class _PayslipsPageState extends State<PayslipsPage> {
  final List<Payslip> _rows = [];
  int _page = 1;
  int _totalPages = 1;
  bool _loading = false;
  bool _initialLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      _page = 1;
      _rows.clear();
    }
    setState(() {
      _loading = true;
      _initialLoading = _rows.isEmpty;
      _error = null;
    });
    try {
      final result = await HrService.instance.getPayslips(_page);
      if (!mounted) return;
      setState(() {
        _rows.addAll(result.data);
        _totalPages = result.totalPages == 0 ? 1 : result.totalPages;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
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
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slip Gaji')),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: _buildList(),
      ),
    );
  }

  Widget _buildList() {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _rows.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () => _load(reset: true),
              child: const Text('Coba Lagi'),
            ),
          ),
        ],
      );
    }
    if (_rows.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.receipt_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Belum ada slip gaji.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _rows.length + (_page < _totalPages ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= _rows.length) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: TextButton(
                onPressed: _loadMore,
                child: const Text('Muat Lebih Banyak'),
              ),
            ),
          );
        }
        return _PayslipTile(
          payslip: _rows[index],
          onTap: () => _showDetail(_rows[index]),
        );
      },
    );
  }

  void _showDetail(Payslip payslip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PayslipDetailSheet(payslip: payslip),
    );
  }
}

class _PayslipTile extends StatelessWidget {
  final Payslip payslip;
  final VoidCallback onTap;

  const _PayslipTile({required this.payslip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final period = payslip.payrollPeriodName ??
        '${idDate(payslip.periodStart)} - ${idDate(payslip.periodEnd)}';
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ZeaColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: ZeaColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ZeaColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hadir ${payslip.totalPresentDays} hari Â· Telat ${payslip.totalLateCount}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rupiah(payslip.netSalary),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ZeaColors.success,
                    ),
                  ),
                  Text(
                    'Gaji Bersih',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayslipDetailSheet extends StatelessWidget {
  final Payslip payslip;

  const _PayslipDetailSheet({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final period = payslip.payrollPeriodName ??
        '${idDate(payslip.periodStart)} - ${idDate(payslip.periodEnd)}';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Slip Gaji',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: ZeaColors.primaryDark,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _exportPdf(context),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('PDF'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  _infoRow('Periode', period),
                  _infoRow('Nama', payslip.employeeName ?? '-'),
                  _infoRow('Jabatan', payslip.position ?? '-'),
                  _infoRow('Cabang', payslip.storeName ?? '-'),
                  _infoRow(
                    'Bank',
                    '${payslip.bankName ?? '-'} ${payslip.bankAccount ?? ''}',
                  ),
                  const Divider(height: 28),
                  _moneyRow('Gaji Pokok', payslip.baseSalary),
                  _moneyRow(
                    'Uang Makan (${payslip.totalPresentDays} hari)',
                    payslip.mealAllowanceAmount,
                  ),
                  _moneyRow(
                    'Uang Transport (${payslip.totalPresentDays} hari)',
                    payslip.transportAllowanceAmount,
                  ),
                  _moneyRow(
                    'Lembur (${payslip.totalOvertimeHours.toStringAsFixed(1)} jam)',
                    payslip.overtimePay,
                  ),
                  if (payslip.bonusAmount > 0)
                    _moneyRow('Bonus', payslip.bonusAmount),
                  const Divider(height: 28),
                  const Text(
                    'Potongan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (payslip.lateDeductionAmount > 0)
                    _moneyRow('Denda Telat', -payslip.lateDeductionAmount, negative: true),
                  if (payslip.absenceDeductionAmount > 0)
                    _moneyRow('Potongan Alpha', -payslip.absenceDeductionAmount, negative: true),
                  if (payslip.unpaidLeaveDeductionAmount > 0)
                    _moneyRow(
                      'Potongan Cuti Tanpa Gaji',
                      -payslip.unpaidLeaveDeductionAmount,
                      negative: true,
                    ),
                  if (payslip.missingCheckoutDeductionAmount > 0)
                    _moneyRow(
                      'Potongan Lupa Absen Pulang',
                      -payslip.missingCheckoutDeductionAmount,
                      negative: true,
                    ),
                  if (payslip.loanDeductionAmount > 0)
                    _moneyRow('Potongan Kasbon', -payslip.loanDeductionAmount, negative: true),
                  if (payslip.otherDeductionAmount > 0)
                    _moneyRow('Potongan Lain', -payslip.otherDeductionAmount, negative: true),
                  const Divider(height: 28),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ZeaColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'GAJI BERSIH',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ZeaColors.primaryDark,
                          ),
                        ),
                        Text(
                          rupiah(payslip.netSalary),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ZeaColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, double value, {bool negative = false}) {
    final color = negative ? ZeaColors.danger : Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          Text(
            rupiah(value),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    try {
      final doc = pw.Document();
      final period = payslip.payrollPeriodName ??
          '${idDate(payslip.periodStart)} - ${idDate(payslip.periodEnd)}';

      pw.Widget row(String label, String value) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 120,
                child: pw.Text(label, style: pw.TextStyle(fontSize: 10)),
              ),
              pw.Expanded(
                child: pw.Text(value, style: pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
        );
      }

      pw.Widget moneyRow(String label, double value) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 10)),
              pw.Text(rupiah(value), style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        );
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Center(
              child: pw.Text(
                'SLIP GAJI PEGAWAI',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text('Zea Textile', style: const pw.TextStyle(fontSize: 11)),
            ),
            pw.SizedBox(height: 12),
            row('Periode', period),
            row('Nama', payslip.employeeName ?? '-'),
            row('Jabatan', payslip.position ?? '-'),
            row('Cabang', payslip.storeName ?? '-'),
            row('Bank', '${payslip.bankName ?? '-'} ${payslip.bankAccount ?? ''}'),
            pw.Divider(),
            moneyRow('Gaji Pokok', payslip.baseSalary),
            moneyRow('Uang Makan', payslip.mealAllowanceAmount),
            moneyRow('Uang Transport', payslip.transportAllowanceAmount),
            moneyRow('Lembur', payslip.overtimePay),
            if (payslip.bonusAmount > 0) moneyRow('Bonus', payslip.bonusAmount),
            moneyRow('Potongan Telat', -payslip.lateDeductionAmount),
            moneyRow('Potongan Alpha', -payslip.absenceDeductionAmount),
            moneyRow('Potongan Cuti Tanpa Gaji', -payslip.unpaidLeaveDeductionAmount),
            moneyRow('Potongan Lupa Absen', -payslip.missingCheckoutDeductionAmount),
            moneyRow('Potongan Kasbon', -payslip.loanDeductionAmount),
            moneyRow('Potongan Lain', -payslip.otherDeductionAmount),
            pw.Divider(),
            moneyRow('GAJI BERSIH', payslip.netSalary),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'slip-gaji-${payslip.id}.pdf',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat PDF.')),
        );
      }
    }
  }
}
