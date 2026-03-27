import '../../../../core/models/astro_models.dart';
import '../../../../core/services/contracts.dart';

class GemstoneBuildResult {
  const GemstoneBuildResult({
    required this.kundliData,
    required this.report,
    required this.summary,
  });

  final KundliData kundliData;
  final GemstoneReport report;
  final String summary;
}

abstract class GemstonesRemoteDataSource {
  Future<GemstoneBuildResult> buildGemstoneReport({
    required BirthDetails birthDetails,
    required String locale,
  });
}

class GemstonesRemoteDataSourceImpl implements GemstonesRemoteDataSource {
  GemstonesRemoteDataSourceImpl({
    required AstroProvider astroProvider,
    required GemstoneEngine gemstoneEngine,
    required AiPersonalizer aiPersonalizer,
  }) : _astroProvider = astroProvider,
       _gemstoneEngine = gemstoneEngine,
       _aiPersonalizer = aiPersonalizer;

  final AstroProvider _astroProvider;
  final GemstoneEngine _gemstoneEngine;
  final AiPersonalizer _aiPersonalizer;

  @override
  Future<GemstoneBuildResult> buildGemstoneReport({
    required BirthDetails birthDetails,
    required String locale,
  }) async {
    final KundliData kundli = await _astroProvider.getKundli(birthDetails);
    final GemstoneReport report = await _gemstoneEngine.buildReport(kundli);
    final String summary = await _aiPersonalizer.summarizeReport(
      report,
      locale: locale,
    );
    return GemstoneBuildResult(
      kundliData: kundli,
      report: report,
      summary: summary,
    );
  }
}
