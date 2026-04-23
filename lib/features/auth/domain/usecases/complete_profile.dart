import '../../../../core/usecase/usecase.dart';
import '../entities/auth_profile.dart';
import '../repositories/auth_repository.dart';

class CompleteProfile implements UseCase<Future<void>, CompleteProfileParams> {
  CompleteProfile(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<void> call(CompleteProfileParams params) {
    return _authRepository.completeProfile(params.profile);
  }
}

class CompleteProfileParams {
  const CompleteProfileParams({required this.profile});

  final AuthProfile profile;
}
