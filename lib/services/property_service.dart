import '../models/property.dart';
import '../models/user_profile.dart';
import '../screens/register_screen.dart' show UserRole;

class PropertyService {
  static const pageSize = 4;

  static final List<Property> _properties = [
    Property(
      id: '1',
      title: 'Appartement moderne au centre',
      city: 'Lome',
      neighborhood: 'Tokoin',
      type: 'Appartement',
      price: 350000,
      imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80',
      description: 'Un appartement lumineux proche des commerces et des services.',
      bedrooms: 2,
      bathrooms: 1,
      area: 85,
    ),
    Property(
      id: '2',
      title: 'Villa familiale avec jardin',
      city: 'Lome',
      neighborhood: 'Agoe',
      type: 'Villa',
      price: 850000,
      imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=900&q=80',
      description: 'Une villa spacieuse et calme, ideale pour une famille.',
      bedrooms: 4,
      bathrooms: 3,
      area: 210,
    ),
    Property(
      id: '3',
      title: 'Maison calme proche de la plage',
      city: 'Aneho',
      neighborhood: 'Centre-ville',
      type: 'Maison',
      price: 520000,
      imageUrl: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=900&q=80',
      description: 'Une maison agreable dans un quartier residentiel paisible.',
      bedrooms: 3,
      bathrooms: 2,
      area: 140,
    ),
    Property(
      id: '4',
      title: 'Studio meuble et lumineux',
      city: 'Kara',
      neighborhood: 'Chateau',
      type: 'Studio',
      price: 180000,
      imageUrl: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80',
      description: 'Un studio pret a vivre, parfait pour un premier logement.',
      bedrooms: 1,
      bathrooms: 1,
      area: 42,
    ),
    Property(
      id: '5',
      title: 'Appartement avec vue degagee',
      city: 'Lome',
      neighborhood: 'Bè',
      type: 'Appartement',
      price: 460000,
      imageUrl: 'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=900&q=80',
      description: 'Un appartement contemporain avec une belle vue sur la ville.',
      bedrooms: 3,
      bathrooms: 2,
      area: 120,
    ),
    Property(
      id: '6',
      title: 'Maison contemporaine',
      city: 'Sokode',
      neighborhood: 'Komah',
      type: 'Maison',
      price: 680000,
      imageUrl: 'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=900&q=80',
      description: 'Des espaces ouverts et une construction recente.',
      bedrooms: 3,
      bathrooms: 2,
      area: 165,
    ),
    Property(
      id: '7',
      title: 'Terrain residentiel viabilise',
      city: 'Lome',
      neighborhood: 'Adidogome',
      type: 'Terrain',
      price: 1200000,
      imageUrl: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=900&q=80',
      description: 'Terrain pret a construire dans un quartier en developpement.',
      area: 500,
    ),
    Property(
      id: '8',
      title: 'Bureau equipe en centre-ville',
      city: 'Lome',
      neighborhood: 'Cacaveli',
      type: 'Bureau',
      price: 400000,
      imageUrl: 'https://images.unsplash.com/photo-1497366811353-6870744d04b2?auto=format&fit=crop&w=900&q=80',
      description: 'Un espace professionnel lumineux et facile d acces.',
      area: 75,
    ),
    Property(
      id: '9',
      title: 'Local commercial avec vitrine',
      city: 'Kara',
      neighborhood: 'Tomdè',
      type: 'Commerce',
      price: 550000,
      imageUrl: 'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&w=900&q=80',
      description: 'Local visible sur un axe passant, ideal pour un commerce.',
      area: 90,
    ),
  ];

  static const _ownerPropertyIds = {'1', '5', '8'};

  Future<List<Property>> fetchProperties({
    String search = '',
    String city = '',
    String neighborhood = '',
    String type = 'Tous',
    double? minPrice,
    double? maxPrice,
    int page = 1,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final normalizedSearch = search.trim().toLowerCase();
    final normalizedCity = city.trim().toLowerCase();
    final normalizedNeighborhood = neighborhood.trim().toLowerCase();
    final filtered = _properties.where((property) {
      final matchesSearch = normalizedSearch.isEmpty || [property.title, property.city, property.neighborhood].any((value) => value.toLowerCase().contains(normalizedSearch));
      final matchesCity = normalizedCity.isEmpty || property.city.toLowerCase().contains(normalizedCity);
      final matchesNeighborhood = normalizedNeighborhood.isEmpty || property.neighborhood.toLowerCase() == normalizedNeighborhood;
      final matchesType = type == 'Tous' || property.type == type;
      final matchesMinPrice = minPrice == null || property.price >= minPrice;
      final matchesPrice = maxPrice == null || property.price <= maxPrice;
      return matchesSearch && matchesCity && matchesNeighborhood && matchesType && matchesMinPrice && matchesPrice;
    }).toList();
    final start = (page - 1) * pageSize;
    if (start >= filtered.length) return [];
    final end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  Future<void> addFavorite(String propertyId) async {}

  Future<void> removeFavorite(String propertyId) async {}

  Future<List<Property>> fetchOwnerProperties() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _properties.where((property) => _ownerPropertyIds.contains(property.id)).toList();
  }

  Future<Property> createProperty({required String title, required String city, required String neighborhood, required String address, required String type, required double price, required String priceType, required double deposit, required int bedrooms, required int bathrooms, required int area, required String description, List<String> images = const []}) async {
    final property = Property(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title, city: city, neighborhood: neighborhood, address: address, type: type, price: price, priceType: priceType, deposit: deposit, imageUrl: images.isEmpty ? 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=900&q=80' : images.first, images: images, bedrooms: bedrooms, bathrooms: bathrooms, area: area, description: description, status: 'pending');
    _properties.insert(0, property);
    return property;
  }

  Future<void> updateStatus(String propertyId, String status) async {
    final property = _properties.firstWhere((item) => item.id == propertyId);
    const allowedTransitions = {
      'pending': {'pending', 'archivé'},
      'active': {'active', 'loué', 'vendu', 'archivé'},
      'loué': {'loué', 'active', 'vendu', 'archivé'},
      'vendu': {'vendu', 'archivé'},
      'archivé': {'archivé', 'active'},
    };
    if (!allowedTransitions[property.status]!.contains(status)) {
      throw StateError('Transition impossible : ${property.status} vers $status');
    }
    property.status = status;
  }

  Future<void> patchPropertyStatus(String propertyId, String status) => updateStatus(propertyId, status);

  Future<void> deleteProperty(String propertyId) async {
    _properties.removeWhere((property) => property.id == propertyId);
  }

  Future<void> updateProperty(Property property, {required String title, required String city, required String neighborhood, required String type, required double price, required int bedrooms, required int bathrooms, required int area, required String description}) async {
    property.title = title;
    property.city = city;
    property.neighborhood = neighborhood;
    property.type = type;
    property.price = price;
    property.bedrooms = bedrooms;
    property.bathrooms = bathrooms;
    property.area = area;
    property.description = description;
  }

  Future<void> uploadPropertyImages(String propertyId, List<String> images) async {}

  Future<UserProfile> fetchUser(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final properties = _properties.where((property) => property.ownerId == userId && property.status != 'archivé').toList();
    return UserProfile(id: userId, name: 'Agence Hohaya', role: UserRole.proprietaire, properties: properties);
  }
}