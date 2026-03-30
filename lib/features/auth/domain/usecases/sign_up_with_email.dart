import '../../../../core/usecase/usecase.dart';
import '../entities/auth_profile.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmail
    implements UseCase<Future<void>, SignUpWithEmailParams> {
  SignUpWithEmail(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<void> call(SignUpWithEmailParams params) {
    return _authRepository.signUpWithEmail(
      email: params.email,
      password: params.password,
      profile: params.profile,
    );
  }
}

class SignUpWithEmailParams {
  const SignUpWithEmailParams({
    required this.email,
    required this.password,
    required this.profile,
  });

  final String email;
  final String password;
  final AuthProfile profile;
}