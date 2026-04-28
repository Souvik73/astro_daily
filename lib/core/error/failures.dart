import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable implements Exception {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];

  @override
  String toString() => message;
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class DataFailure extends Failure {
  const DataFailure(super.message);
}

/// Thrown when the server rejects the request because the user's daily
/// chat quota has been exhausted.
class AiQuotaExceededFailure extends Failure {
  const AiQuotaExceededFailure()
      : super('Daily question limit reached. Upgrade to Premium for more.');
}

/// Thrown when the AI service (Gemini) is temporarily unavailable.
class AiUnavailableFailure extends Failure {
  const AiUnavailableFailure([String message = 'AI is temporarily unavailable. Please try again shortly.'])
      : super(message);
}

/// Thrown when the user has not yet completed their birth profile, so no
/// natal chart exists in the database.
class AiChartMissingFailure extends Failure {
  const AiChartMissingFailure()
      : super('Please complete your birth profile to use this feature.');
}
