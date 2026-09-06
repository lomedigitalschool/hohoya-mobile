import 'payment_transaction.dart';

const monthShortLabels = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];

class RevenuePoint {
  final String label;
  final double amount;

  RevenuePoint({required this.label, required this.amount});
}

class OwnerRevenue {
  final double totalMonth;
  final double totalYear;
  final List<RevenuePoint> monthlyEvolution;
  final List<PaymentTransaction> transactions;

  OwnerRevenue({
    required this.totalMonth,
    required this.totalYear,
    required this.monthlyEvolution,
    required this.transactions,
  });

  factory OwnerRevenue.fromJson(Map<String, dynamic> json) => OwnerRevenue(
    totalMonth: (json['totalMonth'] as num?)?.toDouble() ?? 0,
    totalYear: (json['totalYear'] as num?)?.toDouble() ?? 0,
    monthlyEvolution: (json['monthlyEvolution'] as List? ?? [])
        .map((e) => RevenuePoint(label: e['label'] as String, amount: (e['amount'] as num).toDouble()))
        .toList(),
    transactions: (json['transactions'] as List? ?? [])
        .map((e) => PaymentTransaction.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  factory OwnerRevenue.fromTransactions(List<PaymentTransaction> transactions) {
    final now = DateTime.now();

    double sumWhere(bool Function(PaymentTransaction) test) =>
        transactions.where(test).fold<double>(0, (sum, t) => sum + t.amount);

    final totalMonth = sumWhere((t) => t.createdAt.year == now.year && t.createdAt.month == now.month);
    final totalYear = sumWhere((t) => t.createdAt.year == now.year);

    final monthly = <RevenuePoint>[];
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final amount = sumWhere((t) => t.createdAt.year == month.year && t.createdAt.month == month.month);
      monthly.add(RevenuePoint(label: monthShortLabels[month.month - 1], amount: amount));
    }

    final sorted = List<PaymentTransaction>.from(transactions)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return OwnerRevenue(totalMonth: totalMonth, totalYear: totalYear, monthlyEvolution: monthly, transactions: sorted);
  }
}
