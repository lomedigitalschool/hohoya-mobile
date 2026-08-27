import 'package:flutter/material.dart';

class PropertySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;
  final VoidCallback onFilterTap;
  final int activeFilterCount;

  const PropertySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    this.suggestions = const [],
    required this.onSuggestionTap,
    required this.onFilterTap,
    this.activeFilterCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un bien...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(14)),
                    child: IconButton(tooltip: 'Filtres', icon: const Icon(Icons.tune, color: Colors.white), onPressed: onFilterTap),
                  ),
                  if (activeFilterCount > 0)
                    Positioned(
                      right: -4,
                      top: -6,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text('$activeFilterCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8)],
              ),
              child: Column(
                children: suggestions.take(5).map((suggestion) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.history, size: 18, color: Colors.grey),
                  title: Text(suggestion),
                  onTap: () => onSuggestionTap(suggestion),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
