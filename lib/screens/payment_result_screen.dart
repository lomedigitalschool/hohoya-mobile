import 'package:flutter/material.dart';

import '../models/payment_transaction.dart';
import '../services/payment_service.dart';
import '../utils/date_format.dart';

const _maxPollAttempts = 5;

class PaymentResultScreen extends StatefulWidget {
  final PaymentTransaction transaction;

  const PaymentResultScreen({super.key, required this.transaction});

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  late PaymentTransaction _transaction;
  bool _networkError = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    _poll();
  }

  Future<void> _poll() async {
    while (mounted && _transaction.status == PaymentStatus.pending && _attempts < _maxPollAttempts) {
      try {
        final updated = await PaymentService().verifyTransaction(_transaction);
        if (!mounted) return;
        _attempts++;
        setState(() {
          _transaction = updated;
          _networkError = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _networkError = true);
        return;
      }

      if (_transaction.status == PaymentStatus.pending) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }

    if (mounted && _transaction.status == PaymentStatus.pending) {
      setState(() => _transaction = _transaction.copyWith(status: PaymentStatus.timeout));
    }
  }

  void _retryVerification() {
    setState(() => _networkError = false);
    _poll();
  }

  void _retryPolling() {
    _attempts = 0;
    setState(() => _transaction = _transaction.copyWith(status: PaymentStatus.pending));
    _poll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statut du paiement'), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_networkError)
              _NetworkErrorCard(onRetry: _retryVerification)
            else
              _buildStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    switch (_transaction.status) {
      case PaymentStatus.pending:
        return Column(
          children: [
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Vérification du paiement en cours...',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Confirmation en attente du provider (webhook).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        );
      case PaymentStatus.success:
        return Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Paiement réussi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 24),
            _ReceiptCard(transaction: _transaction),
            const SizedBox(height: 24),
            _backButton(),
          ],
        );
      case PaymentStatus.failed:
        return Column(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text('Paiement échoué', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            if (_transaction.failureReason != null) ...[
              const SizedBox(height: 8),
              Text(_transaction.failureReason!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 24),
            _ReceiptCard(transaction: _transaction),
            const SizedBox(height: 24),
            _backButton(),
          ],
        );
      case PaymentStatus.timeout:
        return Column(
          children: [
            const Icon(Icons.access_time_filled, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            const Text('Vérification expirée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 8),
            const Text(
              "Aucune confirmation reçue du provider pour l'instant. Le paiement a peut-être abouti : vérifiez à nouveau dans un instant.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _backButton(outlined: true)),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: _retryPolling, child: const Text('Vérifier à nouveau')),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _backButton({bool outlined = false}) {
    final child = const Text('Retour');
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(onPressed: () => Navigator.pop(context, _transaction.status == PaymentStatus.success), child: child)
          : FilledButton(onPressed: () => Navigator.pop(context, _transaction.status == PaymentStatus.success), child: child),
    );
  }
}

class _NetworkErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _NetworkErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.wifi_off, color: Colors.grey, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Échec réseau pendant la vérification',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          "Impossible de contacter le serveur pour confirmer le paiement. Réessayez lorsque votre connexion est rétablie.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
        ),
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final PaymentTransaction transaction;

  const _ReceiptCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Reçu de paiement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _row('Transaction', '#${transaction.id}'),
          _row('Type', transaction.type.label),
          _row('Montant', '${transaction.amount.toStringAsFixed(0)} FCFA'),
          _row('Méthode', transaction.method.label),
          _row('Date', formatVisitDateTime(transaction.createdAt)),
          _row('Statut', transaction.status.label),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
