
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _dio = DioClient.instance.dio;
  final _storage = const FlutterSecureStorage();

  Future<String> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post(ApiConstants.register, data: {
        'email': email,
        'username': username,
        'password': password,
      });
      final token = res.data['access_token'] as String;
      await _storage.write(key: AppConstants.tokenKey, value: token);
      return token;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });
      final token = res.data['access_token'] as String;
      await _storage.write(key: AppConstants.tokenKey, value: token);
      return UserModel.fromJson(res.data['user']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final res = await _dio.get(ApiConstants.me);
      return UserModel.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<String?> getToken() =>
    _storage.read(key: AppConstants.tokenKey);

  // Telegram
  Future<Map<String, dynamic>> telegramConnect({
    required int apiId,
    required String apiHash,
    required String phoneNumber,
  }) async {
    try {
      final res = await _dio.post(ApiConstants.tgConnect, data: {
        'api_id': apiId,
        'api_hash': apiHash,
        'phone_number': phoneNumber,
      });
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> telegramVerify({
    required String phoneNumber,
    required String code,
    required String phoneCodeHash,
  }) async {
    try {
      final res = await _dio.post(ApiConstants.tgVerify, data: {
        'phone_number': phoneNumber,
        'code': code,
        'phone_code_hash': phoneCodeHash,
      });
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
