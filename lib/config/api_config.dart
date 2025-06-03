// lib/config/api_config.dart
class ApiConfig {
  // FIXED: Base URL configuration - Use your actual backend URL
  static const String baseUrl = 'https://islomjonovabdulazim-debt-tracker-backend-519e.twc1.net';

  // FIXED: Authentication endpoints matching backend routes
  static const String registerEndpoint = '/auth/register';
  static const String verifyEmailEndpoint = '/auth/verify-email';
  static const String loginEndpoint = '/auth/login';
  static const String getCurrentUserEndpoint = '/auth/me';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String resendCodeEndpoint = '/auth/resend-code';

  // FIXED: Contact endpoints with trailing slashes to avoid redirects
  static const String contactsEndpoint = '/contacts/';
  static String getContactEndpoint(String id) => '/contacts/$id/';
  static String updateContactEndpoint(String id) => '/contacts/$id/';
  static String deleteContactEndpoint(String id) => '/contacts/$id/';

  // FIXED: Debt endpoints with trailing slashes to avoid redirects
  static const String debtsEndpoint = '/debts/';
  static const String homeOverviewEndpoint = '/debts/overview/';
  static String getDebtEndpoint(String id) => '/debts/$id/';
  static String updateDebtEndpoint(String id) => '/debts/$id/';
  static String deleteDebtEndpoint(String id) => '/debts/$id/';
  static String markDebtPaidEndpoint(String id) => '/debts/$id/pay/';

  // Request configuration
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Headers configuration - FIXED for JWT
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token', // FIXED: Proper Bearer token format
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