import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/models/birth_profile.dart';
import '../../../core/widgets/astro_backdrop.dart';
import '../../../core/widgets/astro_page_components.dart';
import 'cubit/matching_cubit.dart';
import 'widgets/partner_input_sheet.dart';

class MatchingPage extends StatelessWidget {
  const MatchingPage({super.key});

  Future<void> _openPartnerSheet(
    BuildContext context, {
    BirthProfile? initial,
  }) async {
    final MatchingCubit cubit = context.read<MatchingCubit>();
    final BirthProfile? partner = await PartnerInputSheet.show(
      context,
      initial: initial,
    );
    if (partner != null) {
      await cubit.submitPartner(partner);
    } else if (initial == null) {
      // Dismissed without ever having a result — nothing to fall back to.
      cubit.requestEditPartner();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AstroBackdrop(
        child: SafeArea(
          child: BlocBuilder<MatchingCubit, MatchingState>(
            builder: (BuildContext context, MatchingState state) {
              if (state.status == MatchingStatus.initial ||
                  state.status == MatchingStatus.loading) {
                return const AstroLoadingView();
              }

              if (state.status == MatchingStatus.needsPartner) {
                return _NeedsPartnerView(
                  onAddPartner: () => _openPartnerSheet(context),
                  onBack: () => Navigator.of(context).maybePop(),
                );
              }

              if (state.status == MatchingStatus.failure ||
                  state.result == null) {
                return AstroErrorView(
                  message:
                      state.errorMessage ?? 'Unable to load compatibility.',
                  onRetry: () => context.read<MatchingCubit>().refresh(),
                );
              }

              final result = state.result!;
              return RefreshIndicator(
                onRefresh: () => context.read<MatchingCubit>().refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: <Widget>[
                    AstroPageHeader(
                      title: 'Compatibility',
                      subtitle: 'A softer look at alignment and rhythm.',
                      onBack: () => Navigator.of(context).maybePop(),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AstroTopIconButton(
                            icon: Icons.person_outline_rounded,
                            onTap: () => _openPartnerSheet(
                              context,
                              initial: result.partner,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AstroTopIconButton(
                            icon: Icons.refresh_rounded,
                            onTap: () =>
                                context.read<MatchingCubit>().refresh(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AstroHeroSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Compatibility score',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${result.score}/100',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            result.summary,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.84),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PartnerChip(
                      partner: result.partner,
                      onEdit: () =>
                          _openPartnerSheet(context, initial: result.partner),
                    ),
                    const SizedBox(height: 16),
                    const AstroSectionHeader(
                      title: 'Strength areas',
                      action: 'What works naturally',
                    ),
                    const SizedBox(height: 12),
                    for (final String strength in result.strengths) ...<Widget>[
                      AstroInfoTile(
                        icon: Icons.favorite_outline_rounded,
                        title: strength,
                        body:
                            'This is one of the strongest harmony cues in the current matching summary.',
                        accent: AppTheme.coral,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NeedsPartnerView extends StatelessWidget {
  const _NeedsPartnerView({required this.onAddPartner, required this.onBack});

  final VoidCallback onAddPartner;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: <Widget>[
        AstroPageHeader(
          title: 'Compatibility',
          subtitle: 'A softer look at alignment and rhythm.',
          onBack: onBack,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.favorite_outline_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Add your partner's birth details",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'We compare your chart against theirs to calculate a real '
                'compatibility score and summary.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAddPartner,
                child: const Text('Add partner details'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PartnerChip extends StatelessWidget {
  const _PartnerChip({required this.partner, required this.onEdit});

  final BirthProfile partner;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final String date =
        '${partner.dateOfBirth.day.toString().padLeft(2, '0')}/'
        '${partner.dateOfBirth.month.toString().padLeft(2, '0')}/'
        '${partner.dateOfBirth.year}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.favorite_outline_rounded,
            size: 18,
            color: AppTheme.berry,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Compared with ${partner.zodiacSign} • born $date',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text('Edit')),
        ],
      ),
    );
  }
}
