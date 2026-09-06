class VisitRequest {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String visitorName;
  final String visitorEmail;
  final String visitorPhone;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String requestedDate;
  final String message;
  final String status;
  final String? refusalReason;
  final DateTime createdAt;

  VisitRequest({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.visitorName,
    required this.visitorEmail,
    required this.visitorPhone,
    this.ownerName = '',
    this.ownerEmail = '',
    this.ownerPhone = '',
    required this.requestedDate,
    required this.message,
    this.status = 'pending',
    this.refusalReason,
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
      ownerName: json['ownerName'] ?? '',
      ownerEmail: json['ownerEmail'] ?? '',
      ownerPhone: json['ownerPhone'] ?? '',
      requestedDate: json['requestedDate'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      refusalReason: json['refusalReason'] as String?,
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
    'ownerName': ownerName,
    'ownerEmail': ownerEmail,
    'ownerPhone': ownerPhone,
    'requestedDate': requestedDate,
    'message': message,
    'status': status,
    'refusalReason': refusalReason,
    'createdAt': createdAt.toIso8601String(),
  };

  VisitRequest copyWith({String? status, String? refusalReason}) => VisitRequest(
    id: id,
    propertyId: propertyId,
    propertyTitle: propertyTitle,
    visitorName: visitorName,
    visitorEmail: visitorEmail,
    visitorPhone: visitorPhone,
    ownerName: ownerName,
    ownerEmail: ownerEmail,
    ownerPhone: ownerPhone,
    requestedDate: requestedDate,
    message: message,
    status: status ?? this.status,
    refusalReason: refusalReason ?? this.refusalReason,
    createdAt: createdAt,
  );
}
