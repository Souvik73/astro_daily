import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/matching_cubit.dart';

class MatchingPage extends StatelessWidget {
  const MatchingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compatibility Matching'),
        actions: <Widget>[
          IconButton(
            onPressed: () =>
                context.read<MatchingCubit>().fetchMatchingResult(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<MatchingCubit, MatchingState>(
        builder: (BuildContext context, MatchingState state) {
          if (state.status == MatchingStatus.initial ||
              state.status == MatchingStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == MatchingStatus.failure || state.result == null) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Unable to load compatibility.',
              ),
            );
          }

          final result = state.result!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Compatibility Score: ${result.score}/100',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(result.summary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Strength Areas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final String strength in result.strengths) ...<Widget>[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.favorite_outline),
                    title: Text(strength),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}
