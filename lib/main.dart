import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

import 'onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HohayaApp());
}

class HohayaApp extends StatelessWidget {
  const HohayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hohaya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const OnboardingScreen(),
    );
  }
}
