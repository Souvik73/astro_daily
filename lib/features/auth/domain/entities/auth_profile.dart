import 'package:equatable/equatable.dart';

import '../../../../core/models/birth_profile.dart';

class AuthProfile extends Equatable {
  const AuthProfile({required this.displayName, required this.birthProfile});

  final String displayName;
  final BirthProfile birthProfile;

  @override
  List<Object?> get props => <Object?>[displayName, birthProfile];
}
