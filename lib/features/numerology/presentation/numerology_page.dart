import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/numerology_cubit.dart';

class NumerologyPage extends StatelessWidget {
  const NumerologyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Numerology'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.read<NumerologyCubit>().fetchNumerology(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<NumerologyCubit, NumerologyState>(
        builder: (BuildContext context, NumerologyState state) {
          if (state.status == NumerologyStatus.initial ||
              state.status == NumerologyStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == NumerologyStatus.failure ||
              state.insight == null) {
            return Center(
              child: Text(state.errorMessage ?? 'Unable to load numerology.'),
            );
          }

          final result = state.insight!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: ListTile(
                  title: const Text('Life Path Number'),
                  subtitle: Text('${result.lifePathNumber}'),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: const Text('Personal Day Number'),
                  subtitle: Text('${result.personalDayNumber}'),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(result.guidance),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
