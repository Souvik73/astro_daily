import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injection.dart';
import '../core/services/contracts.dart';
import '../features/auth/bloc/auth_bloc.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class AstroDailyApp extends StatelessWidget {
  const AstroDailyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<dynamic>>[
        RepositoryProvider<UsagePolicy>.value(value: sl<UsagePolicy>()),
        RepositoryProvider<AstroProvider>.value(value: sl<AstroProvider>()),
        RepositoryProvider<GemstoneEngine>.value(value: sl<GemstoneEngine>()),
        RepositoryProvider<AiPersonalizer>.value(value: sl<AiPersonalizer>()),
        RepositoryProvider<BillingGateway>.value(value: sl<BillingGateway>()),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: sl<AuthBloc>(),
        child: MaterialApp.router(
          title: 'Astro Daily',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: sl<AppRouter>().router,
        ),
      ),
    );
  }
}
