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
  final String phoneNumber;

  AuthModelBackend({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
  });

  // =============================================
  // JSON SERIALIZATION - Updated for API docs
  // =============================================

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullname': fullName,
      'phone_number': phoneNumber,
    };
  }

  // Create from JSON - Updated to handle API response structure
  factory AuthModelBackend.fromJson(Map<String, dynamic> json) {
    return AuthModelBackend(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullname'] ?? json['full_name'] ?? '', // Handle both field names
      phoneNumber: json['phone_number'] ?? '',
    );
  }

  // =============================================
  // AUTHENTICATION METHODS - Updated to match API docs
  // =============================================

  // Register new user - Updated to match API docs (/register)
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      AppLogger.authEvent('Registration attempt', data: {'email': email, 'fullname': fullName});

      final requestData = {
        'email': email.toLowerCase().trim(),
        'password': password,
        'fullname': fullName.trim(), // API expects 'fullname'
        'phone_number': phoneNumber.trim(),
      };

      AppLogger.apiRequest('POST', ApiConfig.registerEndpoint, data: {
        ...requestData,
        'password': '[HIDDEN]' // Don't log password
      });

      final response = await _apiService.post(
        ApiConfig.registerEndpoint,
        requestData,
        requiresAuth: false,
      );

      if (response['success']) {
        AppLogger.authEvent('Registration successful', data: {'email': email});

        // Save token if present in response
        if (response['data']?['token'] != null) {
          await _saveToken(response['data']['token']);
          AppLogger.authEvent('Token saved after registration');
        }

        return {
          'success': true,
          'message': 'Registration successful',
          'userId': response['data']?['user']?['id']?.toString(),
          'verificationCode': response['verificationCode'], // For demo/testing
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

  // Login user - Updated to match API docs (/login)
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

      AppLogger.apiRequest('POST', ApiConfig.loginEndpoint, data: {
        'email': email.toLowerCase().trim(),
        'password': '[HIDDEN]'
      });

      final response = await _apiService.post(
        ApiConfig.loginEndpoint,
        requestData,
        requiresAuth: false,
      );

      if (response['success']) {
        AppLogger.authEvent('Login successful', data: {'email': email});

        // Save token
        if (response['data']?['token'] != null) {
          await _saveToken(response['data']['token']);
          AppLogger.authEvent('Token saved after login');
        }

        // Save current user data if available
        if (response['data']?['user'] != null) {
          final user = AuthModelBackend.fromJson(response['data']['user']);
          await _saveCurrentUser(user);
          AppLogger.authEvent('User data cached');
        }

        return {
          'success': true,
          'message': 'Login successful',
          'user': response['data']?['user'] != null
              ? AuthModelBackend.fromJson(response['data']['user'])
              : null,
        };
      } else {
        AppLogger.authEvent('Login failed', data: {'message': response['message']});
        return {
          'success': false,
          'message': response['message'] ?? 'Login failed',
          'needsVerification': response['needsVerification'] ?? false,
          'errors': response['errors'] ?? {},
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

  // Verify email with code - Updated to match API docs (/verify-email)
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      AppLogger.authEvent('Email verification attempt', data: {'email': email});

      final requestData = {
        'email': email.toLowerCase().trim(),
        'code': code.trim(), // API docs show 'code' field
      };

      AppLogger.apiRequest('POST', ApiConfig.verifyEmailEndpoint, data: requestData);

      final response = await _apiService.post(
        ApiConfig.verifyEmailEndpoint,
        requestData,
        requiresAuth: false,
      );

      if (response['success']) {
        AppLogger.authEvent('Email verification successful', data: {'email': email});
      } else {
        AppLogger.authEvent('Email verification failed', data: {'message': response['message']});
      }

      return {
        'success': response['success'],
        'message': response['message'] ?? (response['success'] ? 'Email verified successfully' : 'Verification failed'),
        'errors': response['errors'] ?? {},
      };
    } catch (e) {
      AppLogger.error('Email verification error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Verification failed: $e',
      };
    }
  }

  // Forgot password - Updated to match API docs (/forgot-password)
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      AppLogger.authEvent('Forgot password request', data: {'email': email});

      final requestData = {
        'email': email.toLowerCase().trim(),
      };

      AppLogger.apiRequest('POST', ApiConfig.forgotPasswordEndpoint, data: requestData);

      final response = await _apiService.post(
        ApiConfig.forgotPasswordEndpoint,
        requestData,
        requiresAuth: false,
      );

      if (response['success']) {
        AppLogger.authEvent('Forgot password successful', data: {'email': email});
      } else {
        AppLogger.authEvent('Forgot password failed', data: {'message': response['message']});
      }

      return {
        'success': response['success'],
        'message': response['message'] ?? (response['success'] ? 'Reset code sent' : 'Failed to send reset code'),
        'resetCode': response['resetCode'], // For demo/testing
      };
    } catch (e) {
      AppLogger.error('Forgot password error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Failed to process request: $e',
      };
    }
  }

  // Verify reset code - Keep existing implementation (not in API docs)
  static Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      AppLogger.authEvent('Reset code verification attempt', data: {'email': email});

      final requestData = {
        'email': email.toLowerCase().trim(),
        'code': code.trim(),
      };

      AppLogger.apiRequest('POST', ApiConfig.verifyResetCodeEndpoint, data: requestData);

      final response = await _apiService.post(
        ApiConfig.verifyResetCodeEndpoint,
        requestData,
        requiresAuth: false,
      );

      if (response['success']) {
        AppLogger.authEvent('Reset code verification successful', data: {'email': email});
      } else {
        AppLogger.authEvent('Reset code verification failed', data: {'message': response['message']});
      }

      return {
        'success': response['success'],
        'message': response['message'] ?? (response['success'] ? 'Code verified' : 'Invalid code'),
      };
    } catch (e) {
      AppLogger.error('Reset code verification error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Verification failed: $e',
      };
    }
  }

  // Reset password - Keep existing implementation (not in API docs)
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      AppLogger.authEvent('Password reset attempt', data: {'email': email});

      final requestData = {
        'email': email.toLowerCase().trim(),
        'newPassword': newPassword,
      };

      AppLogger.apiRequest('POST', ApiConfig.resetPasswordEndpoint, data: {
        'email': email.toLowerCase().trim(),
        'newPassword': '[HIDDEN]'
      });

      final response = await _apiService.post(
        ApiConfig.resetPasswordEndpoint,
        requestData,
        requiresAuth: false,
      );

      if (response['success']) {
        AppLogger.authEvent('Password reset successful', data: {'email': email});
      } else {
        AppLogger.authEvent('Password reset failed', data: {'message': response['message']});
      }

      return {
        'success': response['success'],
        'message': response['message'] ?? (response['success'] ? 'Password reset successful' : 'Reset failed'),
      };
    } catch (e) {
      AppLogger.error('Password reset error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Reset failed: $e',
      };
    }
  }

  // =============================================
  // SESSION MANAGEMENT
  // =============================================

  // Logout - Updated with better error handling
  static Future<void> logout() async {
    try {
      AppLogger.authEvent('Logout initiated');

      // Try to call logout endpoint if it exists
      try {
        await _apiService.post(ApiConfig.logoutEndpoint, {});
        AppLogger.authEvent('Logout API call successful');
      } catch (e) {
        AppLogger.warning('Logout API call failed, proceeding with local cleanup', tag: 'AUTH');
      }
    } catch (e) {
      AppLogger.error('Logout API error', tag: 'AUTH', error: e);
    } finally {
      // Always clean up local data
      await _apiService.logout();
      await _clearCurrentUser();
      await _clearToken();
      AppLogger.authEvent('Logout completed - local data cleared');
    }
  }

  // Get current user - Enhanced with better error handling
  static Future<AuthModelBackend?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('currentUser');

      if (userData == null) {
        AppLogger.debug('No cached user data found', tag: 'AUTH');
        return null;
      }

      final userJson = jsonDecode(userData);
      final user = AuthModelBackend.fromJson(userJson);
      AppLogger.debug('Retrieved cached user data', tag: 'AUTH');
      return user;
    } catch (e) {
      AppLogger.error('Get current user error', tag: 'AUTH', error: e);
      // Clear corrupted data
      await _clearCurrentUser();
      return null;
    }
  }

  // Check if user is logged in - Enhanced validation
  static Future<bool> isLoggedIn() async {
    try {
      final user = await getCurrentUser();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final loggedIn = user != null && token != null && token.isNotEmpty;
      AppLogger.debug('Login status check: $loggedIn', tag: 'AUTH');
      return loggedIn;
    } catch (e) {
      AppLogger.error('Login status check error', tag: 'AUTH', error: e);
      return false;
    }
  }

  // =============================================
  // PRIVATE HELPER METHODS
  // =============================================

  // Save token
  static Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      AppLogger.debug('Auth token saved', tag: 'AUTH');
    } catch (e) {
      AppLogger.error('Failed to save auth token', tag: 'AUTH', error: e);
    }
  }

  // Clear token
  static Future<void> _clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      AppLogger.debug('Auth token cleared', tag: 'AUTH');
    } catch (e) {
      AppLogger.error('Failed to clear auth token', tag: 'AUTH', error: e);
    }
  }

  // Save current user data locally
  static Future<void> _saveCurrentUser(AuthModelBackend user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', jsonEncode(user.toJson()));
      AppLogger.debug('User data cached', tag: 'AUTH');
    } catch (e) {
      AppLogger.error('Failed to save user data', tag: 'AUTH', error: e);
    }
  }

  // Clear current user data
  static Future<void> _clearCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUser');
      AppLogger.debug('User data cleared', tag: 'AUTH');
    } catch (e) {
      AppLogger.error('Failed to clear user data', tag: 'AUTH', error: e);
    }
  }

  // =============================================
  // REMOVED/DEPRECATED METHODS
  // =============================================

  // NOTE: refreshUserData() method removed as getCurrentUserEndpoint
  // is not mentioned in API docs. If needed, it can be re-implemented
  // when the API supports user profile fetching.

  @override
  String toString() {
    return 'AuthModelBackend{id: $id, email: $email, fullName: $fullName}';
  }
}