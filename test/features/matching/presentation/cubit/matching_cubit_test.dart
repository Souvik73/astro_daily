import 'package:astro_daily/core/models/birth_profile.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/matching/domain/entities/matching_result.dart';
import 'package:astro_daily/features/matching/domain/repositories/matching_repository.dart';
import 'package:astro_daily/features/matching/domain/usecases/get_matching_result.dart';
import 'package:astro_daily/features/matching/domain/usecases/get_saved_partner.dart';
import 'package:astro_daily/features/matching/presentation/cubit/matching_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('start prompts for a partner when none is saved', () async {
    final cubit = MatchingCubit(
      getMatchingResult: _MatchingUseCase(),
      getSavedPartner: _SavedPartnerUseCase(saved: null),
    );

    await cubit.start();

    expect(cubit.state.status, MatchingStatus.needsPartner);
    await cubit.close();
  });

  test('start auto-fetches when a partner is already saved', () async {
    final cubit = MatchingCubit(
      getMatchingResult: _MatchingUseCase(),
      getSavedPartner: _SavedPartnerUseCase(saved: _partner()),
    );

    await cubit.start();

    expect(cubit.state.status, MatchingStatus.success);
    expect(cubit.state.result?.score, 75);
    await cubit.close();
  });

  test('submitPartner fetches a result for the given partner', () async {
    final cubit = MatchingCubit(
      getMatchingResult: _MatchingUseCase(),
      getSavedPartner: _SavedPartnerUseCase(saved: null),
    );

    await cubit.submitPartner(_partner());

    expect(cubit.state.status, MatchingStatus.success);
    expect(cubit.state.result?.partner.placeOfBirth, 'Mumbai, India');
    await cubit.close();
  });

  test('refresh prompts for a partner when there is no prior result', () async {
    final cubit = MatchingCubit(
      getMatchingResult: _MatchingUseCase(),
      getSavedPartner: _SavedPartnerUseCase(saved: null),
    );

    await cubit.refresh();

    expect(cubit.state.status, MatchingStatus.needsPartner);
    await cubit.close();
  });

  test('requestEditPartner switches to needsPartner without clearing the result', () async {
    final cubit = MatchingCubit(
      getMatchingResult: _MatchingUseCase(),
      getSavedPartner: _SavedPartnerUseCase(saved: null),
    );
    await cubit.submitPartner(_partner());

    cubit.requestEditPartner();

    expect(cubit.state.status, MatchingStatus.needsPartner);
    expect(cubit.state.result, isNotNull);
    await cubit.close();
  });
}

BirthProfile _partner() {
  return BirthProfile(
    zodiacSign: 'Libra',
    dateOfBirth: DateTime(1995, 12, 5),
    timeOfBirth: '18:10',
    placeOfBirth: 'Mumbai, India',
  );
}

class _MatchingUseCase extends GetMatchingResult {
  _MatchingUseCase() : super(_NoopMatchingRepository());

  @override
  Future<MatchingResult> call(GetMatchingResultParams params) async {
    return MatchingResult(
      score: 75,
      summary: 'Good alignment.',
      strengths: const <String>['Reliable communication rhythm'],
      partner: params.partner,
    );
  }
}

class _SavedPartnerUseCase extends GetSavedPartner {
  _SavedPartnerUseCase({required this.saved}) : super(_NoopMatchingRepository());

  final BirthProfile? saved;

  @override
  Future<BirthProfile?> call(NoParams params) async => saved;
}

class _NoopMatchingRepository implements MatchingRepository {
  const _NoopMatchingRepository();

  @override
  Future<BirthProfile?> getSavedPartner() => throw UnimplementedError();

  @override
  Future<MatchingResult> getMatchingResult(BirthProfile partner) =>
      throw UnimplementedError();
}
