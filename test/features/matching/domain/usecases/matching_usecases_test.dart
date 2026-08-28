import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/core/models/birth_profile.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/matching/domain/entities/matching_result.dart';
import 'package:astro_daily/features/matching/domain/repositories/matching_repository.dart';
import 'package:astro_daily/features/matching/domain/usecases/get_matching_result.dart';
import 'package:astro_daily/features/matching/domain/usecases/get_saved_partner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeMatchingRepository repository;

  setUp(() {
    repository = _FakeMatchingRepository();
  });

  test('GetSavedPartner returns null when nothing is saved', () async {
    final useCase = GetSavedPartner(repository);

    final result = await useCase(const NoParams());

    expect(result, isNull);
  });

  test('GetSavedPartner returns the saved partner', () async {
    repository.savedPartner = _partner();
    final useCase = GetSavedPartner(repository);

    final result = await useCase(const NoParams());

    expect(result?.placeOfBirth, 'Mumbai, India');
  });

  test('GetMatchingResult passes the partner through and returns the score', () async {
    repository.result = MatchingResult(
      score: 82,
      summary: 'Strong alignment.',
      strengths: const <String>['Shared elemental energy'],
      partner: _partner(),
    );
    final useCase = GetMatchingResult(repository);

    final result = await useCase(GetMatchingResultParams(partner: _partner()));

    expect(repository.requestedPartner?.placeOfBirth, 'Mumbai, India');
    expect(result.score, 82);
  });

  test('GetMatchingResult propagates repository failures', () async {
    repository.error = const AuthFailure('User session expired. Please sign in again.');
    final useCase = GetMatchingResult(repository);

    expect(
      () => useCase(GetMatchingResultParams(partner: _partner())),
      throwsA(isA<AuthFailure>()),
    );
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

class _FakeMatchingRepository implements MatchingRepository {
  BirthProfile? savedPartner;
  MatchingResult? result;
  Failure? error;
  BirthProfile? requestedPartner;

  @override
  Future<BirthProfile?> getSavedPartner() async => savedPartner;

  @override
  Future<MatchingResult> getMatchingResult(BirthProfile partner) async {
    requestedPartner = partner;
    final Failure? failure = error;
    if (failure != null) throw failure;
    return result!;
  }
}
