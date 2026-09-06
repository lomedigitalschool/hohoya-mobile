import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/owner_revenue.dart';
import '../models/payment_transaction.dart';
import '../services/payment_service.dart';
import '../services/property_service.dart';
import '../utils/date_format.dart';

class OwnerRevenueScreen extends StatefulWidget {
  const OwnerRevenueScreen({super.key});

  @override
  State<OwnerRevenueScreen> createState() => _OwnerRevenueScreenState();
}

class _OwnerRevenueScreenState extends State<OwnerRevenueScreen> {
  late Future<OwnerRevenue> _revenueFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _revenueFuture = _load());
  }

  Future<OwnerRevenue> _load() async {
    final properties = await PropertyService().fetchOwnerProperties();
    return PaymentService().fetchOwnerRevenue(propertyIds: properties.map((p) => p.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes revenus'), backgroundColor: Colors.teal),
      body: FutureBuilder<OwnerRevenue>(
        future: _revenueFuture,
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

          final revenue = snapshot.data!;

          if (revenue.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Aucun revenu encore', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Ce mois-ci', value: revenue.totalMonth)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Cette année', value: revenue.totalYear)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Évolution sur 6 mois', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(height: 200, child: _RevenueLineChart(points: revenue.monthlyEvolution)),
                const SizedBox(height: 24),
                const Text('Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...revenue.transactions.map((t) => _TransactionRow(transaction: t)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${value.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _RevenueLineChart extends StatelessWidget {
  final List<RevenuePoint> points;

  const _RevenueLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxAmount = points.map((p) => p.amount).fold<double>(0, (a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxAmount == 0 ? 1 : maxAmount * 1.2,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(points[index].label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].amount)],
            isCurved: true,
            color: Colors.teal,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: Colors.teal.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final PaymentTransaction transaction;

  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.attach_money, color: Colors.teal)),
        title: Text(transaction.propertyTitle ?? transaction.type.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${transaction.type.label} · ${formatVisitDateTime(transaction.createdAt)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          '+${transaction.amount.toStringAsFixed(0)} FCFA',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ),
    );
  }
}
