import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/astro_backdrop.dart';
import '../../../core/widgets/astro_page_components.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/profile_completion_cubit.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _zodiacController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _timeOfBirthController = TextEditingController();
  final TextEditingController _placeOfBirthController = TextEditingController();
  bool _seededControllers = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _zodiacController.dispose();
    _dateOfBirthController.dispose();
    _timeOfBirthController.dispose();
    _placeOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final ProfileCompletionCubit cubit = context.read<ProfileCompletionCubit>();
    final DateTime today = DateTime.now();
    final DateTime initialDate =
        cubit.state.dateOfBirth ??
        DateTime(today.year - 22, today.month, today.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: today,
    );

    if (picked == null || !mounted) {
      return;
    }

    cubit.onDateOfBirthSelected(picked);
    _dateOfBirthController.text = _formatDate(picked);
  }

  Future<void> _pickTimeOfBirth() async {
    final ProfileCompletionCubit cubit = context.read<ProfileCompletionCubit>();
    final TimeOfDay initialTime = _parseTime(cubit.state.timeOfBirth);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null || !mounted) {
      return;
    }

    final String formattedTime = _formatTime(picked);
    cubit.onTimeOfBirthSelected(formattedTime);
    _timeOfBirthController.text = formattedTime;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await context.read<ProfileCompletionCubit>().complete(
      displayName: _displayNameController.text.trim(),
      placeOfBirth: _placeOfBirthController.text.trim(),
    );
  }

  /// Triggers birth chart computation on the server immediately after the
  /// profile is saved. Fire-and-forget — navigation is not blocked.
  void _triggerChartComputation(ProfileCompletionState state) {
    final DateTime? dob = state.dateOfBirth;
    final String? tob = state.timeOfBirth;
    final String place = _placeOfBirthController.text.trim();

    if (dob == null || tob == null || place.isEmpty) return;

    final String dobStr =
        '${dob.year.toString().padLeft(4, '0')}-'
        '${dob.month.toString().padLeft(2, '0')}-'
        '${dob.day.toString().padLeft(2, '0')}';

    // Invoke without awaiting — errors are swallowed; the chart will be
    // computed on the user's first feature request if this call fails.
    unawaited(
      Supabase.instance.client.functions
          .invoke(
            'compute-chart',
            body: <String, dynamic>{
              'dob': dobStr,
              'tob': tob,
              'place': place,
            },
          )
          .onError((_, __) => FunctionResponse(data: null, status: 0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthBloc>().state;
    final ProfileCompletionState completionState = context
        .watch<ProfileCompletionCubit>()
        .state;
    final String initialDisplayName = authState.user?.displayName ?? '';

    if (!_seededControllers && initialDisplayName.isNotEmpty) {
      _displayNameController.text = initialDisplayName;
      _seededControllers = true;
    }
    _zodiacController.text = completionState.zodiacSign;

    return BlocListener<ProfileCompletionCubit, ProfileCompletionState>(
      listenWhen:
          (ProfileCompletionState previous, ProfileCompletionState current) =>
              previous.errorMessage != current.errorMessage ||
              previous.status != current.status,
      listener: (BuildContext context, ProfileCompletionState state) {
        if (state.status == ProfileCompletionStatus.success) {
          // Kick off birth chart computation in the background.
          // The edge function caches the result; features degrade gracefully
          // if they open before it finishes.
          _triggerChartComputation(state);
          context.go('/home');
          return;
        }
        final String? message = state.errorMessage;
        if (message == null || message.isEmpty) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      child: Scaffold(
        body: AstroBackdrop(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: <Widget>[
                AstroPageHeader(
                  title: 'Complete profile',
                  subtitle: 'Add birth details before opening your readings.',
                  trailing: AstroTopIconButton(
                    icon: Icons.logout_rounded,
                    onTap: () => context.read<AuthBloc>().add(
                      const AuthSignOutRequested(),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const AstroHeroSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'One last step for accurate guidance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Google and Apple sign-in can land without saved birth details. Finish the profile once, then the rest of the app can rely on the same canonical record.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const AstroSectionHeader(
                  title: 'Birth identity',
                  action: 'Required',
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TextFormField(
                            controller: _displayNameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                              hintText: 'How should we address you?',
                            ),
                            validator: (String? value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Display name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _dateOfBirthController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Date of birth',
                              hintText: 'DD/MM/YYYY',
                              suffixIcon: Icon(Icons.calendar_month_outlined),
                            ),
                            onTap: _pickDateOfBirth,
                            validator: (String? value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Date of birth is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _timeOfBirthController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Time of birth',
                              hintText: 'HH:mm',
                              suffixIcon: Icon(Icons.schedule_outlined),
                            ),
                            onTap: _pickTimeOfBirth,
                            validator: (String? value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Time of birth is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _zodiacController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Zodiac sign',
                              hintText: 'Calculated from date of birth',
                            ),
                            validator: (String? value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Select a date of birth first';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _placeOfBirthController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Place of birth',
                              hintText: 'City, Country',
                            ),
                            validator: (String? value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Place of birth is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          BlocBuilder<
                            ProfileCompletionCubit,
                            ProfileCompletionState
                          >(
                            builder:
                                (
                                  BuildContext context,
                                  ProfileCompletionState state,
                                ) {
                                  return FilledButton(
                                    onPressed: state.isSubmitting
                                        ? null
                                        : _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.midnight,
                                    ),
                                    child: Text(
                                      state.isSubmitting
                                          ? 'Saving...'
                                          : 'Save profile',
                                    ),
                                  );
                                },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _parseTime(String? value) {
    final List<String> parts = (value ?? '06:00').split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 6,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }
}
