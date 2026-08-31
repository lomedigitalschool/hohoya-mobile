import 'package:flutter/material.dart';

import '../models/visit_request.dart';
import '../services/visit_request_service.dart';

class MyVisitRequestsScreen extends StatefulWidget {
  const MyVisitRequestsScreen({super.key});

  @override
  State<MyVisitRequestsScreen> createState() => _MyVisitRequestsScreenState();
}

class _MyVisitRequestsScreenState extends State<MyVisitRequestsScreen> {
  late Future<List<VisitRequest>> _requests;

  @override
  void initState() {
    super.initState();
    _requests = VisitRequestService().fetchMyVisitRequests();
  }

  Future<void> _cancelRequest(String requestId) async {
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

    try {
      await VisitRequestService().cancelVisitRequest(requestId);
      if (!mounted) return;
      setState(() => _requests = VisitRequestService().fetchMyVisitRequests());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande annulée')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes demandes de visite'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<VisitRequest>>(
        future: _requests,
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
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune demande de visite',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Retour à l\'accueil'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final statusColors = {
                'pending': Colors.orange,
                'confirmed': Colors.green,
                'cancelled': Colors.red,
              };
              final statusLabel = {
                'pending': 'En attente',
                'confirmed': 'Confirmée',
                'cancelled': 'Annulée',
              };

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.propertyTitle,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Date souhaitée: ${request.requestedDate}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (statusColors[request.status] ?? Colors.grey).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel[request.status] ?? request.status,
                              style: TextStyle(
                                color: statusColors[request.status] ?? Colors.grey,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (request.message.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Créée le ${request.createdAt.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                          if (request.status == 'pending')
                            TextButton(
                              onPressed: () => _cancelRequest(request.id),
                              child: const Text('Annuler'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
