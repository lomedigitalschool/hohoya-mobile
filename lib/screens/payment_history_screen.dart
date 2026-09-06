import 'package:flutter/material.dart';

import '../models/payment_transaction.dart';
import '../services/payment_service.dart';
import '../utils/date_format.dart';

const _statusColors = {
  PaymentStatus.pending: Colors.orange,
  PaymentStatus.success: Colors.green,
  PaymentStatus.failed: Colors.red,
  PaymentStatus.timeout: Colors.blueGrey,
};

const _refundStatusColors = {
  RefundStatus.requested: Colors.orange,
  RefundStatus.approved: Colors.green,
  RefundStatus.refused: Colors.red,
};

const _typeIcons = {
  TransactionType.rent: Icons.home_outlined,
  TransactionType.deposit: Icons.savings_outlined,
  TransactionType.visitFee: Icons.calendar_today_outlined,
  TransactionType.commission: Icons.percent_outlined,
};

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late Future<List<PaymentTransaction>> _transactionsFuture;
  TransactionType? _filter;
  final Set<String> _refundBusyIds = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _transactionsFuture = PaymentService().fetchMyTransactions());
  }

  Future<void> _requestRefund(PaymentTransaction transaction) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demander un remboursement'),
        content: TextField(
          controller: reasonController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Motif',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              final value = reasonController.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(context, value);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;

    setState(() => _refundBusyIds.add(transaction.id));
    try {
      final updated = await PaymentService().requestRefund(transaction: transaction, reason: reason);
      if (!mounted) return;
      final message = switch (updated.refundStatus) {
        RefundStatus.approved => 'Remboursement approuvé.',
        RefundStatus.refused => 'Remboursement refusé${updated.refundDenialReason != null ? ' : ${updated.refundDenialReason}' : ''}.',
        _ => 'Demande de remboursement envoyée, en cours de traitement.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _refundBusyIds.remove(transaction.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes paiements'), backgroundColor: Colors.teal),
      body: FutureBuilder<List<PaymentTransaction>>(
        future: _transactionsFuture,
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

          final all = snapshot.data ?? [];

          if (all.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Aucun paiement pour le moment', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final filtered = _filter == null ? all : all.where((t) => t.type == _filter).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(label: 'Tous', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                      const SizedBox(width: 8),
                      for (final type in TransactionType.values) ...[
                        _FilterChip(label: type.label, selected: _filter == type, onTap: () => setState(() => _filter = type)),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun paiement de type "${_filter!.label}"',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _reload(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _TransactionTile(
                            transaction: filtered[index],
                            isRefundBusy: _refundBusyIds.contains(filtered[index].id),
                            onRequestRefund: () => _requestRefund(filtered[index]),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}

class _TransactionTile extends StatelessWidget {
  final PaymentTransaction transaction;
  final bool isRefundBusy;
  final VoidCallback onRequestRefund;

  const _TransactionTile({
    required this.transaction,
    required this.isRefundBusy,
    required this.onRequestRefund,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[transaction.status] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade50,
              child: Icon(_typeIcons[transaction.type] ?? Icons.payment, color: Colors.teal),
            ),
            title: Text(transaction.type.label, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(formatVisitDateTime(transaction.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${transaction.amount.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    transaction.status.label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          if (transaction.isRefundEligible || transaction.refundStatus != RefundStatus.none)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: transaction.isRefundEligible
                    ? OutlinedButton.icon(
                        onPressed: isRefundBusy ? null : onRequestRefund,
                        icon: isRefundBusy
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.undo, size: 18),
                        label: Text(isRefundBusy ? 'Envoi...' : 'Demander un remboursement'),
                      )
                    : GestureDetector(
                        onTap: transaction.refundStatus == RefundStatus.refused && transaction.refundDenialReason != null
                            ? () => showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Remboursement refusé'),
                                    content: Text(transaction.refundDenialReason!),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
                                    ],
                                  ),
                                )
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_refundStatusColors[transaction.refundStatus] ?? Colors.grey).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            transaction.refundStatus.label,
                            style: TextStyle(
                              color: _refundStatusColors[transaction.refundStatus] ?? Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
