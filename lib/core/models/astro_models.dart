import 'package:equatable/equatable.dart';

class BirthDetails extends Equatable {
  const BirthDetails({
    required this.dateTime,
    required this.place,
    required this.zodiacSign,
  });

  final DateTime dateTime;
  final String place;
  final String zodiacSign;

  @override
  List<Object> get props => <Object>[dateTime, place, zodiacSign];
}

class CompatibilityRequest extends Equatable {
  const CompatibilityRequest({required this.primary, required this.partner});

  final BirthDetails primary;
  final BirthDetails partner;

  @override
  List<Object> get props => <Object>[primary, partner];
}

class DailyHoroscopeRequest extends Equatable {
  const DailyHoroscopeRequest({
    required this.zodiacSign,
    required this.date,
    required this.locale,
  });

  final String zodiacSign;
  final DateTime date;
  final String locale;

  @override
  List<Object> get props => <Object>[zodiacSign, date, locale];
}

class KundliData extends Equatable {
  const KundliData({
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
  List<Object> get props => <Object>[sunSign, moonSign, ascendant, focusArea];
}

class CompatibilityResult extends Equatable {
  const CompatibilityResult({
    required this.score,
    required this.summary,
    required this.strengths,
  });

  final int score;
  final String summary;
  final List<String> strengths;

  @override
  List<Object> get props => <Object>[score, summary, strengths];
}

class NumerologyResult extends Equatable {
  const NumerologyResult({
    required this.lifePathNumber,
    required this.personalDayNumber,
    required this.guidance,
  });

  final int lifePathNumber;
  final int personalDayNumber;
  final String guidance;

  @override
  List<Object> get props => <Object>[
    lifePathNumber,
    personalDayNumber,
    guidance,
  ];
}

class HoroscopeResponse extends Equatable {
  const HoroscopeResponse({
    required this.date,
    required this.zodiacSign,
    required this.locale,
    required this.summary,
    required this.luckyColor,
    required this.luckyNumber,
  });

  final DateTime date;
  final String zodiacSign;
  final String locale;
  final String summary;
  final String luckyColor;
  final int luckyNumber;

  @override
  List<Object> get props => <Object>[
    date,
    zodiacSign,
    locale,
    summary,
    luckyColor,
    luckyNumber,
  ];
}

class GemstoneReport extends Equatable {
  const GemstoneReport({
    required this.primaryStone,
    required this.alternativeStones,
    required this.rationale,
  });

  final String primaryStone;
  final List<String> alternativeStones;
  final String rationale;

  @override
  List<Object> get props => <Object>[
    primaryStone,
    alternativeStones,
    rationale,
  ];
}
