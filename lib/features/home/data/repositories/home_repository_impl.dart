import '../../../../core/error/failures.dart';
import '../../../../core/services/contracts.dart';
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
  }) : _localDataSource = localDataSource,
       _authRepository = authRepository;

  final HomeLocalDataSource _localDataSource;
  final AuthRepository _authRepository;

  static const List<AppFeature> _supportedFeatures = <AppFeature>[
    AppFeature.dailyHoroscope,
    AppFeature.kundli,
    AppFeature.matching,
    AppFeature.numerology,
    AppFeature.gemstones,
  ];

  @override
  Future<HomeDashboard> getDashboard() async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw const AuthFailure('User session expired. Please sign in again.');
    }

    final List<HomeFeatureUsage> usage = _supportedFeatures
        .map(
          (AppFeature feature) => HomeFeatureUsage(
            feature: feature,
            usedToday: _localDataSource.usedToday(user.id, feature),
            dailyQuota: _localDataSource.dailyQuotaFor(feature),
            canUse: _localDataSource.canUseFeature(user.id, feature),
          ),
        )
        .toList(growable: false);

    return HomeDashboard(user: user, featureUsage: usage);
  }

  @override
  Future<FeatureAccessDecision> requestFeatureAccess(AppFeature feature) async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw const AuthFailure('User session expired. Please sign in again.');
    }

    final bool canUse = _localDataSource.canUseFeature(user.id, feature);
    if (!canUse) {
      return FeatureAccessDecision(
        feature: feature,
        canOpen: false,
        usedToday: _localDataSource.usedToday(user.id, feature),
        dailyQuota: _localDataSource.dailyQuotaFor(feature),
        message: 'Daily free quota reached.',
      );
    }

    _localDataSource.recordUsage(user.id, feature);
    return FeatureAccessDecision(
      feature: feature,
      canOpen: true,
      usedToday: _localDataSource.usedToday(user.id, feature),
      dailyQuota: _localDataSource.dailyQuotaFor(feature),
    );
  }
}
