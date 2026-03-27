import 'package:astro_daily/core/models/subscription_models.dart';
import 'package:astro_daily/features/auth/bloc/auth_bloc.dart';
import 'package:astro_daily/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:astro_daily/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:astro_daily/features/auth/domain/repositories/auth_repository.dart';
import 'package:astro_daily/features/auth/domain/usecases/get_current_user.dart';
import 'package:astro_daily/features/auth/domain/usecases/observe_auth_state.dart';
import 'package:astro_daily/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:astro_daily/features/auth/domain/usecases/sign_out.dart';
import 'package:astro_daily/features/auth/domain/usecases/update_subscription_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuthLocalDataSource localDataSource;
  late AuthRepository authRepository;
  late AuthBloc authBloc;

  setUp(() {
    localDataSource = InMemoryAuthLocalDataSource();
    authRepository = AuthRepositoryImpl(localDataSource: localDataSource);
    authBloc = AuthBloc(
      observeAuthState: ObserveAuthState(authRepository),
      getCurrentUser: GetCurrentUser(authRepository),
      signInWithEmail: SignInWithEmail(authRepository),
      signOut: SignOut(authRepository),
      updateSubscriptionTier: UpdateSubscriptionTier(authRepository),
    );
  });

  tearDown(() async {
    await authBloc.close();
    localDataSource.dispose();
  });

  test('starts unauthenticated', () async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(authBloc.state.status, AuthStatus.unauthenticated);
  });

  test('authenticates after sign in', () async {
    authBloc.add(const AuthSignInRequested('pilot@astro.app'));
    await Future<void>.delayed(const Duration(milliseconds: 320));

    expect(authBloc.state.status, AuthStatus.authenticated);
    expect(authBloc.state.user?.email, 'pilot@astro.app');
  });

  test('returns to unauthenticated after sign out', () async {
    authBloc.add(const AuthSignInRequested('pilot@astro.app'));
    await Future<void>.delayed(const Duration(milliseconds: 320));
    authBloc.add(const AuthSignOutRequested());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(authBloc.state.status, AuthStatus.unauthenticated);
    expect(authBloc.state.user, isNull);
  });

  test('updates subscription tier to premium', () async {
    authBloc.add(const AuthSignInRequested('pilot@astro.app'));
    await Future<void>.delayed(const Duration(milliseconds: 320));
    authBloc.add(const AuthSubscriptionUpdated(SubscriptionTier.premium));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(authBloc.state.user?.tier, SubscriptionTier.premium);
  });
}
