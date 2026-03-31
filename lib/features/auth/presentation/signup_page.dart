import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../core/widgets/astro_backdrop.dart';
import '../../../core/widgets/astro_page_components.dart';
import '../bloc/signup_form_cubit.dart';
import '../bloc/signup_form_state.dart';
import '../domain/entities/auth_profile.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignupFormCubit>(
      create: (BuildContext context) => sl<SignupFormCubit>(),
      child: const _SignupPageBody(),
    );
  }
}

class _SignupPageBody extends StatefulWidget {
  const _SignupPageBody();

  @override
  State<_SignupPageBody> createState() => _SignupPageBodyState();
}

class _SignupPageBodyState extends State<_SignupPageBody> {
  final GlobalKey<FormState> _identityFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _birthFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _zodiacController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _timeOfBirthController = TextEditingController();
  final TextEditingController _placeOfBirthController = TextEditingController();

  int _currentStep = 0;
  bool _requireEmailCredentials = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _zodiacController.dispose();
    _dateOfBirthController.dispose();
    _timeOfBirthController.dispose();
    _placeOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final DateTime today = DateTime.now();
    final SignupFormState formState = context.read<SignupFormCubit>().state;
    final DateTime initialDate =
        formState.dateOfBirth ??
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

    context.read<SignupFormCubit>().onDateOfBirthSelected(picked);
    _dateOfBirthController.text =
        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
  }

  Future<void> _pickTimeOfBirth() async {
    final SignupFormState formState = context.read<SignupFormCubit>().state;
    final List<String> timeParts =
        formState.timeOfBirth?.split(':') ?? <String>['6', '00'];
    final TimeOfDay initialTime = TimeOfDay(
      hour: int.tryParse(timeParts.first) ?? 6,
      minute: int.tryParse(timeParts.last) ?? 0,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null || !mounted) {
      return;
    }

    final String formattedTime = picked.format(context);
    context.read<SignupFormCubit>().onTimeOfBirthSelected(formattedTime);
    _timeOfBirthController.text = formattedTime;
  }

  void _goToNextStep() {
    final FormState? form = _identityFormKey.currentState;
    if (form?.validate() != true) {
      return;
    }
    setState(() {
      _currentStep = 1;
    });
  }

  bool _validateRequiredProfileDetails() {
    final bool identityValid = _nameController.text.trim().isNotEmpty;
    final bool birthValid = _birthFormKey.currentState?.validate() ?? false;
    return identityValid && birthValid;
  }

  Future<void> _submitEmail() async {
    setState(() {
      _requireEmailCredentials = true;
      _currentStep = 1;
    });
    if (!_validateRequiredProfileDetails()) {
      return;
    }

    await context.read<SignupFormCubit>().signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      profile: _buildProfile(),
    );
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _requireEmailCredentials = false;
      _currentStep = 1;
    });
    if (!_validateRequiredProfileDetails()) {
      return;
    }

    await context.read<SignupFormCubit>().signUpWithGoogle(_buildProfile());
  }

  Future<void> _submitApple() async {
    setState(() {
      _requireEmailCredentials = false;
      _currentStep = 1;
    });
    if (!_validateRequiredProfileDetails()) {
      return;
    }

    await context.read<SignupFormCubit>().signUpWithApple(_buildProfile());
  }

  AuthProfile _buildProfile() {
    return AuthProfile(
      displayName: _nameController.text.trim(),
      zodiacSign: _zodiacController.text.trim(),
      dateOfBirth: context.read<SignupFormCubit>().state.dateOfBirth!,
      timeOfBirth: _timeOfBirthController.text.trim(),
      placeOfBirth: _placeOfBirthController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return BlocListener<SignupFormCubit, SignupFormState>(
      listener: (BuildContext context, SignupFormState state) {
        _zodiacController.text = state.zodiacSign;

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          final String message = state.errorMessage!.replaceFirst(
            'AuthException: ',
            '',
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }

        if (state.status == SignupFormStatus.success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Account created. For email sign up, confirm your email before signing in.',
                ),
              ),
            );
        }
      },
      child: Scaffold(
        body: AstroBackdrop(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 38,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AstroPageHeader(
                          title: 'Create profile',
                          subtitle: 'Two steps to make guidance personal.',
                          onBack: () => context.go('/login'),
                          trailing: const AstroTopIconButton(
                            icon: Icons.auto_awesome_rounded,
                          ),
                        ),
                        const SizedBox(height: 22),
                        AstroHeroSurface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _currentStep == 0
                                    ? 'Start your\ncosmic profile'
                                    : 'Add birth details\nfor accurate guidance',
                                style: textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _currentStep == 0
                                    ? 'Keep the first step light. We only ask for the basics before moving into birth details.'
                                    : 'This is the data that powers horoscope, kundli, matching, numerology, and the upcoming chat companion.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.84),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _StepPill(
                                      stepNumber: 1,
                                      title: 'Identity',
                                      isActive: _currentStep == 0,
                                      isComplete: _currentStep > 0,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _StepPill(
                                      stepNumber: 2,
                                      title: 'Birth details',
                                      isActive: _currentStep == 1,
                                      isComplete: false,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _currentStep == 0
                              ? _IdentityStep(
                                  key: const ValueKey<String>('identity_step'),
                                  formKey: _identityFormKey,
                                  controller: _nameController,
                                  onContinue: _goToNextStep,
                                )
                              : _BirthStep(
                                  key: const ValueKey<String>('birth_step'),
                                  formKey: _birthFormKey,
                                  zodiacController: _zodiacController,
                                  dateOfBirthController: _dateOfBirthController,
                                  timeOfBirthController: _timeOfBirthController,
                                  placeOfBirthController:
                                      _placeOfBirthController,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  requireEmailCredentials:
                                      _requireEmailCredentials,
                                  onPickDate: _pickDateOfBirth,
                                  onPickTime: _pickTimeOfBirth,
                                  onBack: () {
                                    setState(() {
                                      _currentStep = 0;
                                      _requireEmailCredentials = false;
                                    });
                                  },
                                  onEmailSubmit: _submitEmail,
                                  onGoogleSubmit: _submitGoogle,
                                  onAppleSubmit: _submitApple,
                                ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Already have an account? Sign in'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({
    required this.formKey,
    required this.controller,
    required this.onContinue,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: AppTheme.cream.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Step 1', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            Text(
              'What should we call you?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'We use your name for a warmer, more personal daily ritual. The real astrology profile comes next.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: controller,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'Your name',
              ),
              validator: (String? value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: onContinue, child: const Text('Continue')),
          ],
        ),
      ),
    );
  }
}

