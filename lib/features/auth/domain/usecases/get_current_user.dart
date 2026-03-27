import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser implements UseCase<User?, NoParams> {
  GetCurrentUser(this._authRepository);

  final AuthRepository _authRepository;

  @override
  User? call(NoParams params) {
    return _authRepository.getCurrentUser();
  }
}
