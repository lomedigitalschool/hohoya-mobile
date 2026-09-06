import 'package:flutter/material.dart';

import '../screens/favorites_screen.dart';
import '../screens/profile_screen.dart';

class AppBottomNavBar extends StatelessWidget {
  final VoidCallback? onReturn;

  const AppBottomNavBar({super.key, this.onReturn});

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
            IconButton(
              icon: const Icon(Icons.favorite_border),
              tooltip: 'Mes favoris',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                );
                onReturn?.call();
              },
            ),
            const SizedBox(width: 40),
            IconButton(icon: const Icon(Icons.calendar_today_outlined), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Mon profil',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                onReturn?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
