import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/astro_backdrop.dart';
import '../../../core/widgets/astro_page_components.dart';
import 'cubit/gemstones_cubit.dart';

class GemstonesPage extends StatelessWidget {
  const GemstonesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AstroBackdrop(
        child: SafeArea(
          child: BlocBuilder<GemstonesCubit, GemstonesState>(
            builder: (BuildContext context, GemstonesState state) {
              if (state.status == GemstonesStatus.initial ||
                  state.status == GemstonesStatus.loading) {
                return const AstroLoadingView();
              }
              if (state.status == GemstonesStatus.failure ||
                  state.insight == null) {
                return AstroErrorView(
                  message:
                      state.errorMessage ?? 'Unable to build gemstone report.',
                  onRetry: () =>
                      context.read<GemstonesCubit>().fetchGemstoneInsight(),
                );
              }

              final insight = state.insight!;
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<GemstonesCubit>().fetchGemstoneInsight(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: <Widget>[
                    AstroPageHeader(
                      title: 'Gemstone Advisor',
                      subtitle: 'Practical gemstone guidance, softened.',
                      onBack: () => Navigator.of(context).maybePop(),
                      trailing: AstroTopIconButton(
                        icon: Icons.refresh_rounded,
                        onTap: () => context
                            .read<GemstonesCubit>()
                            .fetchGemstoneInsight(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    AstroHeroSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Primary recommendation',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            insight.primaryStone,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            insight.summary,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.84),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AstroMetricCard(
                            label: 'Ascendant',
                            value: insight.ascendant,
                            accent: AppTheme.gold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AstroMetricCard(
                            label: 'Focus area',
                            value: insight.focusArea,
                            accent: AppTheme.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const AstroSectionHeader(
                      title: 'Why this works',
                      action: 'Context + alternatives',
                    ),
                    const SizedBox(height: 12),
                    AstroInfoTile(
                      icon: Icons.diamond_outlined,
                      title: 'Rationale',
                      body: insight.rationale,
                      accent: AppTheme.coral,
                    ),
                    const SizedBox(height: 12),
                    AstroInfoTile(
                      icon: Icons.change_circle_outlined,
                      title: 'Alternative stones',
                      body: insight.alternativeStones.join(', '),
                      accent: AppTheme.berry,
                    ),
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
