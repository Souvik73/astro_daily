import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/numerology/domain/entities/numerology_insight.dart';
import 'package:astro_daily/features/numerology/domain/repositories/numerology_repository.dart';
import 'package:astro_daily/features/numerology/domain/usecases/get_numerology_insight.dart';
import 'package:astro_daily/features/numerology/presentation/cubit/numerology_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emits success with the fetched insight', () async {
    final cubit = NumerologyCubit(getNumerologyInsight: _SuccessUseCase());

    await cubit.fetchNumerology();

    expect(cubit.state.status, NumerologyStatus.success);
    expect(cubit.state.insight?.lifePathNumber, 9);
    await cubit.close();
  });

  test('emits failure with the failure message', () async {
    final cubit = NumerologyCubit(getNumerologyInsight: _FailureUseCase());

    await cubit.fetchNumerology();

    expect(cubit.state.status, NumerologyStatus.failure);
    expect(
      cubit.state.errorMessage,
      'User session expired. Please sign in again.',
    );
    await cubit.close();
  });
}

class _SuccessUseCase extends GetNumerologyInsight {
  _SuccessUseCase() : super(_NoopNumerologyRepository());

  @override
  Future<NumerologyInsight> call(NoParams params) async {
    return const NumerologyInsight(
      lifePathNumber: 9,
      personalDayNumber: 2,
      guidance: 'Focus on one concrete outcome today.',
    );
  }
}

class _FailureUseCase extends GetNumerologyInsight {
  _FailureUseCase() : super(_NoopNumerologyRepository());

  @override
  Future<NumerologyInsight> call(NoParams params) {
    throw const AuthFailure('User session expired. Please sign in again.');
  }
}

class _NoopNumerologyRepository implements NumerologyRepository {
  const _NoopNumerologyRepository();

  @override
  Future<NumerologyInsight> getNumerologyInsight() =>
      throw UnimplementedError();
}
