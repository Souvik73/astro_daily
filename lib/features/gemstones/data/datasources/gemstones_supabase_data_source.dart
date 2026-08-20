import '../../../../core/models/astro_models.dart';
import '../../../../core/services/contracts.dart';
import '../../../../core/services/supabase_edge_client.dart';
import 'gemstones_remote_data_source.dart';

/// Real implementation of [GemstonesRemoteDataSource].
///
/// Calls the `astro` edge function with `kind=kundli` — which returns the
/// server-computed gemstone recommendations alongside the natal chart data —
/// instead of running the local [RuleBasedGemstoneEngine].
class GemstonesSupabaseDataSource implements GemstonesRemoteDataSource {
  const GemstonesSupabaseDataSource({
    required SupabaseEdgeClient edgeClient,
    required AiPersonalizer aiPersonalizer,
  }) : _edgeClient = edgeClient,
       _aiPersonalizer = aiPersonalizer;

  final SupabaseEdgeClient _edgeClient;
  final AiPersonalizer _aiPersonalizer;

  @override
  Future<GemstoneBuildResult> buildGemstoneReport({
    required BirthDetails birthDetails,
    required String locale,
  }) async {
    // The server looks up the chart via the user's JWT — birthDetails is only
    // used as a fallback for sunSign if the server omits it.
    final Map<String, dynamic> data =
        await _edgeClient.invokeAstro(<String, dynamic>{'kind': 'kundli'});

    final String primaryStone =
        _str(data['recommendedGemstone'], 'Pearl');
    final String altStone = _str(data['alternateGemstone'], '');
    final String dashaStone = _str(data['dashaGemstone'], '');
    final String ascendant = _str(data['ascendant'], '');
    final String focusArea = _str(data['focusArea'], '');

    final List<String> alternatives = <String>[altStone, dashaStone]
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);

    final GemstoneReport report = GemstoneReport(
      primaryStone: primaryStone,
      alternativeStones: alternatives,
      rationale: 'Recommended for your $ascendant ascendant and current '
          'dasha cycle. Focus area: $focusArea.',
    );

    final KundliData kundliData = KundliData(
      sunSign: _str(data['sunSign'], birthDetails.zodiacSign),
      moonSign: _str(data['moonSign'], ''),
      ascendant: ascendant,
      focusArea: focusArea,
    );

    final String summary =
        await _aiPersonalizer.summarizeReport(report, locale: locale);

    return GemstoneBuildResult(
      kundliData: kundliData,
      report: report,
      summary: summary,
    );
  }

  static String _str(dynamic value, String fallback) =>
      (value is String && value.isNotEmpty) ? value : fallback;
}
