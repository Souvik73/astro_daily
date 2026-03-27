import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class ObserveAuthState implements UseCase<Stream<User?>, NoParams> {
  ObserveAuthState(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Stream<User?> call(NoParams params) {
    return _authRepository.observeAuthState();
  }
}
