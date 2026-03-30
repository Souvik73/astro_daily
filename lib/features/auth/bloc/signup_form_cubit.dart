import 'package:flutter_bloc/flutter_bloc.dart';

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

  String _calculateZodiacSign(DateTime dateOfBirth) {
    final int month = dateOfBirth.month;
    final int day = dateOfBirth.day;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
      return 'Aries';
    } else if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
      return 'Taurus';
    } else if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
      return 'Gemini';
    } else if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
      return 'Cancer';
    } else if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
      return 'Leo';
    } else if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
      return 'Virgo';
    } else if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
      return 'Libra';
    } else if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
      return 'Scorpio';
    } else if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
      return 'Sagittarius';
    } else if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
      return 'Capricorn';
    } else if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      return 'Aquarius';
    } else {
      return 'Pisces';
    }
  }

  void onDateOfBirthSelected(DateTime dateOfBirth) {
    final String zodiacSign = _calculateZodiacSign(dateOfBirth);
    emit(
      state.copyWith(
        dateOfBirth: dateOfBirth,
        zodiacSign: zodiacSign,
      ),
    );
  }

  void onTimeOfBirthSelected(String timeOfBirth) {
    emit(
      state.copyWith(
        timeOfBirth: timeOfBirth,
      ),
    );
  }

  void onFormSubmitting() {
    emit(
      state.copyWith(
        status: SignupFormStatus.submitting,
      ),
    );
  }

  void onFormSubmitSuccess() {
    emit(
      state.copyWith(
        status: SignupFormStatus.success,
      ),
    );
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
