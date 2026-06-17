class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'A server error occurred.']);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache failure occurred.']);
}
