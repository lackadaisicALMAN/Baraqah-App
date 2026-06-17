import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

import 'api_client.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage secureStorage;
  final Dio _refreshDio = Dio();

  AuthInterceptor({required this.secureStorage}) {
    _refreshDio.interceptors.add(ResponseUnwrapInterceptor());
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await secureStorage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.path != ApiEndpoints.refresh) {
      try {
        final refreshToken = await secureStorage.readRefreshToken();
        if (refreshToken == null) {
          return handler.next(err);
        }

        // server expects refresh_token key
        final response = await _refreshDio
            .post(ApiEndpoints.refresh, data: {'refresh_token': refreshToken});
        final data = response.data is Map<String, dynamic> &&
                (response.data as Map).containsKey('data')
            ? response.data['data']
            : response.data;
        final accessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (accessToken != null) {
          await secureStorage.saveToken(accessToken);
          if (newRefreshToken != null) {
            await secureStorage.saveRefreshToken(newRefreshToken);
          }
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $accessToken';
          final clonedResponse = await _refreshDio.request(requestOptions.path,
              options: Options(
                  method: requestOptions.method,
                  headers: requestOptions.headers),
              data: requestOptions.data,
              queryParameters: requestOptions.queryParameters);
          return handler.resolve(clonedResponse);
        }
      } catch (_) {
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}
