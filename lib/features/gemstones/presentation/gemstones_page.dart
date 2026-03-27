import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/gemstones_cubit.dart';

class GemstonesPage extends StatelessWidget {
  const GemstonesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemstone Advisor'),
        actions: <Widget>[
          IconButton(
            onPressed: () =>
                context.read<GemstonesCubit>().fetchGemstoneInsight(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<GemstonesCubit, GemstonesState>(
        builder: (BuildContext context, GemstonesState state) {
          if (state.status == GemstonesStatus.initial ||
              state.status == GemstonesStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == GemstonesStatus.failure ||
              state.insight == null) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Unable to build gemstone report.',
              ),
            );
          }

          final insight = state.insight!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: ListTile(
                  title: const Text('Primary Gemstone'),
                  subtitle: Text(insight.primaryStone),
                  trailing: const Icon(Icons.diamond_outlined),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: const Text('Alternative Stones'),
                  subtitle: Text(insight.alternativeStones.join(', ')),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(insight.rationale),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'AI Personalization',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(insight.summary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: const Text('Kundli Base Context'),
                  subtitle: Text(
                    'Ascendant: ${insight.ascendant}\nFocus: ${insight.focusArea}',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
