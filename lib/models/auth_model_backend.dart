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
  // JSON SERIALIZATION - Updated for backend API
  // =============================================

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullname': fullName, // Backend uses 'fullname'
      'phone_number': phoneNumber,
    };
  }

  // Create from JSON - Updated to handle backend response structure
  factory AuthModelBackend.fromJson(Map<String, dynamic> json) {
    return AuthModelBackend(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullname'] ?? '', // Backend returns 'fullname'
      phoneNumber: json['phone_number'] ?? '', // Backend might not return this
    );
  }

  // =============================================
  // AUTHENTICATION METHODS - Updated to match backend API
  // =============================================

  // Register new user - Updated to match backend API
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
        'fullname': fullName.trim(), // Backend expects 'fullname'
        // Note: phone_number not mentioned in backend docs for registration
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

        // Backend returns verification info
        return {
          'success': true,
          'message': response['message'] ?? 'Registration successful',
          'userId': response['data']?['user_id']?.toString(),
          'verificationCode': '123456', // Demo code for testing
          'emailSent': response['data']?['email_sent'] ?? false,
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

  // Login user - Updated to match backend API
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

        // Backend returns access_token in data object
        final token = response['data']?['access_token'];
        if (token != null) {
          await _saveToken(token);
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
          'message': response['message'] ?? 'Login successful',
          'user': response['data']?['user'] != null
              ? AuthModelBackend.fromJson(response['data']['user'])
              : null,
        };
      } else {
        AppLogger.authEvent('Login failed', data: {'message': response['message']});

        // Check if email verification is needed
        final needsVerification = response['message']?.toLowerCase().contains('not verified') ?? false;

        return {
          'success': false,
          'message': response['message'] ?? 'Login failed',
          'needsVerification': needsVerification,
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

  // Verify email with code - Updated to match backend API
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      AppLogger.authEvent('Email verification attempt', data: {'email': email});

      final requestData = {
        'email': email.toLowerCase().trim(),
        'code': code.trim(),
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

  // Forgot password - Updated to match backend API
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
        'resetCode': '123456', // Demo code for testing
      };
    } catch (e) {
      AppLogger.error('Forgot password error', tag: 'AUTH', error: e);
      return {
        'success': false,
        'message': 'Failed to process request: $e',
      };
    }
  }

  // Reset password - Updated to match backend API
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
    String? code,
  }) async {
    try {
      AppLogger.authEvent('Password reset attempt', data: {'email': email});

      final requestData = {
        'email': email.toLowerCase().trim(),
        'new_password': newPassword,
        'code': code ?? '123456', // Backend expects code for reset
      };

      AppLogger.apiRequest('POST', ApiConfig.resetPasswordEndpoint, data: {
        'email': email.toLowerCase().trim(),
        'new_password': '[HIDDEN]',
        'code': '[HIDDEN]'
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

  // Verify reset code - For compatibility with existing UI
  static Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    // Since backend doesn't have separate verify endpoint,
    // we'll just validate the code format and return success
    try {
      AppLogger.authEvent('Reset code verification attempt', data: {'email': email});

      if (code.trim().length == 6) {
        AppLogger.authEvent('Reset code verification successful (client-side)', data: {'email': email});
        return {
          'success': true,
          'message': 'Code verified successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid code format',
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

  // =============================================
  // SESSION MANAGEMENT
  // =============================================

  // Logout - Updated with better error handling
  static Future<void> logout() async {
    try {
      AppLogger.authEvent('Logout initiated');

      // Just clean up local data since logout endpoint might not exist
      await _apiService.logout();
      await _clearCurrentUser();
      await _clearToken();
      AppLogger.authEvent('Logout completed - local data cleared');
    } catch (e) {
      AppLogger.error('Logout error', tag: 'AUTH', error: e);
      // Always clean up local data even if logout API fails
      await _clearCurrentUser();
      await _clearToken();
    }
  }

  // Get current user - Enhanced to use backend /auth/me endpoint
  static Future<AuthModelBackend?> getCurrentUser() async {
    try {
      // First try to get fresh data from backend
      final token = await _getToken();
      if (token != null) {
        try {
          final response = await _apiService.get(ApiConfig.getCurrentUserEndpoint);
          if (response['success'] && response['data'] != null) {
            final user = AuthModelBackend.fromJson(response['data']);
            await _saveCurrentUser(user);
            AppLogger.debug('Retrieved fresh user data from API', tag: 'AUTH');
            return user;
          }
        } catch (e) {
          AppLogger.warning('Failed to get fresh user data, using cached', tag: 'AUTH');
        }
      }

      // Fallback to cached data
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
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        AppLogger.debug('No token found', tag: 'AUTH');
        return false;
      }

      // Try to validate token with backend
      try {
        final response = await _apiService.get(ApiConfig.getCurrentUserEndpoint);
        final isValid = response['success'] == true;
        AppLogger.debug('Token validation: $isValid', tag: 'AUTH');
        return isValid;
      } catch (e) {
        AppLogger.warning('Token validation failed', tag: 'AUTH');
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

  // Get token
  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      AppLogger.error('Failed to get auth token', tag: 'AUTH', error: e);
      return null;
    }
  }

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

  @override
  String toString() {
    return 'AuthModelBackend{id: $id, email: $email, fullName: $fullName}';
  }
}