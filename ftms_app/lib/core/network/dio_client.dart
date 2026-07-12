
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

class DioClient {
  static DioClient? _instance;
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  
  static String? authToken;

  DioClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15), // Reduced from 30 to fail faster and retry sooner
        receiveTimeout: const Duration(minutes: 5),  // Large files
        sendTimeout: const Duration(minutes: 30),    // Upload timeout
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage),
      _RetryInterceptor(dio: _dio),
      PrettyDioLogger(
        requestHeader: false,
        requestBody: false,
        responseBody: false,
        error: true,
        compact: true,
      ),
    ]);
  }

  static DioClient get instance => _instance ??= DioClient._();
  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  _AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    DioClient.authToken = token;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired - clear and redirect to login
      DioClient.authToken = null;
      _storage.delete(key: AppConstants.tokenKey);
    }
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final List<Duration> retryDelays;

  _RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 5),
    ],
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    
    // Only retry on network errors (timeouts, connection issues)
    // and not on 4xx/5xx server response errors unless it's a gateway issue
    final isNetworkError = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.type == DioExceptionType.unknown && err.error is SocketException) ||
        err.response?.statusCode == 502 ||
        err.response?.statusCode == 503 ||
        err.response?.statusCode == 504;

    int retryCount = requestOptions.extra['retry_count'] ?? 0;

    if (isNetworkError && retryCount < maxRetries) {
      retryCount++;
      requestOptions.extra['retry_count'] = retryCount;

      final delay = retryDelays[retryCount - 1];
      await Future.delayed(delay);

      try {
        final response = await dio.request(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          cancelToken: requestOptions.cancelToken,
          options: Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
            extra: requestOptions.extra,
            responseType: requestOptions.responseType,
            contentType: requestOptions.contentType,
          ),
          onSendProgress: requestOptions.onSendProgress,
          onReceiveProgress: requestOptions.onReceiveProgress,
        );
        return handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          return handler.next(e);
        }
        return handler.next(DioException(requestOptions: requestOptions, error: e));
      }
    }

    handler.next(err);
  }
}
