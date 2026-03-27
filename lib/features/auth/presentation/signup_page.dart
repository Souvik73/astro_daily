import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/signup_form_cubit.dart';
import '../bloc/signup_form_state.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => SignupFormCubit(),
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _zodiacController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _timeOfBirthController = TextEditingController();
  final TextEditingController _placeOfBirthController = TextEditingController();

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

    if (picked == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    context.read<SignupFormCubit>().onDateOfBirthSelected(picked);
    _dateOfBirthController.text =
        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
  }

  Future<void> _pickTimeOfBirth() async {
    final SignupFormState formState = context.read<SignupFormCubit>().state;
    final List<String> timeParts =
        formState.timeOfBirth?.split(':') ?? ['6', '00'];
    final TimeOfDay initialTime = TimeOfDay(
      hour: int.tryParse(timeParts.first) ?? 6,
      minute: int.tryParse(timeParts.last) ?? 0,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final String formattedTime = picked.format(context);
    context.read<SignupFormCubit>().onTimeOfBirthSelected(formattedTime);
    _timeOfBirthController.text = formattedTime;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final SignupFormCubit signupFormCubit = context.read<SignupFormCubit>();

    final String birthSummary =
        '${_dateOfBirthController.text}, ${_timeOfBirthController.text}, ${_placeOfBirthController.text.trim()}';

    signupFormCubit.onFormSubmitting();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sign up submitted (mock flow) for ${_nameController.text.trim()} - $birthSummary',
        ),
      ),
    );
    context.read<AuthBloc>().add(AuthSignInRequested(_emailController.text));
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }
    signupFormCubit.onFormSubmitSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return BlocListener<SignupFormCubit, SignupFormState>(
      listenWhen: (SignupFormState previous, SignupFormState current) =>
          previous.zodiacSign != current.zodiacSign,
      listener: (BuildContext context, SignupFormState state) {
        _zodiacController.text = state.zodiacSign;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                colorScheme.primaryContainer.withValues(alpha: 0.35),
                colorScheme.surface,
                const Color(0xFFFFF4D8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Stack(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          'Create your cosmic profile',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: constraints.maxHeight * 0.85,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Center(
                                  child: Container(
                                    height: 4,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      color: colorScheme.outlineVariant,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Sign up',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your details to personalize kundli and daily insights.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Full name',
                                  ),
                                  validator: (String? value) {
                                    if ((value?.trim() ?? '').isEmpty) {
                                      return 'Name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                  validator: (String? value) {
                                    final String email = value?.trim() ?? '';
                                    if (email.isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!email.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                  ),
                                  validator: (String? value) {
                                    if ((value ?? '').length < 8) {
                                      return 'Password should be at least 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _zodiacController,
                                  readOnly: true,
                                  enabled: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Zodiac sign',
                                    hintText:
                                        'Auto-calculated from date of birth',
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
                                  controller: _dateOfBirthController,
                                  readOnly: true,
                                  onTap: _pickDateOfBirth,
                                  decoration: const InputDecoration(
                                    labelText: 'Date of birth',
                                    suffixIcon: Icon(
                                      Icons.calendar_today_outlined,
                                    ),
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
                                  controller: _timeOfBirthController,
                                  readOnly: true,
                                  onTap: _pickTimeOfBirth,
                                  decoration: const InputDecoration(
                                    labelText: 'Time of birth',
                                    suffixIcon: Icon(
                                      Icons.access_time_outlined,
                                    ),
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
                                  controller: _placeOfBirthController,
                                  textInputAction: TextInputAction.done,
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
                                FilledButton(
                                  onPressed: _submit,
                                  child: const Text('Create account'),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () => context.go('/login'),
                                  child: const Text(
                                    'Already have an account? Sign in',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
