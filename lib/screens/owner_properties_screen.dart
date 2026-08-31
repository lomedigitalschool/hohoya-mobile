import 'package:flutter/material.dart';

import '../models/property.dart';
import '../services/property_service.dart';
import 'create_property_screen.dart';
import 'property_detail_screen.dart';

class OwnerPropertiesScreen extends StatefulWidget {
  const OwnerPropertiesScreen({super.key});

  @override
  State<OwnerPropertiesScreen> createState() => _OwnerPropertiesScreenState();
}

class _OwnerPropertiesScreenState extends State<OwnerPropertiesScreen> {
  final _service = PropertyService();
  late Future<List<Property>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _propertiesFuture = _service.fetchOwnerProperties();

  Future<void> _createProperty() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const CreatePropertyScreen()));
    if (created == true) setState(_reload);
  }

  Future<void> _editProperty(Property property) async {
    final updated = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreatePropertyScreen(property: property)));
    if (updated == true && mounted) setState(() {});
  }

  Future<void> _changeStatus(Property property) async {
    const statuses = {'active': 'Active', 'loué': 'Loué', 'vendu': 'Vendu', 'archivé': 'Archivé'};
    const allowedTransitions = {
      'pending': {'archivé'},
      'active': {'active', 'loué', 'vendu', 'archivé'},
      'loué': {'active', 'loué', 'vendu', 'archivé'},
      'vendu': {'vendu', 'archivé'},
      'archivé': {'active', 'archivé'},
    };
    final allowed = allowedTransitions[property.status] ?? <String>{};
    final status = await showModalBottomSheet<String>(context: context, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: statuses.entries.map((entry) => ListTile(enabled: allowed.contains(entry.key), title: Text(entry.value), trailing: property.status == entry.key ? const Icon(Icons.check, color: Colors.teal) : null, onTap: allowed.contains(entry.key) ? () => Navigator.pop(context, entry.key) : null)).toList())));
    if (status == null || !mounted) return;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Confirmer le changement'), content: Text('Marquer ce bien comme ${statuses[status]!.toLowerCase()} ?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer'))]));
    if (confirmed != true || !mounted) return;
    try {
      await _service.patchPropertyStatus(property.id, status);
    } on StateError catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (mounted) setState(() {});
  }

  Future<void> _deleteProperty(Property property) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Supprimer cette annonce ?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer'))]));
    if (confirmed != true) return;
    await _service.deleteProperty(property.id);
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon portefeuille')),
      floatingActionButton: FloatingActionButton(onPressed: _createProperty, tooltip: 'Créer une annonce', child: const Icon(Icons.add)),
      body: FutureBuilder<List<Property>>(
        future: _propertiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const _OwnerLoading();
          if (snapshot.hasError) return Center(child: FilledButton(onPressed: () => setState(_reload), child: const Text('Réessayer')));
          final properties = snapshot.data ?? [];
          if (properties.isEmpty) return const Center(child: Text('Publiez votre première annonce'));
          return RefreshIndicator(onRefresh: () async => setState(_reload), child: ListView.builder(padding: const EdgeInsets.only(top: 12, bottom: 90), itemCount: properties.length, itemBuilder: (context, index) {
            final property = properties[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: property, isOwner: true, onStatusChanged: () => setState(() {})))),
                leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(property.imageUrl, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.home_work_outlined, size: 48))),
                title: Text(property.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: _StatusBadge(status: property.status)),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editProperty(property);
                    if (value == 'status') _changeStatus(property);
                    if (value == 'delete') _deleteProperty(property);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Éditer')),
                    PopupMenuItem(value: 'status', child: Text('Changer le statut')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              ),
            );
          }));
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = {'pending': Colors.deepPurple, 'active': Colors.green, 'loué': Colors.orange, 'vendu': Colors.blue, 'archivé': Colors.grey}[status] ?? Colors.grey;
    final label = {'pending': 'En attente de validation', 'active': 'Active', 'loué': 'Loué', 'vendu': 'Vendu', 'archivé': 'Archivé'}[status] ?? status;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)));
  }
}

class _OwnerLoading extends StatelessWidget {
  const _OwnerLoading();
  @override
  Widget build(BuildContext context) => ListView.builder(itemCount: 4, itemBuilder: (_, index) => Container(height: 96, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))));
}
