import 'package:equatable/equatable.dart';

import '../../../../core/services/contracts.dart';

class HomeFeatureUsage extends Equatable {
  const HomeFeatureUsage({
    required this.feature,
    required this.usedToday,
    required this.dailyQuota,
    required this.canUse,
  });

  final AppFeature feature;
  final int usedToday;
  final int dailyQuota;
  final bool canUse;

  @override
  List<Object?> get props => <Object?>[feature, usedToday, dailyQuota, canUse];
}
