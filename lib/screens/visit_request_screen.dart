import 'package:flutter/material.dart';

import '../models/property.dart';
import '../services/visit_request_service.dart';
import '../utils/date_format.dart';

const _timeSlots = [
  '08:00', '09:00', '10:00', '11:00', '12:00',
  '14:00', '15:00', '16:00', '17:00', '18:00',
];

class VisitRequestSheet extends StatefulWidget {
  final Property property;

  const VisitRequestSheet({super.key, required this.property});

  static Future<DateTime?> show(BuildContext context, Property property) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => VisitRequestSheet(property: property),
    );
  }

  @override
  State<VisitRequestSheet> createState() => _VisitRequestSheetState();
}

class _VisitRequestSheetState extends State<VisitRequestSheet> {
  final _messageController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedSlot;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _errorMessage = null;
      });
    }
  }

  DateTime? get _scheduledAt {
    if (_selectedDate == null || _selectedSlot == null) return null;
    final parts = _selectedSlot!.split(':');
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Future<void> _submit() async {
    final scheduledAt = _scheduledAt;
    if (scheduledAt == null) {
      setState(() => _errorMessage = 'Veuillez choisir une date et un créneau horaire.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await VisitRequestService().requestVisit(
        property: widget.property,
        scheduledAt: scheduledAt,
        message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, scheduledAt);
    } on VisitRequestFailure catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = "Impossible d'envoyer la demande de visite. Réessayez.");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const Text(
              'Planifier une visite',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.property.title,
              style: const TextStyle(color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _selectedDate == null
                      ? 'Choisir une date'
                      : '${_selectedDate!.day} ${monthNames[_selectedDate!.month - 1]} ${_selectedDate!.year}',
                  style: TextStyle(color: _selectedDate == null ? Colors.grey.shade600 : null),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Créneau horaire', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((slot) {
                final selected = _selectedSlot == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _selectedSlot = slot;
                    _errorMessage = null;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Message (optionnel)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Précisez une info utile pour le propriétaire',
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(_isSubmitting ? 'Envoi en cours...' : 'Envoyer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
