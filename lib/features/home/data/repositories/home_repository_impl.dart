import '../../../../core/error/failures.dart';
import '../../../../core/services/contracts.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/feature_access_decision.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/entities/home_feature_usage.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    required HomeLocalDataSource localDataSource,
    required AuthRepository authRepository,
  })  : _localDataSource = localDataSource,
        _authRepository = authRepository;

  final HomeLocalDataSource _localDataSource;
  final AuthRepository _authRepository;

  /// Surfaces rendered on the home dashboard, in display order.
  static const List<AppFeature> _supportedFeatures = <AppFeature>[
    AppFeature.dailyHoroscope,
    AppFeature.kundli,
    AppFeature.matching,
    AppFeature.numerology,
    AppFeature.gemstones,
    AppFeature.horoscopeChat,
  ];

  @override
  Future<HomeDashboard> getDashboard() async {
    final User user = _requireUser();
    final List<HomeFeatureUsage> usage = _supportedFeatures
        .map((AppFeature feature) => _usageFor(user.id, feature))
        .toList(growable: false);
    return HomeDashboard(user: user, featureUsage: usage);
  }

  @override
  Future<FeatureAccessDecision> requestFeatureAccess(AppFeature feature) async {
    final User user = _requireUser();
    final FeatureAccess access = _localDataSource.resolveAccess(
      user.id,
      feature,
    );
    if (access == FeatureAccess.open) {
      _localDataSource.recordUsage(user.id, feature);
      return FeatureAccessDecision(
        feature: feature,
        access: FeatureAccess.open,
        usage: _usageFor(user.id, feature),
      );
    }
    return FeatureAccessDecision(
      feature: feature,
      access: access,
      usage: _usageFor(user.id, feature),
      message: access == FeatureAccess.rewardUnlockAvailable
          ? 'Free quota reached. Watch a short ad to unlock more.'
          : 'Free access is spent for this period. Upgrade to Premium for '
              'unlimited use.',
    );
  }

  @override
  Future<FeatureAccessDecision> grantFeatureReward(AppFeature feature) async {
    final User user = _requireUser();
    _localDataSource.recordRewardGranted(user.id, feature);
    return FeatureAccessDecision(
      feature: feature,
      access: _localDataSource.resolveAccess(user.id, feature),
      usage: _usageFor(user.id, feature),
    );
  }

  User _requireUser() {
    final User? user = _authRepository.getCurrentUser();
    if (user == null) {
      throw const AuthFailure('User session expired. Please sign in again.');
    }
    return user;
  }

  HomeFeatureUsage _usageFor(String userId, AppFeature feature) {
    final FeatureQuotaStatus status = _localDataSource.statusFor(
      userId,
      feature,
    );
    return HomeFeatureUsage(
      feature: status.feature,
      period: status.period,
      used: status.used,
      quota: status.quota,
      rewardsGranted: status.rewardsGranted,
      rewardCap: status.rewardCap,
      access: status.access,
    );
  }
}
