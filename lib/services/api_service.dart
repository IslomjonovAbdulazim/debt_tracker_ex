import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get stored auth token
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Save auth token
  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Remove auth token
  Future<void> _removeAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // GET request
  Future<Map<String, dynamic>> get(String endpoint, {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
        }
      }

      final response = await http.get(url, headers: headers)
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> data, {
        bool requiresAuth = true
      }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
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

  // PUT request
  Future<Map<String, dynamic>> put(
      String endpoint,
      Map<String, dynamic> data, {
        bool requiresAuth = true
      }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
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

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint, {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
        }
      }

      final response = await http.delete(url, headers: headers)
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> responseData;

    try {
      responseData = jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid response format',
        'statusCode': response.statusCode,
      };
    }

    // Save token if present in response
    if (responseData.containsKey('token')) {
      _saveAuthToken(responseData['token']);
    }

    // Handle different status codes
    switch (response.statusCode) {
      case 200:
      case 201:
        return {
          'success': true,
          ...responseData,
        };
      case 401:
        _removeAuthToken(); // Remove invalid token
        return {
          'success': false,
          'message': responseData['message'] ?? 'Unauthorized',
          'statusCode': response.statusCode,
        };
      case 422:
        return {
          'success': false,
          'message': responseData['message'] ?? 'Validation error',
          'errors': responseData['errors'] ?? {},
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

  // Handle request errors
  Map<String, dynamic> _handleError(dynamic error) {
    print('API Error: $error');

    if (error is SocketException) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    if (error is HttpException) {
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }

    return {
      'success': false,
      'message': 'Request failed: ${error.toString()}',
    };
  }

  // Logout helper
  Future<void> logout() async {
    await _removeAuthToken();
  }
}