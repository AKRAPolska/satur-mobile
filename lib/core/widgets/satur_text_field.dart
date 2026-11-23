import 'package:flutter/material.dart';

class SaturTextField extends StatelessWidget {
  const SaturTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
      ),
    );
  }
}
