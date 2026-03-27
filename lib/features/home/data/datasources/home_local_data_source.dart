import '../../../../core/services/contracts.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

abstract class HomeLocalDataSource {
  String currentUserId();
  int usedToday(String userId, AppFeature feature);
  int dailyQuotaFor(AppFeature feature);
  bool canUseFeature(String userId, AppFeature feature);
  void recordUsage(String userId, AppFeature feature);
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  HomeLocalDataSourceImpl({
    required UsagePolicy usagePolicy,
    required AuthRepository authRepository,
  }) : _usagePolicy = usagePolicy,
       _authRepository = authRepository;

  final UsagePolicy _usagePolicy;
  final AuthRepository _authRepository;

  @override
  bool canUseFeature(String userId, AppFeature feature) {
    return _usagePolicy.canUseFeature(userId, feature);
  }

  @override
  String currentUserId() {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw StateError('User not found');
    }
    return user.id;
  }

  @override
  int dailyQuotaFor(AppFeature feature) {
    return _usagePolicy.dailyQuotaFor(feature);
  }

  @override
  void recordUsage(String userId, AppFeature feature) {
    _usagePolicy.recordUsage(userId, feature);
  }

  @override
  int usedToday(String userId, AppFeature feature) {
    return _usagePolicy.usedToday(userId, feature);
  }
}
