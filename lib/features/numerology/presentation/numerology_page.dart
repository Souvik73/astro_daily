import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/astro_backdrop.dart';
import '../../../core/widgets/astro_page_components.dart';
import 'cubit/numerology_cubit.dart';

class NumerologyPage extends StatelessWidget {
  const NumerologyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AstroBackdrop(
        child: SafeArea(
          child: BlocBuilder<NumerologyCubit, NumerologyState>(
            builder: (BuildContext context, NumerologyState state) {
              if (state.status == NumerologyStatus.initial ||
                  state.status == NumerologyStatus.loading) {
                return const AstroLoadingView();
              }
              if (state.status == NumerologyStatus.failure ||
                  state.insight == null) {
                return AstroErrorView(
                  message: state.errorMessage ?? 'Unable to load numerology.',
                  onRetry: () => context.read<NumerologyCubit>().fetchNumerology(),
                );
              }

              final result = state.insight!;
              return RefreshIndicator(
                onRefresh: () => context.read<NumerologyCubit>().fetchNumerology(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: <Widget>[
                    AstroPageHeader(
                      title: 'Numerology',
                      subtitle: 'Daily rhythm through number language.',
                      onBack: () => Navigator.of(context).maybePop(),
                      trailing: AstroTopIconButton(
                        icon: Icons.refresh_rounded,
                        onTap: () =>
                            context.read<NumerologyCubit>().fetchNumerology(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    AstroHeroSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Number guidance',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Numbers that shape your day',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            result.guidance,
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
                      title: 'Your numbers',
                      action: 'Today at a glance',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AstroMetricCard(
                            label: 'Life path',
                            value: '${result.lifePathNumber}',
                            accent: AppTheme.teal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AstroMetricCard(
                            label: 'Personal day',
                            value: '${result.personalDayNumber}',
                            accent: AppTheme.coral,
                          ),
                        ),
                      ],
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
