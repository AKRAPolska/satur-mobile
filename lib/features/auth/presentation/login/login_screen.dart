import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/core/widgets/satur_button.dart';
import 'package:satur_app/core/widgets/satur_logo.dart';
import 'package:satur_app/features/auth/domain/auth_failure.dart';
import 'package:satur_app/features/auth/presentation/login/login_cubit.dart';
import 'package:satur_app/features/auth/presentation/login/login_state.dart';
import 'package:satur_app/features/auth/presentation/login/widgets/login_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _errorMessage(LoginState state) {
    if (state is! LoginFailureState) return null;
    return switch (state.failure) {
      AuthInvalidCredentialsFailure() => 'Nieprawidłowy e-mail lub hasło.',
      AuthNetworkFailure() => 'Brak połączenia. Spróbuj ponownie.',
      AuthHttpFailure() || AuthUnknownFailure() =>
        'Nie udało się zalogować. Spróbuj ponownie.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaturColors.surfaceContainerLowest,
      body: SafeArea(
        child: BlocConsumer<LoginCubit, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              context.go('/products');
            }
          },
          builder: (context, state) {
            final submitting = state is LoginSubmitting;
            final error = _errorMessage(state);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SaturLogo(width: 160),
                    const SizedBox(height: 24),
                    const Text(
                      'Zaloguj się',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: SaturColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Wprowadź swoje dane, aby kontynuować',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: SaturColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LoginFormField(
                      label: 'Email',
                      controller: _email,
                      icon: Icons.mail_outline,
                      hintText: 'jan@firma.pl',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: context.read<LoginCubit>().emailChanged,
                    ),
                    const SizedBox(height: 16),
                    LoginFormField(
                      label: 'Hasło',
                      controller: _password,
                      icon: Icons.lock_outline,
                      hintText: 'Wpisz swoje hasło',
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onChanged: context.read<LoginCubit>().passwordChanged,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: SaturColors.outlineVariant,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        splashRadius: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {}, // forgot password no-op
                        style: TextButton.styleFrom(
                          foregroundColor: SaturColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Nie pamiętasz hasła?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SaturColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SaturButton(
                      label: 'Zaloguj się',
                      onPressed: submitting
                          ? null
                          : () => context.read<LoginCubit>().submit(),
                    ),
                    if (submitting) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: SaturColors.borderLight)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'LUB',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: SaturColors.outlineVariant,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: SaturColors.borderLight)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: SaturColors.onSurfaceVariant,
                        ),
                        children: [
                          const TextSpan(text: 'Nie masz konta? '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => context.go('/join-program'),
                              child: const Text(
                                'Dołącz do programu',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: SaturColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
