import 'package:equatable/equatable.dart';

class DailyHoroscope extends Equatable {
  const DailyHoroscope({
    required this.date,
    required this.zodiacSign,
    required this.locale,
    required this.summary,
    required this.luckyColor,
    required this.luckyNumber,
    required this.dosDonts,
    required this.personalizedFocus,
  });

  final DateTime date;
  final String zodiacSign;
  final String locale;
  final String summary;
  final String luckyColor;
  final int luckyNumber;
  final List<String> dosDonts;
  final String personalizedFocus;

  @override
  List<Object?> get props => <Object?>[
    date,
    zodiacSign,
    locale,
    summary,
    luckyColor,
    luckyNumber,
    dosDonts,
    personalizedFocus,
  ];
}
