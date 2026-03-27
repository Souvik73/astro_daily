import 'package:equatable/equatable.dart';

import '../../../../core/models/subscription_models.dart';

class SubscriptionOverview extends Equatable {
  const SubscriptionOverview({required this.tier, this.expiresAt});

  final SubscriptionTier tier;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => <Object?>[tier, expiresAt];
}
