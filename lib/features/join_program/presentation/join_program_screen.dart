import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/satur_colors.dart';
import '../../../core/widgets/satur_button.dart';
import '../../../core/widgets/satur_logo.dart';
import '../../../core/widgets/satur_text_field.dart';
import 'join_program_cubit.dart';
import 'join_program_state.dart';

class JoinProgramScreen extends StatefulWidget {
  const JoinProgramScreen({super.key});

  @override
  State<JoinProgramScreen> createState() => _JoinProgramScreenState();
}

class _JoinProgramScreenState extends State<JoinProgramScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<JoinProgramCubit, JoinProgramState>(
      listener: (context, state) {
        if (state is JoinProgramSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Zgłoszenie przyjęte')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: SaturColors.joinBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                const SaturLogo(width: 144),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SingleChildScrollView(
                        child: _JoinCard(
                          emailController: _emailController,
                          textTheme: textTheme,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/welcome'),
                  child: Text(
                    '← Wróć do strony głównej',
                    style: textTheme.labelMedium?.copyWith(
                      color: SaturColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: textTheme.bodyMedium?.copyWith(
                      color: SaturColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    children: [
                      const TextSpan(text: 'Masz już konto? '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          // No-op until login screen exists.
                          onTap: () {},
                          child: Text(
                            'Zaloguj się',
                            style: textTheme.bodyMedium?.copyWith(
                              color: SaturColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({
    required this.emailController,
    required this.textTheme,
  });

  final TextEditingController emailController;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SaturColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: SaturColors.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: BlocBuilder<JoinProgramCubit, JoinProgramState>(
          builder: (context, state) {
            final isSubmitting = state is JoinProgramSubmitting;
            final invalid = state is JoinProgramInvalidEmail;
            final failed = state is JoinProgramFailureState;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: SaturColors.skyBadgeBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: SaturColors.secondaryContainer.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    child: Text(
                      'BENEFITY ZAKUPOWE',
                      style: textTheme.labelMedium?.copyWith(
                        color: SaturColors.primaryContainer,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    children: [
                      const TextSpan(text: 'Dołącz do '),
                      TextSpan(
                        text: 'Satur',
                        style: TextStyle(color: SaturColors.skyAccent),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Platforma benefitów zakupowych.',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Wpisz swój firmowy adres e-mail, aby natychmiast aktywować '
                  'dostęp do podwójnych rabatów i ofert specjalnych dla Twojej firmy.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: SaturColors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                const _BenefitStatsRow(),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 360;
                    final field = SaturTextField(
                      controller: emailController,
                      hintText: 'twoj@firmowy.email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      enabled: !isSubmitting,
                      errorText: invalid
                          ? 'Podaj poprawny adres e-mail'
                          : failed
                              ? 'Nie udało się wysłać zgłoszenia'
                              : null,
                      onChanged: context.read<JoinProgramCubit>().emailChanged,
                      onSubmitted: (_) =>
                          context.read<JoinProgramCubit>().submit(),
                    );
                    final button = SaturCompactButton(
                      label: 'Zarejestruj się',
                      isLoading: isSubmitting,
                      onPressed: () =>
                          context.read<JoinProgramCubit>().submit(),
                    );

                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          field,
                          const SizedBox(height: 8),
                          button,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: field),
                        const SizedBox(width: 8),
                        button,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Bez spamu. Bezpieczna rejestracja w 1 minutę.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: SaturColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BenefitStatsRow extends StatelessWidget {
  const _BenefitStatsRow();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget cell(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                color: SaturColors.primaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: SaturColors.onSurfaceVariant,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9)),
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            cell('0 zł', 'koszt wdrożenia'),
            Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
            cell('2×', 'podwójny rabat'),
            Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
            cell('80%', 'max oszczędności'),
          ],
        ),
      ),
    );
  }
}
