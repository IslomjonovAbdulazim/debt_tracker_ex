// lib/config/api_config.dart
class ApiConfig {
  // Base URL configuration - Updated to match backend docs
  static const String baseUrl = 'https://islomjonovabdulazim-debt-tracker-backend-519e.twc1.net';

  // API versioning
  static const String apiVersion = '2.0.0';

  // Environment flags
  static bool get isProduction => baseUrl.contains('https://');
  static bool get isDevelopment => !isProduction;
  static bool get enableApiLogging => isDevelopment;

  // Request configuration
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Authentication endpoints - Updated to match backend docs
  static const String registerEndpoint = '/auth/register';
  static const String verifyEmailEndpoint = '/auth/verify-email';
  static const String loginEndpoint = '/auth/login';
  static const String getCurrentUserEndpoint = '/auth/me';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String resendCodeEndpoint = '/auth/resend-code';
  static const String logoutEndpoint = '/auth/logout'; // Not in docs but kept for compatibility

  // Contact endpoints - Updated to match backend docs
  static const String contactsEndpoint = '/contacts';
  static const String createContactEndpoint = '/contacts';
  static String getContactEndpoint(String id) => '/contacts/$id';
  static String updateContactEndpoint(String id) => '/contacts/$id';
  static String deleteContactEndpoint = '/contacts'; // Updated: no ID in base, will append

  // Debt endpoints - Updated to match backend docs
  static const String debtsEndpoint = '/debts';
  static const String createDebtEndpoint = '/debts';
  static const String homeOverviewEndpoint = '/debts/overview'; // Updated endpoint name
  static String getDebtEndpoint(String id) => '/debts/$id';
  static String updateDebtEndpoint(String id) => '/debts/$id';
  static String deleteDebtEndpoint(String id) => '/debts/$id';
  static String markDebtPaidEndpoint(String id) => '/debts/$id/pay';

  // Removed non-existent endpoints from original config
  // These were not mentioned in the backend docs:
  // - contactDebtsEndpoint
  // - verifyResetCodeEndpoint

  // Health check endpoints
  static const String healthEndpoint = '/health';
  static const String rootEndpoint = '/';

  // Headers configuration
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  // Query parameters helper
  static String buildQueryString(Map<String, dynamic> params) {
    final queryParams = params.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    return queryParams.isNotEmpty ? '?$queryParams' : '';
  }
}