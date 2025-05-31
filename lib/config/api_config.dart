class ApiConfig {
  // TODO: Change this to your real backend URL when integrating
  static bool get isProduction => baseUrl.contains('api.debttracker.com');
  static bool get isDevelopment => baseUrl.contains('localhost');
  static const String baseUrl = 'http://10.10.3.132:8000/';

  // Logging
  static bool get enableApiLogging => isDevelopment;

  // Auth endpoints - Keep as they match the API docs
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String verifyEmailEndpoint = '/verify-email';
  static const String forgotPasswordEndpoint = '/forgot-password';
  static const String verifyResetCodeEndpoint = '/verify-reset-code';
  static const String resetPasswordEndpoint = '/reset-password';
  static const String logoutEndpoint = '/auth/logout';
  static const String getCurrentUserEndpoint = '/auth/me';

  // Home/Overview endpoint - New from API docs
  static const String homeOverviewEndpoint = '/home/overview';

  // Contact endpoints - Updated to match API docs
  static const String contactsEndpoint = '/contacts';
  static const String createContactEndpoint = '/contact';
  static const String updateContactEndpoint = '/contact'; // + /{id}
  static const String deleteContactEndpoint = '/contact'; // + /{id}

  // Debt endpoints - Simplified to match API docs
  static const String debtsEndpoint = '/debts';
  static const String createDebtEndpoint = '/contact-debt';
  static const String contactDebtsEndpoint = '/contact-debts'; // + /{contact_id}

  // REMOVED: Complex debt endpoints that don't exist in API
  // - myDebtsEndpoint
  // - theirDebtsEndpoint
  // - overdueDebtsEndpoint
  // - debtsSummaryEndpoint
  // - updateDebtEndpoint
  // - deleteDebtEndpoint
  // - markDebtPaidEndpoint

  // REMOVED: Payment endpoints - Not mentioned in API docs
  // Will be handled differently or removed entirely

  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authenticate': '$token',
  };
}