import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // 🔐 Token management
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _removeAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // 📝 Logging helper
  void _logRequest(String method, String url, Map<String, dynamic>? data) {
    if (ApiConfig.enableApiLogging) {
      print('🌐 API $method: $url');
      if (data != null) print('📤 Data: ${jsonEncode(data)}');
    }
  }

  void _logResponse(String method, String url, int statusCode, Map<String, dynamic> response) {
    if (ApiConfig.enableApiLogging) {
      print('📨 API $method Response: $statusCode for $url');
      print('📥 Data: ${jsonEncode(response)}');
    }
  }

  // 🔄 Retry mechanism for network failures
  Future<http.Response> _makeRequest(Future<http.Response> Function() request, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries || e is! SocketException) rethrow;

        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw Exception('Max retries exceeded');
  }

  // 📥 GET request
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

      _logRequest('GET', url.toString(), null);

      final response = await _makeRequest(() =>
          http.get(url, headers: headers).timeout(ApiConfig.requestTimeout)
      );

      final result = _handleResponse(response);
      _logResponse('GET', url.toString(), response.statusCode, result);
      return result;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 📤 POST request
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

      _logRequest('POST', url.toString(), data);

      final response = await _makeRequest(() =>
          http.post(
            url,
            headers: headers,
            body: jsonEncode(data),
          ).timeout(ApiConfig.requestTimeout)
      );

      final result = _handleResponse(response);
      _logResponse('POST', url.toString(), response.statusCode, result);
      return result;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 🔄 PUT request
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

      _logRequest('PUT', url.toString(), data);

      final response = await _makeRequest(() =>
          http.put(
            url,
            headers: headers,
            body: jsonEncode(data),
          ).timeout(ApiConfig.requestTimeout)
      );

      final result = _handleResponse(response);
      _logResponse('PUT', url.toString(), response.statusCode, result);
      return result;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 🗑️ DELETE request
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

      _logRequest('DELETE', url.toString(), null);

      final response = await _makeRequest(() =>
          http.delete(url, headers: headers).timeout(ApiConfig.requestTimeout)
      );

      final result = _handleResponse(response);
      _logResponse('DELETE', url.toString(), response.statusCode, result);
      return result;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 🔧 Response handler
  Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> responseData;

    try {
      responseData = jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid response format from server',
        'statusCode': response.statusCode,
      };
    }

    // Save token if present
    if (responseData.containsKey('token') ||
        (responseData.containsKey('data') && responseData['data']?.containsKey('token'))) {
      final token = responseData['token'] ?? responseData['data']['token'];
      if (token != null) _saveAuthToken(token);
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
          'message': responseData['message'] ?? 'Session expired. Please login again.',
          'statusCode': response.statusCode,
          'needsLogin': true,
        };
      case 422:
        return {
          'success': false,
          'message': responseData['message'] ?? 'Validation error',
          'errors': responseData['errors'] ?? {},
          'statusCode': response.statusCode,
        };
      case 429:
        return {
          'success': false,
          'message': 'Too many requests. Please try again later.',
          'statusCode': response.statusCode,
        };
      case 500:
        return {
          'success': false,
          'message': 'Server error. Please try again later.',
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

  // ❌ Error handler
  Map<String, dynamic> _handleError(dynamic error) {
    print('❌ API Error: $error');

    if (error is SocketException) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
        'isNetworkError': true,
      };
    }

    if (error is HttpException) {
      return {
        'success': false,
        'message': 'Network error occurred. Please try again.',
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
      'message': 'An unexpected error occurred: ${error.toString()}',
    };
  }

  // 🚪 Logout helper
  Future<void> logout() async {
    await _removeAuthToken();
  }

  // 🔍 Connection test
  Future<bool> testConnection() async {
    try {
      final response = await get('/health', requiresAuth: false);
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}