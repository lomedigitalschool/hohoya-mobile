import 'package:dio/dio.dart';

import 'api_config.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!options.path.startsWith('/auth/')) {
            final token = await TokenStorage.instance.accessToken;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthRoute = error.requestOptions.path.startsWith('/auth/');
          final alreadyRetried = error.requestOptions.extra['retried'] == true;
          if (error.response?.statusCode != 401 || isAuthRoute || alreadyRetried) {
            handler.next(error);
            return;
          }

          final refreshed = await _refreshToken();
          if (!refreshed) {
            await TokenStorage.instance.clear();
            handler.next(error);
            return;
          }

          try {
            final retryResponse = await _dio.fetch(
              error.requestOptions..extra['retried'] = true,
            );
            handler.resolve(retryResponse);
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  static final instance = ApiClient._();

  late final Dio _dio;
  Dio get dio => _dio;

  Future<bool> _refreshToken() async {
    final refreshToken = await TokenStorage.instance.refreshToken;
    if (refreshToken == null) return false;

    try {
      final response = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      final accessToken = response.data['accessToken'] as String?;
      final newRefreshToken = response.data['refreshToken'] as String? ?? refreshToken;
      if (accessToken == null) return false;
      await TokenStorage.instance.saveTokens(accessToken: accessToken, refreshToken: newRefreshToken);
      return true;
    } on DioException {
      return false;
    }
  }
}
