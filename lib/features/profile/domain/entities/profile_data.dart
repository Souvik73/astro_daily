import 'package:equatable/equatable.dart';

import '../../../../core/models/subscription_models.dart';

class ProfileData extends Equatable {
  const ProfileData({
    required this.displayName,
    required this.email,
    required this.zodiacSign,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    required this.tier,
  });

  final String displayName;
  final String email;
  final String zodiacSign;
  final DateTime dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
  final SubscriptionTier tier;

  @override
  List<Object?> get props => <Object?>[
    displayName,
    email,
    zodiacSign,
    dateOfBirth,
    timeOfBirth,
    placeOfBirth,
    tier,
  ];
}
