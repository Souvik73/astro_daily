import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/auth_environment.dart';
import '../../../core/di/injection.dart';
import '../../../core/widgets/astro_backdrop.dart';
import 'auth_provider_visibility.dart';
import '../bloc/login_form_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginFormCubit>(
      create: (BuildContext context) => sl<LoginFormCubit>(),
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await context.read<LoginFormCubit>().signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _submitGoogle() {
    return context.read<LoginFormCubit>().signInWithGoogle();
  }

  Future<void> _submitApple() {
    return context.read<LoginFormCubit>().signInWithApple();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool showGoogleAuthButton = shouldShowGoogleAuthButton(
      googleServerClientId: AuthEnvironment.googleServerClientId,
      googleIosClientId: AuthEnvironment.googleIosClientId,
      googleMacosSignInEnabled: AuthEnvironment.googleMacosSignInEnabled,
      isWeb: kIsWeb,
      targetPlatform: defaultTargetPlatform,
    );
    final bool showAppleAuthButton = shouldShowAppleAuthButton(
      appleSignInEnabled: AuthEnvironment.appleSignInEnabled,
      isWeb: kIsWeb,
      targetPlatform: defaultTargetPlatform,
    );

    return BlocListener<LoginFormCubit, LoginFormState>(
      listenWhen: (LoginFormState previous, LoginFormState current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (BuildContext context, LoginFormState state) {
        final String message = state.errorMessage!.replaceFirst(
          'AuthException: ',
          '',
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
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
                        _TopBar(
                          title: 'Astro Daily',
                          subtitle: 'Personalized guidance, softened access.',
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: AppTheme.heroGradient,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Align with today’s\ncosmic rhythm',
                                style: textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'The login flow now feels like a premium astrology ritual instead of a generic utility form.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  _HeroChip('Daily guidance'),
                                  _HeroChip('Free + Premium'),
                                  _HeroChip('Profile-led insights'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                          decoration: BoxDecoration(
                            color: AppTheme.cream.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppTheme.border),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppTheme.midnight.withValues(
                                  alpha: 0.06,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Center(
                                  child: Text(
                                    'Welcome back',
                                    style: textTheme.headlineMedium,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    'Continue with the account that holds your chart and daily guidance.',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                BlocBuilder<LoginFormCubit, LoginFormState>(
                                  builder:
                                      (
                                        BuildContext context,
                                        LoginFormState state,
                                      ) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: <Widget>[
                                            if (showGoogleAuthButton)
                                              OutlinedButton.icon(
                                                onPressed: state.isSubmitting
                                                    ? null
                                                    : _submitGoogle,
                                                icon: const Icon(
                                                  Icons.g_mobiledata_rounded,
                                                ),
                                                label: const Text(
                                                  'Continue with Google',
                                                ),
                                              ),
                                            if (showAppleAuthButton) ...<
                                              Widget
                                            >[
                                              if (showGoogleAuthButton)
                                                const SizedBox(height: 10),
                                              OutlinedButton.icon(
                                                onPressed: state.isSubmitting
                                                    ? null
                                                    : _submitApple,
                                                style: OutlinedButton.styleFrom(
                                                  backgroundColor:
                                                      AppTheme.midnight,
                                                  foregroundColor: Colors.white,
                                                  side: BorderSide.none,
                                                ),
                                                icon: const Icon(Icons.apple),
                                                label: const Text(
                                                  'Continue with Apple',
                                                ),
                                              ),
                                            ],
                                          ],
                                        );
                                      },
                                ),
                                const SizedBox(height: 18),
                                const _InlineDivider(label: 'or use email'),
                                const SizedBox(height: 18),
                                TextFormField(
                                  key: const Key('login_email_field'),
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'seeker@astrodaily.app',
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
                                  key: const Key('login_password_field'),
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                  ),
                                  validator: (String? value) {
                                    if ((value ?? '').length < 8) {
                                      return 'Enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                BlocBuilder<LoginFormCubit, LoginFormState>(
                                  builder:
                                      (
                                        BuildContext context,
                                        LoginFormState state,
                                      ) {
                                        return DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: AppTheme.heroGradient,
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                            boxShadow: <BoxShadow>[
                                              BoxShadow(
                                                color: AppTheme.coral
                                                    .withValues(alpha: 0.22),
                                                blurRadius: 18,
                                                offset: const Offset(0, 12),
                                              ),
                                            ],
                                          ),
                                          child: FilledButton(
                                            key: const Key(
                                              'login_continue_button',
                                            ),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                            ),
                                            onPressed: state.isSubmitting
                                                ? null
                                                : _submitEmail,
                                            child: state.isSubmitting
                                                ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Text(
                                                    'Continue with Email',
                                                  ),
                                          ),
                                        );
                                      },
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      'New here?',
                                      style: textTheme.bodyMedium,
                                    ),
                                    TextButton(
                                      onPressed: () => context.push('/signup'),
                                      child: const Text('Create profile'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text.rich(
                                  TextSpan(
                                    style: textTheme.bodySmall,
                                    children: <InlineSpan>[
                                      const TextSpan(
                                        text: 'By continuing, you accept our ',
                                      ),
                                      TextSpan(
                                        text: 'Terms',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppTheme.berry,
                                        ),
                                        recognizer: _termsTapRecognizer,
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppTheme.berry,
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.berry),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: textTheme.titleLarge),
              Text(subtitle, style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: Colors.white),
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
