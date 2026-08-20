import 'package:equatable/equatable.dart';

import '../../../../core/models/birth_profile.dart';

class MatchingResult extends Equatable {
  const MatchingResult({
    required this.score,
    required this.summary,
    required this.strengths,
    required this.partner,
  });

  final int score;
  final String summary;
  final List<String> strengths;
  final BirthProfile partner;

  @override
  List<Object?> get props => <Object?>[score, summary, strengths, partner];
}
