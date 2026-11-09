import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/device.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/watermark.dart';
import '../../models/models.dart';
import '../../services/hr_service.dart';
import '../auth/auth_controller.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage>
    with WidgetsBindingObserver {
  MyToday? _data;
  bool _loading = true;
  String? _error;

  // Server clock (WIB)
  DateTime? _serverWib;
  Timer? _clockTimer;

  // GPS
  Position? _position;
  StreamSubscription<Position>? _positionStream;
  String? _geoError;
  bool _geoDenied = false;

  // Kamera
  CameraController? _cameraController;
  bool _cameraReady = false;
  String? _cameraError;

  // Hasil foto
  Uint8List? _capturedBytes;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _initCamera();
    _startGps();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _positionStream?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initCamera();
      _startGps();
    }
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
        _serverWib = DateTime.parse(data.serverTime)
            .toUtc()
            .add(const Duration(hours: 7));
      });
      _startClock();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_serverWib == null || !mounted) return;
      setState(() => _serverWib = _serverWib!.add(const Duration(seconds: 1)));
    });
  }

  Future<void> _startGps() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _geoDenied = true;
          _geoError = 'Izin lokasi ditolak. Aktifkan untuk absensi.';
        });
      }
      return;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        setState(() => _geoError = 'GPS perangkat mati. Nyalakan GPS lalu coba lagi.');
      }
      return;
    }

    if (mounted) setState(() => _geoError = null);

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen(
      (position) {
        if (mounted) setState(() => _position = position);
      },
      onError: (Object error) {
        if (mounted) {
          setState(() => _geoError = 'Gagal membaca lokasi: $error');
        }
      },
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      CameraDescription? front;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          front = camera;
          break;
        }
      }
      final description = front ?? (cameras.isNotEmpty ? cameras.first : null);
      if (description == null) {
        if (mounted) setState(() => _cameraError = 'Kamera tidak ditemukan.');
        return;
      }
      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      await _cameraController?.dispose();
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
        _cameraError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _cameraError = 'Gagal mengakses kamera: $error');
      }
    }
  }

  Future<void> _openLocationSettings() async {
    if (_geoDenied) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.openLocationSettings();
    }
    _startGps();
  }

  HrStore get _store => _data!.hrStore;
  Attendance? get _attendance => _data!.attendance;

  double? get _distance {
    final pos = _position;
    if (pos == null || _store.latitude == null || _store.longitude == null) {
      return null;
    }
    return haversineMeters(
      pos.latitude,
      pos.longitude,
      _store.latitude!,
      _store.longitude!,
    );
  }

  bool get _inRadius {
    final distance = _distance;
    return distance != null && distance <= _store.radiusMeters;
  }

  bool get _isMocked => _position?.isMocked ?? false;

  bool get _canSubmit =>
      _inRadius &&
      !_isMocked &&
      _capturedBytes != null &&
      !_submitting &&
      (_attendance == null || _attendance!.checkOutTime == null);

  Future<void> _capture() async {
    final controller = _cameraController;
    if (controller == null || !_cameraReady) {
      _showError('Kamera belum siap.');
      return;
    }
    if (_position == null) {
      _showError('Lokasi belum terdeteksi. Tunggu sebentar.');
      return;
    }
    if (_isMocked) {
      _showError('Lokasi palsu terdeteksi. Matikan aplikasi pemalsu lokasi.');
      return;
    }
    if (!_inRadius) {
      _showError('Anda berada di luar area toko.');
      return;
    }
    try {
      final photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      final serverNow = _serverWib ?? DateTime.now().toUtc().add(const Duration(hours: 7));
      final name = _data!.profile.user?.nama ?? ref.read(authProvider).nama;
      final timestamp =
          '${serverNow.year}-${serverNow.month.toString().padLeft(2, '0')}-${serverNow.day.toString().padLeft(2, '0')} '
          '${serverNow.hour.toString().padLeft(2, '0')}:${serverNow.minute.toString().padLeft(2, '0')}:${serverNow.second.toString().padLeft(2, '0')} WIB';
      final watermarked = addAttendanceWatermark(
        photoBytes: bytes,
        name: name,
        store: _store.namaToko ?? 'Zea Textile',
        timestamp: timestamp,
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        distanceMeters: _distance ?? 0,
      );
      if (!mounted) return;
      setState(() {
        _capturedBytes = watermarked;
      });
    } catch (error) {
      _showError('Gagal mengambil foto: $error');
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      final position = _position!;
      final isOut = _attendance != null &&
          _attendance!.checkInTime != null &&
          _attendance!.checkOutTime == null;
      final type = isOut ? 'OUT' : 'IN';

      String? appVersion;
      try {
        appVersion = (await PackageInfo.fromPlatform()).version;
      } catch (_) {}

      String? deviceId;
      try {
        deviceId = await DeviceInfo.getDeviceId();
      } catch (_) {}

      final form = FormData.fromMap({
        'type': type,
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'accuracy': position.accuracy.toStringAsFixed(1),
        'is_mocked_location': position.isMocked ? 'true' : 'false',
        'device_id': ?deviceId,
        'app_version': ?appVersion,
        'photo': MultipartFile.fromBytes(
          _capturedBytes!,
          filename: 'selfie.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      final res = await HrService.instance.clockInOut(form);
      if (!mounted) return;
      _showSuccess((res['message'] as String?) ?? 'Absensi berhasil tercatat.');
      setState(() {
        _capturedBytes = null;
      });
      _load();
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: ZeaColors.danger,
      ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: ZeaColors.success,
      ));
  }

  String _clockText() {
    final date = _serverWib;
    if (date == null) return '--:--:--';
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final ss = date.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 52, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(),
          const SizedBox(height: 12),
          _locationCard(),
          const SizedBox(height: 12),
          _cameraCard(),
          const SizedBox(height: 12),
          _submitCard(),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Absensi terekam otomatis di sistem HR.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard() {
    final store = _store;
    final attendance = _attendance;
    final shift = store.shift;

    final statusInfo = attendance == null
        ? (label: 'Belum Absen', color: 0xFF8A8A8A)
        : attendance.checkOutTime != null
            ? (label: 'Selesai', color: 0xFF2E9E5B)
            : (label: 'Sudah Masuk', color: 0xFF2FA8A8);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ZeaColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront, color: ZeaColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.namaToko ?? 'Toko Anda',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ZeaColors.primaryDark,
                        ),
                      ),
                      Text(
                        shift != null
                            ? 'Shift: ${shift.name} (${shift.workStartTime}-${shift.workEndTime})'
                            : 'Jam Kerja: ${store.workStartTime}-${store.workEndTime}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(statusInfo.color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusInfo.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(statusInfo.color),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _clockText(),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
                color: ZeaColors.primaryDark,
              ),
            ),
            Text(
              'WIB · ${idShortDate(_data!.serverTime)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            if (attendance != null && attendance.checkInTime != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: ZeaColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _infoRow('Masuk', wibDateTime(attendance.checkInTime),
                        attendance.status == 'LATE'
                            ? 'Terlambat ${attendance.lateMinutes} mnt'
                            : null),
                    if (attendance.checkOutTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _infoRow(
                            'Pulang', wibDateTime(attendance.checkOutTime), null),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, String? sub) {
    return Row(
      children: [
        SizedBox(
          width: 64,
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
        if (sub != null)
          Text(
            sub,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ZeaColors.warning,
            ),
          ),
      ],
    );
  }

  Widget _locationCard() {
    if (!_store.locationConfigured) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.location_off, color: ZeaColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lokasi toko belum diatur oleh admin.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final distance = _distance;
    final inRadius = _inRadius;
    final mocked = _isMocked;

    Color color = Colors.grey;
    IconData icon = Icons.location_searching;
    String title = 'Mencari lokasi Anda...';
    String sub = 'Nyalakan GPS dan tunggu beberapa saat.';

    if (mocked) {
      color = ZeaColors.danger;
      icon = Icons.gpp_bad;
      title = 'Lokasi palsu terdeteksi';
      sub = 'Matikan aplikasi pemalsu lokasi untuk bisa absen.';
    } else if (_geoDenied) {
      color = ZeaColors.danger;
      icon = Icons.location_disabled;
      title = 'Izin lokasi ditolak';
      sub = _geoError ?? 'Aktifkan izin lokasi untuk absensi.';
    } else if (_geoError != null && distance == null) {
      color = ZeaColors.warning;
      icon = Icons.gps_off;
      title = _geoError!;
      sub = 'Ketuk tombol di bawah untuk membuka pengaturan GPS.';
    } else if (distance == null) {
      color = ZeaColors.warning;
      icon = Icons.location_searching;
      title = 'Mencari lokasi...';
      sub = 'Tunggu sinyal GPS stabil.';
    } else if (inRadius) {
      color = ZeaColors.success;
      icon = Icons.check_circle;
      title = 'Di dalam area toko';
      sub =
          'Jarak ${distance.toStringAsFixed(0)} m (batas ${_store.radiusMeters} m) · akurasi ±${_position!.accuracy.toStringAsFixed(0)} m';
    } else {
      color = ZeaColors.danger;
      icon = Icons.cancel;
      title = 'Di luar area toko';
      sub =
          'Jarak ${distance.toStringAsFixed(0)} m (batas ${_store.radiusMeters} m)';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_geoDenied || _geoError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openLocationSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Buka Pengaturan Lokasi'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cameraCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selfie Absensi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Foto akan diberi watermark nama, waktu, dan lokasi otomatis.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            if (_cameraError != null)
              Container(
                width: double.infinity,
                height: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _cameraError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
              )
            else if (_capturedBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  _capturedBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 240,
                ),
              )
            else if (_cameraController != null && _cameraReady)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: CameraPreview(_cameraController!),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const CircularProgressIndicator(),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _capturedBytes == null ? _capture : _resetPhoto,
                    icon: Icon(
                      _capturedBytes == null
                          ? Icons.photo_camera_outlined
                          : Icons.refresh,
                    ),
                    label: Text(
                      _capturedBytes == null ? 'Ambil Foto' : 'Ulangi Foto',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resetPhoto() {
    setState(() {
      _capturedBytes = null;
    });
  }

  Widget _submitCard() {
    final attendance = _attendance;
    if (attendance != null && attendance.checkOutTime != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.task_alt, color: ZeaColors.success, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Absensi hari ini sudah selesai. Sampai jumpa besok!',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isOut = attendance != null && attendance.checkInTime != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: isOut ? ZeaColors.accent : ZeaColors.primary,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(isOut ? 'Absen Pulang' : 'Absen Masuk'),
            ),
            if (_capturedBytes == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Ambil foto selfie terlebih dahulu.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
