import 'package:flutter/material.dart';

import '../models/visit_request.dart';
import '../services/visit_request_service.dart';
import '../utils/date_format.dart';

const visitStatusLabels = {
  'pending': 'En attente',
  'accepted': 'Acceptée',
  'refused': 'Refusée',
  'completed': 'Terminée',
};

const visitStatusColors = {
  'pending': Colors.orange,
  'accepted': Colors.green,
  'refused': Colors.red,
  'completed': Colors.blueGrey,
};

/// Shows the shared "reason for refusal" dialog used by both the owner's list
/// screen and this detail screen. Returns null if cancelled, or the trimmed
/// reason (possibly empty, since the motif is optional) if confirmed.
Future<String?> showRefusalReasonDialog(BuildContext context) {
  final reasonController = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Refuser la demande'),
      content: TextField(
        controller: reasonController,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Motif (optionnel)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: () => Navigator.pop(context, reasonController.text.trim()),
          child: const Text('Refuser'),
        ),
      ],
    ),
  );
}

class VisitRequestDetailScreen extends StatefulWidget {
  final VisitRequest request;
  final bool isOwner;

  const VisitRequestDetailScreen({super.key, required this.request, this.isOwner = false});

  @override
  State<VisitRequestDetailScreen> createState() => _VisitRequestDetailScreenState();
}

class _VisitRequestDetailScreenState extends State<VisitRequestDetailScreen> {
  late VisitRequest _request;
  bool _isRefreshing = true;
  String? _actionBusy;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    _refreshDetail();
  }

  Future<void> _refreshDetail() async {
    try {
      final fresh = await VisitRequestService().fetchVisitDetail(widget.request.id);
      if (mounted) setState(() => _request = fresh);
    } catch (_) {
      // On garde les données déjà disponibles si le rafraîchissement échoue.
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String get _formattedDate {
    final parsed = DateTime.tryParse(_request.requestedDate);
    return parsed != null ? formatVisitDateTime(parsed) : _request.requestedDate;
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la demande'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette demande de visite ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actionBusy = 'cancel');
    try {
      await VisitRequestService().cancelVisitRequest(_request.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : ${e.toString()}')));
      setState(() => _actionBusy = null);
    }
  }

  Future<void> _accept() async {
    setState(() => _actionBusy = 'accept');
    try {
      await VisitRequestService().updateVisitAgreement(visitId: _request.id, accepted: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visite acceptée. La notification au locataire arrivera dès que le backend la prendra en charge.'),
          backgroundColor: Colors.teal,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: Colors.red),
      );
      setState(() => _actionBusy = null);
    }
  }

  Future<void> _refuse() async {
    final reason = await showRefusalReasonDialog(context);
    if (reason == null) return;

    setState(() => _actionBusy = 'refuse');
    try {
      await VisitRequestService().updateVisitAgreement(
        visitId: _request.id,
        accepted: false,
        refusalReason: reason.isEmpty ? null : reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande refusée')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: Colors.red),
      );
      setState(() => _actionBusy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final isPending = request.status == 'pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la visite'),
        backgroundColor: Colors.teal,
        bottom: _isRefreshing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2, color: Colors.white),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.propertyTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.teal),
                const SizedBox(width: 6),
                Text(_formattedDate, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Statut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _StatusTimeline(status: request.status),
            if (request.status == 'refused' && (request.refusalReason?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text('Motif du refus : ${request.refusalReason}', style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            const Text('Locataire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _PartyCard(
              name: request.visitorName,
              email: request.visitorEmail,
              phone: request.visitorPhone,
              fallbackName: 'Locataire',
            ),
            const SizedBox(height: 20),
            const Text('Propriétaire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _PartyCard(
              name: request.ownerName,
              email: request.ownerEmail,
              phone: request.ownerPhone,
              fallbackName: 'Propriétaire',
            ),
            if (request.message.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(request.message, style: const TextStyle(color: Colors.grey)),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Créée le ${request.createdAt.toLocal().toString().split(' ')[0]}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            if (isPending) ...[
              const SizedBox(height: 32),
              if (widget.isOwner)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _actionBusy != null ? null : _refuse,
                        icon: _actionBusy == 'refuse'
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                            : const Icon(Icons.close, color: Colors.red),
                        label: const Text('Refuser', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _actionBusy != null ? null : _accept,
                        icon: _actionBusy == 'accept'
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Accepter'),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _actionBusy != null ? null : _cancel,
                    icon: _actionBusy == 'cancel'
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                        : const Icon(Icons.close),
                    label: Text(_actionBusy == 'cancel' ? 'Annulation...' : 'Annuler la demande'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String fallbackName;

  const _PartyCard({required this.name, required this.email, required this.phone, required this.fallbackName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(name.isNotEmpty ? name : fallbackName, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(phone),
              ],
            ),
          ],
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(email, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineStepData {
  final String label;
  final bool done;
  final Color color;

  _TimelineStepData(this.label, this.done, this.color);
}

class _StatusTimeline extends StatelessWidget {
  final String status;

  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = <_TimelineStepData>[
      _TimelineStepData('Demande envoyée', true, Colors.teal),
    ];
    if (status == 'refused') {
      steps.add(_TimelineStepData('Refusée', true, Colors.red));
    } else {
      steps.add(_TimelineStepData('Acceptée', status == 'accepted' || status == 'completed', Colors.green));
      steps.add(_TimelineStepData('Terminée', status == 'completed', Colors.blueGrey));
    }

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) _buildStep(steps[i], isLast: i == steps.length - 1),
      ],
    );
  }

  Widget _buildStep(_TimelineStepData step, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done ? step.color : Colors.transparent,
                  border: Border.all(color: step.done ? step.color : Colors.grey.shade300, width: 2),
                ),
                child: step.done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: step.done ? step.color : Colors.grey.shade300),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24, top: 2),
            child: Text(
              step.label,
              style: TextStyle(
                fontWeight: step.done ? FontWeight.w600 : FontWeight.normal,
                color: step.done ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
