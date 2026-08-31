import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_config.dart';
import '../models/visit_request.dart';

class VisitRequestService {
  final _dio = ApiClient.instance.dio;

  static final List<VisitRequest> _visitRequests = [];

  Future<VisitRequest> submitVisitRequest({
    required String propertyId,
    required String propertyTitle,
    required String visitorName,
    required String visitorEmail,
    required String visitorPhone,
    required String requestedDate,
    required String message,
  }) async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final request = VisitRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        propertyId: propertyId,
        propertyTitle: propertyTitle,
        visitorName: visitorName,
        visitorEmail: visitorEmail,
        visitorPhone: visitorPhone,
        requestedDate: requestedDate,
        message: message,
        status: 'pending',
      );

      _visitRequests.add(request);
      return request;
    }

    try {
      final response = await _dio.post(
        '/visit-requests',
        data: {
          'propertyId': propertyId,
          'propertyTitle': propertyTitle,
          'visitorName': visitorName,
          'visitorEmail': visitorEmail,
          'visitorPhone': visitorPhone,
          'requestedDate': requestedDate,
          'message': message,
        },
      );
      return VisitRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible de soumettre la demande de visite'));
    }
  }

  Future<VisitRequest> proposeVisitDateTime({
    required String visitRequestId,
    required DateTime proposedDateTime,
    required String message,
  }) async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final now = DateTime.now();
      if (proposedDateTime.isBefore(now)) {
        throw StateError('Le créneau proposé ne peut pas être dans le passé');
      }

      return VisitRequest(
        id: visitRequestId,
        propertyId: '',
        propertyTitle: '',
        visitorName: '',
        visitorEmail: '',
        visitorPhone: '',
        requestedDate: proposedDateTime.toString(),
        message: message,
        status: 'confirmed',
      );
    }

    try {
      final now = DateTime.now();
      if (proposedDateTime.isBefore(now)) {
        throw StateError('Le créneau proposé ne peut pas être dans le passé');
      }

      final response = await _dio.post(
        '/visits',
        data: {
          'visitRequestId': visitRequestId,
          'proposedDateTime': proposedDateTime.toIso8601String(),
          'message': message,
        },
      );
      return VisitRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible de proposer un créneau'));
    }
  }

  Future<List<VisitRequest>> fetchMyVisitRequests() async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return _visitRequests;
    }

    try {
      final response = await _dio.get('/visit-requests/my');
      final list = response.data as List;
      return list.map((item) => VisitRequest.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible de charger vos demandes'));
    }
  }

  Future<List<VisitRequest>> fetchPropertyVisitRequests(String propertyId) async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return _visitRequests.where((req) => req.propertyId == propertyId).toList();
    }

    try {
      final response = await _dio.get('/properties/$propertyId/visit-requests');
      final list = response.data as List;
      return list.map((item) => VisitRequest.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw StateError(_extractErrorMessage(error, fallback: 'Impossible de charger les demandes de visite'));
    }
  }

  Future<void> cancelVisitRequest(String visitRequestId) async {
    if (ApiConfig.useLocalAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _visitRequests.removeWhere((req) => req.id == visitRequestId);
      return;
    }

    try {
      await _dio.delete('/visit-requests/$visitRequestId');
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
