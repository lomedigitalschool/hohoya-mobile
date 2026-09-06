import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/visit_stats.dart';
import '../services/visit_request_service.dart';
import 'visit_request_detail_screen.dart' show visitStatusColors, visitStatusLabels;

class VisitStatsScreen extends StatefulWidget {
  const VisitStatsScreen({super.key});

  @override
  State<VisitStatsScreen> createState() => _VisitStatsScreenState();
}

class _VisitStatsScreenState extends State<VisitStatsScreen> {
  late Future<VisitStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _statsFuture = VisitRequestService().fetchVisitStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques des visites'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<VisitStats>(
        future: _statsFuture,
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
                  FilledButton(onPressed: _reload, child: const Text('Réessayer')),
                ],
              ),
            );
          }

          final stats = snapshot.data!;

          if (stats.total == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'Statistiques disponibles après votre première visite',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatCard(label: 'Visites au total', value: '${stats.total}', color: Colors.teal),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _StatCard(label: visitStatusLabels['pending']!, value: '${stats.pending}', color: visitStatusColors['pending']!),
                      _StatCard(label: visitStatusLabels['accepted']!, value: '${stats.accepted}', color: visitStatusColors['accepted']!),
                      _StatCard(label: visitStatusLabels['refused']!, value: '${stats.refused}', color: visitStatusColors['refused']!),
                      _StatCard(label: visitStatusLabels['completed']!, value: '${stats.completed}', color: visitStatusColors['completed']!),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    label: "Taux d'acceptation",
                    value: stats.acceptanceRate == null ? 'N/A' : '${(stats.acceptanceRate! * 100).round()}%',
                    color: Colors.indigo,
                    subtitle: stats.acceptanceRate == null ? 'Aucune demande traitée pour le moment' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text('Répartition par statut', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _StatusDonutChart(stats: stats),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  const _StatCard({required this.label, required this.value, required this.color, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }
}

class _StatusDonutChart extends StatelessWidget {
  final VisitStats stats;

  const _StatusDonutChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = <MapEntry<String, int>>[
      MapEntry('pending', stats.pending),
      MapEntry('accepted', stats.accepted),
      MapEntry('refused', stats.refused),
      MapEntry('completed', stats.completed),
    ].where((entry) => entry.value > 0).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: entries
                  .map((entry) => PieChartSectionData(
                        value: entry.value.toDouble(),
                        color: visitStatusColors[entry.key],
                        title: '${entry.value}',
                        radius: 48,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: entries
              .map((entry) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: visitStatusColors[entry.key], shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('${visitStatusLabels[entry.key]} (${entry.value})', style: const TextStyle(fontSize: 13)),
                    ],
                  ))
              .toList(),
        ),
      ],
    );
  }
}
