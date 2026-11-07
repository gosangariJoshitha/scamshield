import '../models/emergency_contact_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class EmergencyContactsService {
  EmergencyContactsService({
    required this.api,
    required this.authService,
  });

  final ApiService api;
  final AuthService authService;

  Future<List<EmergencyContact>> getContacts() async {
    final token = await authService.getStoredToken();
    if (token == null) {
      throw const ApiException('Authentication required to view emergency contacts.');
    }

    final response = await api.get('/emergency-contacts', token: token);
    if (response is! List<dynamic>) {
      throw const ApiException('Invalid response when fetching emergency contacts.');
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(EmergencyContact.fromJson)
        .toList();
  }

  Future<EmergencyContact> addContact({
    required String name,
    required String phoneNumber,
    String relationshipType = 'Family',
    bool notifySms = true,
  }) async {
    final token = await authService.getStoredToken();
    if (token == null) {
      throw const ApiException('Authentication required to add emergency contact.');
    }

    final body = {
      'name': name.trim(),
      'phone_number': phoneNumber.trim(),
      'relationship_type': relationshipType.trim(),
      'notify_sms': notifySms,
    };

    final response = await api.postJson('/emergency-contacts', body, token: token);
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid response when adding emergency contact.');
    }

    return EmergencyContact.fromJson(response);
  }

  Future<EmergencyContact> updateContact(
    int id, {
    String? name,
    String? phoneNumber,
    String? relationshipType,
    bool? isActive,
    bool? notifySms,
  }) async {
    final token = await authService.getStoredToken();
    if (token == null) {
      throw const ApiException('Authentication required to update emergency contact.');
    }

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (phoneNumber != null) body['phone_number'] = phoneNumber.trim();
    if (relationshipType != null) body['relationship_type'] = relationshipType.trim();
    if (isActive != null) body['is_active'] = isActive;
    if (notifySms != null) body['notify_sms'] = notifySms;

    final response = await api.putJson('/emergency-contacts/$id', body, token: token);
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid response when updating emergency contact.');
    }

    return EmergencyContact.fromJson(response);
  }

  Future<bool> deleteContact(int id) async {
    final token = await authService.getStoredToken();
    if (token == null) {
      throw const ApiException('Authentication required to delete emergency contact.');
    }

    await api.delete('/emergency-contacts/$id', token: token);
    return true;
  }

  Future<Map<String, dynamic>> sendTestAlert({
    required String sessionId,
    int riskScore = 90,
    String detectedCategory = 'Live Sentinel Scam Test Alert',
  }) async {
    final token = await authService.getStoredToken();
    if (token == null) {
      throw const ApiException('Authentication required to send alert.');
    }

    final body = {
      'session_id': sessionId,
      'risk_score': riskScore,
      'detected_category': detectedCategory,
    };

    final response = await api.postJson('/emergency-contacts/alert', body, token: token);
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid response when sending alert.');
    }

    return response;
  }
}

