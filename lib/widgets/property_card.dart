import 'package:flutter/material.dart';

import '../models/property.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.grey.shade100,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(
                    property.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFFE3F2FD),
                      child: Icon(Icons.home_work_outlined, size: 52, color: Color(0xFF1565C0)),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: property.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                      icon: Icon(property.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.teal),
                      onPressed: onFavoriteTap,
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Chip(label: Text(property.type), visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${property.price.toStringAsFixed(0)} FCFA / mois', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(property.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(property.city, style: const TextStyle(color: Colors.grey)),
                    const Spacer(),
                    Text('${property.bedrooms} ch.  ${property.area} m2', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
