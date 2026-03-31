import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/astro_backdrop.dart';
import '../../../core/widgets/astro_page_components.dart';
import 'cubit/settings_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _confirmAccountDeletion() async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This action is irreversible. v1 currently signs out and marks this flow for backend deletion integration.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.coral),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }
    context.read<SettingsCubit>().deleteAccount();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (BuildContext context, SettingsState state) {
        final String? message = state.errorMessage ?? state.infoMessage;
        if (message == null) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        context.read<SettingsCubit>().clearMessages();
      },
      builder: (BuildContext context, SettingsState state) {
        if (state.status == SettingsStatus.initial ||
            (state.status == SettingsStatus.loading &&
                state.preferences == null)) {
          return const Scaffold(
            body: AstroBackdrop(child: AstroLoadingView()),
          );
        }

        if (state.status == SettingsStatus.failure && state.preferences == null) {
          return Scaffold(
            body: AstroBackdrop(
              child: AstroErrorView(
                message: state.errorMessage ?? 'Unable to load settings.',
                onRetry: () => context.read<SettingsCubit>().loadPreferences(),
              ),
            ),
          );
        }

        final bool isBusy =
            state.status == SettingsStatus.loading ||
            state.status == SettingsStatus.deleting;
        final bool pushEnabled = state.preferences?.pushEnabled ?? true;
        final bool localAiEnabled = state.preferences?.localAiEnabled ?? true;

        return Scaffold(
          body: AstroBackdrop(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: <Widget>[
                  AstroPageHeader(
                    title: 'Settings',
                    subtitle: 'Privacy, alerts, and personalization.',
                    onBack: () => Navigator.of(context).maybePop(),
                    trailing: const AstroTopIconButton(
                      icon: Icons.settings_outlined,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AstroHeroSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Choose how Astro Daily shows up for you',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'The settings flow is now calmer and more explicit about what each preference controls.',
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
                    title: 'Daily experience',
                    action: 'Saved locally for now',
                  ),
                  const SizedBox(height: 12),
                  _SettingCard(
                    icon: Icons.notifications_none_rounded,
                    title: 'Daily push notifications',
                    body:
                        'Turn reminders for your daily reading on or off. This will map to notification preferences in the backend.',
                    value: pushEnabled,
                    onChanged: isBusy
                        ? null
                        : (bool value) =>
                              context.read<SettingsCubit>().setPushEnabled(value),
                  ),
                  const SizedBox(height: 12),
                  _SettingCard(
                    icon: Icons.auto_awesome_outlined,
                    title: 'On-device personalization',
                    body:
                        'Prefer local AI-style summarization where available before falling back to server summaries.',
                    value: localAiEnabled,
                    accent: AppTheme.coral,
                    onChanged: isBusy
                        ? null
                        : (bool value) => context
                              .read<SettingsCubit>()
                              .setLocalAiEnabled(value),
                  ),
                  const SizedBox(height: 16),
                  const AstroSectionHeader(
                    title: 'Legal',
                    action: 'Hosted docs pending',
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    body:
                        'Terms and privacy links will be connected to hosted legal docs in the next milestone.',
                    onTap: () => _showInfoDialog(
                      title: 'Terms of Service',
                      message:
                          'Terms and privacy links will be connected to hosted legal docs.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    body:
                        'Privacy notice and data processing details will be published in the next milestone.',
                    accent: AppTheme.berry,
                    onTap: () => _showInfoDialog(
                      title: 'Privacy Policy',
                      message:
                          'Privacy notice and data processing details will be published in next milestone.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: AppTheme.coral.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Danger zone',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Deleting the account currently signs you out and marks this action for real backend deletion support.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                            onPressed: isBusy ? null : _confirmAccountDeletion,
                            style: FilledButton.styleFrom(
                              foregroundColor: AppTheme.coral,
                            ),
                            child: Text(
                              isBusy ? 'Working...' : 'Delete Account',
                            ),
                          ),
                        ],
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

  Future<void> _showInfoDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
    this.accent = AppTheme.teal,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color accent;

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
            const SizedBox(width: 12),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.accent = AppTheme.gold,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
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
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(body, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.open_in_new_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
