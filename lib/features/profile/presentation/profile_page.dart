import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/subscription_models.dart';
import 'cubit/profile_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (BuildContext context, ProfileState state) {
        if (state.status == ProfileStatus.initial ||
            state.status == ProfileStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == ProfileStatus.failure || state.profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Text(state.errorMessage ?? 'No active profile.'),
            ),
          );
        }

        final profile = state.profile!;
        final String formattedDob =
            '${profile.dateOfBirth.day.toString().padLeft(2, '0')}/${profile.dateOfBirth.month.toString().padLeft(2, '0')}/${profile.dateOfBirth.year}';
        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(profile.displayName),
                  subtitle: Text(profile.email),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: const Text('Zodiac Sign'),
                  subtitle: Text(profile.zodiacSign),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cake_outlined),
                  title: const Text('Birth Details'),
                  subtitle: Text(
                    'Date: $formattedDob\nTime: ${profile.timeOfBirth}\nPlace: ${profile.placeOfBirth}',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: const Text('Membership'),
                  subtitle: Text(
                    profile.tier == SubscriptionTier.premium
                        ? 'Premium'
                        : 'Free',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
