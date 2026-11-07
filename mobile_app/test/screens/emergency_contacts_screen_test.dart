import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/emergency_contact_models.dart';
import 'package:scamshield_guardian/screens/settings/emergency_contacts_screen.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/auth_service.dart';
import 'package:scamshield_guardian/services/emergency_contacts_service.dart';

class FakeAuthService extends Fake implements AuthService {
  @override
  Future<String?> getStoredToken() async => 'fake-test-token-123';
}

void main() {
  final sampleContacts = [
    EmergencyContact(
      id: 101,
      userId: 1,
      name: 'Elena Gilbert',
      phoneNumber: '+1555123456',
      relationshipType: 'Sister',
      isActive: true,
      notifySms: true,
      createdAt: DateTime.now(),
    ),
    EmergencyContact(
      id: 102,
      userId: 1,
      name: 'John Gilbert',
      phoneNumber: '+1555987654',
      relationshipType: 'Father',
      isActive: true,
      notifySms: false,
      createdAt: DateTime.now(),
    ),
  ];

  EmergencyContactsService createMockService({
    List<EmergencyContact>? initialContacts,
    bool throwError = false,
  }) {
    final contacts = List<EmergencyContact>.from(initialContacts ?? []);

    final client = MockClient((request) async {
      if (throwError) {
        return http.Response(jsonEncode({'detail': 'Server error'}), 500);
      }

      final path = request.url.path;

      // GET /api/emergency-contacts
      if (request.method == 'GET' && path.contains('/emergency-contacts')) {
        return http.Response(
          jsonEncode(contacts.map((c) => c.toJson()).toList()),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      // POST /api/emergency-contacts/alert
      if (request.method == 'POST' && path.contains('/emergency-contacts/alert')) {
        return http.Response(
          jsonEncode({
            'status': 'dispatched',
            'dispatched_count': contacts.length,
            'recipients': contacts.map((c) => c.phoneNumber).toList(),
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      // POST /api/emergency-contacts
      if (request.method == 'POST' && path.contains('/emergency-contacts')) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final newContact = EmergencyContact(
          id: 999,
          userId: 1,
          name: body['name'] as String,
          phoneNumber: body['phone_number'] as String,
          relationshipType: body['relationship_type'] as String? ?? 'Family',
          isActive: true,
          notifySms: body['notify_sms'] as bool? ?? true,
          createdAt: DateTime.now(),
        );
        contacts.add(newContact);
        return http.Response(
          jsonEncode(newContact.toJson()),
          201,
          headers: {'content-type': 'application/json'},
        );
      }

      // PUT /api/emergency-contacts/{id}
      if (request.method == 'PUT' && path.contains('/emergency-contacts/')) {
        final idStr = path.split('/').last;
        final id = int.tryParse(idStr) ?? 0;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final idx = contacts.indexWhere((c) => c.id == id);
        if (idx != -1) {
          final updated = contacts[idx].copyWith(
            notifySms: body['notify_sms'] as bool?,
          );
          contacts[idx] = updated;
          return http.Response(
            jsonEncode(updated.toJson()),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
      }

      // DELETE /api/emergency-contacts/{id}
      if (request.method == 'DELETE' && path.contains('/emergency-contacts/')) {
        final idStr = path.split('/').last;
        final id = int.tryParse(idStr) ?? 0;
        contacts.removeWhere((c) => c.id == id);
        return http.Response(
          jsonEncode({'status': 'deleted', 'id': id}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response(jsonEncode({'detail': 'Not found'}), 404);
    });

    final api = ApiService(client: client);
    final auth = FakeAuthService();
    return EmergencyContactsService(api: api, authService: auth);
  }

  Widget createWidget({required EmergencyContactsService service}) {
    return MaterialApp(
      home: EmergencyContactsScreen(
        emergencyContactsService: service,
        authService: service.authService,
      ),
    );
  }

  testWidgets('renders banner and empty state when contacts list is empty', (tester) async {
    final service = createMockService(initialContacts: []);
    await tester.pumpWidget(createWidget(service: service));
    await tester.pumpAndSettle();

    expect(find.text('Emergency Contacts'), findsOneWidget);
    expect(find.text('Sentinel Family Safety Net'), findsOneWidget);
    expect(find.text('No Emergency Contacts Yet'), findsOneWidget);
    expect(find.text('Configured Contacts (0/3)'), findsOneWidget);
    expect(find.text('Add First Contact'), findsOneWidget);
  });

  testWidgets('renders list of contacts with names, relations, and phone numbers', (tester) async {
    final service = createMockService(initialContacts: sampleContacts);
    await tester.pumpWidget(createWidget(service: service));
    await tester.pumpAndSettle();

    expect(find.text('Configured Contacts (2/3)'), findsOneWidget);
    expect(find.text('Elena Gilbert'), findsOneWidget);
    expect(find.text('Sister'), findsOneWidget);
    expect(find.text('+1555123456'), findsOneWidget);

    expect(find.text('John Gilbert'), findsOneWidget);
    expect(find.text('Father'), findsOneWidget);
    expect(find.text('+1555987654'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Test Family Alerts'), findsOneWidget);
    expect(find.text('Send Test Alert'), findsOneWidget);
  });

  testWidgets('toggles SMS switch successfully', (tester) async {
    final service = createMockService(initialContacts: sampleContacts);
    await tester.pumpWidget(createWidget(service: service));
    await tester.pumpAndSettle();

    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));

    await tester.tap(switches.first);
    await tester.pumpAndSettle();
  });

  testWidgets('shows Add Contact bottom sheet and adds new contact', (tester) async {
    final service = createMockService(initialContacts: sampleContacts);
    await tester.pumpWidget(createWidget(service: service));
    await tester.pumpAndSettle();

    final addButton = find.text('Add Contact');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('Add Emergency Contact'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Stefan Salvatore');
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone Number (e.g. +1234567890)'),
      '+1555444333',
    );

    await tester.tap(find.text('Save Contact'));
    await tester.pumpAndSettle();

    expect(find.text('Configured Contacts (3/3)'), findsOneWidget);
    expect(find.text('Stefan Salvatore'), findsOneWidget);
  });

  testWidgets('deletes contact when confirmed in dialog', (tester) async {
    final service = createMockService(initialContacts: sampleContacts);
    await tester.pumpWidget(createWidget(service: service));
    await tester.pumpAndSettle();

    final deleteIcons = find.byIcon(Icons.delete_outline_rounded);
    expect(deleteIcons, findsNWidgets(2));

    await tester.tap(deleteIcons.first);
    await tester.pumpAndSettle();

    expect(find.text('Remove Contact?'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Configured Contacts (1/3)'), findsOneWidget);
    expect(find.text('Elena Gilbert'), findsNothing);
    expect(find.text('John Gilbert'), findsOneWidget);
  });

  testWidgets('sends test alert when Send Test Alert is tapped', (tester) async {
    final service = createMockService(initialContacts: sampleContacts);
    await tester.pumpWidget(createWidget(service: service));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    final testAlertButton = find.text('Send Test Alert');
    expect(testAlertButton, findsOneWidget);

    await tester.tap(testAlertButton);
    await tester.pumpAndSettle();

    expect(find.text('Test alert dispatched to 2 contact(s)!'), findsOneWidget);
  });
}
