// lib/services/dio_service.dart
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DioService {
  static Dio? _dio;

  // Singleton Pattern
  static Dio get dio {
    if (_dio == null) {
      _dio = Dio(_baseOptions);
      _setupInterceptors();
    }
    return _dio!;
  }

  // Base URL ayarları
  static BaseOptions get _baseOptions {
    // Platform kontrolü
    String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://127.0.0.1:5192/';
    }else if(Platform.isAndroid){
      baseUrl = 'http://10.0.2.2:5192/'; // Android Emulator

    } else if (Platform.isIOS) {
      baseUrl = 'http://localhost:5192/'; // iOS Simulator
    } else {
      baseUrl = 'http://172.21.144.1:5192/'; // Gerçek cihaz
    }

    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    );
  }

  // Interceptor'lar (Loglama, Token ekleme vb.)
  static void _setupInterceptors() {
    _dio!.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );

    // Token eklemek için
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('📤 Request: ${options.method} ${options.baseUrl}${options.path}');
          print('📤 Full URL: ${options.uri}');
          
          // TODO: Token'ı ekle (şimdilik test için koment edildi)
          final token = await _getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            print('✅ Token header eklendi');
          } else {
            print('⚠️ Token bulunamadı - endpoint [AllowAnonymous] olmalı');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('📥 Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ Error Type: ${error.type}');
          print('❌ Error Message: ${error.message}');
          print('❌ Response Status: ${error.response?.statusCode}');
          print('❌ Response Data: ${error.response?.data}');
          print('❌ Error Object: $error');
          if (error.error != null) {
            print('❌ Underlying Error: ${error.error}');
          }
          if (error.response?.statusCode == 401) {
            print('🔐 401 Unauthorized - Token geçersiz veya eksik');
            // Token'ı sil ve login screen'e yönlendir
            await clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }
// ✅ Token'ı al (SharedPreferences'dan)
  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('❌ Token alma hatası: $e');
      return null;
    }
  }

  // ✅ Token'ı kaydet
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('✅ Token kaydedildi');
    } catch (e) {
      print('❌ Token kaydetme hatası: $e');
    }
  }

  // ✅ Token'ı sil
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('✅ Token silindi');
    } catch (e) {
      print('❌ Token silme hatası: $e');
    }
  }

  // ✅ Token var mı kontrol et
  static Future<bool> hasToken() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }
}