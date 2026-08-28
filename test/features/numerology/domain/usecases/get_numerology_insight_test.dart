import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/numerology/domain/entities/numerology_insight.dart';
import 'package:astro_daily/features/numerology/domain/repositories/numerology_repository.dart';
import 'package:astro_daily/features/numerology/domain/usecases/get_numerology_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns the insight from the repository', () async {
    final repository = _FakeNumerologyRepository(
      insight: const NumerologyInsight(
        lifePathNumber: 7,
        personalDayNumber: 3,
        guidance: 'Focus on one concrete outcome today.',
      ),
    );
    final useCase = GetNumerologyInsight(repository);

    final result = await useCase(const NoParams());

    expect(result.lifePathNumber, 7);
    expect(result.personalDayNumber, 3);
  });

  test('propagates failures from the repository', () async {
    final repository = _FakeNumerologyRepository(
      error: const AuthFailure('User session expired. Please sign in again.'),
    );
    final useCase = GetNumerologyInsight(repository);

    expect(() => useCase(const NoParams()), throwsA(isA<AuthFailure>()));
  });
}

class _FakeNumerologyRepository implements NumerologyRepository {
  _FakeNumerologyRepository({this.insight, this.error});

  final NumerologyInsight? insight;
  final Failure? error;

  @override
  Future<NumerologyInsight> getNumerologyInsight() async {
    final Failure? failure = error;
    if (failure != null) throw failure;
    return insight!;
  }
}
