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
<<<<<<< HEAD
      theme: AppTheme.light,
=======
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
      ),
>>>>>>> 5d952171a042169ccba98fcd036f4b286b9a7568
      home: const OnboardingScreen(),
    );
  }
}
