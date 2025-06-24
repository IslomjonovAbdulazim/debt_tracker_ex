// lib/models/auth_model.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AuthModel {
  final ApiService _apiService = ApiService();

  final String id;
  final String email;
  final String fullName;

  AuthModel({
    required this.id,
    required this.email,
    required this.fullName,
  });

  // JSON serialization - simplified
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullname': fullName,
    };
  }

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullname'] ?? '',
    );
  }

  // Authentication methods - simplified for teaching
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final apiService = ApiService();

    try {
      final requestData = {
        'email': email.toLowerCase().trim(),
        'password': password,
        'fullname': fullName.trim(),
      };

      final response = await apiService.post(
        ApiConfig.registerEndpoint,
        requestData,
        requiresAuth: false,
      );

      if (response['success'] == true) {
        // IMPORTANT: Return verification code for display in app
        return {
          'success': true,
          'message': response['message'] ?? 'Registration successful!',
          'verificationCode': response['code']?.toString(), // Show code in app
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Registration failed',
          'errors': response['errors'] ?? {},
        };
      }
    } catch (e) {
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
    final apiService = ApiService();

    try {
      final requestData = {
        'email': email.toLowerCase().trim(),
        'password': password,
      };

      final response = await apiService.post(
        ApiConfig.loginEndpoint,
        requestData,
        requiresAuth: false,
      );

      if (response['success'] == true) {
        // Save user data if available
        if (response['data']?['user'] != null) {
          final user = AuthModel.fromJson(response['data']['user']);
          await _saveCurrentUser(user);
        }

        return {
          'success': true,
          'message': response['message'] ?? 'Login successful',
        };
      } else {
        // Check if email verification is needed
        final needsVerification = response['message']?.toLowerCase().contains('not verified') ?? false;

        return {
          'success': false,
          'message': response['message'] ?? 'Login failed',
          'needsVerification': needsVerification,
        };
      }
    } catch (e) {
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
    final apiService = ApiService();

    try {
      final requestData = {
        'email': email.toLowerCase().trim(),
        'otp_code': code.trim(),
      };

      final response = await apiService.post(
        ApiConfig.verifyEmailEndpoint,
        requestData,
        requiresAuth: false,
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Verification failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Verification failed: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final apiService = ApiService();

    try {
      final requestData = {
        'email': email.toLowerCase().trim(),
      };

      final response = await apiService.post(
        ApiConfig.forgotPasswordEndpoint,
        requestData,
        requiresAuth: false,
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Failed to send reset code',
        'verificationCode': response['code']?.toString(), // Show reset code
      };
    } catch (e) {
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
    final apiService = ApiService();

    try {
      final requestData = {
        'email': email.toLowerCase().trim(),
        'otp_code': code.trim(),
      };

      final response = await apiService.post(
        ApiConfig.verifyOtpEndpoint,
        requestData,
        requiresAuth: false,
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Verification failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Verification failed: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final apiService = ApiService();

    try {
      final requestData = {
        'email': email.toLowerCase().trim(),
        'password': newPassword,
        'confirm_password': newPassword,
      };

      final response = await apiService.post(
        ApiConfig.changePasswordEndpoint,
        requestData,
        requiresAuth: false,
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Reset failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Reset failed: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> resendCode({
    required String email,
  }) async {
    final apiService = ApiService();

    try {
      final requestData = {
        'email': email.toLowerCase().trim(),
      };

      final response = await apiService.post(
        ApiConfig.resendCodeEndpoint,
        requestData,
        requiresAuth: false,
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Failed to resend code',
        'verificationCode': response['code']?.toString(), // Show new code
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to resend code: $e',
      };
    }
  }

  // Session management - simplified
  static Future<void> logout() async {
    final apiService = ApiService();
    await _clearCurrentUser();
    await apiService.logout();
  }

  static Future<AuthModel?> getCurrentUser() async {
    try {
      final apiService = ApiService();

      // Try to get user from API
      final response = await apiService.get(ApiConfig.getCurrentUserEndpoint);
      if (response['success'] == true && response['data'] != null) {
        final user = AuthModel.fromJson(response['data']);
        await _saveCurrentUser(user);
        return user;
      }

      // Fallback to cached data
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('currentUser');
      if (userData == null) return null;

      final userJson = jsonDecode(userData);
      return AuthModel.fromJson(userJson);
    } catch (e) {
      await _clearCurrentUser();
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final apiService = ApiService();
      final hasToken = await apiService.hasToken();

      if (!hasToken) return false;

      // Test token validity
      final response = await apiService.get(ApiConfig.getCurrentUserEndpoint);
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Helper methods
  static Future<void> _saveCurrentUser(AuthModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', jsonEncode(user.toJson()));
    } catch (e) {
      // Handle error silently for teaching simplicity
    }
  }

  static Future<void> _clearCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUser');
    } catch (e) {
      // Handle error silently for teaching simplicity
    }
  }

  @override
  String toString() {
    return 'AuthModel{id: $id, email: $email, fullName: $fullName}';
  }
}