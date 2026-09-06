import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hohaya/main.dart';
import 'package:hohaya/models/property.dart';
import 'package:hohaya/screens/property_detail_screen.dart';

void main() {
  testWidgets('displays onboarding content and next action', (tester) async {
    await tester.pumpWidget(const HohayaApp());

    expect(find.text('Trouvez votre bien idéal'), findsOneWidget);
    expect(find.text('Découvrir les biens qui correspondent à votre style de vie'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });

  testWidgets('shows visit CTA for available properties', (tester) async {
    final property = Property(
      id: 'p-1',
      title: 'Appartement de test',
      city: 'Lome',
      neighborhood: 'Tokoin',
      type: 'Appartement',
      price: 350000,
      imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
      description: 'Appartement test',
      bedrooms: 2,
      bathrooms: 1,
      area: 80,
      status: 'active',
      ownerName: 'Awa Kpodzro',
      ownerRating: 4.8,
      reviewCount: 14,
    );

    await tester.pumpWidget(MaterialApp(home: PropertyDetailScreen(property: property)));

    expect(find.text('Demander une visite'), findsOneWidget);
    final visitButton = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
    expect(visitButton.onPressed, isNotNull);
  });

  testWidgets('disables visit CTA for unavailable properties', (tester) async {
    final property = Property(
      id: 'p-2',
      title: 'Appartement indisponible',
      city: 'Lome',
      neighborhood: 'Bè',
      type: 'Appartement',
      price: 280000,
      imageUrl: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85',
      description: 'Appartement indisponible',
      bedrooms: 1,
      bathrooms: 1,
      area: 60,
      status: 'vendu',
      ownerName: 'Awa Kpodzro',
      ownerRating: 4.8,
      reviewCount: 14,
    );

    await tester.pumpWidget(MaterialApp(home: PropertyDetailScreen(property: property)));
    await tester.pumpAndSettle();

    final disabledButton = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
    expect(disabledButton.onPressed, isNull);
    expect(find.text('Non disponible'), findsOneWidget);
  });

  testWidgets('visit CTA button triggers navigation', (tester) async {
    final property = Property(
      id: 'p-3',
      title: 'Appartement de test',
      city: 'Lome',
      neighborhood: 'Tokoin',
      type: 'Appartement',
      price: 390000,
      imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
      description: 'Appartement test',
      bedrooms: 2,
      bathrooms: 1,
      area: 78,
      status: 'active',
      ownerName: 'Awa Kpodzro',
      ownerRating: 4.8,
      reviewCount: 14,
    );

    await tester.pumpWidget(MaterialApp(home: PropertyDetailScreen(property: property)));

    expect(find.text('Demander une visite'), findsOneWidget);
    final visitButton = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
    expect(visitButton.onPressed, isNotNull);
  });
}