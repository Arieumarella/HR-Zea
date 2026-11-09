import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/api_client.dart';
import '../../core/device.dart';
import '../../core/storage.dart';
import '../../services/hr_service.dart';

enum AuthStatus { unknown, loggedOut, loggedIn, blocked }

class AuthController extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  String nama = '';
  String role = '';
  String blockReason = '';
  bool sessionExpired = false;

  AuthController() {
    ApiClient.instance.onAuthError = _handleAuthError;
  }

  void _handleAuthError() {
    if (status == AuthStatus.loggedIn) {
      sessionExpired = true;
      logout();
    }
  }

  Future<void> bootstrap() async {
    try {
      final token = await Storage.token();
      if (token == null || token.isEmpty) {
        status = AuthStatus.loggedOut;
        notifyListeners();
        return;
      }
      final user = await Storage.readUser();
      nama = user.nama;
      role = user.role;
      if (!user.isEmployee) {
        blockReason = 'Akun Anda tidak terdaftar sebagai pegawai.\nHubungi admin untuk pendaftaran.';
        status = AuthStatus.blocked;
      } else if (!user.isActive) {
        blockReason = 'Status pegawai Anda tidak aktif.\nHubungi admin.';
        status = AuthStatus.blocked;
      } else {
        status = AuthStatus.loggedIn;
      }
    } catch (_) {
      // Jangan biarkan error startup mematikan aplikasi.
      status = AuthStatus.loggedOut;
    }
    notifyListeners();
  }

  Future<String?> login(String username, String password) async {
    final Map<String, dynamic> res;
    try {
      String? deviceId;
      try {
        deviceId = await DeviceInfo.getDeviceId();
      } catch (_) {}
      res = await HrService.instance.login(
        username.trim(),
        password,
        deviceId: deviceId,
      );
    } catch (error) {
      return error.toString();
    }
    final token = res['token'];
    if (token == null || token.toString().isEmpty) {
      return 'Respons login tidak valid.';
    }
    await Storage.saveToken(token.toString());

    final employeeProfile = res['employee_profile'];
    final isEmployee = employeeProfile is Map;
    final isActive = isEmployee && employeeProfile['is_active'] == true;

    nama = (res['nama'] as String?) ?? '';
    role = (res['role'] as String?) ?? '';

    await Storage.saveUser(
      nama: nama,
      role: role,
      isEmployee: isEmployee,
      isActive: isActive,
      blockReason: isEmployee && !isActive
          ? 'Status pegawai Anda tidak aktif. Hubungi admin.'
          : null,
    );

    if (!isEmployee) {
      blockReason = 'Akun Anda tidak terdaftar sebagai pegawai.\nHubungi admin untuk pendaftaran.';
      status = AuthStatus.blocked;
    } else if (!isActive) {
      blockReason = 'Status pegawai Anda tidak aktif. Hubungi admin.';
      status = AuthStatus.blocked;
    } else {
      blockReason = '';
      sessionExpired = false;
      status = AuthStatus.loggedIn;
    }
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    await Storage.clearToken();
    await Storage.clearUser();
    status = AuthStatus.loggedOut;
    nama = '';
    role = '';
    blockReason = '';
    notifyListeners();
  }
}

final authProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController();
});
