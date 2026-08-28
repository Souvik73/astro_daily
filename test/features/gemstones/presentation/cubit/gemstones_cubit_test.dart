import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/gemstones/domain/entities/gemstone_insight.dart';
import 'package:astro_daily/features/gemstones/domain/repositories/gemstones_repository.dart';
import 'package:astro_daily/features/gemstones/domain/usecases/get_gemstone_insight.dart';
import 'package:astro_daily/features/gemstones/presentation/cubit/gemstones_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emits success with the fetched insight', () async {
    final cubit = GemstonesCubit(getGemstoneInsight: _SuccessUseCase());

    await cubit.fetchGemstoneInsight();

    expect(cubit.state.status, GemstonesStatus.success);
    expect(cubit.state.insight?.primaryStone, 'Ruby');
    await cubit.close();
  });

  test('emits failure with the failure message', () async {
    final cubit = GemstonesCubit(getGemstoneInsight: _FailureUseCase());

    await cubit.fetchGemstoneInsight();

    expect(cubit.state.status, GemstonesStatus.failure);
    expect(
      cubit.state.errorMessage,
      'Please complete your birth profile to use this feature.',
    );
    await cubit.close();
  });
}

class _SuccessUseCase extends GetGemstoneInsight {
  _SuccessUseCase() : super(_NoopGemstonesRepository());

  @override
  Future<GemstoneInsight> call(NoParams params) async {
    return const GemstoneInsight(
      primaryStone: 'Ruby',
      alternativeStones: <String>['Garnet'],
      rationale: 'Selected by ascendant.',
      summary: 'Primary recommendation is Ruby.',
      ascendant: 'Leo',
      focusArea: 'Career & Status',
    );
  }
}

class _FailureUseCase extends GetGemstoneInsight {
  _FailureUseCase() : super(_NoopGemstonesRepository());

  @override
  Future<GemstoneInsight> call(NoParams params) {
    throw const AiChartMissingFailure();
  }
}

class _NoopGemstonesRepository implements GemstonesRepository {
  const _NoopGemstonesRepository();

  @override
  Future<GemstoneInsight> getGemstoneInsight() => throw UnimplementedError();
}
