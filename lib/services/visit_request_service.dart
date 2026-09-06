import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_config.dart';
import '../models/property.dart';
import '../models/visit_request.dart';
import '../models/visit_stats.dart';
import 'auth_service.dart';
import 'property_service.dart';

enum VisitRequestErrorType { slotInPast, propertyUnavailable, generic }

class VisitRequestFailure implements Exception {
  final VisitRequestErrorType type;
  final String message;

  VisitRequestFailure(this.type, this.message);

  @override
  String toString() => message;
}

class VisitRequestService {
  final _dio = ApiClient.instance.dio;

  static final List<VisitRequest> _visitRequests = [];

  Future<VisitRequest> requestVisit({
    required Property property,
    required DateTime scheduledAt,
    String? message,
  }) async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 300));

      if (scheduledAt.isBefore(DateTime.now())) {
        throw VisitRequestFailure(
          VisitRequestErrorType.slotInPast,
          'Ce créneau est déjà passé. Choisissez une autre date ou heure.',
        );
      }
      if (property.isUnavailable) {
        throw VisitRequestFailure(
          VisitRequestErrorType.propertyUnavailable,
          "Ce bien n'est plus disponible pour une visite.",
        );
      }

      final tenant = await AuthService.instance.getCurrentUser();

      final request = VisitRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        propertyId: property.id,
        propertyTitle: property.title,
        visitorName: tenant.name,
        visitorEmail: tenant.email,
        visitorPhone: tenant.phone,
        ownerName: property.ownerName,
        requestedDate: scheduledAt.toIso8601String(),
        message: message ?? '',
        status: 'pending',
      );
      _visitRequests.add(request);
      return request;
    }

    try {
      final response = await _dio.post(
        '/visits',
        data: {
          'propertyId': property.id,
          'scheduledAt': scheduledAt.toIso8601String(),
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );
      return VisitRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _mapVisitError(error);
    }
  }

  Future<List<VisitRequest>> fetchOwnerVisitRequests() async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final ownedIds = (await PropertyService().fetchOwnerProperties()).map((p) => p.id).toSet();
      return _visitRequests.where((request) => ownedIds.contains(request.propertyId)).toList();
    }

    try {
      final response = await _dio.get('/visits/owner/me');
      final list = response.data as List;
      return list.map((item) => VisitRequest.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible de charger les demandes de visite'));
    }
  }

  Future<VisitRequest> updateVisitAgreement({
    required String visitId,
    required bool accepted,
    String? refusalReason,
  }) async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final index = _visitRequests.indexWhere((request) => request.id == visitId);
      if (index == -1) {
        throw StateError('Demande de visite introuvable');
      }
      final updated = _visitRequests[index].copyWith(
        status: accepted ? 'accepted' : 'refused',
        refusalReason: accepted ? null : refusalReason,
      );
      _visitRequests[index] = updated;
      return updated;
    }

    try {
      final response = await _dio.patch(
        '/visits/$visitId/agreement',
        data: {
          'status': accepted ? 'accepted' : 'refused',
          if (!accepted && refusalReason != null && refusalReason.isNotEmpty) 'reason': refusalReason,
        },
      );
      return VisitRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible de mettre à jour la demande'));
    }
  }

  Future<VisitRequest> fetchVisitDetail(String visitId) async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final index = _visitRequests.indexWhere((request) => request.id == visitId);
      if (index == -1) {
        throw StateError('Visite introuvable');
      }
      return _visitRequests[index];
    }

    try {
      final response = await _dio.get('/visits/populate/$visitId');
      return VisitRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible de charger cette visite'));
    }
  }

  Future<VisitStats> fetchVisitStats() async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return VisitStats.fromRequests(_visitRequests);
    }

    try {
      final response = await _dio.get('/visits/stats');
      return VisitStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible de charger les statistiques'));
    }
  }

  VisitRequestFailure _mapVisitError(DioException error) {
    final data = error.response?.data;
    final code = data is Map ? data['code']?.toString() : null;
    final message = data is Map ? data['message']?.toString() : null;

    if (code == 'SLOT_IN_PAST') {
      return VisitRequestFailure(
        VisitRequestErrorType.slotInPast,
        message ?? 'Ce créneau est déjà passé. Choisissez une autre date ou heure.',
      );
    }
    if (code == 'PROPERTY_UNAVAILABLE') {
      return VisitRequestFailure(
        VisitRequestErrorType.propertyUnavailable,
        message ?? "Ce bien n'est plus disponible pour une visite.",
      );
    }
    return VisitRequestFailure(
      VisitRequestErrorType.generic,
      message ?? "Impossible d'envoyer la demande de visite.",
    );
  }

  Future<List<VisitRequest>> fetchMyVisitRequests() async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return _visitRequests;
    }

    try {
      final response = await _dio.get('/visits/tenant/me');
      final list = response.data as List;
      return list.map((item) => VisitRequest.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible de charger vos demandes'));
    }
  }

  Future<void> cancelVisitRequest(String visitRequestId) async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _visitRequests.removeWhere((req) => req.id == visitRequestId);
      return;
    }

    try {
      await _dio.delete('/visits/$visitRequestId');
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible d\'annuler la demande'));
    }
  }

  String _extractErrorMessage(DioException error, {required String fallback}) {
    if (error.response?.data is Map<String, dynamic>) {
      return error.response!.data['message'] ?? fallback;
    }
    return fallback;
  }
}
