abstract class Failure {
  final String message;
  const Failure(this.message);
}
class NetworkFailure extends Failure { const NetworkFailure([String msg = 'No internet connection']) : super(msg); }
class ServerFailure extends Failure { const ServerFailure([String msg = 'Server error occurred']) : super(msg); }
class AuthFailure extends Failure { const AuthFailure([String msg = 'Authentication failed']) : super(msg); }
class ValidationFailure extends Failure { const ValidationFailure([String msg = 'Validation failed']) : super(msg); }
class CacheFailure extends Failure { const CacheFailure([String msg = 'Local storage error']) : super(msg); }
class NotFoundFailure extends Failure { const NotFoundFailure([String msg = 'Not found']) : super(msg); }
class UnknownFailure extends Failure { const UnknownFailure([String msg = 'Unknown error']) : super(msg); }
class ServerException implements Exception { final String message; const ServerException(this.message); }
