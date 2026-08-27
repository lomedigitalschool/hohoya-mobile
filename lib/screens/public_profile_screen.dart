import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/property_service.dart';
import '../widgets/property_card.dart';
import 'property_detail_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<UserProfile> _profile;

  @override
  void initState() {
    super.initState();
    _profile = PropertyService().fetchUser(widget.userId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profil utilisateur')),
    body: FutureBuilder<UserProfile>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: FilledButton(onPressed: () => setState(() => _profile = PropertyService().fetchUser(widget.userId)), child: const Text('Réessayer')));
        final profile = snapshot.data!;
        return ListView(padding: const EdgeInsets.all(20), children: [
          Center(child: CircleAvatar(radius: 48, backgroundImage: profile.pictureUrl == null ? null : NetworkImage(profile.pictureUrl!), child: profile.pictureUrl == null ? const Icon(Icons.person, size: 48) : null)),
          const SizedBox(height: 12),
          Center(child: Text(profile.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          Center(child: Text(profile.role == 'owner' ? 'Propriétaire' : 'Locataire', style: const TextStyle(color: Colors.grey))),
          if (profile.rating != null) Center(child: Padding(padding: const EdgeInsets.only(top: 8), child: Text('★ ${profile.rating!.toStringAsFixed(1)} (${profile.reviewCount} avis)'))),
          const SizedBox(height: 28),
          if (profile.role == 'owner') ...[
            Text('Biens publiés (${profile.properties.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...profile.properties.map((property) => PropertyCard(
              property: property,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: property))),
              onFavoriteTap: () {},
            )),
          ],
          if (profile.role != 'owner') const Center(child: Text('Aucun bien publié')),
          if (profile.rating == null) const Padding(padding: EdgeInsets.only(top: 16), child: Text('Les avis et notes ne sont pas encore disponibles.', style: TextStyle(color: Colors.grey))),
        ]);
      },
    ),
  );
}