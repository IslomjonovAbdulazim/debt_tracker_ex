// lib/config/api_config.dart
class ApiConfig {
  // Base URL configuration
  static const String baseUrl = 'http://10.10.1.123:8000';

  // FIXED: Authentication endpoints matching API documentation exactly
  static const String registerEndpoint = '/api/v1/auth/register';
  static const String verifyEmailEndpoint = '/api/v1/auth/register/verify/otp';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String forgotPasswordEndpoint = '/api/v1/auth/forgot-password';
  static const String verifyOtpEndpoint = '/api/v1/auth/forgot-password/otp';
  static const String changePasswordEndpoint = '/api/v1/auth/forgot/change-password';
  static const String refreshTokenEndpoint = '/api/v1/auth/token/refresh';
  static const String resendCodeEndpoint = '/api/v1/auth/resend';

  // FIXED: Contact endpoints matching documentation exactly
  static const String contactsEndpoint = '/api/v1/apps/contact/list'; // GET all contacts
  static const String createContactEndpoint = '/api/v1/apps/contact'; // POST create contact
  static String getContactEndpoint(String id) => '/api/v1/apps/contact/$id';
  static String updateContactEndpoint(String id) => '/api/v1/apps/contact/$id';
  static String deleteContactEndpoint(String id) => '/api/v1/apps/contact/$id';

  // FIXED: Contact debt endpoints from documentation
  static String getContactDebtsEndpoint(String contactId) => '/api/v1/apps/contact-debts/$contactId';
  static String createContactDebtEndpoint(String contactId) => '/api/v1/apps/contact-debt/$contactId';

  // FIXED: Home endpoint matching documentation exactly
  static const String homeOverviewEndpoint = '/api/v1/apps/home/overview';

  // FIXED: Debt endpoints matching documentation
  static const String debtsEndpoint = '/api/v1/apps/debts';
  static String getDebtEndpoint(String id) => '/api/v1/apps/debt/$id';
  static String updateDebtEndpoint(String id) => '/api/v1/apps/debt/$id';
  static String deleteDebtEndpoint(String id) => '/api/v1/apps/debt/$id';
  static String markDebtPaidEndpoint(String id) => '/api/v1/apps/debt/$id/pay';

  // User profile endpoint
  static const String getCurrentUserEndpoint = '/api/v1/apps/me';

  // Request configuration
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

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