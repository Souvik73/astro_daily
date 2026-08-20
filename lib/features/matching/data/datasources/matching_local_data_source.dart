import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/models/birth_profile.dart';

abstract class MatchingLocalDataSource {
  Future<BirthProfile?> getSavedPartner();
  Future<void> savePartner(BirthProfile partner);
}

class MatchingLocalDataSourceImpl implements MatchingLocalDataSource {
  static const String _key = 'matching_partner_profile';

  @override
  Future<BirthProfile?> getSavedPartner() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) {
      return null;
    }
    try {
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      return BirthProfile(
        zodiacSign: json['zodiacSign'] as String,
        dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
        timeOfBirth: json['timeOfBirth'] as String,
        placeOfBirth: json['placeOfBirth'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePartner(BirthProfile partner) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(<String, dynamic>{
        'zodiacSign': partner.zodiacSign,
        'dateOfBirth': partner.dateOfBirth.toIso8601String(),
        'timeOfBirth': partner.timeOfBirth,
        'placeOfBirth': partner.placeOfBirth,
      }),
    );
  }
}
