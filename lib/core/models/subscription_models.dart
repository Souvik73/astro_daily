import 'package:equatable/equatable.dart';

enum SubscriptionTier { free, premium }

enum PlanType { monthly, yearly }

enum PurchaseStatus { success, cancelled, failed }

class SubscriptionEntitlement extends Equatable {
  const SubscriptionEntitlement({required this.tier, this.expiresAt});

  final SubscriptionTier tier;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => <Object?>[tier, expiresAt];
}
