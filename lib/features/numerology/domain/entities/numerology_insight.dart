import 'package:equatable/equatable.dart';

class NumerologyInsight extends Equatable {
  const NumerologyInsight({
    required this.lifePathNumber,
    required this.personalDayNumber,
    required this.guidance,
  });

  final int lifePathNumber;
  final int personalDayNumber;
  final String guidance;

  @override
  List<Object?> get props => <Object?>[
    lifePathNumber,
    personalDayNumber,
    guidance,
  ];
}
