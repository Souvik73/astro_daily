import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/failures.dart';
import '../models/astro_models.dart';
import 'contracts.dart';

/// Real AI implementation of [AiPersonalizer].
/// Routes all calls through Supabase edge functions so no API key ever
/// touches the Flutter binary.
class RemoteAiPersonalizer implements AiPersonalizer {
  RemoteAiPersonalizer({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  // ── Chat ─────────────────────────────────────────────────────────────────────

  @override
  Future<String> answerHoroscopeQuestion(
    String question, {
    required HoroscopeResponse horoscope,
    required String locale,
    List<Map<String, String>> chatHistory = const <Map<String, String>>[],
  }) async {
    try {
      final FunctionResponse response = await _supabase.functions.invoke(
        'chat',
        body: <String, dynamic>{
          'question': question,
          'history': chatHistory,
          'locale': locale,
        },
      );

      // Handle server-side error codes returned in a 2xx body
      if (response.data is Map) {
        final String? error = (response.data as Map)['error'] as String?;
        if (error == 'quota_exceeded') throw const AiQuotaExceededFailure();
        if (error == 'chart_missing') throw const AiChartMissingFailure();
        if (error == 'ai_unavailable') {
          throw AiUnavailableFailure(
            (response.data as Map)['message'] as String? ??
                'AI is temporarily unavailable.',
          );
        }
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      return data['reply'] as String? ?? '';
    } on AiQuotaExceededFailure {
      rethrow;
    } on AiChartMissingFailure {
      rethrow;
    } on AiUnavailableFailure {
      rethrow;
    } on FunctionException catch (e) {
      // supabase_flutter throws FunctionException for non-2xx edge function
      // responses before response.data can be inspected.
      if (e.status == 402) throw const AiQuotaExceededFailure();
      if (e.status == 422) throw const AiChartMissingFailure();
      if (e.status == 503) {
        final String? msg =
            e.details is Map ? (e.details as Map)['message'] as String? : null;
        throw AiUnavailableFailure(
            msg ?? 'AI is temporarily unavailable. Please try again.');
      }
      throw AiUnavailableFailure('Could not reach the AI service.');
    } on Failure {
      rethrow;
    } catch (e) {
      throw AiUnavailableFailure('Could not reach the AI service: $e');
    }
  }

  // ── Dos & Don'ts ──────────────────────────────────────────────────────────────

  @override
  Future<List<String>> generateDosDonts(
    HoroscopeResponse horoscope, {
    required String locale,
  }) async {
    try {
      final FunctionResponse response = await _supabase.functions.invoke(
        'astro',
        body: <String, dynamic>{
          'kind': 'dosddonts',
          'locale': locale,
        },
      );

      if (response.data is Map) {
        final dynamic rawItems = (response.data as Map)['items'];
        if (rawItems is List) {
          return rawItems.map((dynamic e) => e.toString()).toList();
        }
      }
    } catch (_) {
      // Fall through to template fallback
    }

    // Fallback template if edge function fails
    return <String>[
      'Do: Finish your highest-impact task before noon.',
      'Do: Keep one important conversation concise and explicit.',
      "Don't: Make financial commitments without full context.",
      "Don't: Overbook your evening with low-priority tasks.",
    ];
  }

  // ── Gemstone summary ─────────────────────────────────────────────────────────

  @override
  Future<String> summarizeReport(
    GemstoneReport report, {
    required String locale,
  }) async {
    // Template-based — fast and free; no chart needed.
    // Upgrade to AI in a future iteration.
    if (locale.startsWith('hi')) {
      return 'मुख्य रत्न ${report.primaryStone} है। '
          'यह आपकी वर्तमान दशा की ऊर्जा को संतुलित करता है।';
    }
    return 'Primary recommendation: ${report.primaryStone}. '
        'It resonates with your current dasha energy and supports steadier decision-making.';
  }
}
