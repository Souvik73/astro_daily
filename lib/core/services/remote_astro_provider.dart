import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/failures.dart';
import '../models/astro_models.dart';
import 'contracts.dart';

/// Real implementation of [AstroProvider].
/// All data comes from the user's birth chart cached in Supabase (birth_charts table).
/// Chart is computed server-side on profile completion via the compute-chart edge function.
class RemoteAstroProvider implements AstroProvider {
  RemoteAstroProvider({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Future<KundliData> getKundli(BirthDetails birthDetails) async {
    final Map<String, dynamic> data = await _invoke(
      body: <String, dynamic>{'kind': 'kundli'},
    );
    return KundliData(
      sunSign: _str(data['sunSign'], birthDetails.zodiacSign),
      moonSign: _str(data['moonSign'], 'Aries'),
      ascendant: _str(data['ascendant'], birthDetails.zodiacSign),
      focusArea: _str(data['focusArea'], 'Career & Status'),
    );
  }

  @override
  Future<HoroscopeResponse> getDailyHoroscope(
    DailyHoroscopeRequest request,
  ) async {
    final Map<String, dynamic> data = await _invoke(
      body: <String, dynamic>{
        'kind': 'horoscope',
        'locale': request.locale,
      },
    );
    return HoroscopeResponse(
      date: request.date,
      zodiacSign: _str(data['sunSign'], request.zodiacSign),
      locale: request.locale,
      summary: _str(data['summary'], 'A powerful day for reflection and action.'),
      luckyColor: _str(data['luckyColor'], 'Gold'),
      luckyNumber: (data['luckyNumber'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  Future<NumerologyResult> getNumerology(BirthDetails birthDetails) async {
    final Map<String, dynamic> data = await _invoke(
      body: <String, dynamic>{'kind': 'numerology'},
    );

    final int lifePath = (data['lifePathNumber'] as num?)?.toInt() ?? 1;
    final int lucky = (data['luckyNumber'] as num?)?.toInt() ?? lifePath;
    final String meaning = _str(data['meaning'], 'A unique life path with great potential.');

    return NumerologyResult(
      lifePathNumber: lifePath,
      personalDayNumber: lucky,
      guidance: meaning,
    );
  }

  @override
  Future<CompatibilityResult> getCompatibility(
    CompatibilityRequest request,
  ) async {
    final DateTime pDOB = request.partner.dateTime;
    final String partnerDob =
        '${pDOB.year.toString().padLeft(4, '0')}-'
        '${pDOB.month.toString().padLeft(2, '0')}-'
        '${pDOB.day.toString().padLeft(2, '0')}';
    final String partnerTob =
        '${pDOB.hour.toString().padLeft(2, '0')}:'
        '${pDOB.minute.toString().padLeft(2, '0')}';

    final Map<String, dynamic> data = await _invoke(
      body: <String, dynamic>{
        'kind': 'compatibility',
        'partnerDob': partnerDob,
        'partnerTob': partnerTob,
        'partnerPlace': request.partner.place,
      },
    );

    final int score = (data['score'] as num?)?.toInt() ?? 60;
    final String rating = _str(data['rating'], 'Good');
    final String description = _str(data['description'], 'Positive cosmic alignment.');

    return CompatibilityResult(
      score: score,
      summary: '$rating — $description',
      strengths: <String>[
        'Shared elemental energy',
        'Compatible moon signs',
        'Complementary dasha cycles',
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _invoke({
    required Map<String, dynamic> body,
  }) async {
    try {
      final FunctionResponse response =
          await _supabase.functions.invoke('astro', body: body);

      if (response.data is Map) {
        final dynamic error = (response.data as Map)['error'];
        if (error == 'chart_missing') throw const AiChartMissingFailure();
      }

      return (response.data as Map<String, dynamic>?) ?? <String, dynamic>{};
    } on AiChartMissingFailure {
      rethrow;
    } on FunctionException catch (e) {
      // supabase_flutter throws FunctionException for non-2xx edge function
      // responses before response.data can be inspected.
      if (e.status == 422) throw const AiChartMissingFailure();
      throw DataFailure('Failed to load astrology data (${e.status}).');
    } catch (e) {
      throw DataFailure('Failed to load astrology data: $e');
    }
  }

  String _str(dynamic value, String fallback) =>
      (value is String && value.isNotEmpty) ? value : fallback;
}
