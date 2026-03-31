import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/models/subscription_models.dart';
import '../../../core/widgets/astro_backdrop.dart';
import '../../../core/widgets/astro_page_components.dart';
import 'cubit/profile_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (BuildContext context, ProfileState state) {
        if (state.status == ProfileStatus.initial ||
            state.status == ProfileStatus.loading) {
          return const Scaffold(
            body: AstroBackdrop(child: AstroLoadingView()),
          );
        }
        if (state.status == ProfileStatus.failure || state.profile == null) {
          return Scaffold(
            body: AstroBackdrop(
              child: AstroErrorView(
                message: state.errorMessage ?? 'No active profile.',
                onRetry: () => context.read<ProfileCubit>().loadProfile(),
              ),
            ),
          );
        }

        final profile = state.profile!;
        final String formattedDob =
            '${profile.dateOfBirth.day.toString().padLeft(2, '0')}/${profile.dateOfBirth.month.toString().padLeft(2, '0')}/${profile.dateOfBirth.year}';
        final bool isPremium = profile.tier == SubscriptionTier.premium;

        return Scaffold(
          body: AstroBackdrop(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: <Widget>[
                  AstroPageHeader(
                    title: 'Profile',
                    subtitle: 'Your saved identity and birth context.',
                    onBack: () => Navigator.of(context).maybePop(),
                    trailing: const AstroTopIconButton(
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AstroHeroSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          profile.zodiacSign.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          profile.displayName,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.email,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.84),
                              ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            _HeroTag(label: profile.zodiacSign),
                            _HeroTag(
                              label: isPremium ? 'Premium active' : 'Free plan',
                            ),
                            _HeroTag(label: profile.placeOfBirth),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AstroSectionHeader(
                    title: 'Birth identity',
                    action: 'Used across every reading',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AstroMetricCard(
                          label: 'Date of birth',
                          value: formattedDob,
                          accent: AppTheme.coral,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AstroMetricCard(
                          label: 'Time of birth',
                          value: profile.timeOfBirth,
                          accent: AppTheme.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AstroInfoTile(
                    icon: Icons.location_on_outlined,
                    title: 'Place of birth',
                    body: profile.placeOfBirth,
                    accent: AppTheme.gold,
                  ),
                  const SizedBox(height: 12),
                  AstroInfoTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Membership',
                    body: isPremium
                        ? 'Premium removes ads and raises your daily limits.'
                        : 'Free keeps the core ritual open with softer limits.',
                    accent: isPremium ? AppTheme.gold : AppTheme.teal,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isPremium ? AppTheme.gold : AppTheme.teal)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isPremium ? 'Premium' : 'Free',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isPremium ? AppTheme.gold : AppTheme.teal,
                        ),
                      ),
                    ),
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

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

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
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}
