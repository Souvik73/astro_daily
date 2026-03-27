import 'package:equatable/equatable.dart';

import '../../../../core/services/contracts.dart';

class FeatureAccessDecision extends Equatable {
  const FeatureAccessDecision({
    required this.feature,
    required this.canOpen,
    required this.usedToday,
    required this.dailyQuota,
    this.message,
  });

  final AppFeature feature;
  final bool canOpen;
  final int usedToday;
  final int dailyQuota;
  final String? message;

  @override
  List<Object?> get props => <Object?>[
    feature,
    canOpen,
    usedToday,
    dailyQuota,
    message,
  ];
}
