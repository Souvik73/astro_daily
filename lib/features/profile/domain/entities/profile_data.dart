import 'package:equatable/equatable.dart';

import '../../../../core/models/birth_profile.dart';
import '../../../../core/models/subscription_models.dart';

class ProfileData extends Equatable {
  const ProfileData({
    required this.displayName,
    required this.email,
    required this.birthProfile,
    required this.tier,
  });

  final String displayName;
  final String email;
  final BirthProfile birthProfile;
  final SubscriptionTier tier;

  String get zodiacSign => birthProfile.zodiacSign;
  DateTime get dateOfBirth => birthProfile.dateOfBirth;
  String get timeOfBirth => birthProfile.timeOfBirth;
  String get placeOfBirth => birthProfile.placeOfBirth;

  @override
  List<Object?> get props => <Object?>[displayName, email, birthProfile, tier];
}
