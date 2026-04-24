import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/astro_backdrop.dart';
import '../bloc/daily_horoscope_bloc.dart';
import '../../horoscope_chat/presentation/horoscope_chat_sheet.dart';

class DailyHoroscopePage extends StatelessWidget {
  const DailyHoroscopePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String locale =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    return Scaffold(
      body: AstroBackdrop(
        child: SafeArea(
          child: BlocBuilder<DailyHoroscopeBloc, DailyHoroscopeState>(
            builder: (BuildContext context, DailyHoroscopeState state) {
              if (state.status == DailyHoroscopeStatus.loading ||
                  state.status == DailyHoroscopeStatus.initial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == DailyHoroscopeStatus.failure) {
                return _ErrorPanel(
                  message:
                      state.errorMessage ?? 'Unable to load today\'s report.',
                  onRetry: () => context.read<DailyHoroscopeBloc>().add(
                    DailyHoroscopeRequested(
                      locale: locale,
                      date: DateTime.now(),
                    ),
                  ),
                );
              }

              final horoscope = state.horoscope!;
              final String dateLabel =
                  '${horoscope.date.day.toString().padLeft(2, '0')} '
                  '${_monthLabel(horoscope.date.month).toUpperCase()}';

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DailyHoroscopeBloc>().add(
                    DailyHoroscopeRequested(locale: locale, date: DateTime.now()),
                  );
                },
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
                            'Daily Horoscope',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const _TopIconButton(
                          icon: Icons.favorite_border_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
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
                            '$dateLabel • ${horoscope.zodiacSign.toUpperCase()}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Wear confidence,\nnot noise',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            horoscope.personalizedFocus,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.86),
                                ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _StatCard(
                                  label: 'Lucky Color',
                                  value: horoscope.luckyColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  label: 'Lucky Number',
                                  value: '${horoscope.luckyNumber}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Horoscope companion',
                      action: '3 free questions/day',
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => HoroscopeChatSheet.show(
                        context,
                        horoscope: horoscope,
                        locale: locale,
                      ),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: _ChatBubble(
                                      message: 'Should I wear red today?',
                                      fill: const Color(0xFFF2E7DA),
                                      textColor: AppTheme.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _ChatBubble(
                                  message:
                                      'Yes, but keep the rest of the look neutral. It matches today\'s visibility theme without getting too loud.',
                                  fill: AppTheme.midnight,
                                  textColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  _SuggestionChip(
                                    label: 'Ask about work',
                                    onTap: () => HoroscopeChatSheet.show(
                                      context,
                                      horoscope: horoscope,
                                      locale: locale,
                                      initialQuestion:
                                          'What does today look like for work?',
                                    ),
                                  ),
                                  _SuggestionChip(
                                    label: 'Ask about love',
                                    onTap: () => HoroscopeChatSheet.show(
                                      context,
                                      horoscope: horoscope,
                                      locale: locale,
                                      initialQuestion:
                                          'What does today look like for love?',
                                    ),
                                  ),
                                  _SuggestionChip(
                                    label: 'Open chat',
                                    onTap: () => HoroscopeChatSheet.show(
                                      context,
                                      horoscope: horoscope,
                                      locale: locale,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Do / Don\'t',
                      action: 'Grounded cues',
                    ),
                    const SizedBox(height: 12),
                    for (int index = 0; index < horoscope.dosDonts.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _InsightRow(
                          title: index.isEven ? 'Do' : 'Don\'t',
                          body: horoscope.dosDonts[index],
                          accent: index.isEven ? AppTheme.teal : AppTheme.coral,
                          icon: index.isEven
                              ? Icons.check_circle_outline_rounded
                              : Icons.remove_circle_outline_rounded,
                        ),
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

  String _monthLabel(int month) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    this.onTap,
  });

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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
            ),
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
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(width: 8),
        Text(
          action,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.berry),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.fill,
    required this.textColor,
  });

  final String message;
  final Color fill;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      side: const BorderSide(color: AppTheme.border),
      backgroundColor: AppTheme.canvasSoft,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppTheme.ink,
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.title,
    required this.body,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String body;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent),
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

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
