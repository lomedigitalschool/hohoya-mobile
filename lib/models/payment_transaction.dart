enum TransactionType { rent, deposit, visitFee, commission }

enum PaymentMethodType { mobileMoney, card }

enum PaymentStatus { pending, success, failed, timeout }

enum RefundStatus { none, requested, approved, refused }

extension TransactionTypeLabel on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.rent:
        return 'Loyer';
      case TransactionType.deposit:
        return 'Caution';
      case TransactionType.visitFee:
        return 'Frais de visite';
      case TransactionType.commission:
        return 'Commission';
    }
  }
}

extension PaymentMethodTypeLabel on PaymentMethodType {
  String get label {
    switch (this) {
      case PaymentMethodType.mobileMoney:
        return 'Mobile Money';
      case PaymentMethodType.card:
        return 'Carte bancaire';
    }
  }
}

extension PaymentStatusLabel on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.success:
        return 'Réussi';
      case PaymentStatus.failed:
        return 'Échoué';
      case PaymentStatus.timeout:
        return 'Expiré';
    }
  }
}

extension RefundStatusLabel on RefundStatus {
  String get label {
    switch (this) {
      case RefundStatus.none:
        return '';
      case RefundStatus.requested:
        return 'Remboursement en cours';
      case RefundStatus.approved:
        return 'Remboursé';
      case RefundStatus.refused:
        return 'Remboursement refusé';
    }
  }
}

class PaymentTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final PaymentMethodType method;
  final PaymentStatus status;
  final String? failureReason;
  final String? propertyId;
  final String? propertyTitle;
  final RefundStatus refundStatus;
  final String? refundRequestReason;
  final String? refundDenialReason;
  final DateTime createdAt;

  PaymentTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.method,
    this.status = PaymentStatus.pending,
    this.failureReason,
    this.propertyId,
    this.propertyTitle,
    this.refundStatus = RefundStatus.none,
    this.refundRequestReason,
    this.refundDenialReason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isRefundEligible => status == PaymentStatus.success && refundStatus == RefundStatus.none;

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) => PaymentTransaction(
    id: json['id'].toString(),
    type: TransactionType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => TransactionType.rent,
    ),
    amount: (json['amount'] as num).toDouble(),
    method: PaymentMethodType.values.firstWhere(
      (m) => m.name == json['method'],
      orElse: () => PaymentMethodType.mobileMoney,
    ),
    status: PaymentStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => PaymentStatus.pending,
    ),
    failureReason: json['failureReason'] as String?,
    propertyId: json['propertyId']?.toString(),
    propertyTitle: json['propertyTitle'] as String?,
    refundStatus: RefundStatus.values.firstWhere(
      (r) => r.name == json['refundStatus'],
      orElse: () => RefundStatus.none,
    ),
    refundRequestReason: json['refundRequestReason'] as String?,
    refundDenialReason: json['refundDenialReason'] as String?,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'amount': amount,
    'method': method.name,
    'status': status.name,
    'failureReason': failureReason,
    'propertyId': propertyId,
    'propertyTitle': propertyTitle,
    'refundStatus': refundStatus.name,
    'refundRequestReason': refundRequestReason,
    'refundDenialReason': refundDenialReason,
    'createdAt': createdAt.toIso8601String(),
  };

  PaymentTransaction copyWith({
    PaymentStatus? status,
    String? failureReason,
    RefundStatus? refundStatus,
    String? refundRequestReason,
    String? refundDenialReason,
  }) => PaymentTransaction(
    id: id,
    type: type,
    amount: amount,
    method: method,
    status: status ?? this.status,
    failureReason: failureReason ?? this.failureReason,
    propertyId: propertyId,
    propertyTitle: propertyTitle,
    refundStatus: refundStatus ?? this.refundStatus,
    refundRequestReason: refundRequestReason ?? this.refundRequestReason,
    refundDenialReason: refundDenialReason ?? this.refundDenialReason,
    createdAt: createdAt,
  );
}
