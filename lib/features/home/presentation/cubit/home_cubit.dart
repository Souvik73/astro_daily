import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/subscription_models.dart';
import '../../../../core/services/contracts.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/feature_access_decision.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/entities/home_feature_usage.dart';
import '../../domain/usecases/get_home_dashboard.dart';
import '../../domain/usecases/request_feature_access.dart';

enum HomeStatus { initial, loading, loaded, failure }

class HomeState extends Equatable {
  const HomeState({
    required this.status,
    this.user,
    this.featureUsage = const <HomeFeatureUsage>[],
    this.errorMessage,
  });

  const HomeState.initial() : this(status: HomeStatus.initial);

  final HomeStatus status;
  final User? user;
  final List<HomeFeatureUsage> featureUsage;
  final String? errorMessage;

  HomeState copyWith({
    HomeStatus? status,
    User? user,
    List<HomeFeatureUsage>? featureUsage,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      user: user ?? this.user,
      featureUsage: featureUsage ?? this.featureUsage,
      errorMessage: errorMessage,
    );
  }

  HomeFeatureUsage usageFor(AppFeature feature) {
    return featureUsage.firstWhere(
      (HomeFeatureUsage usage) => usage.feature == feature,
      orElse: () => HomeFeatureUsage(
        feature: feature,
        usedToday: 0,
        dailyQuota: 0,
        canUse: false,
      ),
    );
  }

  bool get isPremium => user?.tier == SubscriptionTier.premium;

  @override
  List<Object?> get props => <Object?>[
    status,
    user,
    featureUsage,
    errorMessage,
  ];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required GetHomeDashboard getHomeDashboard,
    required RequestFeatureAccess requestFeatureAccess,
  }) : _getHomeDashboard = getHomeDashboard,
       _requestFeatureAccess = requestFeatureAccess,
       super(const HomeState.initial());

  final GetHomeDashboard _getHomeDashboard;
  final RequestFeatureAccess _requestFeatureAccess;

  Future<void> loadDashboard() async {
    emit(state.copyWith(status: HomeStatus.loading, errorMessage: null));
    try {
      final HomeDashboard dashboard = await _getHomeDashboard(const NoParams());
      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          user: dashboard.user,
          featureUsage: dashboard.featureUsage,
          errorMessage: null,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Could not load home dashboard.',
        ),
      );
    }
  }

  Future<FeatureAccessDecision> openFeature(AppFeature feature) async {
    final FeatureAccessDecision decision = await _requestFeatureAccess(
      RequestFeatureAccessParams(feature: feature),
    );
    await loadDashboard();
    return decision;
  }
}
