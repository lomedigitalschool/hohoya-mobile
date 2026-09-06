import 'package:flutter/material.dart';

import '../models/property.dart';
import '../services/property_service.dart';

/// Optimistically toggles [property]'s favorite state, persists it, and reverts
/// with an error SnackBar if the request fails. [onChanged] should trigger a
/// rebuild of whatever is displaying [property] (it is mutated in place).
Future<void> toggleFavorite(
  BuildContext context,
  Property property, {
  required VoidCallback onChanged,
}) async {
  property.isFavorite = !property.isFavorite;
  onChanged();
  try {
    if (property.isFavorite) {
      await PropertyService().addFavorite(property.id);
    } else {
      await PropertyService().removeFavorite(property.id);
    }
  } catch (_) {
    if (!context.mounted) return;
    property.isFavorite = !property.isFavorite;
    onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible de modifier le favori')),
    );
  }
}
