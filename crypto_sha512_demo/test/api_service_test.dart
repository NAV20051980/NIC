import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_sha512_demo/api_service.dart';

void main() {
  setUpAll(() {
    // For local tests running on macOS VM against Node backend
    ApiService.customBaseUrl = 'http://localhost:3000';
  });

  group('REST API & SHA-512 Authentication Integration Tests', () {
    test('1. Successful login with seeded user alex_dev', () async {
      final result = await ApiService.login('alex_dev', 'password123');
      expect(result.success, isTrue);
      expect(result.id, 'alex_dev');
      expect(
        result.hash,
        'bed4efa1d4fdbd954bd3705d6a2a78270ec9a52ecfbfb010c61862af5c76af176'
        '1ffeb1aef6aca1bf5d02b3781aa854fabd2b69c790de74e17ecfec3cb6ac4bf',
      );
    });

    test('2. Successful login with seeded user navaneet', () async {
      final result = await ApiService.login('navaneet', 'test1234');
      expect(result.success, isTrue);
      expect(result.id, 'navaneet');
      expect(result.hash, isNotNull);
      expect(result.hash!.length, 128);
    });

    test('3. Failed login with wrong password', () async {
      final result = await ApiService.login('alex_dev', 'wrongpassword');
      expect(result.success, isFalse);
      expect(result.message, 'Invalid id or password');
    });

    test('4. Failed login with unknown user ID', () async {
      final result = await ApiService.login('unknown_user_99', 'password123');
      expect(result.success, isFalse);
      expect(result.message, 'Invalid id or password');
    });

    test('5. Register new user and authenticate', () async {
      final uniqueId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
      final regResult = await ApiService.register(uniqueId, 'securepass123');
      expect(regResult.success, isTrue);
      expect(regResult.id, uniqueId);

      final loginResult = await ApiService.login(uniqueId, 'securepass123');
      expect(loginResult.success, isTrue);
      expect(loginResult.id, uniqueId);
    });
  });
}
