
import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.statusCode,
  });

  factory ApiException.fromDioError(DioException e) {
    String msg = 'Something went wrong';

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      msg = 'Connection timeout. Check your internet.';
    } else if (e.type == DioExceptionType.connectionError) {
      msg = 'Cannot connect to server';
    } else if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('detail')) {
        msg = data['detail'].toString();
      } else {
        msg = 'Server error (${e.response!.statusCode})';
      }
    }

    return ApiException(
      message: msg,
      statusCode: e.response?.statusCode,
    );
  }

  @override
  String toString() => message;
}
