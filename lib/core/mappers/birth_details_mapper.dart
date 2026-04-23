import '../models/astro_models.dart';
import '../models/birth_profile.dart';

class BirthDetailsMapper {
  const BirthDetailsMapper();

  BirthDetails map(BirthProfile birthProfile) {
    final _ParsedTime parsedTime = _parseTime(birthProfile.timeOfBirth);
    return BirthDetails(
      dateTime: DateTime(
        birthProfile.dateOfBirth.year,
        birthProfile.dateOfBirth.month,
        birthProfile.dateOfBirth.day,
        parsedTime.hour,
        parsedTime.minute,
      ),
      place: birthProfile.placeOfBirth,
      zodiacSign: birthProfile.zodiacSign,
    );
  }

  _ParsedTime _parseTime(String value) {
    final RegExpMatch? match = RegExp(
      r'^(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?$',
    ).firstMatch(value.trim());

    if (match == null) {
      throw const FormatException(
        'Birth time must use HH:mm or h:mm AM/PM format.',
      );
    }

    int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    final String meridiem = (match.group(3) ?? '').toUpperCase();

    if (minute < 0 || minute > 59) {
      throw const FormatException(
        'Birth time minute must be between 00 and 59.',
      );
    }

    if (meridiem.isEmpty) {
      if (hour < 0 || hour > 23) {
        throw const FormatException(
          'Birth time hour must be between 00 and 23.',
        );
      }
      return _ParsedTime(hour: hour, minute: minute);
    }

    if (hour < 1 || hour > 12) {
      throw const FormatException('Birth time hour must be between 1 and 12.');
    }

    if (meridiem == 'PM' && hour != 12) {
      hour += 12;
    } else if (meridiem == 'AM' && hour == 12) {
      hour = 0;
    }

    return _ParsedTime(hour: hour, minute: minute);
  }
}

class _ParsedTime {
  const _ParsedTime({required this.hour, required this.minute});

  final int hour;
  final int minute;
}
