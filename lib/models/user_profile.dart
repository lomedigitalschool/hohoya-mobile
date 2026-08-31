import 'property.dart';
import '../screens/register_screen.dart' show UserRole;

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    required this.role,
    this.pictureUrl,
    this.properties = const [],
    this.rating,
    this.reviewCount = 0,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? pictureUrl;
  final List<Property> properties;
  final double? rating;
  final int reviewCount;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id']?.toString() ?? '',
    name: json['name'] ?? json['fullName'] ?? 'Utilisateur',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    role: _parseRole(json['role']),
    pictureUrl: json['pictureUrl'] ?? json['avatarUrl'],
    properties: (json['properties'] as List<dynamic>? ?? [])
        .map((item) => Property.fromJson(item as Map<String, dynamic>))
        .toList(),
    rating: (json['rating'] as num?)?.toDouble(),
    reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
  );

  UserProfile copyWith({
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    String? pictureUrl,
    List<Property>? properties,
    double? rating,
    int? reviewCount,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      pictureUrl: pictureUrl ?? this.pictureUrl,
      properties: properties ?? this.properties,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  static UserRole _parseRole(dynamic value) {
    final normalized = (value ?? '').toString().toLowerCase();
    if (normalized == 'proprietaire' || normalized == 'owner')
      return UserRole.proprietaire;
    return UserRole.locataire;
  }
}
