import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/usecases/sign_in_with_apple.dart';
import '../domain/usecases/sign_in_with_email.dart';
import '../domain/usecases/sign_in_with_google.dart';

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
  LoginFormCubit({
    required SignInWithEmail signInWithEmail,
    required SignInWithGoogle signInWithGoogle,
    required SignInWithApple signInWithApple,
  }) : _signInWithEmail = signInWithEmail,
       _signInWithGoogle = signInWithGoogle,
       _signInWithApple = signInWithApple,
       super(const LoginFormState.initial());

  final SignInWithEmail _signInWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;

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

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(const LoginFormState(status: LoginFormStatus.submitting));
    try {
      await _signInWithEmail(
        SignInWithEmailParams(email: email, password: password),
      );
      emit(
        const LoginFormState(
          status: LoginFormStatus.success,
        ),
      );
    } catch (error) {
      emit(
        LoginFormState(
          status: LoginFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const LoginFormState(status: LoginFormStatus.submitting));
    try {
      await _signInWithGoogle(const SignInWithGoogleParams());
      emit(
        const LoginFormState(
          status: LoginFormStatus.success,
        ),
      );
    } catch (error) {
      emit(
        LoginFormState(
          status: LoginFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> signInWithApple() async {
    emit(const LoginFormState(status: LoginFormStatus.submitting));
    try {
      await _signInWithApple(const SignInWithAppleParams());
      emit(
        const LoginFormState(
          status: LoginFormStatus.success,
        ),
      );
    } catch (error) {
      emit(
        LoginFormState(
          status: LoginFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
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
