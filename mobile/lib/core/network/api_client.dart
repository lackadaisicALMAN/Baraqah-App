import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio dio;

  ApiClient({required AuthInterceptor authInterceptor})
      : dio = Dio(BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
            sendTimeout: const Duration(seconds: 8))) {
    dio.interceptors.add(authInterceptor);
    dio.interceptors.add(ResponseUnwrapInterceptor());
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // simple request logging for debugging
        // ignore: avoid_print
        print('API Request: ${options.method} ${options.uri}');
        // ignore: avoid_print
        print('API Request Data: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        // ignore: avoid_print
        print(
            'API Response: ${response.statusCode} ${response.requestOptions.uri}');
        // ignore: avoid_print
        print('API Response Data: ${response.data}');
        handler.next(response);
      },
      onError: (err, handler) {
        // ignore: avoid_print
        print('API Error: ${err.message}');
        if (err.response != null) {
          // ignore: avoid_print
          print(
              'API Error Response: ${err.response?.statusCode} ${err.response?.data}');
        }
        handler.next(err);
      },
    ));
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return dio.patch(path, data: data);
  }
}

class ResponseUnwrapInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is Map) {
      final map = response.data as Map;
      if (map.containsKey('success') && map.containsKey('data')) {
        response.data = map['data'];
      }
    }
    handler.next(response);
  }
}
