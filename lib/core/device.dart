import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// ID unik perangkat untuk audit sesi & absensi.
class DeviceInfo {
  DeviceInfo._();

  static String? _cached;

  static Future<String> getDeviceId() async {
    final cached = _cached;
    if (cached != null && cached.isNotEmpty) return cached;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString('device_id', id);
    }
    _cached = id;
    return id;
  }
}
