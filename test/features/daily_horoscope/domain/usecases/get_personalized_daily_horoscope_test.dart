import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/core/models/astro_models.dart';
import 'package:astro_daily/core/models/subscription_models.dart';
import 'package:astro_daily/features/auth/domain/entities/user.dart';
import 'package:astro_daily/features/auth/domain/repositories/auth_repository.dart';
import 'package:astro_daily/features/daily_horoscope/data/datasources/daily_horoscope_remote_data_source.dart';
import 'package:astro_daily/features/daily_horoscope/data/repositories/daily_horoscope_repository_impl.dart';
import 'package:astro_daily/features/daily_horoscope/domain/repositories/daily_horoscope_repository.dart';
import 'package:astro_daily/features/daily_horoscope/domain/usecases/get_personalized_daily_horoscope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeDailyHoroscopeRemoteDataSource remoteDataSource;
  late _FakeAuthRepository authRepository;
  late DailyHoroscopeRepository repository;
  late GetPersonalizedDailyHoroscope useCase;

  setUp(() {
    remoteDataSource = _FakeDailyHoroscopeRemoteDataSource();
    authRepository = _FakeAuthRepository();
    repository = DailyHoroscopeRepositoryImpl(
      remoteDataSource: remoteDataSource,
      authRepository: authRepository,
    );
    useCase = GetPersonalizedDailyHoroscope(repository);
  });

  test('returns personalized horoscope for authenticated user', () async {
    authRepository.currentUser = User(
      id: 'u_1',
      email: 'pilot@astro.app',
      displayName: 'pilot',
      zodiacSign: 'Aries',
      dateOfBirth: DateTime(1998, 4, 10),
      timeOfBirth: '06:30',
      placeOfBirth: 'Kolkata, India',
      tier: SubscriptionTier.free,
    );

    final result = await useCase(
      GetPersonalizedDailyHoroscopeParams(
        locale: 'en',
        date: DateTime(2026, 3, 19),
      ),
    );

    expect(result.zodiacSign, 'Aries');
    expect(result.locale, 'en');
    expect(result.personalizedFocus.startsWith('pilot,'), isTrue);
    expect(result.dosDonts.length, 2);
  });

  test('passes locale through to data source', () async {
    authRepository.currentUser = User(
      id: 'u_2',
      email: 'hindi@astro.app',
      displayName: 'hindi',
      zodiacSign: 'Aries',
      dateOfBirth: DateTime(1997, 11, 12),
      timeOfBirth: '07:10',
      placeOfBirth: 'Delhi, India',
      tier: SubscriptionTier.free,
    );

    await useCase(
      GetPersonalizedDailyHoroscopeParams(
        locale: 'hi',
        date: DateTime(2026, 3, 19),
      ),
    );

    expect(remoteDataSource.lastLocaleUsed, 'hi');
  });

  test('throws auth failure when no active user', () async {
    authRepository.currentUser = null;

    expect(
      () => useCase(
        GetPersonalizedDailyHoroscopeParams(
          locale: 'en',
          date: DateTime(2026, 3, 19),
        ),
      ),
      throwsA(isA<AuthFailure>()),
    );
  });
}

class _FakeDailyHoroscopeRemoteDataSource
    implements DailyHoroscopeRemoteDataSource {
  String? lastLocaleUsed;

  @override
  Future<List<String>> generateDosDonts(
    HoroscopeResponse horoscope, {
    required String locale,
  }) async {
    lastLocaleUsed = locale;
    return <String>['Do: Focus on one priority.', "Don't: Overcommit."];
  }

  @override
  Future<HoroscopeResponse> getDailyHoroscope(
    DailyHoroscopeRequest request,
  ) async {
    return HoroscopeResponse(
      date: request.date,
      zodiacSign: request.zodiacSign,
      locale: request.locale,
      summary: 'Steady progress wins today.',
      luckyColor: 'Green',
      luckyNumber: 5,
    );
  }
}

class _FakeAuthRepository implements AuthRepository {
  User? currentUser;

  @override
  User? getCurrentUser() => currentUser;

  @override
  User? getUserById(String userId) =>
      currentUser?.id == userId ? currentUser : null;

  @override
  Stream<User?> observeAuthState() => const Stream<User?>.empty();

  @override
  Future<void> signInWithEmail(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateSubscriptionTier(SubscriptionTier tier) async {}
}
