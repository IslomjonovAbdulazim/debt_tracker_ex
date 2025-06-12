// lib/models/auth_model_backend.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../config/app_logger.dart';

class AuthModelBackend {
  static final ApiService _apiService = ApiService();

  final String id;
  final String email;
  final String fullName;

  AuthModelBackend({
    required this.id,
    required this.email,
    required this.fullName,
  });

  // =============================================
  // JSON SERIALIZATION - FIXED for documentation
  // =============================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullname': fullName, // Documentation uses 'fullname'
    };
  }

  // FIXED: Documentation returns 'fullname' field
  factory AuthModelBackend.fromJson(Map<String, dynamic> json) {
    return AuthModelBackend(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullname'] ?? '', // Documentation field name
    );
  }

  // =============================================
  // AUTHENTICATION METHODS - FIXED for documentation endpoints
  // =============================================

  // FIXED: Register using documentation endpoint
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      AppLogger.authEvent('Registration attempt', data: {'email': email});

      // FIXED: Documentation expects these exact field names
      final requestData = {
        'email': email.toLowerCase().trim(),
        'password': password,
        'fullname': fullName.trim(), // Documentation field name
      };

      final response = await _apiService.post(
        ApiConfig.registerEndpoint, // POST /register
        requestData,
        requiresAuth: false,
      );

      if (response['success'] == true) {
        AppLogger.authEvent('Registration successful');
        return {
          'success': true,
          'message': response['message'] ?? 'Registration successful',
          'verificationCode': '123456', // Demo code for development
        };
      } else {
        AppLogger.authEvent('Registration failed', data: {'message': response['message']});
        return {
          'success': false,
          'message': response['message'] ?? 'Registration failed',
          'errors': response['errors'] ?? {},
        };
      }
    } catch (e) {
      AppLogger.error('Registration error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Registration failed: $e',
      };
    }
  }

  // FIXED: Login using documentation endpoint
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.authEvent('Login attempt', data: {'email': email});

      final requestData = {
        'email': email.toLowerCase().trim(),
        'password': password,
      };

      final response = await _apiService.post(
        ApiConfig.loginEndpoint, // POST /login
        requestData,
        requiresAuth: false,
      );

      if (response['success'] == true) {
        AppLogger.authEvent('Login successful');

        // Handle token from response
        final token = response['data']?['access_token'];
        if (token != null) {
          await _saveToken(token);
        }

        // Handle user data from response
        if (response['data']?['user'] != null) {
          final user = AuthModelBackend.fromJson(response['data']['user']);
          await _saveCurrentUser(user);
        }

        return {
          'success': true,
          'message': response['message'] ?? 'Login successful',
        };
      } else {
        AppLogger.authEvent('Login failed');

        // Check for email verification needed
        final needsVerification = response['message']?.toLowerCase().contains('not verified') ?? false;

        return {
          'success': false,
          'message': response['message'] ?? 'Login failed',
          'needsVerification': needsVerification,
        };
      }
    } catch (e) {
      AppLogger.error('Login error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Login failed: $e',
      };
    }
  }

  // FIXED: Email verification using documentation endpoint
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      AppLogger.authEvent('Email verification attempt');

      final requestData = {
        'email': email.toLowerCase().trim(),
        'code': code.trim(),
      };

      final response = await _apiService.post(
        ApiConfig.verifyEmailEndpoint, // POST /verify-email
        requestData,
        requiresAuth: false,
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Verification failed',
      };
    } catch (e) {
      AppLogger.error('Email verification error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Verification failed: $e',
      };
    }
  }

  // FIXED: Forgot password using documentation endpoint
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      AppLogger.authEvent('Forgot password request');

      final requestData = {
        'email': email.toLowerCase().trim(),
      };

      final response = await _apiService.post(
        ApiConfig.forgotPasswordEndpoint, // POST /forgot-password
        requestData,
        requiresAuth: false,
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Failed to send reset code',
        'resetCode': '123456', // Demo code for development
      };
    } catch (e) {
      AppLogger.error('Forgot password error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Failed to process request: $e',
      };
    }
  }

  // FIXED: Reset password using documentation endpoint
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
    String? code,
  }) async {
    try {
      AppLogger.authEvent('Password reset attempt');

      final requestData = {
        'email': email.toLowerCase().trim(),
        'new_password': newPassword, // Backend field name
        'code': code ?? '123456',
      };

      final response = await _apiService.post(
        ApiConfig.resetPasswordEndpoint, // POST /reset-password
        requestData,
        requiresAuth: false,
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Reset failed',
      };
    } catch (e) {
      AppLogger.error('Password reset error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Reset failed: $e',
      };
    }
  }

  // Verify reset code method (for UI compatibility)
  static Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      AppLogger.authEvent('Reset code verification attempt');

      // Simple validation since there's no specific endpoint
      if (code.trim().length == 6 && RegExp(r'^[0-9]+$').hasMatch(code.trim())) {
        AppLogger.authEvent('Reset code format validation successful');
        return {
          'success': true,
          'message': 'Code format is valid',
        };
      } else {
        AppLogger.authEvent('Reset code format validation failed');
        return {
          'success': false,
          'message': 'Invalid code format. Please enter a 6-digit code.',
        };
      }
    } catch (e) {
      AppLogger.error('Reset code verification error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Verification failed: $e',
      };
    }
  }

  // FIXED: Resend code endpoint (if available)
  static Future<Map<String, dynamic>> resendCode({
    required String email,
  }) async {
    try {
      AppLogger.authEvent('Resend code request');

      final requestData = {
        'email': email.toLowerCase().trim(),
      };

      final response = await _apiService.post(
        ApiConfig.resendCodeEndpoint, // POST /resend
        requestData,
        requiresAuth: false,
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Failed to resend code',
        'verificationCode': '123456', // Demo code for development
      };
    } catch (e) {
      AppLogger.error('Resend code error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Failed to resend code: $e',
      };
    }
  }

  // =============================================
  // SESSION MANAGEMENT
  // =============================================

  static Future<void> logout() async {
    try {
      AppLogger.authEvent('Logout initiated');
      await _clearCurrentUser();
      await _clearToken();
      AppLogger.authEvent('Logout completed');
    } catch (e) {
      AppLogger.error('Logout error', tag: 'AUTH', error: e);
      // Always clean up even if error
      await _clearCurrentUser();
      await _clearToken();
    }
  }

  // FIXED: Get current user using documentation endpoint
  static Future<AuthModelBackend?> getCurrentUser() async {
    try {
      final token = await _getToken();
      if (token != null) {
        try {
          final response = await _apiService.get(ApiConfig.getCurrentUserEndpoint); // GET /me
          if (response['success'] == true && response['data'] != null) {
            final user = AuthModelBackend.fromJson(response['data']);
            await _saveCurrentUser(user);
            return user;
          }
        } catch (e) {
          AppLogger.warning('Failed to get fresh user data', tag: 'AUTH');
        }
      }

      // Fallback to cached data
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('currentUser');
      if (userData == null) return null;

      final userJson = jsonDecode(userData);
      return AuthModelBackend.fromJson(userJson);
    } catch (e) {
      AppLogger.error('Get current user error', tag: 'AUTH', error: e);
      await _clearCurrentUser();
      return null;
    }
  }

  // Check login status with backend validation
  static Future<bool> isLoggedIn() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return false;

      // Validate token with backend
      try {
        final response = await _apiService.get(ApiConfig.getCurrentUserEndpoint);
        return response['success'] == true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // =============================================
  // PRIVATE HELPER METHODS
  // =============================================

  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      return null;
    }
  }

  static Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      AppLogger.error('Failed to save token', tag: 'AUTH', error: e);
    }
  }

  static Future<void> _clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      AppLogger.error('Failed to clear token', tag: 'AUTH', error: e);
    }
  }

  static Future<void> _saveCurrentUser(AuthModelBackend user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', jsonEncode(user.toJson()));
    } catch (e) {
      AppLogger.error('Failed to save user', tag: 'AUTH', error: e);
    }
  }

  static Future<void> _clearCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUser');
    } catch (e) {
      AppLogger.error('Failed to clear user', tag: 'AUTH', error: e);
    }
  }

  @override
  String toString() {
    return 'AuthModelBackend{id: $id, email: $email, fullName: $fullName}';
  }
}