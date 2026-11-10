import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../services/hr_service.dart';
import '../auth/auth_controller.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  MyToday? _data;
  bool _loading = true;
  String? _error;
  String? _version;

  @override
  void initState() {
    super.initState();
    _load();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = 'v${info.version}');
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await HrService.instance.getMyToday();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Anda akan keluar dari aplikasi Zea HR.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ZeaColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: ZeaColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 44,
                        color: ZeaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.nama.isEmpty ? 'Pegawai' : auth.nama,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ZeaColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _data?.profile.position ?? auth.role,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              )
            else if (_data != null) ...[
              _SectionCard(
                title: 'Informasi Pekerjaan',
                rows: [
                  _infoRow('Toko', _data!.hrStore.namaToko ?? '-'),
                  _infoRow(
                    'Shift',
                    _data!.hrStore.shift != null
                        ? '${_data!.hrStore.shift!.name} (${_data!.hrStore.shift!.workStartTime}-${_data!.hrStore.shift!.workEndTime})'
                        : 'Jam toko (${_data!.hrStore.workStartTime}-${_data!.hrStore.workEndTime})',
                  ),
                  _infoRow('Kode Pegawai', _data!.profile.employeeCode ?? '-'),
                  _infoRow('Bergabung', _data!.profile.joinDate == null ? '-' : idDate(_data!.profile.joinDate)),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Cuti Tahunan',
                rows: [
                  _infoRow(
                    'Sisa Kuota',
                    '${_data!.profile.annualLeaveQuota} hari',
                  ),
                  _infoRow(
                    'Jatah',
                    '${_data!.profile.annualLeaveEntitlement} hari',
                  ),
                ],
              ),
              if (_data!.profile.resignDate != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: ZeaColors.warning),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tanggal berhenti: ${idDate(_data!.profile.resignDate)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: ZeaColors.danger),
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Zea HR ${_version ?? ''} · Zea Textile',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _SectionCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }
}
