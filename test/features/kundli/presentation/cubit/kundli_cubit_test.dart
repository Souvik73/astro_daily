import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/kundli/domain/entities/kundli_insight.dart';
import 'package:astro_daily/features/kundli/domain/repositories/kundli_repository.dart';
import 'package:astro_daily/features/kundli/domain/usecases/get_kundli_insight.dart';
import 'package:astro_daily/features/kundli/presentation/cubit/kundli_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emits success with the fetched kundli', () async {
    final cubit = KundliCubit(getKundliInsight: _SuccessUseCase());

    await cubit.fetchKundli();

    expect(cubit.state.status, KundliStatus.success);
    expect(cubit.state.kundli?.sunSign, 'Aries');
    await cubit.close();
  });

  test('emits failure with a fallback message on unknown errors', () async {
    final cubit = KundliCubit(getKundliInsight: _FailureUseCase());

    await cubit.fetchKundli();

    expect(cubit.state.status, KundliStatus.failure);
    expect(cubit.state.errorMessage, 'Unable to load kundli.');
    await cubit.close();
  });
}

class _SuccessUseCase extends GetKundliInsight {
  _SuccessUseCase() : super(_NoopKundliRepository());

  @override
  Future<KundliInsight> call(NoParams params) async {
    return const KundliInsight(
      sunSign: 'Aries',
      moonSign: 'Cancer',
      ascendant: 'Libra',
      focusArea: 'Career & Status',
    );
  }
}

class _FailureUseCase extends GetKundliInsight {
  _FailureUseCase() : super(_NoopKundliRepository());

  @override
  Future<KundliInsight> call(NoParams params) {
    throw StateError('boom');
  }
}

class _NoopKundliRepository implements KundliRepository {
  const _NoopKundliRepository();

  @override
  Future<KundliInsight> getKundliInsight() => throw UnimplementedError();
}
