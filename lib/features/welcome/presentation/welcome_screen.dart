import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/satur_button.dart';
import '../../../core/widgets/satur_logo.dart';

/// Entry screen — Zaloguj (no-op) / Dołącz → join program.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SaturLogo(width: 280),
                    const SizedBox(height: 24),
                    Text(
                      'Witaj w Satur',
                      textAlign: TextAlign.center,
                      style: textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Twoje centrum technologii i biznesu.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SaturButton(
                label: 'Zaloguj się',
                // Intentionally empty — login screen not in this slice.
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              SaturButton(
                label: 'Dołącz do programu',
                variant: SaturButtonVariant.outline,
                onPressed: () => context.go('/join-program'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
