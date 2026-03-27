import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/login_form_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => LoginFormCubit(),
      child: const _LoginPageBody(),
    );
  }
}

class _LoginPageBody extends StatefulWidget {
  const _LoginPageBody();

  @override
  State<_LoginPageBody> createState() => _LoginPageBodyState();
}

class _LoginPageBodyState extends State<_LoginPageBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(
    text: 'seeker@astrodaily.app',
  );
  final TapGestureRecognizer _termsTapRecognizer = TapGestureRecognizer();
  final TapGestureRecognizer _privacyTapRecognizer = TapGestureRecognizer();

  static final Uri _termsUrl = Uri.parse('https://mock.astrodaily.app/terms');
  static final Uri _privacyUrl = Uri.parse(
    'https://mock.astrodaily.app/privacy',
  );

  @override
  void initState() {
    super.initState();
    _termsTapRecognizer.onTap = () => _openUrl(_termsUrl);
    _privacyTapRecognizer.onTap = () => _openUrl(_privacyUrl);
  }

  @override
  void dispose() {
    _termsTapRecognizer.dispose();
    _privacyTapRecognizer.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await _submitWithEmail(_emailController.text.trim());
  }

  Future<void> _submitWithEmail(String email) async {
    context.read<LoginFormCubit>().setSubmitting(true);
    context.read<AuthBloc>().add(AuthSignInRequested(email));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) {
      return;
    }
    context.read<LoginFormCubit>().setSubmitting(false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
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
                        'Align your stars with Astro Daily',
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
                                'Welcome back',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in to continue with your personalized guidance.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 20),
                              BlocBuilder<LoginFormCubit, LoginFormState>(
                                builder: (BuildContext context,
                                    LoginFormState state) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      OutlinedButton.icon(
                                        onPressed: state.isSubmitting
                                            ? null
                                            : () => _submitWithEmail(
                                                'google.user@astrodaily.app',
                                              ),
                                        icon: const Icon(
                                            Icons.g_mobiledata_rounded),
                                        label: const Text(
                                            'Continue with Google'),
                                      ),
                                      const SizedBox(height: 10),
                                      OutlinedButton.icon(
                                        onPressed: state.isSubmitting
                                            ? null
                                            : () => _submitWithEmail(
                                                'apple.user@astrodaily.app',
                                              ),
                                        icon: const Icon(Icons.apple),
                                        label:
                                            const Text('Continue with Apple'),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: <Widget>[
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'or use email',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                key: const Key('login_email_field'),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'you@example.com',
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
                              const SizedBox(height: 16),
                              BlocBuilder<LoginFormCubit, LoginFormState>(
                                builder: (BuildContext context,
                                    LoginFormState state) {
                                  return FilledButton(
                                    key: const Key('login_continue_button'),
                                    onPressed: state.isSubmitting
                                        ? null
                                        : _submitEmail,
                                    child: state.isSubmitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                            ),
                                          )
                                        : const Text('Continue with Email'),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'New here?',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  TextButton(
                                    onPressed: () => context.push('/signup'),
                                    child: const Text('Sign up'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text.rich(
                                TextSpan(
                                  style: Theme.of(context).textTheme.bodySmall,
                                  children: <InlineSpan>[
                                    const TextSpan(
                                      text:
                                          'By continuing, you accept our ',
                                    ),
                                    TextSpan(
                                      text: 'Terms',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer: _termsTapRecognizer,
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer: _privacyTapRecognizer,
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                                textAlign: TextAlign.center,
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
    );
  }
}
