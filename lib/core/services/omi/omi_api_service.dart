import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OmiApiService {
  OmiApiService._();

  static OmiApiService? _instance;
  static OmiApiService get instance => _instance ??= OmiApiService._();

  late final Dio _dio;
  bool _initialized = false;

  String? get _apiKey => dotenv.env['OMI_API_KEY'];
  static const String _baseUrl = 'https://api.omi.me/v1/dev/user';

  void initialize() {
    if (_initialized) return;
    
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_apiKey != null && _apiKey!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_apiKey';
        }

        debugPrint('Auth header: ${options.headers['Authorization']}');
        debugPrint('Full URL: ${options.baseUrl}${options.path}');
        debugPrint('Omi API Request: ${options.method} ${options.path}');

        return handler.next(options);
      },      onResponse: (response, handler) {
        debugPrint('Omi API Response: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('Omi API Error: ${error.message}');
        return handler.next(error);
      },
    ));

    _initialized = true;
    debugPrint('OmiApiService initialized with baseUrl: $_baseUrl');
  }

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      final parsedData = parser != null ? parser(response.data) : response.data as T;
      return ApiResponse.success(parsedData);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      final parsedData = parser != null ? parser(response.data) : response.data as T;
      return ApiResponse.success(parsedData);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      final parsedData = parser != null ? parser(response.data) : response.data as T;
      return ApiResponse.success(parsedData);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.delete(path);
      final parsedData = parser != null ? parser(response.data) : response.data as T;
      return ApiResponse.success(parsedData);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? error.message;
        return 'Server error ($statusCode): $message';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      default:
        return error.message ?? 'Unknown error';
    }
  }
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse._({this.data, this.error, required this.isSuccess});

  factory ApiResponse.success(T data) => ApiResponse._(data: data, isSuccess: true);
  factory ApiResponse.error(String error) => ApiResponse._(error: error, isSuccess: false);
}