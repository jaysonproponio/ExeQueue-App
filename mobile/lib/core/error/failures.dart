import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object> get props => <Object>[message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cached data is unavailable.']);
}

class NotificationFailure extends Failure {
  const NotificationFailure([super.message = 'Notification setup failed.']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error occurred.']);
}
