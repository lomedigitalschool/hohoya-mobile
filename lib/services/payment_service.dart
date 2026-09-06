import 'dart:math';

import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_config.dart';
import '../models/owner_revenue.dart';
import '../models/payment_transaction.dart';

// Hypothèse métier : le loyer et la caution reviennent au propriétaire, tandis que les frais de
// visite et la commission sont des frais de plateforme — à confirmer avec le métier si besoin.
const _revenueTypes = {TransactionType.rent, TransactionType.deposit};

class PaymentService {
  final _dio = ApiClient.instance.dio;
  final _random = Random();

  static final Map<String, int> _pollAttempts = {};
  static final List<PaymentTransaction> _transactions = [];

  Future<PaymentTransaction> initiateTransaction({
    required TransactionType type,
    required double amount,
    required PaymentMethodType method,
    String? propertyId,
    String? propertyTitle,
  }) async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final transaction = PaymentTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        amount: amount,
        method: method,
        status: PaymentStatus.pending,
        propertyId: propertyId,
        propertyTitle: propertyTitle,
      );
      _transactions.add(transaction);
      return transaction;
    }

    try {
      final response = await _dio.post(
        '/transactions/initiate',
        data: {
          'type': type.name,
          'amount': amount,
          'method': method.name,
          'propertyId': ?propertyId,
        },
      );
      return PaymentTransaction.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: "Impossible d'initier le paiement"));
    }
  }

  /// Interroge le statut de la transaction. Le webhook du provider (Mvola/Orange Money/carte)
  /// met à jour le statut côté serveur de façon transparente pour le mobile ; l'app doit donc
  /// re-vérifier périodiquement tant que le statut renvoyé reste "pending".
  Future<PaymentTransaction> verifyTransaction(PaymentTransaction transaction) async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 800));

      final attempts = (_pollAttempts[transaction.id] ?? 0) + 1;
      _pollAttempts[transaction.id] = attempts;

      PaymentTransaction updated;
      if (attempts < 2) {
        updated = transaction.copyWith(status: PaymentStatus.pending);
      } else {
        final roll = _random.nextDouble();
        if (roll < 0.7) {
          updated = transaction.copyWith(status: PaymentStatus.success);
        } else if (roll < 0.9) {
          final reason = transaction.method == PaymentMethodType.mobileMoney
              ? 'Solde insuffisant sur le compte mobile money'
              : 'Paiement refusé par la banque';
          updated = transaction.copyWith(status: PaymentStatus.failed, failureReason: reason);
        } else {
          updated = transaction.copyWith(status: PaymentStatus.timeout);
        }
      }

      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) _transactions[index] = updated;
      return updated;
    }

    try {
      final response = await _dio.patch('/transactions/${transaction.id}/verify');
      return PaymentTransaction.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible de vérifier ce paiement'));
    }
  }

  Future<List<PaymentTransaction>> fetchMyTransactions() async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return List<PaymentTransaction>.from(_transactions.reversed);
    }

    try {
      final response = await _dio.get('/transactions/user/me');
      final list = response.data as List;
      return list.map((item) => PaymentTransaction.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible de charger vos paiements'));
    }
  }

  Future<OwnerRevenue> fetchOwnerRevenue({required List<String> propertyIds}) async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final relevant = _transactions.where(
        (t) =>
            t.status == PaymentStatus.success &&
            t.propertyId != null &&
            propertyIds.contains(t.propertyId) &&
            _revenueTypes.contains(t.type),
      );
      return OwnerRevenue.fromTransactions(relevant.toList());
    }

    try {
      final response = await _dio.get('/transactions/owner/revenue');
      return OwnerRevenue.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible de charger vos revenus'));
    }
  }

  Future<PaymentTransaction> requestRefund({
    required PaymentTransaction transaction,
    required String reason,
  }) async {
    if (transaction.refundStatus != RefundStatus.none) {
      throw StateError('Une demande de remboursement est déjà en cours pour cette transaction.');
    }

    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final roll = _random.nextDouble();
      PaymentTransaction updated;
      if (roll < 0.55) {
        updated = transaction.copyWith(refundStatus: RefundStatus.requested, refundRequestReason: reason);
      } else if (roll < 0.8) {
        updated = transaction.copyWith(refundStatus: RefundStatus.approved, refundRequestReason: reason);
      } else {
        updated = transaction.copyWith(
          refundStatus: RefundStatus.refused,
          refundRequestReason: reason,
          refundDenialReason: 'Délai de remboursement dépassé',
        );
      }

      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) _transactions[index] = updated;
      return updated;
    }

    try {
      final response = await _dio.patch('/transactions/${transaction.id}/refund', data: {'reason': reason});
      return PaymentTransaction.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible de soumettre la demande de remboursement'));
    }
  }

  String _extractErrorMessage(DioException error, {required String fallback}) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    return fallback;
  }
}
