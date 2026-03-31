import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/astro_backdrop.dart';
import '../../../core/widgets/astro_page_components.dart';
import 'cubit/kundli_cubit.dart';

class KundliPage extends StatelessWidget {
  const KundliPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AstroBackdrop(
        child: SafeArea(
          child: BlocBuilder<KundliCubit, KundliState>(
            builder: (BuildContext context, KundliState state) {
              if (state.status == KundliStatus.initial ||
                  state.status == KundliStatus.loading) {
                return const AstroLoadingView();
              }
              if (state.status == KundliStatus.failure || state.kundli == null) {
                return AstroErrorView(
                  message: state.errorMessage ?? 'Unable to load kundli.',
                  onRetry: () => context.read<KundliCubit>().fetchKundli(),
                );
              }

              final data = state.kundli!;
              return RefreshIndicator(
                onRefresh: () => context.read<KundliCubit>().fetchKundli(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: <Widget>[
                    AstroPageHeader(
                      title: 'Kundli',
                      subtitle: 'Your chart language, simplified.',
                      onBack: () => Navigator.of(context).maybePop(),
                      trailing: AstroTopIconButton(
                        icon: Icons.refresh_rounded,
                        onTap: () => context.read<KundliCubit>().fetchKundli(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    AstroHeroSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Chart snapshot',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            data.focusArea,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'This screen now reads like a guided chart summary instead of a raw list of labels.',
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
                      title: 'Core placements',
                      action: 'Daily-use view',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AstroMetricCard(
                            label: 'Sun sign',
                            value: data.sunSign,
                            accent: AppTheme.gold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AstroMetricCard(
                            label: 'Moon sign',
                            value: data.moonSign,
                            accent: AppTheme.coral,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AstroInfoTile(
                      icon: Icons.north_east_rounded,
                      title: 'Ascendant',
                      body: data.ascendant,
                      accent: AppTheme.teal,
                    ),
                    const SizedBox(height: 12),
                    AstroInfoTile(
                      icon: Icons.auto_graph_rounded,
                      title: 'Current focus',
                      body: data.focusArea,
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