class _BirthStep extends StatelessWidget {
  const _BirthStep({
    required this.formKey,
    required this.zodiacController,
    required this.dateOfBirthController,
    required this.timeOfBirthController,
    required this.placeOfBirthController,
    required this.emailController,
    required this.passwordController,
    required this.requireEmailCredentials,
    required this.onPickDate,
    required this.onPickTime,
    required this.onBack,
    required this.onEmailSubmit,
    required this.onGoogleSubmit,
    required this.onAppleSubmit,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController zodiacController;
  final TextEditingController dateOfBirthController;
  final TextEditingController timeOfBirthController;
  final TextEditingController placeOfBirthController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool requireEmailCredentials;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onBack;
  final VoidCallback onEmailSubmit;
  final VoidCallback onGoogleSubmit;
  final VoidCallback onAppleSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: AppTheme.cream.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Step 2', style: Theme.of(context).textTheme.labelSmall),
                const Spacer(),
                TextButton(onPressed: onBack, child: const Text('Back')),
              ],
            ),
            Text(
              'Birth details',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'These details make the experience feel like Astro Daily instead of a generic horoscope feed.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: zodiacController,
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Zodiac sign',
                hintText: 'Auto-calculated from date of birth',
              ),
              validator: (String? value) {
                if ((value ?? '').isEmpty) {
                  return 'Please select your date of birth first';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dateOfBirthController,
              readOnly: true,
              onTap: onPickDate,
              decoration: const InputDecoration(
                labelText: 'Date of birth',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (String? value) {
                if ((value ?? '').isEmpty) {
                  return 'Date of birth is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: timeOfBirthController,
              readOnly: true,
              onTap: onPickTime,
              decoration: const InputDecoration(
                labelText: 'Time of birth',
                suffixIcon: Icon(Icons.access_time_outlined),
              ),
              validator: (String? value) {
                if ((value ?? '').isEmpty) {
                  return 'Time of birth is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: placeOfBirthController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Place of birth',
                hintText: 'City, Country',
              ),
              validator: (String? value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Place of birth is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const _InlineDivider(label: 'Choose sign-up method'),
            const SizedBox(height: 18),
            BlocBuilder<SignupFormCubit, SignupFormState>(
              builder: (BuildContext context, SignupFormState state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: state.isSubmitting ? null : onGoogleSubmit,
                      icon: const Icon(Icons.g_mobiledata_rounded),
                      label: const Text('Continue with Google'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: state.isSubmitting ? null : onAppleSubmit,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppTheme.midnight,
                        foregroundColor: Colors.white,
                        side: BorderSide.none,
                      ),
                      icon: const Icon(Icons.apple),
                      label: const Text('Continue with Apple'),
                    ),
                    const SizedBox(height: 18),
                    const _InlineDivider(label: 'or use email'),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                      ),
                      validator: (String? value) {
                        if (!requireEmailCredentials) {
                          return null;
                        }
                        final String email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Email is required for email sign up';
                        }
                        if (!email.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (String? value) {
                        if (!requireEmailCredentials) {
                          return null;
                        }
                        if ((value ?? '').length < 8) {
                          return 'Password should be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppTheme.heroGradient,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppTheme.coral.withValues(alpha: 0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: state.isSubmitting ? null : onEmailSubmit,
                        child: state.isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Create account with Email'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.stepNumber,
    required this.title,
    required this.isActive,
    required this.isComplete,
  });

  final int stepNumber;
  final String title;
  final bool isActive;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final Color fill = isActive
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: isActive ? 0.36 : 0.16),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isComplete ? 0.24 : 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isComplete ? Icons.check_rounded : Icons.circle_outlined,
              color: Colors.white,
              size: isComplete ? 16 : 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$stepNumber. $title',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineDivider extends StatelessWidget {
  const _InlineDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
