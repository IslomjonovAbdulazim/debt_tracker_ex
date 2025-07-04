// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  // Simple singleton pattern for teaching
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Token management - simplified
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
  }

  Future<void> _removeTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // Helper method to handle tokens from response
  void _handleTokensFromResponse(Map<String, dynamic> responseData) {
    // Check for tokens in different response formats
    String? accessToken;
    String? refreshToken;

    if (responseData.containsKey('access') && responseData.containsKey('refresh')) {
      accessToken = responseData['access'];
      refreshToken = responseData['refresh'];
    } else if (responseData.containsKey('data') && responseData['data'] is Map) {
      final data = responseData['data'] as Map<String, dynamic>;
      if (data.containsKey('access')) {
        accessToken = data['access'];
        refreshToken = data['refresh'];
      }
    }

    if (accessToken != null) {
      _saveTokens(accessToken, refreshToken);
    }
  }

  // Basic HTTP Methods - Simplified for teaching
  Future<Map<String, dynamic>> get(String endpoint, {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
        } else {
          return {'success': false, 'message': 'No authentication token'};
        }
      }

      final response = await http.get(url, headers: headers).timeout(ApiConfig.requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
        } else {
          return {'success': false, 'message': 'No authentication token'};
        }
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // NEW: PUT method for updates
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data, {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
        } else {
          return {'success': false, 'message': 'No authentication token'};
        }
      }

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // NEW: PATCH method for partial updates
  Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> data, {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
        } else {
          return {'success': false, 'message': 'No authentication token'};
        }
      }

      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint, {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
        } else {
          return {'success': false, 'message': 'No authentication token'};
        }
      }

      final response = await http.delete(url, headers: headers).timeout(ApiConfig.requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // FIXED: Response handler to handle both objects and arrays
  Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic responseData;

    try {
      responseData = jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid response format',
        'statusCode': response.statusCode,
      };
    }

    // FIXED: Handle raw array responses (like contacts endpoint)
    if (responseData is List && response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'message': 'Success',
        'data': responseData, // Wrap array in data field
        'statusCode': response.statusCode,
      };
    }

    // Handle object responses
    if (responseData is Map<String, dynamic>) {
      // Handle tokens if present
      _handleTokensFromResponse(responseData);

      // Simplified status code handling
      switch (response.statusCode) {
        case 200:
        case 201:
        case 204: // Added 204 for successful DELETE operations
          return {
            'success': true,
            'message': responseData['message'] ?? 'Success',
            'data': responseData['data'] ?? responseData,
            'code': responseData['code'], // ADDED: Handle verification code
            'statusCode': response.statusCode,
          };

        case 400:
          return {
            'success': false,
            'message': responseData['message'] ?? 'Bad request',
            'errors': responseData['errors'] ?? {},
            'statusCode': response.statusCode,
          };

        case 401:
          return {
            'success': false,
            'message': responseData['message'] ?? 'Unauthorized',
            'statusCode': response.statusCode,
            'needsLogin': true,
          };

        case 404:
          return {
            'success': false,
            'message': responseData['message'] ?? 'Not found',
            'statusCode': response.statusCode,
          };

        default:
          return {
            'success': false,
            'message': responseData['message'] ?? 'Request failed',
            'statusCode': response.statusCode,
          };
      }
    }

    // Fallback for unexpected response types
    return {
      'success': false,
      'message': 'Unexpected response format',
      'statusCode': response.statusCode,
    };
  }

  // Error handler - simplified
  Map<String, dynamic> _handleError(dynamic error) {
    if (error is SocketException) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
        'isNetworkError': true,
      };
    }

    if (error.toString().contains('TimeoutException')) {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'isTimeoutError': true,
      };
    }

    return {
      'success': false,
      'message': 'An error occurred: ${error.toString()}',
    };
  }

  // Utility methods
  Future<void> logout() async {
    await _removeTokens();
  }

  Future<bool> hasToken() async {
    final token = await _getAuthToken();
    return token != null;
  }
}