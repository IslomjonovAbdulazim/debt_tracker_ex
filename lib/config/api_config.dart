// lib/config/api_config.dart
class ApiConfig {
  // Base URL configuration
  static const String baseUrl = 'http://10.10.2.210';

  // FIXED: Authentication endpoints matching documentation exactly
  static const String registerEndpoint = '/register';
  static const String verifyEmailEndpoint = '/verify-email';
  static const String loginEndpoint = '/login';
  static const String forgotPasswordEndpoint = '/forgot-password';
  static const String resetPasswordEndpoint = '/reset-password';
  static const String resendCodeEndpoint = '/resend'; // Not in docs, keeping for app functionality

  // FIXED: Contact endpoints matching documentation
  static const String contactsEndpoint = '/contacts'; // GET all contacts
  static const String createContactEndpoint = '/contact'; // POST create contact
  static String getContactEndpoint(String id) => '/contact/$id';
  static String updateContactEndpoint(String id) => '/contact/$id';
  static String deleteContactEndpoint(String id) => '/contact/$id';

  // FIXED: Contact debt endpoints from documentation
  static String getContactDebtsEndpoint(String contactId) => '/contact-debts/$contactId';
  static const String createContactDebtEndpoint = '/contact-debt';

  // FIXED: Home endpoint matching documentation
  static const String homeOverviewEndpoint = '/home/overview';

  // FIXED: Debt endpoints matching documentation
  static const String debtsEndpoint = '/debts';
  static String getDebtEndpoint(String id) => '/debt/$id'; // Assuming pattern
  static String updateDebtEndpoint(String id) => '/debt/$id'; // Assuming pattern
  static String deleteDebtEndpoint(String id) => '/debt/$id'; // Assuming pattern
  static String markDebtPaidEndpoint(String id) => '/debt/$id/pay'; // Assuming pattern

  // User profile endpoint (not in docs but needed for auth check)
  static const String getCurrentUserEndpoint = '/me'; // Assuming simple path

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