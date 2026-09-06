import 'package:flutter/material.dart';

import '../models/visit_request.dart';
import '../services/visit_request_service.dart';
import 'visit_request_detail_screen.dart'
    show VisitRequestDetailScreen, showRefusalReasonDialog, visitStatusColors, visitStatusLabels;
import '../utils/date_format.dart';

class OwnerVisitRequestsScreen extends StatefulWidget {
  const OwnerVisitRequestsScreen({super.key});

  @override
  State<OwnerVisitRequestsScreen> createState() =>
      _OwnerVisitRequestsScreenState();
}

class _OwnerVisitRequestsScreenState extends State<OwnerVisitRequestsScreen> {
  late Future<List<VisitRequest>> _requestsFuture;
  final Map<String, String> _busyAction = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(
      () => _requestsFuture = VisitRequestService().fetchOwnerVisitRequests(),
    );
  }

  Future<void> _openDetail(VisitRequest request) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            VisitRequestDetailScreen(request: request, isOwner: true),
      ),
    );
    if (changed == true) _reload();
  }

  Future<void> _accept(VisitRequest request) async {
    setState(() => _busyAction[request.id] = 'accept');
    try {
      await VisitRequestService().updateVisitAgreement(
        visitId: request.id,
        accepted: true,
      );
      if (!mounted) return;
      // Le backend n'expose pas encore de notification tenant : on informe seulement le propriétaire ici.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Visite acceptée. La notification au locataire arrivera dès que le backend la prendra en charge.',
          ),
          backgroundColor: Colors.teal,
        ),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyAction.remove(request.id));
    }
  }

  Future<void> _refuse(VisitRequest request) async {
    final reason = await showRefusalReasonDialog(context);
    if (reason == null) return;

    setState(() => _busyAction[request.id] = 'refuse');
    try {
      await VisitRequestService().updateVisitAgreement(
        visitId: request.id,
        accepted: false,
        refusalReason: reason.isEmpty ? null : reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Demande refusée')));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyAction.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes de visite reçues'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<VisitRequest>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur : ${snapshot.error}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final requests = List<VisitRequest>.from(snapshot.data ?? [])
            ..sort((a, b) {
              final aPending = a.status == 'pending';
              final bPending = b.status == 'pending';
              if (aPending != bPending) return aPending ? -1 : 1;
              return b.createdAt.compareTo(a.createdAt);
            });

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune demande de visite reçue',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: requests.length,
              itemBuilder: (context, index) => _VisitRequestCard(
                request: requests[index],
                busyAction: _busyAction[requests[index].id],
                onAccept: () => _accept(requests[index]),
                onRefuse: () => _refuse(requests[index]),
                onTap: () => _openDetail(requests[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VisitRequestCard extends StatelessWidget {
  final VisitRequest request;
  final String? busyAction;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;
  final VoidCallback onTap;

  const _VisitRequestCard({
    required this.request,
    required this.busyAction,
    required this.onAccept,
    required this.onRefuse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final busy = busyAction != null;
    final acceptBusy = busyAction == 'accept';
    final refuseBusy = busyAction == 'refuse';
    final parsedDate = DateTime.tryParse(request.requestedDate);
    final formattedDate = parsedDate != null
        ? formatVisitDateTime(parsedDate)
        : request.requestedDate;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.propertyTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.visitorName.isNotEmpty
                          ? request.visitorName
                          : 'Locataire',
                    ),
                  ),
                ],
              ),
              if (request.visitorPhone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(request.visitorPhone),
                  ],
                ),
              ],
              if (request.visitorEmail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.visitorEmail,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (request.message.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.message,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
              if (request.status == 'refused' &&
                  (request.refusalReason?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 10),
                Text(
                  'Motif du refus : ${request.refusalReason}',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const SizedBox(height: 14),
              if (request.status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : onRefuse,
                        icon: refuseBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              )
                            : const Icon(Icons.close, color: Colors.red),
                        label: const Text(
                          'Refuser',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: busy ? null : onAccept,
                        icon: acceptBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Accepter'),
                      ),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (visitStatusColors[request.status] ?? Colors.grey)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      visitStatusLabels[request.status] ?? request.status,
                      style: TextStyle(
                        color: visitStatusColors[request.status] ?? Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
