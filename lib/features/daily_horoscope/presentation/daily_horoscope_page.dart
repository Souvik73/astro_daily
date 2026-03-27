import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/daily_horoscope_bloc.dart';

class DailyHoroscopePage extends StatelessWidget {
  const DailyHoroscopePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String locale =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Horoscope')),
      body: BlocBuilder<DailyHoroscopeBloc, DailyHoroscopeState>(
        builder: (BuildContext context, DailyHoroscopeState state) {
          if (state.status == DailyHoroscopeStatus.loading ||
              state.status == DailyHoroscopeStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == DailyHoroscopeStatus.failure) {
            return _ErrorPanel(
              message: state.errorMessage ?? 'Unable to load today’s report.',
              onRetry: () => context.read<DailyHoroscopeBloc>().add(
                DailyHoroscopeRequested(locale: locale, date: DateTime.now()),
              ),
            );
          }

          final horoscope = state.horoscope!;
          return RefreshIndicator(
            onRefresh: () async {
              context.read<DailyHoroscopeBloc>().add(
                DailyHoroscopeRequested(locale: locale, date: DateTime.now()),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Today for ${horoscope.zodiacSign}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          horoscope.personalizedFocus,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.palette_outlined),
                          title: const Text('Lucky Color'),
                          subtitle: Text(horoscope.luckyColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.onetwothree_outlined),
                          title: const Text('Lucky Number'),
                          subtitle: Text('${horoscope.luckyNumber}'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Do / Don’t',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final String item in horoscope.dosDonts) ...<Widget>[
                  Card(
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(item),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
