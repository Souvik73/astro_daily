import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/subscription_models.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/subscription_overview.dart';
import '../../domain/usecases/get_subscription_overview.dart';
import '../../domain/usecases/purchase_subscription_plan.dart';
import '../../domain/usecases/restore_subscription_purchases.dart';

enum SubscriptionStatusState { initial, loading, success, failure }

class SubscriptionState extends Equatable {
  const SubscriptionState({
    required this.status,
    this.overview,
    this.errorMessage,
    this.infoMessage,
  });

  const SubscriptionState.initial()
    : this(status: SubscriptionStatusState.initial);

  final SubscriptionStatusState status;
  final SubscriptionOverview? overview;
  final String? errorMessage;
  final String? infoMessage;

  SubscriptionState copyWith({
    SubscriptionStatusState? status,
    SubscriptionOverview? overview,
    String? errorMessage,
    String? infoMessage,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    overview,
    errorMessage,
    infoMessage,
  ];
}

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({
    required GetSubscriptionOverview getSubscriptionOverview,
    required PurchaseSubscriptionPlan purchaseSubscriptionPlan,
    required RestoreSubscriptionPurchases restoreSubscriptionPurchases,
  }) : _getSubscriptionOverview = getSubscriptionOverview,
       _purchaseSubscriptionPlan = purchaseSubscriptionPlan,
       _restoreSubscriptionPurchases = restoreSubscriptionPurchases,
       super(const SubscriptionState.initial());

  final GetSubscriptionOverview _getSubscriptionOverview;
  final PurchaseSubscriptionPlan _purchaseSubscriptionPlan;
  final RestoreSubscriptionPurchases _restoreSubscriptionPurchases;

  Future<void> loadOverview() async {
    emit(
      state.copyWith(
        status: SubscriptionStatusState.loading,
        errorMessage: null,
        infoMessage: null,
      ),
    );
    try {
      final SubscriptionOverview overview = await _getSubscriptionOverview(
        const NoParams(),
      );
      emit(
        state.copyWith(
          status: SubscriptionStatusState.success,
          overview: overview,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: SubscriptionStatusState.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SubscriptionStatusState.failure,
          errorMessage: 'Unable to load subscription details.',
        ),
      );
    }
  }

  Future<void> purchase(PlanType planType) async {
    emit(
      state.copyWith(
        status: SubscriptionStatusState.loading,
        errorMessage: null,
        infoMessage: null,
      ),
    );
    try {
      final SubscriptionOverview overview = await _purchaseSubscriptionPlan(
        PurchaseSubscriptionPlanParams(planType: planType),
      );
      emit(
        state.copyWith(
          status: SubscriptionStatusState.success,
          overview: overview,
          infoMessage:
              'Premium active until ${overview.expiresAt?.toLocal().toString().split(' ').first ?? 'N/A'}.',
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: SubscriptionStatusState.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SubscriptionStatusState.failure,
          errorMessage: 'Purchase could not be completed.',
        ),
      );
    }
  }

  Future<void> restore() async {
    emit(
      state.copyWith(
        status: SubscriptionStatusState.loading,
        errorMessage: null,
        infoMessage: null,
      ),
    );
    try {
      final SubscriptionOverview overview = await _restoreSubscriptionPurchases(
        const NoParams(),
      );
      emit(
        state.copyWith(
          status: SubscriptionStatusState.success,
          overview: overview,
          infoMessage: 'Purchases restored.',
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: SubscriptionStatusState.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SubscriptionStatusState.failure,
          errorMessage: 'Unable to restore purchases.',
        ),
      );
    }
  }

  void clearMessages() {
    emit(state.copyWith(infoMessage: null, errorMessage: null));
  }
}
