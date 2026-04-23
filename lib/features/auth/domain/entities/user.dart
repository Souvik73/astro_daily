import 'package:equatable/equatable.dart';

import '../../../../core/models/birth_profile.dart';
import '../../../../core/models/subscription_models.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.tier,
    this.birthProfile,
  });

  static const Object _birthProfileSentinel = Object();

  final String id;
  final String email;
  final String displayName;
  final SubscriptionTier tier;
  final BirthProfile? birthProfile;

  bool get needsProfileCompletion => birthProfile == null;
  String get zodiacSign => _requireBirthProfile().zodiacSign;
  DateTime get dateOfBirth => _requireBirthProfile().dateOfBirth;
  String get timeOfBirth => _requireBirthProfile().timeOfBirth;
  String get placeOfBirth => _requireBirthProfile().placeOfBirth;

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    SubscriptionTier? tier,
    Object? birthProfile = _birthProfileSentinel,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      tier: tier ?? this.tier,
      birthProfile: identical(birthProfile, _birthProfileSentinel)
          ? this.birthProfile
          : birthProfile as BirthProfile?,
    );
  }

  BirthProfile _requireBirthProfile() {
    final BirthProfile? value = birthProfile;
    if (value == null) {
      throw StateError('Birth details are incomplete for this user.');
    }
    return value;
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    email,
    displayName,
    tier,
    birthProfile,
  ];
}
