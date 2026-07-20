import 'package:flutter/material.dart';
import 'filter_chip.dart';

class TrendingFilters extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;

  const TrendingFilters({
    super.key,
    required this.filters,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending Now',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: filters
                  .map((f) => AppFilterChip(
                        label: f,
                        selected: f == selectedFilter,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}