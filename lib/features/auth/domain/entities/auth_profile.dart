import 'package:equatable/equatable.dart';

class AuthProfile extends Equatable {
  const AuthProfile({
    required this.displayName,
    required this.zodiacSign,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
  });

  final String displayName;
  final String zodiacSign;
  final DateTime dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;

  @override
  List<Object?> get props => <Object?>[
    displayName,
    zodiacSign,
    dateOfBirth,
    timeOfBirth,
    placeOfBirth,
  ];
}