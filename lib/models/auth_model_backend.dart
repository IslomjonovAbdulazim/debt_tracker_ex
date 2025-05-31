import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AuthModelBackend {
  static final ApiService _apiService = ApiService();

  final String userId;
  final String email;
  final String fullName;
  final String phoneNumber; // Added phone number as required by API
  final bool isVerified;
  final DateTime createdDate;

  AuthModelBackend({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.phoneNumber, // Added phone number
    required this.isVerified,
    required this.createdDate,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'fullname': fullName,  // Changed to snake_case
      'phone_number': phoneNumber,  // Added phone number
      'is_verified': isVerified,  // Changed to snake_case
      'created_at': createdDate.toIso8601String(),  // Changed to snake_case
    };
  }

  // Create from JSON
  factory AuthModelBackend.fromJson(Map<String, dynamic> json) {
    return AuthModelBackend(
      userId: json['userId'] ?? json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullname'] ?? '',  // API uses snake_case
      phoneNumber: json['phone_number'] ?? '',  // API uses snake_case
      isVerified: json['is_verified'] ?? false,  // API uses snake_case
      createdDate: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Register new user - Updated to match API requirements
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber, // Now required
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.registerEndpoint,
        {
          'email': email.toLowerCase(),
          'password': password,
          'fullname': fullName,  // Send as full_name
          'phone_number': phoneNumber,  // Send as phone_number
        },
        requiresAuth: false,
      );

      if (response['success']) {
        // Save token if present in response
        if (response['data']?['token'] != null) {
          await _saveToken(response['data']['token']);
        }

        return {
          'success': true,
          'message': 'Registration successful',
          'userId': response['data']?['user']?['id']?.toString(),
          'verificationCode': response['verificationCode'], // For demo/testing
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: $e',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.loginEndpoint,
        {
          'email': email.toLowerCase(),
          'password': password,
        },
        requiresAuth: false,
      );

      if (response['success']) {
        // Save token
        if (response['data']?['token'] != null) {
          await _saveToken(response['data']['token']);
        }

        // Save current user data
        final user = AuthModelBackend.fromJson(response['data']['user']);
        await _saveCurrentUser(user);

        return {
          'success': true,
          'message': 'Login successful',
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Login failed',
          'needsVerification': response['needsVerification'] ?? false,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: $e',
      };
    }
  }

  // Verify email with code
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.verifyEmailEndpoint,
        {
          'email': email.toLowerCase(),
          'otp': code,
        },
        requiresAuth: false,
      );

      return {
        'success': response['success'],
        'message': response['message'] ?? (response['success'] ? 'Email verified successfully' : 'Verification failed'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Verification failed: $e',
      };
    }
  }

  // Forgot password - Generate reset code
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.forgotPasswordEndpoint,
        {
          'email': email.toLowerCase(),
        },
        requiresAuth: false,
      );

      return {
        'success': response['success'],
        'message': response['message'] ?? (response['success'] ? 'Reset code sent' : 'Failed to send reset code'),
        'resetCode': response['resetCode'], // For demo/testing
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to process request: $e',
      };
    }
  }

  // Verify reset code
  static Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.verifyResetCodeEndpoint,
        {
          'email': email.toLowerCase(),
          'code': code,
        },
        requiresAuth: false,
      );

      return {
        'success': response['success'],
        'message': response['message'] ?? (response['success'] ? 'Code verified' : 'Invalid code'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Verification failed: $e',
      };
    }
  }

  // Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.resetPasswordEndpoint,
        {
          'email': email.toLowerCase(),
          'newPassword': newPassword,
        },
        requiresAuth: false,
      );

      return {
        'success': response['success'],
        'message': response['message'] ?? (response['success'] ? 'Password reset successful' : 'Reset failed'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Reset failed: $e',
      };
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      await _apiService.post(ApiConfig.logoutEndpoint, {});
    } catch (e) {
      print('Logout API call failed: $e');
    } finally {
      await _apiService.logout();
      await _clearCurrentUser();
      await _clearToken();
    }
  }

  // Get current user
  static Future<AuthModelBackend?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('currentUser');

      if (userData == null) return null;

      final userJson = jsonDecode(userData);
      return AuthModelBackend.fromJson(userJson);
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    return user != null && token != null;
  }

  // Save token
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token
  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Save current user data locally
  static Future<void> _saveCurrentUser(AuthModelBackend user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', jsonEncode(user.toJson()));
  }

  // Clear current user data
  static Future<void> _clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
  }

  // Refresh user data from server
  static Future<AuthModelBackend?> refreshUserData() async {
    try {
      final response = await _apiService.get(ApiConfig.getCurrentUserEndpoint);

      if (response['success']) {
        final user = AuthModelBackend.fromJson(response['data']['user']);
        await _saveCurrentUser(user);
        return user;
      }

      return null;
    } catch (e) {
      print('Failed to refresh user data: $e');
      return null;
    }
  }
}