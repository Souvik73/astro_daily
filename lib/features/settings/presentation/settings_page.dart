import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        final bool isBusy =
            state.status == SettingsStatus.loading ||
            state.status == SettingsStatus.deleting;
        final bool pushEnabled = state.preferences?.pushEnabled ?? true;
        final bool localAiEnabled = state.preferences?.localAiEnabled ?? true;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: SwitchListTile(
                  value: pushEnabled,
                  onChanged: isBusy
                      ? null
                      : (bool value) =>
                            context.read<SettingsCubit>().setPushEnabled(value),
                  title: const Text('Daily push notifications'),
                  subtitle: const Text(
                    'Will map to notification_preferences table.',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: SwitchListTile(
                  value: localAiEnabled,
                  onChanged: isBusy
                      ? null
                      : (bool value) => context
                            .read<SettingsCubit>()
                            .setLocalAiEnabled(value),
                  title: const Text('On-device personalization'),
                  subtitle: const Text(
                    'Fallback to server summary when unavailable.',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _showInfoDialog(
                        title: 'Terms of Service',
                        message:
                            'Terms and privacy links will be connected to hosted legal docs.',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _showInfoDialog(
                        title: 'Privacy Policy',
                        message:
                            'Privacy notice and data processing details will be published in next milestone.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: isBusy ? null : _confirmAccountDeletion,
                child: const Text('Delete Account'),
              ),
            ],
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
