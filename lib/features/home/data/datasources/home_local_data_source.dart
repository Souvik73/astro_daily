import '../../../../core/services/contracts.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

abstract class HomeLocalDataSource {
  String currentUserId();
  FeatureQuotaStatus statusFor(String userId, AppFeature feature);
  FeatureAccess resolveAccess(String userId, AppFeature feature);
  void recordUsage(String userId, AppFeature feature);
  void recordRewardGranted(String userId, AppFeature feature);
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  HomeLocalDataSourceImpl({
    required UsagePolicy usagePolicy,
    required AuthRepository authRepository,
  })  : _usagePolicy = usagePolicy,
        _authRepository = authRepository;

  final UsagePolicy _usagePolicy;
  final AuthRepository _authRepository;

  @override
  String currentUserId() {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw StateError('User not found');
    }
    return user.id;
  }

  @override
  FeatureQuotaStatus statusFor(String userId, AppFeature feature) {
    return _usagePolicy.statusFor(userId, feature);
  }

  @override
  FeatureAccess resolveAccess(String userId, AppFeature feature) {
    return _usagePolicy.resolveAccess(userId, feature);
  }

  @override
  void recordUsage(String userId, AppFeature feature) {
    _usagePolicy.recordUsage(userId, feature);
  }

  @override
  void recordRewardGranted(String userId, AppFeature feature) {
    _usagePolicy.recordRewardGranted(userId, feature);
  }
}
