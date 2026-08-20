import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/failures.dart';

/// Thin wrapper around [SupabaseClient.functions.invoke] that maps known
/// error codes and HTTP statuses to typed [Failure] subclasses, so
/// per-feature data sources never have to inspect raw response shapes.
class SupabaseEdgeClient {
  const SupabaseEdgeClient(this._supabase);

  final SupabaseClient _supabase;

  /// Invoke the `astro` edge function and return the decoded response body.
  ///
  /// Throws:
  /// - [AiChartMissingFailure] when the server returns `error: chart_missing`
  ///   or HTTP 422 (no natal chart on file for the current user).
  /// - [DataFailure] for any other non-2xx response or network error.
  Future<Map<String, dynamic>> invokeAstro(Map<String, dynamic> body) =>
      _invoke('astro', body);

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _invoke(
    String function,
    Map<String, dynamic> body,
  ) async {
    try {
      final FunctionResponse res =
          await _supabase.functions.invoke(function, body: body);
      _throwIfErrorBody(res.data);
      return (res.data as Map<String, dynamic>?) ?? const <String, dynamic>{};
    } on Failure {
      rethrow;
    } on FunctionException catch (e) {
      if (e.status == 422) throw const AiChartMissingFailure();
      throw DataFailure('$function service error (${e.status}).');
    } catch (e) {
      throw DataFailure('$function service unavailable: $e');
    }
  }

  /// Maps well-known `error` values in a 2xx response body to typed failures.
  static void _throwIfErrorBody(dynamic data) {
    if (data is! Map) return;
    final String? err = data['error'] as String?;
    if (err == 'chart_missing') throw const AiChartMissingFailure();
  }
}
