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
  // JSON SERIALIZATION
  // =============================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullname': fullName,
    };
  }

  factory AuthModelBackend.fromJson(Map<String, dynamic> json) {
    return AuthModelBackend(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullname'] ?? '',
    );
  }

  // =============================================
  // AUTHENTICATION METHODS - PRODUCTION READY
  // =============================================

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      AppLogger.authEvent('Registration attempt', data: {'email': email});

      final requestData = {
        'email': email.toLowerCase().trim(),
        'password': password,
        'fullname': fullName.trim(),
      };

      final response = await _apiService.post(
        ApiConfig.registerEndpoint,
        requestData,
        requiresAuth: false,
      );

      if (response['success'] == true) {
        AppLogger.authEvent('Registration successful');
        return {
          'success': true,
          'message': response['message'] ?? 'Registration successful! Please check your email for verification code.',
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
        ApiConfig.loginEndpoint,
        requestData,
        requiresAuth: false,
      );

      if (response['success'] == true) {
        AppLogger.authEvent('Login successful');

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

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      AppLogger.authEvent('Email verification attempt');

      final requestData = {
        'email': email.toLowerCase().trim(),
        'otp_code': code.trim(),
      };

      final response = await _apiService.post(
        ApiConfig.verifyEmailEndpoint,
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

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      AppLogger.authEvent('Forgot password request');

      final requestData = {
        'email': email.toLowerCase().trim(),
      };

      final response = await _apiService.post(
        ApiConfig.forgotPasswordEndpoint,
        requestData,
        requiresAuth: false,
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Failed to send reset code',
      };
    } catch (e) {
      AppLogger.error('Forgot password error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Failed to process request: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      AppLogger.authEvent('Reset code verification attempt');

      final requestData = {
        'email': email.toLowerCase().trim(),
        'otp_code': code.trim(),
      };

      final response = await _apiService.post(
        ApiConfig.verifyOtpEndpoint,
        requestData,
        requiresAuth: false,
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Verification failed',
      };
    } catch (e) {
      AppLogger.error('Reset code verification error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Verification failed: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
    String? code,
  }) async {
    try {
      AppLogger.authEvent('Password reset attempt');

      final requestData = {
        'email': email.toLowerCase().trim(),
        'password': newPassword,
        'confirm_password': newPassword,
      };

      final response = await _apiService.post(
        ApiConfig.changePasswordEndpoint,
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

  static Future<Map<String, dynamic>> resendCode({
    required String email,
  }) async {
    try {
      AppLogger.authEvent('Resend code request');

      final requestData = {
        'email': email.toLowerCase().trim(),
      };

      final response = await _apiService.post(
        ApiConfig.resendCodeEndpoint,
        requestData,
        requiresAuth: false,
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Failed to resend code',
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
      await _apiService.logout();
      AppLogger.authEvent('Logout completed');
    } catch (e) {
      AppLogger.error('Logout error', tag: 'AUTH', error: e);
      await _clearCurrentUser();
      await _apiService.logout();
    }
  }

  static Future<AuthModelBackend?> getCurrentUser() async {
    try {
      // Try to get fresh user data from API
      try {
        final response = await _apiService.get(ApiConfig.getCurrentUserEndpoint);
        if (response['success'] == true && response['data'] != null) {
          final user = AuthModelBackend.fromJson(response['data']);
          await _saveCurrentUser(user);
          return user;
        }
      } catch (e) {
        AppLogger.warning('Failed to get fresh user data from API', tag: 'AUTH');
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

  static Future<bool> isLoggedIn() async {
    try {
      final tokenStatus = await _apiService.checkTokenStatus();
      if (tokenStatus['hasToken'] != true) {
        AppLogger.debug('No access token found', tag: 'AUTH');
        return false;
      }

      try {
        final response = await _apiService.get(ApiConfig.getCurrentUserEndpoint);
        final isValid = response['success'] == true;
        AppLogger.debug('Token validation result: $isValid', tag: 'AUTH');
        return isValid;
      } catch (e) {
        AppLogger.warning('Token validation failed', tag: 'AUTH', error: e);
        return false;
      }
    } catch (e) {
      AppLogger.error('Login status check error', tag: 'AUTH', error: e);
      return false;
    }
  }

  // =============================================
  // PRIVATE HELPER METHODS
  // =============================================

  static Future<void> _saveCurrentUser(AuthModelBackend user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', jsonEncode(user.toJson()));
      AppLogger.debug('User data saved to cache', tag: 'AUTH');
    } catch (e) {
      AppLogger.error('Failed to save user', tag: 'AUTH', error: e);
    }
  }

  static Future<void> _clearCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUser');
      AppLogger.debug('User data cleared from cache', tag: 'AUTH');
    } catch (e) {
      AppLogger.error('Failed to clear user', tag: 'AUTH', error: e);
    }
  }

  @override
  String toString() {
    return 'AuthModelBackend{id: $id, email: $email, fullName: $fullName}';
  }
}