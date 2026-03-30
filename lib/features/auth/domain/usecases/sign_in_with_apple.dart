import '../../../../core/usecase/usecase.dart';
import '../entities/auth_profile.dart';
import '../repositories/auth_repository.dart';

class SignInWithApple implements UseCase<Future<void>, SignInWithAppleParams> {
  SignInWithApple(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<void> call(SignInWithAppleParams params) {
    return _authRepository.signInWithApple(profile: params.profile);
  }
}

class SignInWithAppleParams {
  const SignInWithAppleParams({this.profile});

  final AuthProfile? profile;
}