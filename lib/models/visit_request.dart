class VisitRequest {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String visitorName;
  final String visitorEmail;
  final String visitorPhone;
  final String requestedDate;
  final String message;
  final String status;
  final DateTime createdAt;

  VisitRequest({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.visitorName,
    required this.visitorEmail,
    required this.visitorPhone,
    required this.requestedDate,
    required this.message,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory VisitRequest.fromJson(Map<String, dynamic> json) {
    return VisitRequest(
      id: json['id'].toString(),
      propertyId: json['propertyId'].toString(),
      propertyTitle: json['propertyTitle'] ?? '',
      visitorName: json['visitorName'] ?? '',
      visitorEmail: json['visitorEmail'] ?? '',
      visitorPhone: json['visitorPhone'] ?? '',
      requestedDate: json['requestedDate'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'propertyId': propertyId,
    'propertyTitle': propertyTitle,
    'visitorName': visitorName,
    'visitorEmail': visitorEmail,
    'visitorPhone': visitorPhone,
    'requestedDate': requestedDate,
    'message': message,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };
}
