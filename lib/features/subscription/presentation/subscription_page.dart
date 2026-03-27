import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/subscription_models.dart';
import 'cubit/subscription_cubit.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listener: (BuildContext context, SubscriptionState state) {
        final String? message = state.errorMessage ?? state.infoMessage;
        if (message == null) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        context.read<SubscriptionCubit>().clearMessages();
      },
      builder: (BuildContext context, SubscriptionState state) {
        final bool isLoading = state.status == SubscriptionStatusState.loading;
        final bool isPremium = state.overview?.tier == SubscriptionTier.premium;

        return Scaffold(
          appBar: AppBar(title: const Text('Subscription')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: ListTile(
                  title: const Text('Current Plan'),
                  subtitle: Text(isPremium ? 'Premium' : 'Free'),
                  trailing: isPremium
                      ? const Icon(Icons.verified, color: Colors.green)
                      : const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Premium Monthly',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Unlimited feature usage and priority insights.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: isLoading
                            ? null
                            : () => context.read<SubscriptionCubit>().purchase(
                                PlanType.monthly,
                              ),
                        child: const Text('Start Monthly Plan'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Premium Yearly',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text('Best value for long-term users.'),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: isLoading
                            ? null
                            : () => context.read<SubscriptionCubit>().purchase(
                                PlanType.yearly,
                              ),
                        child: const Text('Start Yearly Plan'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () => context.read<SubscriptionCubit>().restore(),
                child: const Text('Restore Purchases'),
              ),
            ],
          ),
        );
      },
    );
  }
}
