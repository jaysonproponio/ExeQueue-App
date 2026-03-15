class ServerException implements Exception {
  const ServerException([this.message = 'Server error occurred.']);

  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error occurred.']);

  final String message;
}

class NotificationException implements Exception {
  const NotificationException([this.message = 'Notification error occurred.']);

  final String message;
}

class ParsingException implements Exception {
  const ParsingException([this.message = 'Response parsing failed.']);

  final String message;
}
