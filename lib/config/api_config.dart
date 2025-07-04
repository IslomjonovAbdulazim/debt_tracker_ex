// lib/config/api_config.dart
class ApiConfig {
  // UPDATED: New base URL
  static const String baseUrl = 'http://10.10.1.239:8000/';

  // Authentication endpoints
  static const String registerEndpoint = '/api/v1/auth/register';
  static const String verifyEmailEndpoint = '/api/v1/auth/register/verify/otp';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String forgotPasswordEndpoint = '/api/v1/auth/forgot-password';
  static const String verifyOtpEndpoint = '/api/v1/auth/forgot-password/otp';
  static const String changePasswordEndpoint = '/api/v1/auth/forgot/change-password';
  static const String refreshTokenEndpoint = '/api/v1/auth/token/refresh';
  static const String resendCodeEndpoint = '/api/v1/auth/resend';

  // Contact endpoints - Simplified (Create, Read, Delete only)
  static const String contactsEndpoint = '/api/v1/apps/contact/list';
  static const String createContactEndpoint = '/api/v1/apps/contact';
  static String deleteContactEndpoint(String id) => '/api/v1/apps/contact/$id';

  // Debt endpoints - Simplified
  static const String allDebtsEndpoint = '/api/v1/apps/debt/list';
  static String createContactDebtEndpoint(String contactId) => '/api/v1/apps/contact-debt/$contactId';
  static String getContactDebtsEndpoint(String contactId) => '/api/v1/apps/contact-debts/$contactId';

  // Home endpoint
  static const String homeOverviewEndpoint = '/api/v1/apps/home/overview';

  // User profile endpoint
  static const String getCurrentUserEndpoint = '/api/v1/apps/me';

  // Request configuration
  static const Duration requestTimeout = Duration(seconds: 30);

  // Headers configuration
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}