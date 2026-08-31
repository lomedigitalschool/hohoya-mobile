import 'package:flutter/material.dart';

import '../screens/profile_screen.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home), onPressed: () {}),
            IconButton(icon: const Icon(Icons.explore_outlined), onPressed: () {}),
            const SizedBox(width: 40),
            IconButton(icon: const Icon(Icons.calendar_today_outlined), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Mon profil',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
