import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result model returned upon successful or failed authentication
class AuthResult {
  final bool success;
  final String? id;
  final String? hash;
  final String? message;

  const AuthResult({
    required this.success,
    this.id,
    this.hash,
    this.message,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      success: json['success'] as bool? ?? false,
      id: json['id'] as String?,
      hash: json['hash'] as String?,
      message: json['message'] as String?,
    );
  }
}

/// Service handling cryptographic hashing and REST API communication
class ApiService {
  /// Build-time environment variable: flutter run --dart-define=API_BASE_URL=https://your-service.onrender.com
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Optional runtime override for custom physical device LAN IP or debugging
  static String? customBaseUrl;

  /// Resolves the backend base URL:
  /// 1. API_BASE_URL (from dart-define if specified and non-empty)
  /// 2. customBaseUrl (if explicitly set in code/runtime)
  /// 3. Android Emulator: http://10.0.2.2:3000
  /// 4. Web / iOS Simulator / Desktop: http://localhost:3000
  static String get baseUrl {
    if (_envBaseUrl.trim().isNotEmpty) {
      // Remove any trailing slash for consistency
      return _envBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return customBaseUrl!.trim().replaceAll(RegExp(r'/+$'), '');
    }
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {
      // Fallback if Platform is unsupported on current platform
    }
    return 'http://localhost:3000';
  }

  /// Hashes a plaintext password into a 128-character SHA-512 hex string
  static String sha512Hex(String password) {
    final bytes = utf8.encode(password);
    return sha512.convert(bytes).toString();
  }

  /// Sends login credentials to the REST API with a 60-second timeout (accommodates cold start wake-up on free tiers)
  static Future<AuthResult> login(String id, String password) async {
    final pwdHash = sha512Hex(password);
    final url = Uri.parse('$baseUrl/api/login');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': id.trim(),
              'pwdHash': pwdHash,
            }),
          )
          .timeout(const Duration(seconds: 60));

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return AuthResult.fromJson(data);
      } else {
        final errorMsg = data['message'] as String? ?? 'Invalid id or password';
        return AuthResult(success: false, message: errorMsg);
      }
    } on TimeoutException {
      return const AuthResult(
        success: false,
        message: 'Connection timed out (60s). The server took too long to respond.',
      );
    } on http.ClientException catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error: ${e.message}. Check backend URL ($baseUrl).',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Unable to connect to backend: $e',
      );
    }
  }

  /// Optional registration endpoint with 60-second timeout
  static Future<AuthResult> register(String id, String password) async {
    final pwdHash = sha512Hex(password);
    final url = Uri.parse('$baseUrl/api/register');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': id.trim(),
              'pwdHash': pwdHash,
            }),
          )
          .timeout(const Duration(seconds: 60));

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 && data['success'] == true) {
        return AuthResult.fromJson(data);
      } else {
        final errorMsg = data['message'] as String? ?? 'Registration failed.';
        return AuthResult(success: false, message: errorMsg);
      }
    } on TimeoutException {
      return const AuthResult(
        success: false,
        message: 'Connection timed out (60s).',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Registration error: $e',
      );
    }
  }
}
