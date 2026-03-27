import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum LoginFormStatus { initial, submitting, success, failure }

final class LoginFormState extends Equatable {
  const LoginFormState({
    required this.status,
    this.errorMessage,
  });

  const LoginFormState.initial()
      : this(
          status: LoginFormStatus.initial,
          errorMessage: null,
        );

  final LoginFormStatus status;
  final String? errorMessage;

  bool get isSubmitting => status == LoginFormStatus.submitting;

  LoginFormState copyWith({
    LoginFormStatus? status,
    String? errorMessage,
  }) {
    return LoginFormState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, errorMessage];
}

class LoginFormCubit extends Cubit<LoginFormState> {
  LoginFormCubit() : super(const LoginFormState.initial());

  void setSubmitting(bool isSubmitting) {
    emit(
      copyWith(
        status: isSubmitting
            ? LoginFormStatus.submitting
            : LoginFormStatus.initial,
      ),
    );
  }

  void setSuccess() {
    emit(
      state.copyWith(
        status: LoginFormStatus.success,
      ),
    );
  }

  void setFailure(String errorMessage) {
    emit(
      state.copyWith(
        status: LoginFormStatus.failure,
        errorMessage: errorMessage,
      ),
    );
  }

  void reset() {
    emit(const LoginFormState.initial());
  }

  LoginFormState copyWith({
    LoginFormStatus? status,
    String? errorMessage,
  }) {
    return LoginFormState(
      status: status ?? state.status,
      errorMessage: errorMessage ?? state.errorMessage,
    );
  }
}
