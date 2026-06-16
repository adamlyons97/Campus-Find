import 'package:flutter/material.dart';

/// A labelled, validated text field used across the auth forms
/// (Feature 1 — automatic field validation).
class AuthValidatorField extends StatelessWidget {
  const AuthValidatorField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
        ),
      ),
    );
  }
}

/// Common validators kept here so the same rules apply everywhere.
class Validators {
  static String? requiredField(String? v, {String field = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required.';
    final pattern = RegExp(r'^[\w.\-]+@[\w\-]+\.[\w.\-]+$');
    if (!pattern.hasMatch(v.trim())) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required.';
    if (v.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }
}
