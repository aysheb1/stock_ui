import 'package:dio/dio.dart';
import '../../../../core/dio_service.dart';
import '../models/user_model.dart';

abstract class AuthDatasource {
  Future<bool> sendOtp(String phoneNumber);
  Future<UserModel> verifyOtp(String phoneNumber, String otp);
  Future<bool> resendOtp(String phoneNumber);
  Future<void> setTestOtp(String phoneNumber, String code);
}

class AuthDatasourceImpl implements AuthDatasource {
  final Dio _dio = DioService.dio;

  @override
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      final res = await _dio.post('/api/auth/sms-login-send', data: {'phoneNumber': phoneNumber});
      final data = res.data;
      if (data is Map && data['isSuccess'] == true) return true;
      final msg = data['message'] ?? 'OTP gönderilemedi';
      throw Exception(msg);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('OTP gönderilemedi: $e');
    }
  }

  @override
  Future<UserModel> verifyOtp(String phoneNumber, String otp) async {
    try {
      final res = await _dio.post('/api/auth/sms-login', data: {'phoneNumber': phoneNumber, 'code': otp});
      final data = res.data;
      if (data is Map && data['isSuccess'] == true) {
        final d = data['data'] ?? {};
        final token = d['token'] ?? '';
        if (token.isNotEmpty) await DioService.saveToken(token);
        final user = UserModel.fromJson({...d, 'phoneNumber': phoneNumber});
        return user;
      }
      final msg = data['message'] ?? 'Doğrulama başarısız';
      throw Exception(msg);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Doğrulama başarısız: $e');
    }
  }

  @override
  Future<bool> resendOtp(String phoneNumber) async {
    try {
      final res = await _dio.post('/api/auth/sms-resend-code', data: {'phoneNumber': phoneNumber});
      final data = res.data;
      if (data is Map && data['isSuccess'] == true) return true;
      final msg = data['message'] ?? 'OTP yeniden gönderilemedi';
      throw Exception(msg);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('OTP yeniden gönderilemedi: $e');
    }
  }

  @override
  Future<void> setTestOtp(String phoneNumber, String code) async {
    try {
      await _dio.post('/api/auth/test-set-otp', data: {'phoneNumber': phoneNumber, 'code': code});
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Test OTP ayarlanamadı: $e');
    }
  }

  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        if (data is Map && data.containsKey('message')) return data['message'];
        switch (statusCode) {
          case 400:
            return 'Geçersiz istek. Lütfen bilgilerinizi kontrol edin.';
          case 401:
            return 'Yetkisiz erişim. Lütfen tekrar giriş yapın.';
          case 403:
            return 'Bu işlem için yetkiniz yok.';
          case 404:
            return 'İstenen kaynak bulunamadı.';
          case 500:
            return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
          default:
            return 'Bir hata oluştu: $statusCode';
        }
      case DioExceptionType.cancel:
        return 'İstek iptal edildi.';
      case DioExceptionType.connectionError:
        return 'İnternet bağlantınızı kontrol edin.';
      case DioExceptionType.unknown:
      default:
        return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
