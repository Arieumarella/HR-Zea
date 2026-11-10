import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../services/hr_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final List<Attendance> _rows = [];
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
      final result = await HrService.instance.getHistory(_page);
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
      appBar: AppBar(title: const Text('Riwayat Absensi')),
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
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Belum ada riwayat absensi.',
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
        return _AttendanceTile(
          attendance: _rows[index],
          onTapPhoto: _showPhoto,
        );
      },
    );
  }

  void _showPhoto(String? path) {
    if (path == null || path.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            AppConfig.fileUrl(path),
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Container(
                    width: 300,
                    height: 300,
                    color: Colors.black,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final Attendance attendance;
  final void Function(String?) onTapPhoto;

  const _AttendanceTile({required this.attendance, required this.onTapPhoto});

  @override
  Widget build(BuildContext context) {
    final status = attendanceStatus(attendance.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    idDate(attendance.attendanceDate),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ZeaColors.primaryDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(status.color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(status.color),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _timeCell(
                    'Masuk',
                    attendance.checkInTime == null
                        ? '-'
                        : wibTime(attendance.checkInTime),
                    attendance.checkInPhoto,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _timeCell(
                    'Pulang',
                    attendance.checkOutTime == null
                        ? '-'
                        : wibTime(attendance.checkOutTime),
                    attendance.checkOutPhoto,
                  ),
                ),
              ],
            ),
            if (attendance.lateMinutes > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: ZeaColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Terlambat ${attendance.lateMinutes} menit',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ZeaColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timeCell(String label, String time, String? photoPath) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (photoPath != null && photoPath.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => onTapPhoto(photoPath),
                child: Text(
                  'Lihat foto',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ZeaColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
