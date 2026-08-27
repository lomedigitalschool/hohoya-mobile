import 'property.dart';

class UserProfile {
  final String id;
  final String name;
  final String? pictureUrl;
  final String role;
  final List<Property> properties;
  final double? rating;
  final int reviewCount;

  const UserProfile({required this.id, required this.name, this.pictureUrl, required this.role, this.properties = const [], this.rating, this.reviewCount = 0});

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'].toString(),
    name: json['name'] ?? json['fullName'] ?? 'Utilisateur',
    pictureUrl: json['pictureUrl'] ?? json['avatarUrl'],
    role: json['role'] ?? 'tenant',
    properties: (json['properties'] as List<dynamic>? ?? []).map((item) => Property.fromJson(item as Map<String, dynamic>)).toList(),
    rating: (json['rating'] as num?)?.toDouble(),
    reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
  );
}