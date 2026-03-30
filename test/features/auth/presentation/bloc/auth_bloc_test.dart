import 'dart:async';

import 'package:astro_daily/core/models/subscription_models.dart';
import 'package:astro_daily/features/auth/bloc/auth_bloc.dart';
import 'package:astro_daily/features/auth/domain/entities/auth_profile.dart';
import 'package:astro_daily/features/auth/domain/entities/user.dart';
import 'package:astro_daily/features/auth/domain/repositories/auth_repository.dart';
import 'package:astro_daily/features/auth/domain/usecases/get_current_user.dart';
import 'package:astro_daily/features/auth/domain/usecases/observe_auth_state.dart';
import 'package:astro_daily/features/auth/domain/usecases/sign_out.dart';
import 'package:astro_daily/features/auth/domain/usecases/update_subscription_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAuthRepository authRepository;
  late AuthBloc authBloc;

  setUp(() {
    authRepository = _FakeAuthRepository();
    authBloc = AuthBloc(
      observeAuthState: ObserveAuthState(authRepository),
      getCurrentUser: GetCurrentUser(authRepository),
      signOut: SignOut(authRepository),
      updateSubscriptionTier: UpdateSubscriptionTier(authRepository),
    );
  });

  tearDown(() async {
    await authBloc.close();
    authRepository.dispose();
  });

  test('starts unauthenticated', () async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(authBloc.state.status, AuthStatus.unauthenticated);
  });

  test('authenticates when repository emits a user', () async {
    authRepository.seedUser(
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
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(authBloc.state.status, AuthStatus.authenticated);
    expect(authBloc.state.user?.email, 'pilot@astro.app');
  });

  test('returns to unauthenticated after sign out', () async {
    authRepository.seedUser(
      User(
        id: 'u_2',
        email: 'pilot@astro.app',
        displayName: 'pilot',
        zodiacSign: 'Aries',
        dateOfBirth: DateTime.utc(1998, 4, 10),
        timeOfBirth: '06:30',
        placeOfBirth: 'Kolkata, India',
        tier: SubscriptionTier.free,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    authBloc.add(const AuthSignOutRequested());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(authBloc.state.status, AuthStatus.unauthenticated);
    expect(authBloc.state.user, isNull);
  });

  test('updates subscription tier to premium', () async {
    authRepository.seedUser(
      User(
        id: 'u_3',
        email: 'pilot@astro.app',
        displayName: 'pilot',
        zodiacSign: 'Aries',
        dateOfBirth: DateTime.utc(1998, 4, 10),
        timeOfBirth: '06:30',
        placeOfBirth: 'Kolkata, India',
        tier: SubscriptionTier.free,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    authBloc.add(const AuthSubscriptionUpdated(SubscriptionTier.premium));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(authBloc.state.user?.tier, SubscriptionTier.premium);
  });
}

class _FakeAuthRepository implements AuthRepository {
  final StreamController<User?> _controller =
      StreamController<User?>.broadcast();

  User? _currentUser;

  void seedUser(User? user) {
    _currentUser = user;
    _controller.add(user);
  }

  void dispose() {
    _controller.close();
  }

  @override
  User? getCurrentUser() => _currentUser;

  @override
  User? getUserById(String userId) {
    final User? user = _currentUser;
    if (user == null || user.id != userId) {
      return null;
    }
    return user;
  }

  @override
  Stream<User?> observeAuthState() => _controller.stream;

  @override
  Future<void> signInWithApple({AuthProfile? profile}) async {}

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> signInWithGoogle({AuthProfile? profile}) async {}

  @override
  Future<void> signOut() async {
    seedUser(null);
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required AuthProfile profile,
  }) async {}

  @override
  Future<void> updateSubscriptionTier(SubscriptionTier tier) async {
    final User? user = _currentUser;
    if (user == null) {
      return;
    }
    seedUser(user.copyWith(tier: tier));
  }
}
