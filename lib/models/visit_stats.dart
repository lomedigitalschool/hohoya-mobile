import 'visit_request.dart';

class VisitStats {
  final int total;
  final int pending;
  final int accepted;
  final int refused;
  final int completed;

  VisitStats({
    required this.total,
    required this.pending,
    required this.accepted,
    required this.refused,
    required this.completed,
  });

  int get decided => accepted + refused + completed;

  double? get acceptanceRate {
    if (decided == 0) return null;
    return (accepted + completed) / decided;
  }

  factory VisitStats.fromJson(Map<String, dynamic> json) => VisitStats(
    total: (json['total'] as num?)?.toInt() ?? 0,
    pending: (json['pending'] as num?)?.toInt() ?? 0,
    accepted: (json['accepted'] as num?)?.toInt() ?? 0,
    refused: (json['refused'] as num?)?.toInt() ?? 0,
    completed: (json['completed'] as num?)?.toInt() ?? 0,
  );

  factory VisitStats.fromRequests(List<VisitRequest> requests) {
    int count(String status) => requests.where((r) => r.status == status).length;
    return VisitStats(
      total: requests.length,
      pending: count('pending'),
      accepted: count('accepted'),
      refused: count('refused'),
      completed: count('completed'),
    );
  }
}
