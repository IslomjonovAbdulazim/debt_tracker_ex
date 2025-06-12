// lib/config/api_config.dart
class ApiConfig {
  // FIXED: Base URL configuration - Use your actual backend URL
  static const String baseUrl = 'http://10.10.2.188:8000';

  // FIXED: Authentication endpoints matching backend routes exactly
  static const String registerEndpoint = '/api/auth/register';
  static const String verifyEmailEndpoint = '/api/auth/verify-email';
  static const String loginEndpoint = '/api/auth/login';
  static const String getCurrentUserEndpoint = '/api/auth/me';
  static const String forgotPasswordEndpoint = '/api/auth/forgot-password';
  static const String resetPasswordEndpoint = '/api/auth/reset-password';
  static const String resendCodeEndpoint = '/api/auth/resend';

  // FIXED: Contact endpoints with exact API paths
  static const String contactsEndpoint = '/api/contact-create';
  static String getContactEndpoint(String id) => '/api/contact-update/$id';
  static String updateContactEndpoint(String id) => '/api/contact-update/$id';
  static String deleteContactEndpoint(String id) => '/api/contact-delete/$id';

  // FIXED: Debt endpoints (assuming similar pattern)
  static const String debtsEndpoint = '/api/debts/';
  static const String homeOverviewEndpoint = '/api/debts/overview/';
  static String getDebtEndpoint(String id) => '/api/debts/$id/';
  static String updateDebtEndpoint(String id) => '/api/debts/$id/';
  static String deleteDebtEndpoint(String id) => '/api/debts/$id/';
  static String markDebtPaidEndpoint(String id) => '/api/debts/$id/pay/';

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