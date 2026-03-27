import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/subscription_models.dart';
import '../../../core/services/contracts.dart';
import '../../../core/widgets/astro_drawer.dart';
import '../../../core/widgets/feature_card.dart';
import '../../auth/domain/entities/user.dart';
import 'cubit/home_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<_FeatureItem> _features = <_FeatureItem>[
    _FeatureItem(
      feature: AppFeature.dailyHoroscope,
      title: 'Daily Horoscope',
      subtitle: 'Personalized day insight with do/don’t guidance.',
      icon: Icons.wb_sunny_outlined,
      route: '/daily-horoscope',
    ),
    _FeatureItem(
      feature: AppFeature.kundli,
      title: 'Kundli',
      subtitle: 'Generate your chart and current focus area.',
      icon: Icons.auto_graph_outlined,
      route: '/kundli',
    ),
    _FeatureItem(
      feature: AppFeature.matching,
      title: 'Compatibility Matching',
      subtitle: 'Check relationship and communication alignment.',
      icon: Icons.favorite_outline,
      route: '/matching',
    ),
    _FeatureItem(
      feature: AppFeature.numerology,
      title: 'Numerology',
      subtitle: 'Life-path and personal-day number reading.',
      icon: Icons.pin_outlined,
      route: '/numerology',
    ),
    _FeatureItem(
      feature: AppFeature.gemstones,
      title: 'Gemstone Advisor',
      subtitle: 'Rule-based gemstone report with AI summary.',
      icon: Icons.diamond_outlined,
      route: '/gemstones',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (BuildContext context, HomeState state) {
        if (state.status == HomeStatus.initial ||
            state.status == HomeStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == HomeStatus.failure || state.user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Astro Daily')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(state.errorMessage ?? 'Unable to load dashboard.'),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => context.read<HomeCubit>().loadDashboard(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final User user = state.user!;
        final bool isPremium = user.tier == SubscriptionTier.premium;

        return Scaffold(
          appBar: AppBar(title: const Text('Astro Daily')),
          drawer: AstroDrawer(user: user),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _WelcomeHeader(user: user),
              const SizedBox(height: 16),
              Text(
                'Astro Daily Modules',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final _FeatureItem item in _features) ...<Widget>[
                FeatureCard(
                  icon: item.icon,
                  title: item.title,
                  subtitle: item.subtitle,
                  usageLabel: isPremium
                      ? 'Unlimited'
                      : '${state.usageFor(item.feature).usedToday}/${state.usageFor(item.feature).dailyQuota} today',
                  isLocked: !state.usageFor(item.feature).canUse,
                  onTap: () => _openFeature(context, item),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.workspace_premium_outlined),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Premium unlocks unlimited usage and priority insights.',
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/subscription'),
                        child: const Text('View plans'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openFeature(BuildContext context, _FeatureItem item) async {
    final HomeCubit cubit = context.read<HomeCubit>();
    final decision = await cubit.openFeature(item.feature);
    if (!context.mounted) {
      return;
    }
    if (!decision.canOpen) {
      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Daily free quota reached'),
          content: const Text(
            'Upgrade to Premium for unlimited access across astrology modules.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.push('/subscription');
              },
              child: const Text('Go Premium'),
            ),
          ],
        ),
      );
      return;
    }
    context.push(item.route);
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Welcome back, ${user.displayName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your sign: ${user.zodiacSign} • Tier: ${user.tier.name.toUpperCase()}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => context.push('/daily-horoscope'),
              child: const Text('Open today’s horoscope'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.feature,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final AppFeature feature;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
