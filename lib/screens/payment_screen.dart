import 'package:flutter/material.dart';

import '../models/payment_transaction.dart';
import '../services/payment_service.dart';
import 'payment_result_screen.dart';

class PaymentScreen extends StatefulWidget {
  final TransactionType type;
  final double amount;
  final String? propertyId;
  final String? contextLabel;

  const PaymentScreen({
    super.key,
    required this.type,
    required this.amount,
    this.propertyId,
    this.contextLabel,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethodType _method = PaymentMethodType.mobileMoney;
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _pay() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final initiated = await PaymentService().initiateTransaction(
        type: widget.type,
        amount: widget.amount,
        method: _method,
        propertyId: widget.propertyId,
        propertyTitle: widget.contextLabel,
      );
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PaymentResultScreen(transaction: initiated)),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement'), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RecapCard(type: widget.type, amount: widget.amount, contextLabel: widget.contextLabel),
            const SizedBox(height: 24),
            const Text('Méthode de paiement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...PaymentMethodType.values.map(
              (method) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: _method == method ? Colors.teal.shade50 : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _method == method ? Colors.teal : Colors.grey.shade300),
                ),
                child: ListTile(
                  onTap: _isProcessing ? null : () => setState(() => _method = method),
                  leading: Icon(
                    method == PaymentMethodType.mobileMoney ? Icons.phone_iphone : Icons.credit_card,
                    color: _method == method ? Colors.teal : Colors.grey,
                  ),
                  title: Text(method.label),
                  trailing: Icon(
                    _method == method ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: _method == method ? Colors.teal : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : _pay,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Icon(Icons.payment),
                label: Text(_isProcessing ? 'Initialisation...' : 'Payer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapCard extends StatelessWidget {
  final TransactionType type;
  final double amount;
  final String? contextLabel;

  const _RecapCard({required this.type, required this.amount, this.contextLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type.label, style: const TextStyle(fontSize: 15, color: Colors.teal, fontWeight: FontWeight.w600)),
          if (contextLabel != null) ...[
            const SizedBox(height: 4),
            Text(contextLabel!, style: const TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 12),
          Text('${amount.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
