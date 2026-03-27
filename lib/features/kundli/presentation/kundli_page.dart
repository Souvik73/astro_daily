import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/kundli_cubit.dart';

class KundliPage extends StatelessWidget {
  const KundliPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kundli'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.read<KundliCubit>().fetchKundli(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<KundliCubit, KundliState>(
        builder: (BuildContext context, KundliState state) {
          if (state.status == KundliStatus.initial ||
              state.status == KundliStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == KundliStatus.failure || state.kundli == null) {
            return Center(
              child: Text(state.errorMessage ?? 'Unable to load kundli.'),
            );
          }

          final data = state.kundli!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: ListTile(
                  title: const Text('Sun Sign'),
                  subtitle: Text(data.sunSign),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: const Text('Moon Sign'),
                  subtitle: Text(data.moonSign),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: const Text('Ascendant'),
                  subtitle: Text(data.ascendant),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Current focus: ${data.focusArea}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
