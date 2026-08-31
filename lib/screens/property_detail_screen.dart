import 'package:flutter/material.dart';

import '../models/property.dart';
import '../services/property_service.dart';
import 'public_profile_screen.dart';
import 'visit_request_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;
  final String? propertyId;
  final bool isOwner;
  final VoidCallback? onStatusChanged;

  const PropertyDetailScreen({
    super.key,
    required this.property,
    this.propertyId,
    this.isOwner = false,
    this.onStatusChanged,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late Property _property;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isUnavailable => _property.isUnavailable;

  void _toggleFavorite() {
    setState(() => _property.isFavorite = !_property.isFavorite);
  }

  Future<void> _requestVisit() async {
    if (_isUnavailable) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitRequestScreen(property: _property),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gallery = _property.galleryImages;
    final statusLabel = {
      'active': 'Disponible',
      'pending': 'En attente',
      'loué': 'Loué',
      'vendu': 'Vendu',
      'archivé': 'Archivé',
    }[_property.status.toLowerCase()] ?? _property.status;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUnavailable ? null : _requestVisit,
        backgroundColor: _isUnavailable ? Colors.grey : null,
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(_isUnavailable ? 'Non disponible' : 'Demander une visite'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.teal,
            actions: [
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(_property.isFavorite ? Icons.favorite : Icons.favorite_border),
                tooltip: _property.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
              ),
              if (widget.isOwner)
                IconButton(onPressed: () => _openStatusSheet(context), icon: const Icon(Icons.more_vert), tooltip: 'Changer le statut'),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 50, 14),
              title: Text(_property.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              background: gallery.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFFE3F2FD),
                      child: Icon(Icons.home_work_outlined, size: 72, color: Color(0xFF1565C0)),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: gallery.length,
                      itemBuilder: (context, index) => Image.network(
                        gallery[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFE3F2FD),
                          child: Icon(Icons.home_work_outlined, size: 72, color: Color(0xFF1565C0)),
                        ),
                      ),
                    ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_property.price.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(_property.type, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isUnavailable ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: _isUnavailable ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(children: [const Icon(Icons.location_on_outlined, color: Colors.teal), const SizedBox(width: 6), Expanded(child: Text('${_property.city} • ${_property.neighborhood.isNotEmpty ? _property.neighborhood : _property.address}'))]),
                  const SizedBox(height: 20),
                  if (_isUnavailable)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                      child: const Text("Ce bien n'est plus disponible", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.teal.shade100,
                          child: Text(_property.ownerName.isNotEmpty ? _property.ownerName[0].toUpperCase() : 'P'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_property.ownerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(_property.ownerRating == null ? 'Nouveau' : '${_property.ownerRating!.toStringAsFixed(1)} (${_property.reviewCount} avis)'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: _property.ownerId))),
                          icon: const Icon(Icons.person_outline),
                          label: const Text('Voir profil'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _Feature(icon: Icons.bed_outlined, label: '${_property.bedrooms} chambres'),
                    _Feature(icon: Icons.bathtub_outlined, label: '${_property.bathrooms} sdb'),
                    _Feature(icon: Icons.square_foot, label: '${_property.area} m2'),
                  ]),
                  const SizedBox(height: 28),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_property.description, style: const TextStyle(color: Colors.grey, height: 1.5)),
                  const SizedBox(height: 20),
                  if (_property.address.isNotEmpty || _property.city.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_outlined, color: Colors.teal),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _property.address.isNotEmpty ? _property.address : '${_property.neighborhood} • ${_property.city}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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
    final nextStatus = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.entries.map((entry) => ListTile(
            enabled: allowed[_property.status]?.contains(entry.key) ?? false,
            title: Text(entry.value),
            onTap: (allowed[_property.status]?.contains(entry.key) ?? false) ? () => Navigator.pop(context, entry.key) : null,
          )).toList(),
        ),
      ),
    );
    if (nextStatus == null || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le changement'),
        content: Text('Marquer ce bien comme ${statuses[nextStatus]!.toLowerCase()} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await PropertyService().patchPropertyStatus(_property.id, nextStatus);
      if (!context.mounted) return;
      setState(() => _property.status = nextStatus);
      widget.onStatusChanged?.call();
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