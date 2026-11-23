import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';

class LoginFormField extends StatelessWidget {
  const LoginFormField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05 * 12,
            color: SaturColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: SaturColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: SaturColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: SaturColors.outlineVariant),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onChanged: onChanged,
                  cursorColor: SaturColors.primary,
                  decoration: InputDecoration(
                    hintText: hintText,
                    isDense: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      color: SaturColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    color: SaturColors.onSurface,
                  ),
                ),
              ),
              ?suffix,
            ],
          ),
        ),
      ],
    );
  }
}
