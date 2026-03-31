import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/astro_backdrop.dart';
import '../../../core/widgets/astro_page_components.dart';
import 'cubit/matching_cubit.dart';

class MatchingPage extends StatelessWidget {
  const MatchingPage({super.key});

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
              if (state.status == MatchingStatus.failure ||
                  state.result == null) {
                return AstroErrorView(
                  message:
                      state.errorMessage ?? 'Unable to load compatibility.',
                  onRetry: () => context.read<MatchingCubit>().fetchMatchingResult(),
                );
              }

              final result = state.result!;
              return RefreshIndicator(
                onRefresh: () => context.read<MatchingCubit>().fetchMatchingResult(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: <Widget>[
                    AstroPageHeader(
                      title: 'Compatibility',
                      subtitle: 'A softer look at alignment and rhythm.',
                      onBack: () => Navigator.of(context).maybePop(),
                      trailing: AstroTopIconButton(
                        icon: Icons.refresh_rounded,
                        onTap: () =>
                            context.read<MatchingCubit>().fetchMatchingResult(),
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
