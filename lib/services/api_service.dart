// lib/services/api_service.dart
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

  // =============================================
  // TOKEN MANAGEMENT - Enhanced for refresh tokens
  // =============================================

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      AppLogger.debug('Retrieved access token: ${token != null ? 'EXISTS' : 'NULL'}', tag: 'AUTH');
      return token;
    } catch (e) {
      AppLogger.error('Failed to get access token', tag: 'AUTH', error: e);
      return null;
    }
  }

  Future<String?> _getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('refresh_token');
      AppLogger.debug('Retrieved refresh token: ${token != null ? 'EXISTS' : 'NULL'}', tag: 'AUTH');
      return token;
    } catch (e) {
      AppLogger.error('Failed to get refresh token', tag: 'AUTH', error: e);
      return null;
    }
  }

  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      if (refreshToken != null) {
        await prefs.setString('refresh_token', refreshToken);
      }
      AppLogger.info('Tokens saved successfully', tag: 'AUTH');
    } catch (e) {
      AppLogger.error('Failed to save tokens', tag: 'AUTH', error: e);
    }
  }

  // FIXED: Handle token saving from different response formats
  Future<void> _saveTokensFromResponse(Map<String, dynamic> responseData) async {
    try {
      String? accessToken;
      String? refreshToken;

      // Format 1: Tokens directly in response (login response)
      if (responseData.containsKey('access') && responseData.containsKey('refresh')) {
        accessToken = responseData['access'];
        refreshToken = responseData['refresh'];
        AppLogger.info('Found tokens in direct response format', tag: 'AUTH');
      }
      // Format 2: Tokens in data object
      else if (responseData.containsKey('data') && responseData['data'] is Map) {
        final data = responseData['data'] as Map<String, dynamic>;
        if (data.containsKey('access')) {
          accessToken = data['access'];
          refreshToken = data['refresh'];
          AppLogger.info('Found tokens in data object format', tag: 'AUTH');
        }
        // Format 3: Tokens in nested structure
        if (data.containsKey('tokens') && data['tokens'] is Map) {
          final tokens = data['tokens'] as Map<String, dynamic>;
          accessToken = tokens['access'];
          refreshToken = tokens['refresh'];
          AppLogger.info('Found tokens in nested tokens object', tag: 'AUTH');
        }
      }

      // Save tokens if found
      if (accessToken != null) {
        AppLogger.info('Saving new tokens to storage', tag: 'AUTH');
        await _saveTokens(accessToken, refreshToken);
      }
    } catch (e) {
      AppLogger.error('Error parsing tokens from response', tag: 'AUTH', error: e);
    }
  }

  Future<void> _removeTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      AppLogger.info('Tokens removed successfully', tag: 'AUTH');
    } catch (e) {
      AppLogger.error('Failed to remove tokens', tag: 'AUTH', error: e);
    }
  }

  // =============================================
  // TOKEN REFRESH LOGIC
  // =============================================

  Future<bool> _refreshTokenIfNeeded() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        AppLogger.warning('No refresh token available', tag: 'AUTH');
        return false;
      }

      AppLogger.info('Attempting to refresh access token', tag: 'AUTH');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshTokenEndpoint}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({'refresh': refreshToken}),
      ).timeout(ApiConfig.requestTimeout);

      final result = await _handleResponse(response);

      if (result['success'] == true) {
        AppLogger.info('Token refresh successful', tag: 'AUTH');
        return true;
      } else {
        AppLogger.warning('Token refresh failed: ${result['message']}', tag: 'AUTH');
        await _removeTokens();
        return false;
      }
    } catch (e) {
      AppLogger.error('Token refresh error', tag: 'AUTH', error: e);
      await _removeTokens();
      return false;
    }
  }

  // =============================================
  // RETRY MECHANISM
  // =============================================

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

        // Exponential backoff
        final delay = Duration(seconds: attempts * 2);
        AppLogger.info('Retrying in ${delay.inSeconds} seconds...', tag: 'API');
        await Future.delayed(delay);
      }
    }
    throw Exception('Max retries exceeded');
  }

  // =============================================
  // HTTP METHODS - Enhanced with auto-retry and token refresh
  // =============================================

  Future<Map<String, dynamic>> get(String endpoint, {bool requiresAuth = true}) async {
    return _requestWithAuth(() async {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
        } else {
          return {
            'success': false,
            'message': 'No authentication token available',
            'needsLogin': true,
          };
        }
      }

      AppLogger.apiRequest('GET', url.toString());

      final response = await _makeRequest(() =>
          http.get(url, headers: headers).timeout(ApiConfig.requestTimeout)
      );

      return await _handleResponse(response);
    }, endpoint, requiresAuth);
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, {bool requiresAuth = true}) async {
    return _requestWithAuth(() async {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
        } else {
          return {
            'success': false,
            'message': 'No authentication token available',
            'needsLogin': true,
          };
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

      return await _handleResponse(response);
    }, endpoint, requiresAuth);
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data, {bool requiresAuth = true}) async {
    return _requestWithAuth(() async {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
        } else {
          return {
            'success': false,
            'message': 'No authentication token available',
            'needsLogin': true,
          };
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

      return await _handleResponse(response);
    }, endpoint, requiresAuth);
  }

  Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> data, {bool requiresAuth = true}) async {
    return _requestWithAuth(() async {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
        } else {
          return {
            'success': false,
            'message': 'No authentication token available',
            'needsLogin': true,
          };
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

      return await _handleResponse(response);
    }, endpoint, requiresAuth);
  }

  Future<Map<String, dynamic>> delete(String endpoint, {bool requiresAuth = true}) async {
    return _requestWithAuth(() async {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      Map<String, String> headers = ApiConfig.defaultHeaders;

      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
        } else {
          return {
            'success': false,
            'message': 'No authentication token available',
            'needsLogin': true,
          };
        }
      }

      AppLogger.apiRequest('DELETE', url.toString());

      final response = await _makeRequest(() =>
          http.delete(url, headers: headers).timeout(ApiConfig.requestTimeout)
      );

      return await _handleResponse(response);
    }, endpoint, requiresAuth);
  }

  // =============================================
  // REQUEST WITH AUTH AND AUTO-RETRY
  // =============================================

  Future<Map<String, dynamic>> _requestWithAuth(
      Future<Map<String, dynamic>> Function() request,
      String endpoint,
      bool requiresAuth,
      ) async {
    try {
      final result = await request();

      // If we get a 401 and we have auth enabled, try to refresh token
      if (result['statusCode'] == 401 && requiresAuth) {
        AppLogger.info('Got 401, attempting token refresh', tag: 'API');

        final refreshSuccess = await _refreshTokenIfNeeded();
        if (refreshSuccess) {
          AppLogger.info('Token refreshed, retrying request', tag: 'API');
          return await request(); // Retry with new token
        } else {
          AppLogger.warning('Token refresh failed, user needs to login', tag: 'API');
          return {
            'success': false,
            'message': 'Session expired. Please login again.',
            'needsLogin': true,
            'statusCode': 401,
          };
        }
      }

      return result;
    } catch (e) {
      AppLogger.error('Request with auth error', tag: 'API', error: e);
      return _handleError(e);
    }
  }

  // =============================================
  // RESPONSE HANDLER - Fixed for new API format
  // =============================================

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
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

    // FIXED: Save tokens if present - handle multiple formats
    await _saveTokensFromResponse(responseData);

    AppLogger.apiResponse('REQUEST', 'response', response.statusCode, response: responseData);

    // Enhanced status code handling with better response parsing
    switch (response.statusCode) {
      case 200:
      case 201:
      // FIXED: Better success handling for different API response formats
        bool isSuccess = responseData['success'] ??
            (response.statusCode >= 200 && response.statusCode < 300);

        return {
          'success': isSuccess,
          'message': responseData['message'] ?? 'Success',
          'data': responseData['data'] ?? responseData,
          'statusCode': response.statusCode,
        };

      case 400:
        return {
          'success': false,
          'message': responseData['message'] ?? 'Bad request',
          'errors': responseData['errors'] ?? responseData['error'] ?? [],
          'statusCode': response.statusCode,
        };

      case 401:
        AppLogger.warning('Unauthorized response', tag: 'API');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Session expired. Please login again.',
          'statusCode': response.statusCode,
          'needsLogin': true,
        };

      case 403:
        return {
          'success': false,
          'message': responseData['message'] ?? 'Access forbidden',
          'statusCode': response.statusCode,
          'needsVerification': responseData['message']?.toLowerCase().contains('not verified') ?? false,
        };

      case 404:
        return {
          'success': false,
          'message': responseData['message'] ?? 'Resource not found',
          'statusCode': response.statusCode,
        };

      case 422:
        return {
          'success': false,
          'message': responseData['message'] ?? 'Validation error',
          'errors': responseData['errors'] ?? responseData['error'] ?? [],
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

  // =============================================
  // ERROR HANDLER
  // =============================================

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

  // =============================================
  // UTILITY METHODS
  // =============================================

  Future<void> logout() async {
    AppLogger.authEvent('User logout initiated');
    await _removeTokens();
    AppLogger.authEvent('User logout completed');
  }

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

  // Enhanced token status check
  Future<Map<String, dynamic>> checkTokenStatus() async {
    try {
      final accessToken = await _getAuthToken();
      final refreshToken = await _getRefreshToken();

      if (accessToken == null) {
        return {
          'hasToken': false,
          'message': 'No access token found',
        };
      }

      AppLogger.debug('Current access token: ${accessToken.substring(0, 20)}...', tag: 'AUTH');

      // Test token with /me endpoint
      final response = await get('/api/v1/apps/me', requiresAuth: true);

      return {
        'hasToken': true,
        'hasRefreshToken': refreshToken != null,
        'tokenValid': response['success'] == true,
        'accessTokenPreview': '${accessToken.substring(0, 20)}...',
        'testResponse': response,
      };
    } catch (e) {
      return {
        'hasToken': false,
        'error': e.toString(),
      };
    }
  }
}