import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/config/app_config.dart';

void main() {
  test('API base URL uses the Render cloud host by default', () {
    expect(AppConfig.apiBaseUri.host, 'scamshield-backend-f0wc.onrender.com');
    expect(AppConfig.apiBaseUri.path, '/api');
    expect(AppConfig.apiBaseUri.scheme, 'https');
  });
}
