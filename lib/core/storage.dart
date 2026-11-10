import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan token & data user (SharedPreferences).
/// Catatan: token tersimpan plain di penyimpanan privat aplikasi untuk
/// kompatibilitas maksimal di semua ROM (termasuk MIUI/HyperOS yang kerap
/// crash dengan Android Keystore). Naikkan ke secure storage jika aplikasi
/// sudah lewat rilis Play Store resmi.
class Storage {
  Storage._();

  static const _tokenKey = 'auth_token';
  static const _namaKey = 'auth_nama';
  static const _roleKey = 'auth_role';
  static const _employeeKey = 'auth_is_employee';
  static const _activeKey = 'auth_is_active';
  static const _blockReasonKey = 'auth_block_reason';

  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, value);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> saveUser({
    required String nama,
    required String role,
    required bool isEmployee,
    required bool isActive,
    String? blockReason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_namaKey, nama);
    await prefs.setString(_roleKey, role);
    await prefs.setBool(_employeeKey, isEmployee);
    await prefs.setBool(_activeKey, isActive);
    if (blockReason != null) {
      await prefs.setString(_blockReasonKey, blockReason);
    } else {
      await prefs.remove(_blockReasonKey);
    }
  }

  static Future<({String nama, String role, bool isEmployee, bool isActive, String blockReason})>
      readUser() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      nama: prefs.getString(_namaKey) ?? '',
      role: prefs.getString(_roleKey) ?? '',
      isEmployee: prefs.getBool(_employeeKey) ?? false,
      isActive: prefs.getBool(_activeKey) ?? true,
      blockReason: prefs.getString(_blockReasonKey) ?? '',
    );
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_namaKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_employeeKey);
    await prefs.remove(_activeKey);
    await prefs.remove(_blockReasonKey);
  }
}
