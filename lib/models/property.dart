class Property {
  final String id;
  String title;
  String city;
  String neighborhood;
  String type; // ex: 'House', 'Apartment', 'Villa'
  double price;
  final String imageUrl;
  final String ownerId;
  String description;
  int bedrooms;
  int bathrooms;
  int area;
  String status;
  String address;
  String priceType;
  double deposit;
  List<String> images;
  bool isFavorite;

  Property({
    required this.id,
    required this.title,
    required this.city,
    this.neighborhood = '',
    required this.type,
    required this.price,
    required this.imageUrl,
    this.ownerId = 'owner-1',
    this.description = '',
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.area = 0,
    this.status = 'active',
    this.address = '',
    this.priceType = 'location',
    this.deposit = 0,
    this.images = const [],
    this.isFavorite = false,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      city: json['city'] ?? '',
      neighborhood: json['neighborhood'] ?? json['district'] ?? '',
      type: json['type'] ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      ownerId: json['ownerId']?.toString() ?? 'owner-1',
      description: json['description'] ?? '',
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 0,
      area: (json['area'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'active',
      address: json['address'] ?? '',
      priceType: json['priceType'] ?? 'location',
      deposit: (json['deposit'] as num?)?.toDouble() ?? 0,
      images: List<String>.from(json['images'] ?? const []),
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}