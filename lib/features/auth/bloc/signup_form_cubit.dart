import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/birth_profile.dart';
import '../domain/entities/auth_profile.dart';
import '../domain/usecases/sign_in_with_apple.dart';
import '../domain/usecases/sign_in_with_google.dart';
import '../domain/usecases/sign_up_with_email.dart';
import 'signup_form_state.dart';

class SignupFormCubit extends Cubit<SignupFormState> {
  SignupFormCubit({
    required SignUpWithEmail signUpWithEmail,
    required SignInWithGoogle signInWithGoogle,
    required SignInWithApple signInWithApple,
  }) : _signUpWithEmail = signUpWithEmail,
       _signInWithGoogle = signInWithGoogle,
       _signInWithApple = signInWithApple,
       super(const SignupFormState.initial());

  final SignUpWithEmail _signUpWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;

  void onDateOfBirthSelected(DateTime dateOfBirth) {
    final String zodiacSign = BirthProfile.calculateZodiacSign(dateOfBirth);
    emit(state.copyWith(dateOfBirth: dateOfBirth, zodiacSign: zodiacSign));
  }

  void onTimeOfBirthSelected(String timeOfBirth) {
    emit(state.copyWith(timeOfBirth: timeOfBirth));
  }

  void onFormSubmitting() {
    emit(state.copyWith(status: SignupFormStatus.submitting));
  }

  void onFormSubmitSuccess() {
    emit(state.copyWith(status: SignupFormStatus.success));
  }

  void onFormSubmitFailure(String errorMessage) {
    emit(
      state.copyWith(
        status: SignupFormStatus.failure,
        errorMessage: errorMessage,
      ),
    );
  }

  void resetForm() {
    emit(const SignupFormState.initial());
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required AuthProfile profile,
  }) async {
    onFormSubmitting();
    try {
      await _signUpWithEmail(
        SignUpWithEmailParams(
          email: email,
          password: password,
          profile: profile,
        ),
      );
      onFormSubmitSuccess();
    } catch (error) {
      onFormSubmitFailure(error.toString());
    }
  }

  Future<void> signUpWithGoogle(AuthProfile profile) async {
    onFormSubmitting();
    try {
      await _signInWithGoogle(SignInWithGoogleParams(profile: profile));
      onFormSubmitSuccess();
    } catch (error) {
      onFormSubmitFailure(error.toString());
    }
  }

  Future<void> signUpWithApple(AuthProfile profile) async {
    onFormSubmitting();
    try {
      await _signInWithApple(SignInWithAppleParams(profile: profile));
      onFormSubmitSuccess();
    } catch (error) {
      onFormSubmitFailure(error.toString());
    }
  }
}
