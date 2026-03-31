import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/models/subscription_models.dart';
import '../../../core/services/contracts.dart';
import '../../../core/widgets/astro_backdrop.dart';
import '../../../core/widgets/astro_drawer.dart';
import '../../../core/widgets/feature_card.dart';
import '../../auth/domain/entities/user.dart';
import '../domain/entities/home_feature_usage.dart';
import 'cubit/home_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<_FeatureItem> _features = <_FeatureItem>[
    _FeatureItem(
      feature: AppFeature.dailyHoroscope,
      title: 'Daily Horoscope',
      subtitle: 'Your daily focus, lucky cues, and guidance ritual.',
      icon: Icons.wb_sunny_outlined,
      route: '/daily-horoscope',
    ),
    _FeatureItem(
      feature: AppFeature.kundli,
      title: 'Kundli',
      subtitle: 'Open your chart, revisit patterns, and refresh timing.',
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
      subtitle: 'Life-path, personal-day rhythm, and calm direction.',
      icon: Icons.pin_outlined,
      route: '/numerology',
    ),
    _FeatureItem(
      feature: AppFeature.gemstones,
      title: 'Gemstone Advisor',
      subtitle: 'Rule-based gemstone recommendations with soft guidance.',
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
            body: AstroBackdrop(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        state.errorMessage ?? 'Unable to load dashboard.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context.read<HomeCubit>().loadDashboard(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final User user = state.user!;
        final bool isPremium = user.tier == SubscriptionTier.premium;

        return Scaffold(
          endDrawer: AstroDrawer(user: user),
          body: AstroBackdrop(
            child: SafeArea(
              child: Builder(
                builder: (BuildContext scaffoldContext) {
                  return RefreshIndicator(
                    onRefresh: () => context.read<HomeCubit>().loadDashboard(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                      children: <Widget>[
                        _HomeHeader(
                          user: user,
                          onProfileTap: () =>
                              Scaffold.of(scaffoldContext).openEndDrawer(),
                        ),
                        const SizedBox(height: 18),
                        _HeroCard(user: user),
                        const SizedBox(height: 20),
                        _SectionHeader(
                          title: 'Your cosmic tools',
                          action: isPremium ? 'Ad-free active' : 'Soft free tier',
                        ),
                        const SizedBox(height: 12),
                        for (final _FeatureItem item in _features) ...<Widget>[
                          FeatureCard(
                            icon: item.icon,
                            title: item.title,
                            subtitle: item.subtitle,
                            usageLabel: _usageLabel(
                              usage: state.usageFor(item.feature),
                              isPremium: isPremium,
                            ),
                            isLocked: !state.usageFor(item.feature).canUse,
                            onTap: () => _openFeature(context, item),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 4),
                        _MembershipCard(isPremium: isPremium),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _usageLabel({
    required HomeFeatureUsage usage,
    required bool isPremium,
  }) {
    if (isPremium) {
      return 'Ad-free';
    }
    return '${usage.usedToday}/${usage.dailyQuota} free';
  }

  Future<void> _openFeature(BuildContext context, _FeatureItem item) async {
    final HomeCubit cubit = context.read<HomeCubit>();
    final decision = await cubit.openFeature(item.feature);
    if (!context.mounted) {
      return;
    }
    if (!decision.canOpen) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext sheetContext) => _SoftUnlockSheet(
          onViewPlans: () {
            Navigator.of(sheetContext).pop();
            context.push('/subscription');
          },
        ),
      );
      return;
    }
    context.push(item.route);
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.user, required this.onProfileTap});

  final User user;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.berry),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Astro Daily', style: textTheme.titleLarge),
              Text(
                'A calmer daily ritual for ${user.zodiacSign}',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.workspace_premium_outlined,
          onTap: () => context.push('/subscription'),
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.person_outline_rounded,
          onTap: onProfileTap,
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isPremium = user.tier == SubscriptionTier.premium;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'TODAY FOR ${user.zodiacSign.toUpperCase()}',
            style: textTheme.labelSmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            'Good to see you,\n${user.displayName}',
            style: textTheme.displaySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            'The home flow now leads with atmosphere and one clear ritual instead of a flat utility list.',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _HeroPill(label: user.zodiacSign),
              _HeroPill(label: isPremium ? 'Premium active' : 'Free + soft unlocks'),
            ],
          ),
          const SizedBox(height: 18),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
              ),
              onPressed: () => context.push('/daily-horoscope'),
              child: const Text('Open today’s horoscope'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isPremium ? AppTheme.gold : AppTheme.teal).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isPremium
                        ? Icons.workspace_premium_outlined
                        : Icons.favorite_border_rounded,
                    color: isPremium ? AppTheme.gold : AppTheme.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isPremium
                        ? 'You are on the calmer, ad-free path.'
                        : 'Premium now removes ads and raises limits without blocking free users harshly.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: () => context.push('/subscription'),
              child: Text(isPremium ? 'View benefits' : 'View plans'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftUnlockSheet extends StatelessWidget {
  const _SoftUnlockSheet({required this.onViewPlans});

  final VoidCallback onViewPlans;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
      decoration: const BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 52,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Free usage reached for now',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The monetization will be softened further, but for the current build this feature still needs Premium once the daily free access is used.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onViewPlans, child: const Text('View plans')),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: textTheme.titleLarge)),
        const SizedBox(width: 8),
        Text(
          action,
          style: textTheme.bodySmall?.copyWith(color: AppTheme.berry),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, color: AppTheme.ink),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
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
