class AppConfig {
  AppConfig._();

  /// Base URL API. Default produksi; bisa di-override saat build:
  /// flutter build apk --dart-define=API_BASE_URL=https://.../api
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://www.zeatextile.cloud/api',
  );

  static const String appName = 'Zea HR';

  /// Ambil URL lengkap untuk file upload (path relatif dari API, mis. attendance/2026/11/x.webp).
  /// File statis disajikan di `/uploads/...`, di balik prefix `/api/` nginx.
  static String fileUrl(String relativePath) {
    var normalized = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    if (!normalized.startsWith('uploads/')) {
      normalized = 'uploads/$normalized';
    }
    return '$apiBaseUrl/$normalized';
  }
}
