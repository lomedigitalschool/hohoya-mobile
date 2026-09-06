import 'package:flutter/material.dart';

import 'onboarding_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_visit_requests_screen.dart';
import 'screens/owner_properties_screen.dart';
import 'screens/owner_visit_requests_screen.dart';
import 'screens/new_payment_screen.dart';
import 'screens/owner_revenue_screen.dart';
import 'screens/payment_history_screen.dart';
import 'screens/visit_stats_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
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
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/owner-properties': (context) => const OwnerPropertiesScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/my-visit-requests': (context) => const MyVisitRequestsScreen(),
        '/owner-visit-requests': (context) => const OwnerVisitRequestsScreen(),
        '/visit-stats': (context) => const VisitStatsScreen(),
        '/new-payment': (context) => const NewPaymentScreen(),
        '/payment-history': (context) => const PaymentHistoryScreen(),
        '/owner-revenue': (context) => const OwnerRevenueScreen(),
        '/favorites': (context) => const FavoritesScreen(),
      },
    );
  }
}
