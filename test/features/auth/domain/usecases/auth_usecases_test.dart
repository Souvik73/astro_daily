import 'dart:async';

import 'package:astro_daily/core/models/subscription_models.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/auth/domain/entities/auth_profile.dart';
import 'package:astro_daily/features/auth/domain/entities/user.dart';
import 'package:astro_daily/features/auth/domain/repositories/auth_repository.dart';
import 'package:astro_daily/features/auth/domain/usecases/get_current_user.dart';
import 'package:astro_daily/features/auth/domain/usecases/observe_auth_state.dart';
import 'package:astro_daily/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:astro_daily/features/auth/domain/usecases/sign_out.dart';
import 'package:astro_daily/features/auth/domain/usecases/update_subscription_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAuthRepository repository;

  setUp(() {
    repository = _FakeAuthRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  test('GetCurrentUser returns active user', () {
    final GetCurrentUser useCase = GetCurrentUser(repository);
    repository.seedUser(
      User(
        id: 'u_1',
        email: 'pilot@astro.app',
        displayName: 'pilot',
        zodiacSign: 'Aries',
        dateOfBirth: DateTime.utc(1998, 4, 10),
        timeOfBirth: '06:30',
        placeOfBirth: 'Kolkata, India',
        tier: SubscriptionTier.free,
      ),
    );

    final User? result = useCase(const NoParams());

    expect(result?.email, 'pilot@astro.app');
  });

  test('SignInWithEmail updates repository and stream emits user', () async {
    final ObserveAuthState observeAuthState = ObserveAuthState(repository);
    final SignInWithEmail signInWithEmail = SignInWithEmail(repository);

    User? emitted;
    final StreamSubscription<User?> subscription =
        observeAuthState(const NoParams()).listen((User? user) {
          emitted = user;
        });
    await signInWithEmail(
      const SignInWithEmailParams(
        email: 'seeker@astro.app',
        password: 'password123',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await subscription.cancel();

    expect(emitted, isNotNull);
    expect(emitted!.displayName, 'seeker');
  });

  test('SignOut clears current user', () async {
    final SignOut signOut = SignOut(repository);
    repository.seedUser(
      User(
        id: 'u_2',
        email: 'seeker@astro.app',
        displayName: 'seeker',
        zodiacSign: 'Aries',
        dateOfBirth: DateTime.utc(1999, 8, 20),
        timeOfBirth: '05:45',
        placeOfBirth: 'Delhi, India',
        tier: SubscriptionTier.free,
      ),
    );

    await signOut(const NoParams());

    expect(repository.getCurrentUser(), isNull);
  });

  test('UpdateSubscriptionTier sets premium tier', () async {
    final UpdateSubscriptionTier updateSubscriptionTier =
        UpdateSubscriptionTier(repository);
    repository.seedUser(
      User(
        id: 'u_3',
        email: 'pro@astro.app',
        displayName: 'pro',
        zodiacSign: 'Leo',
        dateOfBirth: DateTime.utc(1995, 7, 25),
        timeOfBirth: '09:15',
        placeOfBirth: 'Mumbai, India',
        tier: SubscriptionTier.free,
      ),
    );

    await updateSubscriptionTier(
      const UpdateSubscriptionTierParams(tier: SubscriptionTier.premium),
    );

    expect(repository.getCurrentUser()!.tier, SubscriptionTier.premium);
  });
}

class _FakeAuthRepository implements AuthRepository {
  final StreamController<User?> _controller =
      StreamController<User?>.broadcast();
  User? _currentUser;

  void seedUser(User user) {
    _currentUser = user;
    _controller.add(user);
  }

  void dispose() {
    _controller.close();
  }

  @override
  User? getCurrentUser() => _currentUser;

  @override
  User? getUserById(String userId) =>
      _currentUser?.id == userId ? _currentUser : null;

  @override
  Stream<User?> observeAuthState() => _controller.stream;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    final User user = User(
      id: 'u_4',
      email: email,
      displayName: email.split('@').first,
      zodiacSign: 'Aries',
      dateOfBirth: DateTime(2000, 1, 1),
      timeOfBirth: '06:00',
      placeOfBirth: 'Kolkata, India',
      tier: SubscriptionTier.free,
    );
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Future<void> signInWithApple({AuthProfile? profile}) async {
    seedUser(
      User(
        id: 'u_apple',
        email: 'apple@astro.app',
        displayName: profile?.displayName ?? 'apple',
        zodiacSign: profile?.zodiacSign ?? 'Aries',
        dateOfBirth: profile?.dateOfBirth ?? DateTime(2000, 1, 1),
        timeOfBirth: profile?.timeOfBirth ?? '06:00',
        placeOfBirth: profile?.placeOfBirth ?? 'Kolkata, India',
        tier: SubscriptionTier.free,
      ),
    );
  }

  @override
  Future<void> signInWithGoogle({AuthProfile? profile}) async {
    seedUser(
      User(
        id: 'u_google',
        email: 'google@astro.app',
        displayName: profile?.displayName ?? 'google',
        zodiacSign: profile?.zodiacSign ?? 'Aries',
        dateOfBirth: profile?.dateOfBirth ?? DateTime(2000, 1, 1),
        timeOfBirth: profile?.timeOfBirth ?? '06:00',
        placeOfBirth: profile?.placeOfBirth ?? 'Kolkata, India',
        tier: SubscriptionTier.free,
      ),
    );
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required AuthProfile profile,
  }) async {
    seedUser(
      User(
        id: 'u_signup',
        email: email,
        displayName: profile.displayName,
        zodiacSign: profile.zodiacSign,
        dateOfBirth: profile.dateOfBirth,
        timeOfBirth: profile.timeOfBirth,
        placeOfBirth: profile.placeOfBirth,
        tier: SubscriptionTier.free,
      ),
    );
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> updateSubscriptionTier(SubscriptionTier tier) async {
    final User? user = _currentUser;
    if (user == null) {
      return;
    }
    final User updated = user.copyWith(tier: tier);
    _currentUser = updated;
    _controller.add(updated);
  }
}
