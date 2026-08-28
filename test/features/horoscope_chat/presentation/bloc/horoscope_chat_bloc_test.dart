import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/core/models/birth_profile.dart';
import 'package:astro_daily/core/models/subscription_models.dart';
import 'package:astro_daily/core/services/contracts.dart';
import 'package:astro_daily/features/auth/domain/entities/auth_profile.dart';
import 'package:astro_daily/features/auth/domain/entities/user.dart';
import 'package:astro_daily/features/auth/domain/repositories/auth_repository.dart';
import 'package:astro_daily/features/daily_horoscope/domain/entities/daily_horoscope.dart';
import 'package:astro_daily/features/horoscope_chat/domain/entities/chat_message.dart';
import 'package:astro_daily/features/horoscope_chat/domain/repositories/horoscope_chat_repository.dart';
import 'package:astro_daily/features/horoscope_chat/domain/usecases/send_horoscope_message.dart';
import 'package:astro_daily/features/horoscope_chat/presentation/bloc/horoscope_chat_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAuthRepository authRepository;
  late _FakeUsagePolicy usagePolicy;

  setUp(() {
    authRepository = _FakeAuthRepository()..currentUser = _user();
    usagePolicy = _FakeUsagePolicy(access: FeatureAccess.open, quota: 3);
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('opening the chat computes remaining questions from the quota', () async {
    final bloc = HoroscopeChatBloc(
      sendHoroscopeMessage: _SuccessUseCase(),
      usagePolicy: usagePolicy,
      authRepository: authRepository,
    );

    bloc.add(HoroscopeChatOpened(horoscope: _horoscope(), locale: 'en'));
    await settle();

    expect(bloc.state.status, HoroscopeChatStatus.ready);
    expect(bloc.state.questionsRemaining, 3);
    await bloc.close();
  });

  test('opening the chat fails when there is no active user', () async {
    authRepository.currentUser = null;
    final bloc = HoroscopeChatBloc(
      sendHoroscopeMessage: _SuccessUseCase(),
      usagePolicy: usagePolicy,
      authRepository: authRepository,
    );

    bloc.add(HoroscopeChatOpened(horoscope: _horoscope(), locale: 'en'));
    await settle();

    expect(bloc.state.status, HoroscopeChatStatus.failure);
    await bloc.close();
  });

  test('sending a message appends the reply and records usage', () async {
    final bloc = HoroscopeChatBloc(
      sendHoroscopeMessage: _SuccessUseCase(),
      usagePolicy: usagePolicy,
      authRepository: authRepository,
    );
    bloc.add(HoroscopeChatOpened(horoscope: _horoscope(), locale: 'en'));
    await settle();

    bloc.add(const HoroscopeChatMessageSent(question: 'What about work?'));
    await settle();

    expect(bloc.state.status, HoroscopeChatStatus.ready);
    expect(bloc.state.messages.length, 2);
    expect(bloc.state.messages.last.author, ChatAuthor.assistant);
    expect(usagePolicy.recordUsageCalls, 1);
    await bloc.close();
  });

  test('sending a message is blocked once the reward-unlock quota is hit', () async {
    usagePolicy.access = FeatureAccess.rewardUnlockAvailable;
    final bloc = HoroscopeChatBloc(
      sendHoroscopeMessage: _SuccessUseCase(),
      usagePolicy: usagePolicy,
      authRepository: authRepository,
    );
    bloc.add(HoroscopeChatOpened(horoscope: _horoscope(), locale: 'en'));
    await settle();

    bloc.add(const HoroscopeChatMessageSent(question: 'One more?'));
    await settle();

    expect(bloc.state.messages, isEmpty);
    expect(bloc.state.access, FeatureAccess.rewardUnlockAvailable);
    expect(usagePolicy.recordUsageCalls, 0);
    await bloc.close();
  });

  test('a quota-exceeded failure removes the optimistic message and gates premium', () async {
    final bloc = HoroscopeChatBloc(
      sendHoroscopeMessage: _QuotaExceededUseCase(),
      usagePolicy: usagePolicy,
      authRepository: authRepository,
    );
    bloc.add(HoroscopeChatOpened(horoscope: _horoscope(), locale: 'en'));
    await settle();

    bloc.add(const HoroscopeChatMessageSent(question: 'Push past the limit'));
    await settle();

    expect(bloc.state.status, HoroscopeChatStatus.ready);
    expect(bloc.state.messages, isEmpty);
    expect(bloc.state.access, FeatureAccess.premiumRequired);
    await bloc.close();
  });
}

User _user() {
  return const User(
    id: 'u_1',
    email: 'pilot@astro.app',
    displayName: 'pilot',
    tier: SubscriptionTier.free,
  );
}

DailyHoroscope _horoscope() {
  return DailyHoroscope(
    date: DateTime(2026, 3, 19),
    zodiacSign: 'Aries',
    locale: 'en',
    summary: 'Steady progress wins today.',
    luckyColor: 'Green',
    luckyNumber: 5,
    dosDonts: const <String>['Do: Focus', "Don't: Rush"],
    personalizedFocus: 'pilot, steady progress wins today.',
  );
}

class _SuccessUseCase extends SendHoroscopeMessage {
  _SuccessUseCase() : super(_NoopHoroscopeChatRepository());

  @override
  Future<ChatMessage> call(SendHoroscopeMessageParams params) async {
    return ChatMessage(
      id: 'm_1',
      content: 'On the work front, focused execution wins.',
      author: ChatAuthor.assistant,
      timestamp: DateTime(2026, 3, 19),
    );
  }
}

class _QuotaExceededUseCase extends SendHoroscopeMessage {
  _QuotaExceededUseCase() : super(_NoopHoroscopeChatRepository());

  @override
  Future<ChatMessage> call(SendHoroscopeMessageParams params) {
    throw const AiQuotaExceededFailure();
  }
}

class _NoopHoroscopeChatRepository implements HoroscopeChatRepository {
  const _NoopHoroscopeChatRepository();

  @override
  Future<ChatMessage> sendMessage({
    required String question,
    required DailyHoroscope horoscope,
    required String locale,
    List<Map<String, String>> chatHistory = const <Map<String, String>>[],
  }) => throw UnimplementedError();
}

class _FakeUsagePolicy implements UsagePolicy {
  _FakeUsagePolicy({required this.access, this.quota = 3});

  FeatureAccess access;
  int quota;
  int used = 0;
  int recordUsageCalls = 0;

  @override
  FeatureAccess resolveAccess(String userId, AppFeature feature) => access;

  @override
  void recordUsage(String userId, AppFeature feature) {
    recordUsageCalls++;
    used++;
  }

  @override
  void recordRewardGranted(String userId, AppFeature feature) {}

  @override
  FeatureQuotaStatus statusFor(String userId, AppFeature feature) {
    return FeatureQuotaStatus(
      feature: feature,
      period: QuotaPeriod.daily,
      used: used,
      quota: quota,
      rewardsGranted: 0,
      rewardCap: 1,
      access: access,
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
  Future<void> signInWithApple({AuthProfile? profile}) async {}

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> signInWithGoogle({AuthProfile? profile}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> completeProfile(AuthProfile profile) async {}

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required AuthProfile profile,
  }) async {}

  @override
  Future<void> updateSubscriptionTier(SubscriptionTier tier) async {}

  @override
  Future<void> updateDisplayName(String displayName) async {}

  @override
  Future<void> updateBirthProfile(BirthProfile birthProfile) async {}

  @override
  Future<void> deleteAccount() async {}
}
