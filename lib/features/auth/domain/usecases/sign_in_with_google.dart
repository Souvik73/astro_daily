import '../../../../core/usecase/usecase.dart';
import '../entities/auth_profile.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle
    implements UseCase<Future<void>, SignInWithGoogleParams> {
  SignInWithGoogle(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<void> call(SignInWithGoogleParams params) {
    return _authRepository.signInWithGoogle(profile: params.profile);
  }
}

class SignInWithGoogleParams {
  const SignInWithGoogleParams({this.profile});

  final AuthProfile? profile;
}