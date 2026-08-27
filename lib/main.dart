import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/owner_properties_screen.dart';
import 'screens/profile_screen.dart';
import 'onboarding_screen.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
      ),
      // L'application commence par l'onboarding
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/owner-properties': (context) => const OwnerPropertiesScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}