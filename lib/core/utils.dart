import 'dart:math' as math;

/// Haversine: jarak dua titik koordinat dalam meter.
double haversineMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadius = 6371000.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _degToRad(double deg) => deg * math.pi / 180.0;

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Parse ISO string (dari server, UTC) lalu ubah ke WIB (UTC+7).
DateTime _parseWib(String? iso) {
  if (iso == null || iso.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return DateTime.fromMillisecondsSinceEpoch(0);
  return parsed.toUtc().add(const Duration(hours: 7));
}

String wibClock(String? iso) {
  final date = _parseWib(iso);
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  final ss = date.second.toString().padLeft(2, '0');
  return '$hh:$mm:$ss';
}

String wibTime(String? iso) {
  final date = _parseWib(iso);
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String wibDateTime(String? iso) {
  final date = _parseWib(iso);
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '${_days[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year} $hh:$mm';
}

String idDate(String? iso) {
  final date = _parseWib(iso);
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

String idShortDate(String? iso) {
  final date = _parseWib(iso);
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  return '${date.year}-$mm-$dd';
}

String rupiah(num value) {
  final negative = value < 0;
  final abs = value.abs();
  final text = abs.toStringAsFixed(abs % 1 == 0 ? 0 : 0);
  final buffer = StringBuffer();
  final chars = text.split('');
  for (var i = 0; i < chars.length; i++) {
    buffer.write(chars[i]);
    final remaining = chars.length - 1 - i;
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  return '${negative ? '-' : ''}Rp $buffer';
}

({String label, int color}) attendanceStatus(String status) {
  switch (status) {
    case 'PRESENT':
      return (label: 'Hadir', color: 0xFF2E9E5B);
    case 'LATE':
      return (label: 'Terlambat', color: 0xFFE9A23B);
    case 'SICK':
      return (label: 'Sakit', color: 0xFF4C8BF5);
    case 'ANNUAL_LEAVE':
      return (label: 'Cuti Tahunan', color: 0xFF8E6CD8);
    case 'UNPAID_LEAVE':
      return (label: 'Cuti Tanpa Gaji', color: 0xFFB06CD8);
    case 'FIELD_DUTY':
      return (label: 'Dinas Luar', color: 0xFF2FA8A8);
    case 'ALPHA':
      return (label: 'Alpha', color: 0xFFD64545);
    default:
      return (label: status, color: 0xFF8A8A8A);
  }
}

({String label, int color}) requestStatus(String status) {
  switch (status) {
    case 'PENDING':
      return (label: 'Menunggu', color: 0xFFE9A23B);
    case 'APPROVED':
      return (label: 'Disetujui', color: 0xFF2E9E5B);
    case 'APPROVED_ACTIVE':
      return (label: 'Aktif', color: 0xFF2E9E5B);
    case 'REJECTED':
      return (label: 'Ditolak', color: 0xFFD64545);
    case 'PAID_OFF':
      return (label: 'Lunas', color: 0xFF4C8BF5);
    default:
      return (label: status, color: 0xFF8A8A8A);
  }
}
