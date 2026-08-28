import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/features/gemstones/domain/entities/gemstone_insight.dart';
import 'package:astro_daily/features/gemstones/domain/repositories/gemstones_repository.dart';
import 'package:astro_daily/features/gemstones/domain/usecases/get_gemstone_insight.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns the insight from the repository', () async {
    final repository = _FakeGemstonesRepository(
      insight: const GemstoneInsight(
        primaryStone: 'Emerald',
        alternativeStones: <String>['Moonstone', 'Citrine'],
        rationale: 'Selected by ascendant.',
        summary: 'Primary recommendation is Emerald.',
        ascendant: 'Gemini',
        focusArea: 'Career & Status',
      ),
    );
    final useCase = GetGemstoneInsight(repository);

    final result = await useCase(const NoParams());

    expect(result.primaryStone, 'Emerald');
    expect(result.ascendant, 'Gemini');
    expect(result.alternativeStones, <String>['Moonstone', 'Citrine']);
  });

  test('propagates failures from the repository', () async {
    final repository = _FakeGemstonesRepository(
      error: const AiChartMissingFailure(),
    );
    final useCase = GetGemstoneInsight(repository);

    expect(
      () => useCase(const NoParams()),
      throwsA(isA<AiChartMissingFailure>()),
    );
  });
}

class _FakeGemstonesRepository implements GemstonesRepository {
  _FakeGemstonesRepository({this.insight, this.error});

  final GemstoneInsight? insight;
  final Failure? error;

  @override
  Future<GemstoneInsight> getGemstoneInsight() async {
    final Failure? failure = error;
    if (failure != null) throw failure;
    return insight!;
  }
}
