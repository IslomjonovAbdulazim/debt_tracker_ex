import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_logger.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // 🔐 Token management
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      AppLogger.debug('Retrieved auth token: ${token != null ? 'EXISTS' : 'NULL'}', tag: 'AUTH');
      return token;
    } catch (e) {
      AppLogger.error('Failed to get auth token', tag: 'AUTH', error: e);
      return null;
    }
  }

  Future<void> _saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      AppLogger.info('Auth token saved successfully', tag: 'AUTH');
    } catch (e) {
      AppLogger.error('Failed to save auth token', tag: 'AUTH', error: e);
    }
  }

  Future<void> _removeAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      AppLogger.info('Auth token removed successfully', tag: 'AUTH');
    } catch (e) {
      AppLogger.error('Failed to remove auth token', tag: 'AUTH', error: e);
    }
  }

  // 🔄 Retry mechanism for network failures
  Future<http.Response> _makeRequest(Future<http.Response> Function() request, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final stopwatch = Stopwatch()..start();
        final response = await request();
        stopwatch.stop();

        AppLogger.performance('HTTP Request', stopwatch.elapsed);
        return response;
      } catch (e) {
        attempts++;
        AppLogger.warning('Request attempt $attempts failed: $e', tag: 'API');

        if (attempts >= maxRetries || e is! SocketException) {
          AppLogger.error('Max retries exceeded or non-recoverable error', tag: 'API', error: e);
          rethrow;
        }

        // Wait before retry (exponential backoff)
        final delay = Duration(seconds: attempts * 2);
        AppLogger.info('Retrying in ${delay.inSeconds} seconds...', tag: 'API');
        await Future.delayed(delay);
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
        } else {
          AppLogger.warning('No auth token available for authenticated request', tag: 'API');
        }
      }

      AppLogger.apiRequest('GET', url.toString());

      final response = await _makeRequest(() =>
          http.get(url, headers: headers).timeout(ApiConfig.requestTimeout)
      );

      final result = _handleResponse(response);
      AppLogger.apiResponse('GET', url.toString(), response.statusCode, response: result);
      return result;
    } catch (e, stackTrace) {
      AppLogger.apiError('GET', endpoint, e, stackTrace: stackTrace);
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
        } else {
          AppLogger.warning('No auth token available for authenticated request', tag: 'API');
        }
      }

      AppLogger.apiRequest('POST', url.toString(), data: data);

      final response = await _makeRequest(() =>
          http.post(
            url,
            headers: headers,
            body: jsonEncode(data),
          ).timeout(ApiConfig.requestTimeout)
      );

      final result = _handleResponse(response);
      AppLogger.apiResponse('POST', url.toString(), response.statusCode, response: result);
      return result;
    } catch (e, stackTrace) {
      AppLogger.apiError('POST', endpoint, e, stackTrace: stackTrace);
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
        } else {
          AppLogger.warning('No auth token available for authenticated request', tag: 'API');
        }
      }

      AppLogger.apiRequest('PUT', url.toString(), data: data);

      final response = await _makeRequest(() =>
          http.put(
            url,
            headers: headers,
            body: jsonEncode(data),
          ).timeout(ApiConfig.requestTimeout)
      );

      final result = _handleResponse(response);
      AppLogger.apiResponse('PUT', url.toString(), response.statusCode, response: result);
      return result;
    } catch (e, stackTrace) {
      AppLogger.apiError('PUT', endpoint, e, stackTrace: stackTrace);
      return _handleError(e);
    }
  }

  // 🔄 PATCH request (for mark as paid functionality)
  Future<Map<String, dynamic>> patch(
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
        } else {
          AppLogger.warning('No auth token available for authenticated request', tag: 'API');
        }
      }

      AppLogger.apiRequest('PATCH', url.toString(), data: data);

      final response = await _makeRequest(() =>
          http.patch(
            url,
            headers: headers,
            body: jsonEncode(data),
          ).timeout(ApiConfig.requestTimeout)
      );

      final result = _handleResponse(response);
      AppLogger.apiResponse('PATCH', url.toString(), response.statusCode, response: result);
      return result;
    } catch (e, stackTrace) {
      AppLogger.apiError('PATCH', endpoint, e, stackTrace: stackTrace);
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
        } else {
          AppLogger.warning('No auth token available for authenticated request', tag: 'API');
        }
      }

      AppLogger.apiRequest('DELETE', url.toString());

      final response = await _makeRequest(() =>
          http.delete(url, headers: headers).timeout(ApiConfig.requestTimeout)
      );

      final result = _handleResponse(response);
      AppLogger.apiResponse('DELETE', url.toString(), response.statusCode, response: result);
      return result;
    } catch (e, stackTrace) {
      AppLogger.apiError('DELETE', endpoint, e, stackTrace: stackTrace);
      return _handleError(e);
    }
  }

  // 🔧 Response handler - Updated to handle new backend response structure
  Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> responseData;

    try {
      responseData = jsonDecode(response.body);
      AppLogger.debug('Response body parsed successfully', tag: 'API');
    } catch (e) {
      AppLogger.error('Failed to parse response body', tag: 'API', error: e);
      return {
        'success': false,
        'message': 'Invalid response format from server',
        'statusCode': response.statusCode,
      };
    }

    // Save token if present in the new structure
    if (responseData.containsKey('data') &&
        responseData['data'] is Map &&
        responseData['data'].containsKey('access_token')) {
      final token = responseData['data']['access_token'];
      if (token != null) {
        AppLogger.info('New token received in response', tag: 'AUTH');
        _saveAuthToken(token);
      }
    }

    // Handle different status codes
    switch (response.statusCode) {
      case 200:
      case 201:
        AppLogger.info('Successful response: ${response.statusCode}', tag: 'API');
        // Backend always returns success field, so use that
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? 'Success',
          'data': responseData['data'],
          'timestamp': responseData['timestamp'],
        };
      case 401:
        AppLogger.warning('Unauthorized response - removing token', tag: 'API');
        _removeAuthToken(); // Remove invalid token
        return {
          'success': false,
          'message': responseData['message'] ?? 'Session expired. Please login again.',
          'statusCode': response.statusCode,
          'needsLogin': true,
        };
      case 422:
        AppLogger.warning('Validation error response', tag: 'API');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Validation error',
          'errors': responseData['errors'] ?? [],
          'statusCode': response.statusCode,
        };
      case 429:
        AppLogger.warning('Rate limit exceeded', tag: 'API');
        return {
          'success': false,
          'message': 'Too many requests. Please try again later.',
          'statusCode': response.statusCode,
        };
      case 500:
        AppLogger.error('Server error response', tag: 'API');
        return {
          'success': false,
          'message': 'Server error. Please try again later.',
          'statusCode': response.statusCode,
        };
      default:
        AppLogger.warning('Unhandled status code: ${response.statusCode}', tag: 'API');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Request failed',
          'statusCode': response.statusCode,
        };
    }
  }

  // ❌ Error handler
  Map<String, dynamic> _handleError(dynamic error) {
    AppLogger.error('API Error occurred', tag: 'API', error: error);

    if (error is SocketException) {
      AppLogger.network('No internet connection');
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
        'isNetworkError': true,
      };
    }

    if (error is HttpException) {
      AppLogger.network('HTTP exception occurred');
      return {
        'success': false,
        'message': 'Network error occurred. Please try again.',
        'isNetworkError': true,
      };
    }

    if (error.toString().contains('TimeoutException')) {
      AppLogger.warning('Request timeout', tag: 'API');
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
    AppLogger.authEvent('User logout initiated');
    await _removeAuthToken();
    AppLogger.authEvent('User logout completed');
  }

  // 🔍 Connection test
  Future<bool> testConnection() async {
    try {
      AppLogger.info('Testing API connection...', tag: 'API');
      final response = await get('/health', requiresAuth: false);
      final isConnected = response['success'] == true;
      AppLogger.network(isConnected ? 'API connection successful' : 'API connection failed');
      return isConnected;
    } catch (e) {
      AppLogger.network('API connection test failed');
      return false;
    }
  }
}