import 'package:flutter/material.dart';

class PropertyCard extends StatelessWidget {
  final String title;
  final String address;
  final String imageUrl;
  final int beds;
  final int baths;
  final int sqft;
  final VoidCallback? onTap;

  const PropertyCard({
    super.key,
    required this.title,
    required this.address,
    required this.imageUrl,
    required this.beds,
    required this.baths,
    required this.sqft,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(address, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.bed, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('$beds Bed', style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 8),
                        const Icon(Icons.bathtub, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('$baths Bath', style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 8),
                        const Icon(Icons.square_foot, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('$sqft sq ft', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}