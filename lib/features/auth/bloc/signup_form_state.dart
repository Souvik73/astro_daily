import 'package:equatable/equatable.dart';

enum SignupFormStatus { initial, submitting, success, failure }

final class SignupFormState extends Equatable {
  const SignupFormState({
    required this.status,
    this.dateOfBirth,
    this.timeOfBirth,
    this.zodiacSign = '',
    this.errorMessage,
  });

  const SignupFormState.initial()
      : this(
          status: SignupFormStatus.initial,
          dateOfBirth: null,
          timeOfBirth: null,
          zodiacSign: '',
          errorMessage: null,
        );

  final SignupFormStatus status;
  final DateTime? dateOfBirth;
  final String? timeOfBirth;
  final String zodiacSign;
  final String? errorMessage;

  SignupFormState copyWith({
    SignupFormStatus? status,
    DateTime? dateOfBirth,
    String? timeOfBirth,
    String? zodiacSign,
    String? errorMessage,
  }) {
    return SignupFormState(
      status: status ?? this.status,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      timeOfBirth: timeOfBirth ?? this.timeOfBirth,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        dateOfBirth,
        timeOfBirth,
        zodiacSign,
        errorMessage,
      ];
}
