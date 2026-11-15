class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException()
      : super('Session expired. Please log in again.', statusCode: 401);
}

class ForbiddenException extends AppException {
  const ForbiddenException()
      : super('You do not have permission to do this.', statusCode: 403);
}

class NetworkException extends AppException {
  const NetworkException()
      : super('Internet connection unavailable. Please check your network.');
}

class ServerException extends AppException {
  // ignore: use_super_parameters
  const ServerException([String msg = 'Server error. Please try again.'])
      : super(msg, statusCode: 500);
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.statusCode});
}
