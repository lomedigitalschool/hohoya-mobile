import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum SocialProvider { google, apple }

class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.provider,
    required this.onPressed,
  });

  final String label;
  final SocialProvider provider;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: switch (provider) {
        SocialProvider.google => const Text(
            'G',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEA4335)),
          ),
        SocialProvider.apple => const Icon(Icons.apple, size: 20, color: Colors.black),
      },
      label: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
