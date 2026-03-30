import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/subscription_models.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/entities/user.dart';
import '../domain/usecases/get_current_user.dart';
import '../domain/usecases/observe_auth_state.dart';
import '../domain/usecases/sign_out.dart';
import '../domain/usecases/update_subscription_tier.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

final class AuthState extends Equatable {
	const AuthState({required this.status, this.user});

	const AuthState.unknown() : this(status: AuthStatus.unknown);
	const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
	const AuthState.authenticated(User user)
		: this(status: AuthStatus.authenticated, user: user);

	final AuthStatus status;
	final User? user;

	@override
	List<Object?> get props => <Object?>[status, user];
}

sealed class AuthEvent extends Equatable {
	const AuthEvent();

	@override
	List<Object?> get props => <Object?>[];
}

final class AuthStarted extends AuthEvent {
	const AuthStarted();
}

final class AuthSignOutRequested extends AuthEvent {
	const AuthSignOutRequested();
}

final class AuthSubscriptionUpdated extends AuthEvent {
	const AuthSubscriptionUpdated(this.tier);

	final SubscriptionTier tier;

	@override
	List<Object?> get props => <Object?>[tier];
}

final class _AuthUserChanged extends AuthEvent {
	const _AuthUserChanged(this.user);

	final User? user;

	@override
	List<Object?> get props => <Object?>[user];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
	AuthBloc({
		required ObserveAuthState observeAuthState,
		required GetCurrentUser getCurrentUser,
		required SignOut signOut,
		required UpdateSubscriptionTier updateSubscriptionTier,
	}) : _observeAuthState = observeAuthState,
			 _getCurrentUser = getCurrentUser,
			 _signOut = signOut,
			 _updateSubscriptionTier = updateSubscriptionTier,
			 super(const AuthState.unknown()) {
		on<AuthStarted>(_onStarted);
		on<AuthSignOutRequested>(_onSignOutRequested);
		on<AuthSubscriptionUpdated>(_onSubscriptionUpdated);
		on<_AuthUserChanged>(_onAuthUserChanged);

		_userSubscription = _observeAuthState(
			const NoParams(),
		).listen((User? user) => add(_AuthUserChanged(user)));

		add(const AuthStarted());
	}

	final ObserveAuthState _observeAuthState;
	final GetCurrentUser _getCurrentUser;
	final SignOut _signOut;
	final UpdateSubscriptionTier _updateSubscriptionTier;
	late final StreamSubscription<User?> _userSubscription;

	Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
		final User? currentUser = _getCurrentUser(const NoParams());
		if (currentUser == null) {
			emit(const AuthState.unauthenticated());
			return;
		}
		emit(AuthState.authenticated(currentUser));
	}

	Future<void> _onSignOutRequested(
		AuthSignOutRequested event,
		Emitter<AuthState> emit,
	) async {
		await _signOut(const NoParams());
	}

	Future<void> _onSubscriptionUpdated(
		AuthSubscriptionUpdated event,
		Emitter<AuthState> emit,
	) async {
		await _updateSubscriptionTier(
			UpdateSubscriptionTierParams(tier: event.tier),
		);
	}

	void _onAuthUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
		if (event.user == null) {
			emit(const AuthState.unauthenticated());
			return;
		}
		emit(AuthState.authenticated(event.user!));
	}

	@override
	Future<void> close() async {
		await _userSubscription.cancel();
		return super.close();
	}
}
