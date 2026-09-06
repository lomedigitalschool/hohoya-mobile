import 'package:flutter/material.dart';

import '../models/property.dart';
import '../services/property_service.dart';
import '../widgets/property_card.dart';
import 'property_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Property>> _favorites;
  List<Property> _displayedFavorites = [];
  final _service = PropertyService();
  ScaffoldMessengerState? _messenger;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    // Avoid an "Annuler" SnackBar from this screen bleeding into whatever
    // screen is revealed once this one is popped.
    _messenger?.clearSnackBars();
    super.dispose();
  }

  void _loadFavorites() {
    _favorites = _service.fetchFavorites().then((list) {
      setState(() => _displayedFavorites = list);
      return list;
    });
  }

  Future<void> _removeFavorite(Property property) async {
    final index = _displayedFavorites.indexOf(property);
    setState(() => _displayedFavorites.removeAt(index));

    try {
      await _service.removeFavorite(property.id);
      property.isFavorite = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${property.title} retiré des favoris'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () async {
              try {
                await _service.addFavorite(property.id);
                property.isFavorite = true;
                if (!mounted) return;
                setState(() => _displayedFavorites.insert(index, property));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: ${e.toString()}')),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _displayedFavorites.insert(index, property));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes favoris'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<Property>>(
        future: _favorites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _loadFavorites,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (_displayedFavorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun favori',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explorez les annonces et sauvegardez vos préférées',
                    style: TextStyle(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('Découvrir les biens'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _displayedFavorites.length,
            itemBuilder: (context, index) {
              final property = _displayedFavorites[index];
              return Dismissible(
                key: ValueKey(property.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade500,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => _removeFavorite(property),
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailScreen(property: property),
                      ),
                    );
                    // The heart on the detail screen may have unfavorited this
                    // property (same shared instance); drop it from this list.
                    if (mounted && !property.isFavorite) {
                      setState(() => _displayedFavorites.removeWhere((p) => p.id == property.id));
                    }
                  },
                  child: PropertyCard(
                    property: property,
                    onTap: () {},
                    onFavoriteTap: () => _removeFavorite(property),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}