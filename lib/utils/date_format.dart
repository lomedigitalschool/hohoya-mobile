const monthNames = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// Formats a date/time as "6 septembre 2026 à 14:32", used across visit and
/// payment screens.
String formatVisitDateTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '${dateTime.day} ${monthNames[dateTime.month - 1]} ${dateTime.year} à $hour:$minute';
}
