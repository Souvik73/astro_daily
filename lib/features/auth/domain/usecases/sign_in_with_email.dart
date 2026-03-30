import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmail implements UseCase<Future<void>, SignInWithEmailParams> {
  SignInWithEmail(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<void> call(SignInWithEmailParams params) {
    return _authRepository.signInWithEmail(params.email, params.password);
  }
}

class SignInWithEmailParams {
  const SignInWithEmailParams({required this.email, required this.password});

  final String email;
  final String password;
}
