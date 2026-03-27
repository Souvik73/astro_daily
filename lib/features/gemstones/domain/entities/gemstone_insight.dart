import 'package:equatable/equatable.dart';

class GemstoneInsight extends Equatable {
  const GemstoneInsight({
    required this.primaryStone,
    required this.alternativeStones,
    required this.rationale,
    required this.summary,
    required this.ascendant,
    required this.focusArea,
  });

  final String primaryStone;
  final List<String> alternativeStones;
  final String rationale;
  final String summary;
  final String ascendant;
  final String focusArea;

  @override
  List<Object?> get props => <Object?>[
    primaryStone,
    alternativeStones,
    rationale,
    summary,
    ascendant,
    focusArea,
  ];
}
