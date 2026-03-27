import 'package:equatable/equatable.dart';

class MatchingResult extends Equatable {
  const MatchingResult({
    required this.score,
    required this.summary,
    required this.strengths,
  });

  final int score;
  final String summary;
  final List<String> strengths;

  @override
  List<Object?> get props => <Object?>[score, summary, strengths];
}
