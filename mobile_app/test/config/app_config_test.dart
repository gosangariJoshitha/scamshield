import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/config/app_config.dart';

void main() {
  test('API base URL uses the Android emulator host by default', () {
    expect(AppConfig.apiBaseUri.host, '10.0.2.2');
    expect(AppConfig.apiBaseUri.path, '/api');
    expect(AppConfig.apiBaseUri.scheme, 'http');
  });
}
