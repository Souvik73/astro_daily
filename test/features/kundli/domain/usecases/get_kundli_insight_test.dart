import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/kundli/domain/entities/kundli_insight.dart';
import 'package:astro_daily/features/kundli/domain/repositories/kundli_repository.dart';
import 'package:astro_daily/features/kundli/domain/usecases/get_kundli_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns the insight from the repository', () async {
    final repository = _FakeKundliRepository(
      insight: const KundliInsight(
        sunSign: 'Leo',
        moonSign: 'Cancer',
        ascendant: 'Libra',
        focusArea: 'Career alignment and communication timing.',
      ),
    );
    final useCase = GetKundliInsight(repository);

    final result = await useCase(const NoParams());

    expect(result.sunSign, 'Leo');
    expect(result.ascendant, 'Libra');
  });

  test('propagates failures from the repository', () async {
    final repository = _FakeKundliRepository(
      error: const AuthFailure('User session expired. Please sign in again.'),
    );
    final useCase = GetKundliInsight(repository);

    expect(() => useCase(const NoParams()), throwsA(isA<AuthFailure>()));
  });
}

class _FakeKundliRepository implements KundliRepository {
  _FakeKundliRepository({this.insight, this.error});

  final KundliInsight? insight;
  final Failure? error;

  @override
  Future<KundliInsight> getKundliInsight() async {
    final Failure? failure = error;
    if (failure != null) throw failure;
    return insight!;
  }
}
