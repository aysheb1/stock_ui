// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'dio_service.dart';

class ApiService {
  static final Dio _dio = DioService.dio;

  // GET isteği
  static Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST isteği
  static Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT isteği
  static Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE isteği
  static Future<Response> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Hata yönetimi
  static Exception _handleError(DioException error) {
    String errorMessage = 'Bir hata oluştu';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Bağlantı zaman aşımına uğradı';
        break;

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'];
        } else {
          switch (statusCode) {
            case 400:
              errorMessage = 'Geçersiz istek';
              break;
            case 401:
              errorMessage = 'Yetkisiz erişim';
              break;
            case 403:
              errorMessage = 'Erişim engellendi';
              break;
            case 404:
              errorMessage = 'Kaynak bulunamadı';
              break;
            case 500:
              errorMessage = 'Sunucu hatası';
              break;
            default:
              errorMessage = 'Beklenmeyen hata: $statusCode';
          }
        }
        break;

      case DioExceptionType.cancel:
        errorMessage = 'İstek iptal edildi';
        break;

      case DioExceptionType.connectionError:
        errorMessage = 'İnternet bağlantısı yok';
        break;

      case DioExceptionType.badCertificate:
        errorMessage = 'Güvenlik sertifikası hatası';
        break;

      case DioExceptionType.unknown:
        errorMessage = 'Bilinmeyen hata: ${error.message}';
        break;
    }

    print('API Hatası: $errorMessage');
    return Exception(errorMessage);
  }
}