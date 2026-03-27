import 'package:equatable/equatable.dart';

class KundliInsight extends Equatable {
  const KundliInsight({
    required this.sunSign,
    required this.moonSign,
    required this.ascendant,
    required this.focusArea,
  });

  final String sunSign;
  final String moonSign;
  final String ascendant;
  final String focusArea;

  @override
  List<Object?> get props => <Object?>[sunSign, moonSign, ascendant, focusArea];
}
