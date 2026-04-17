class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.isUnauthorized = false});

  final String message;
  final int? statusCode;
  final bool isUnauthorized;

  @override
  String toString() => message;
}
