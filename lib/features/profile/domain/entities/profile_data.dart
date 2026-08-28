import 'package:equatable/equatable.dart';

import '../../../../core/models/birth_profile.dart';
import '../../../../core/models/subscription_models.dart';

class ProfileData extends Equatable {
  const ProfileData({
    required this.displayName,
    required this.email,
    required this.birthProfile,
    required this.tier,
    this.birthDetailsEditableAfter,
  });

  final String displayName;
  final String email;
  final BirthProfile birthProfile;
  final SubscriptionTier tier;

  /// Earliest time DOB/time/place can be changed again, mirroring the
  /// server's own 24-hour cooldown in `compute-chart`. Null means never
  /// computed yet (no lock) or the timestamp couldn't be read.
  final DateTime? birthDetailsEditableAfter;

  String get zodiacSign => birthProfile.zodiacSign;
  DateTime get dateOfBirth => birthProfile.dateOfBirth;
  String get timeOfBirth => birthProfile.timeOfBirth;
  String get placeOfBirth => birthProfile.placeOfBirth;

  bool get isBirthDetailsLocked {
    final DateTime? editableAfter = birthDetailsEditableAfter;
    return editableAfter != null && DateTime.now().isBefore(editableAfter);
  }

  @override
  List<Object?> get props => <Object?>[
    displayName,
    email,
    birthProfile,
    tier,
    birthDetailsEditableAfter,
  ];
}
