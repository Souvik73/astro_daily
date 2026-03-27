import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SignOut implements UseCase<Future<void>, NoParams> {
  SignOut(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<void> call(NoParams params) {
    return _authRepository.signOut();
  }
}
