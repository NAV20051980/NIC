import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_sha512_demo/main.dart';
import 'package:crypto_sha512_demo/api_service.dart';

void main() {
  test('SHA-512 Hashing verification', () {
    const password = 'password123';
    final hash = ApiService.sha512Hex(password);
    expect(
      hash,
      'bed4efa1d4fdbd954bd3705d6a2a78270ec9a52ecfbfb010c61862af5c76af176'
      '1ffeb1aef6aca1bf5d02b3781aa854fabd2b69c790de74e17ecfec3cb6ac4bf',
    );
    expect(hash.length, 128);
  });

  testWidgets('Login Page UI Elements smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify UI components exist
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
