import 'package:flutter/material.dart';

import '../models/visit_request.dart';
import '../services/visit_request_service.dart';
import 'visit_request_detail_screen.dart';

const _statusTabs = ['pending', 'accepted', 'refused', 'completed'];

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

  void _reload() {
    setState(() => _requests = VisitRequestService().fetchMyVisitRequests());
  }

  Future<void> _openDetail(VisitRequest request) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VisitRequestDetailScreen(request: request)),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _statusTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes demandes de visite'),
          backgroundColor: Colors.teal,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'En attente'),
              Tab(text: 'Acceptée'),
              Tab(text: 'Refusée'),
              Tab(text: 'Terminée'),
            ],
          ),
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

            return TabBarView(
              children: _statusTabs
                  .map((status) => _VisitRequestList(
                        requests: requests.where((r) => r.status == status).toList(),
                        onTap: _openDetail,
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class _VisitRequestList extends StatelessWidget {
  final List<VisitRequest> requests;
  final ValueChanged<VisitRequest> onTap;

  const _VisitRequestList({required this.requests, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final color = visitStatusColors[request.status] ?? Colors.grey;
        final label = visitStatusLabels[request.status] ?? request.status;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            onTap: () => onTap(request),
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              request.propertyTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Créée le ${request.createdAt.toLocal().toString().split(' ')[0]}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }
}
