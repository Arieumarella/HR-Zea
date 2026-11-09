import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'config.dart';
import 'storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Thin wrapper di atas Dio untuk aplikasi Zea HR.
/// Semua response API berbentuk { status: bool, message?: string, data?... }.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio dio;

  /// Dipanggil ketika token tidak valid (401/403) → app auto logout.
  void Function()? onAuthError;

  void init() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 45),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await Storage.token();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {
            // Abaikan kegagalan pembacaan token.
          }
          handler.next(options);
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (object) => debugPrint('[ZEA] $object'),
      ),
    );
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<dynamic>> Function() send, {
    bool isAuthCall = false,
  }) async {
    try {
      final response = await send();
      final body = response.data;
      if (body is Map<String, dynamic>) {
        if (body['status'] == false || body['status'] == 'false') {
          final message = (body['message'] as String?) ?? 'Terjadi kesalahan.';
          if (!isAuthCall &&
              response.statusCode == 401 &&
              await Storage.token() != null) {
            onAuthError?.call();
          }
          throw ApiException(message, statusCode: response.statusCode);
        }
        return body;
      }
      throw ApiException('Respons server tidak dikenali.');
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      debugPrint('[ZEA] DioException type=${error.type} message=${error.message}');
      debugPrint('[ZEA] error=${error.error}');
      debugPrint('[ZEA] stack=${error.stackTrace}');
      if (data is Map<String, dynamic> &&
          (data['message'] is String) &&
          (data['message'] as String).isNotEmpty) {
        final message = data['message'] as String;
        if (!isAuthCall && (status == 401) && await Storage.token() != null) {
          onAuthError?.call();
        }
        throw ApiException(message, statusCode: status);
      }
      if (status == 401 && await Storage.token() != null) {
        onAuthError?.call();
        throw ApiException('Sesi Anda berakhir. Silakan login kembali.', statusCode: status);
      }
      if (error.type == DioExceptionType.badCertificate) {
        throw ApiException(
          'Koneksi aman gagal diverifikasi (sertifikat SSL server tidak valid).',
          statusCode: status,
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        throw ApiException(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
          statusCode: status,
        );
      }
      final detail = error.error?.toString() ?? error.message ?? '-';
      throw ApiException(
        'Terjadi kesalahan jaringan (${error.type.name}: $detail)',
        statusCode: status,
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: $error');
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool isAuthCall = false,
  }) {
    return _request(
      () => dio.get(path, queryParameters: query),
      isAuthCall: isAuthCall,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool isAuthCall = false,
  }) {
    return _request(
      () => dio.post(path, data: body),
      isAuthCall: isAuthCall,
    );
  }

  Future<Map<String, dynamic>> postForm(
    String path,
    FormData formData,
  ) {
    return _request(() => dio.post(path, data: formData));
  }
}
