import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/signup_page.dart';
import '../../features/daily_horoscope/presentation/bloc/daily_horoscope_bloc.dart';
import '../../features/daily_horoscope/presentation/daily_horoscope_page.dart';
import '../../features/gemstones/presentation/cubit/gemstones_cubit.dart';
import '../../features/gemstones/presentation/gemstones_page.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/kundli/presentation/cubit/kundli_cubit.dart';
import '../../features/kundli/presentation/kundli_page.dart';
import '../../features/matching/presentation/cubit/matching_cubit.dart';
import '../../features/matching/presentation/matching_page.dart';
import '../../features/numerology/presentation/cubit/numerology_cubit.dart';
import '../../features/numerology/presentation/numerology_page.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/subscription/presentation/cubit/subscription_cubit.dart';
import '../../features/subscription/presentation/subscription_page.dart';

class AppRouter {
  AppRouter({
    required AuthBloc authBloc,
    required DailyHoroscopeBloc Function() dailyHoroscopeBlocFactory,
    required HomeCubit Function() homeCubitFactory,
    required KundliCubit Function() kundliCubitFactory,
    required MatchingCubit Function() matchingCubitFactory,
    required NumerologyCubit Function() numerologyCubitFactory,
    required GemstonesCubit Function() gemstonesCubitFactory,
    required SubscriptionCubit Function() subscriptionCubitFactory,
    required ProfileCubit Function() profileCubitFactory,
    required SettingsCubit Function() settingsCubitFactory,
  }) : _authBloc = authBloc,
       _dailyHoroscopeBlocFactory = dailyHoroscopeBlocFactory,
       _homeCubitFactory = homeCubitFactory,
       _kundliCubitFactory = kundliCubitFactory,
       _matchingCubitFactory = matchingCubitFactory,
       _numerologyCubitFactory = numerologyCubitFactory,
       _gemstonesCubitFactory = gemstonesCubitFactory,
       _subscriptionCubitFactory = subscriptionCubitFactory,
       _profileCubitFactory = profileCubitFactory,
       _settingsCubitFactory = settingsCubitFactory {
    _refreshListenable = _GoRouterRefreshStream(_authBloc.stream);
    router = GoRouter(
      initialLocation: '/login',
      refreshListenable: _refreshListenable,
      redirect: _redirect,
      routes: <RouteBase>[
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) =>
              const LoginPage(),
        ),
        GoRoute(
          path: '/signup',
          builder: (BuildContext context, GoRouterState state) =>
              const SignupPage(),
        ),
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) {
            return BlocProvider<HomeCubit>(
              create: (BuildContext context) =>
                  _homeCubitFactory()..loadDashboard(),
              child: const HomePage(),
            );
          },
        ),
        GoRoute(
          path: '/daily-horoscope',
          builder: (BuildContext context, GoRouterState state) {
            final String locale =
                Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
            return BlocProvider<DailyHoroscopeBloc>(
              create: (BuildContext context) => _dailyHoroscopeBlocFactory()
                ..add(
                  DailyHoroscopeRequested(locale: locale, date: DateTime.now()),
                ),
              child: const DailyHoroscopePage(),
            );
          },
        ),
        GoRoute(
          path: '/kundli',
          builder: (BuildContext context, GoRouterState state) {
            return BlocProvider<KundliCubit>(
              create: (BuildContext context) =>
                  _kundliCubitFactory()..fetchKundli(),
              child: const KundliPage(),
            );
          },
        ),
        GoRoute(
          path: '/matching',
          builder: (BuildContext context, GoRouterState state) {
            return BlocProvider<MatchingCubit>(
              create: (BuildContext context) =>
                  _matchingCubitFactory()..fetchMatchingResult(),
              child: const MatchingPage(),
            );
          },
        ),
        GoRoute(
          path: '/numerology',
          builder: (BuildContext context, GoRouterState state) {
            return BlocProvider<NumerologyCubit>(
              create: (BuildContext context) =>
                  _numerologyCubitFactory()..fetchNumerology(),
              child: const NumerologyPage(),
            );
          },
        ),
        GoRoute(
          path: '/gemstones',
          builder: (BuildContext context, GoRouterState state) {
            return BlocProvider<GemstonesCubit>(
              create: (BuildContext context) =>
                  _gemstonesCubitFactory()..fetchGemstoneInsight(),
              child: const GemstonesPage(),
            );
          },
        ),
        GoRoute(
          path: '/subscription',
          builder: (BuildContext context, GoRouterState state) {
            return BlocProvider<SubscriptionCubit>(
              create: (BuildContext context) =>
                  _subscriptionCubitFactory()..loadOverview(),
              child: const SubscriptionPage(),
            );
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (BuildContext context, GoRouterState state) {
            return BlocProvider<ProfileCubit>(
              create: (BuildContext context) =>
                  _profileCubitFactory()..loadProfile(),
              child: const ProfilePage(),
            );
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (BuildContext context, GoRouterState state) {
            return BlocProvider<SettingsCubit>(
              create: (BuildContext context) =>
                  _settingsCubitFactory()..loadPreferences(),
              child: const SettingsPage(),
            );
          },
        ),
      ],
    );
  }

  final AuthBloc _authBloc;
  final DailyHoroscopeBloc Function() _dailyHoroscopeBlocFactory;
  final HomeCubit Function() _homeCubitFactory;
  final KundliCubit Function() _kundliCubitFactory;
  final MatchingCubit Function() _matchingCubitFactory;
  final NumerologyCubit Function() _numerologyCubitFactory;
  final GemstonesCubit Function() _gemstonesCubitFactory;
  final SubscriptionCubit Function() _subscriptionCubitFactory;
  final ProfileCubit Function() _profileCubitFactory;
  final SettingsCubit Function() _settingsCubitFactory;
  late final _GoRouterRefreshStream _refreshListenable;
  late final GoRouter router;

  String? _redirect(BuildContext context, GoRouterState state) {
    final bool loggedIn = _authBloc.state.status == AuthStatus.authenticated;
    final bool isOnLogin = state.matchedLocation == '/login';
    final bool isOnSignup = state.matchedLocation == '/signup';

    if (!loggedIn && !isOnLogin && !isOnSignup) {
      return '/login';
    }
    if (loggedIn && (isOnLogin || isOnSignup)) {
      return '/home';
    }
    return null;
  }

  void dispose() {
    _refreshListenable.dispose();
    router.dispose();
  }
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((dynamic _) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
