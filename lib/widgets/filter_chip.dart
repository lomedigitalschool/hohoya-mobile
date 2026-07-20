import 'package:flutter/material.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const AppFilterChip({
    super.key,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.teal : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}