import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/models/subscription_models.dart';
import '../../../core/widgets/astro_backdrop.dart';
import 'cubit/subscription_cubit.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listener: (BuildContext context, SubscriptionState state) {
        final String? message = state.errorMessage ?? state.infoMessage;
        if (message == null) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        context.read<SubscriptionCubit>().clearMessages();
      },
      builder: (BuildContext context, SubscriptionState state) {
        final bool isLoading = state.status == SubscriptionStatusState.loading;
        final bool isPremium = state.overview?.tier == SubscriptionTier.premium;

        return Scaffold(
          body: AstroBackdrop(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _TopIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Subscription',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _TopIconButton(
                        icon: Icons.workspace_premium_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Premium, softened',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'This page now sells calm, convenience, ad-free access, and higher limits instead of feeling like a hard stop.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.84),
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _PlanBadge(
                                title: 'Free',
                                subtitle: 'Ads + softened limits',
                                highlighted: !isPremium,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PlanBadge(
                                title: 'Premium',
                                subtitle: 'Ad-free + deeper access',
                                highlighted: isPremium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _BenefitTile(
                    icon: Icons.block_rounded,
                    title: 'Remove ads',
                    body: 'No banners, no reward prompts, and a calmer ritual.',
                  ),
                  const SizedBox(height: 10),
                  const _BenefitTile(
                    icon: Icons.bolt_rounded,
                    title: 'Higher limits',
                    body:
                        'More horoscope chat usage and broader access across astrology tools.',
                  ),
                  const SizedBox(height: 10),
                  const _BenefitTile(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Priority insights',
                    body:
                        'Premium becomes the friction-free path without making free users feel shut out.',
                  ),
                  const SizedBox(height: 18),
                  _PlanCard(
                    title: 'Premium Monthly',
                    note: 'For users who want an ad-free daily ritual.',
                    priceLabel: 'Monthly',
                    ctaLabel: isPremium ? 'Current plan' : 'Start Monthly Plan',
                    accent: AppTheme.coral,
                    enabled: !isLoading && !isPremium,
                    onTap: () => context.read<SubscriptionCubit>().purchase(
                      PlanType.monthly,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PlanCard(
                    title: 'Premium Yearly',
                    note:
                        'Best value for long-term consistency and calm access.',
                    priceLabel: 'Yearly',
                    ctaLabel: isPremium ? 'Current plan' : 'Start Yearly Plan',
                    accent: AppTheme.teal,
                    highlighted: true,
                    enabled: !isLoading && !isPremium,
                    onTap: () => context.read<SubscriptionCubit>().purchase(
                      PlanType.yearly,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () => context.read<SubscriptionCubit>().restore(),
                    child: const Text('Restore Purchases'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, size: 18, color: AppTheme.ink),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({
    required this.title,
    required this.subtitle,
    required this.highlighted,
  });

  final String title;
  final String subtitle;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: highlighted ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: highlighted ? 0.4 : 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppTheme.midnight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.note,
    required this.priceLabel,
    required this.ctaLabel,
    required this.accent,
    required this.enabled,
    required this.onTap,
    this.highlighted = false,
  });

  final String title;
  final String note;
  final String priceLabel;
  final String ctaLabel;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          color: highlighted ? accent.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: highlighted
                ? accent.withValues(alpha: 0.4)
                : AppTheme.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    priceLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: accent),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(note, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: enabled ? onTap : null,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                ),
                child: Text(ctaLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
