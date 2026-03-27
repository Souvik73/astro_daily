import 'package:equatable/equatable.dart';

import '../../../../core/models/subscription_models.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.zodiacSign,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    required this.tier,
  });

  final String id;
  final String email;
  final String displayName;
  final String zodiacSign;
  final DateTime dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
  final SubscriptionTier tier;

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? zodiacSign,
    DateTime? dateOfBirth,
    String? timeOfBirth,
    String? placeOfBirth,
    SubscriptionTier? tier,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      timeOfBirth: timeOfBirth ?? this.timeOfBirth,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      tier: tier ?? this.tier,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    email,
    displayName,
    zodiacSign,
    dateOfBirth,
    timeOfBirth,
    placeOfBirth,
    tier,
  ];
}
