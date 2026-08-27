import 'package:flutter/material.dart';

import '../models/property.dart';
import '../services/property_service.dart';
import 'public_profile_screen.dart';

class PropertyDetailScreen extends StatelessWidget {
  final Property property;
  final bool isOwner;
  final VoidCallback? onStatusChanged;

  const PropertyDetailScreen({super.key, required this.property, this.isOwner = false, this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.teal,
            actions: [
              if (isOwner)
                IconButton(onPressed: () => _openStatusSheet(context), icon: const Icon(Icons.more_vert), tooltip: 'Changer le statut'),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(property.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              background: Image.network(property.imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFE3F2FD),
                child: Icon(Icons.home_work_outlined, size: 72, color: Color(0xFF1565C0)),
              )),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${property.price.toStringAsFixed(0)} FCFA / mois', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [const Icon(Icons.location_on_outlined, color: Colors.teal), const SizedBox(width: 6), Text(property.city)]),
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: property.ownerId))), icon: const Icon(Icons.person_outline), label: const Text('Voir le profil du propriétaire')),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _Feature(icon: Icons.bed_outlined, label: '${property.bedrooms} chambres'),
                _Feature(icon: Icons.bathtub_outlined, label: '${property.bathrooms} salles de bain'),
                _Feature(icon: Icons.square_foot, label: '${property.area} m2'),
              ]),
              const SizedBox(height: 28),
              const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(property.description, style: const TextStyle(color: Colors.grey, height: 1.5)),
            ])),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(minimum: const EdgeInsets.all(16), child: FilledButton.icon(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact bientôt disponible'))),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Contacter le propriétaire'),
      )),
    );
  }

  Future<void> _openStatusSheet(BuildContext context) async {
    const statuses = {'active': 'Active', 'loué': 'Loué', 'vendu': 'Vendu', 'archivé': 'Archivé'};
    const allowed = {
      'pending': {'archivé'},
      'active': {'active', 'loué', 'vendu', 'archivé'},
      'loué': {'active', 'loué', 'vendu', 'archivé'},
      'vendu': {'vendu', 'archivé'},
      'archivé': {'active', 'archivé'},
    };
    final nextStatus = await showModalBottomSheet<String>(context: context, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: statuses.entries.map((entry) => ListTile(enabled: allowed[property.status]?.contains(entry.key) ?? false, title: Text(entry.value), onTap: (allowed[property.status]?.contains(entry.key) ?? false) ? () => Navigator.pop(context, entry.key) : null)).toList())));
    if (nextStatus == null || !context.mounted) return;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Confirmer le changement'), content: Text('Marquer ce bien comme ${statuses[nextStatus]!.toLowerCase()} ?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer'))]));
    if (confirmed != true || !context.mounted) return;
    try {
      await PropertyService().patchPropertyStatus(property.id, nextStatus);
      if (!context.mounted) return;
      onStatusChanged?.call();
    } on StateError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Feature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [Icon(icon, color: Colors.teal), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12))]);
}