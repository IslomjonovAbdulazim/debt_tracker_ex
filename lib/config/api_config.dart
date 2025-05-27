class ApiConfig {
  // TODO: Change this to your real backend URL when integrating
  static const String baseUrl = 'http://localhost:8080/api';
  // static const String baseUrl = 'https://your-backend-domain.com/api';

  // Auth endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String verifyEmailEndpoint = '/auth/verify-email';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String verifyResetCodeEndpoint = '/auth/verify-reset-code';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String logoutEndpoint = '/auth/logout';
  static const String getCurrentUserEndpoint = '/auth/me';

  // Contact endpoints
  static const String contactsEndpoint = '/contacts';
  static const String createContactEndpoint = '/contacts';
  static const String updateContactEndpoint = '/contacts'; // + /{id}
  static const String deleteContactEndpoint = '/contacts'; // + /{id}
  static const String searchContactsEndpoint = '/contacts/search';

  // Debt endpoints
  static const String debtsEndpoint = '/debts';
  static const String createDebtEndpoint = '/debts';
  static const String updateDebtEndpoint = '/debts'; // + /{id}
  static const String deleteDebtEndpoint = '/debts'; // + /{id}
  static const String markDebtPaidEndpoint = '/debts'; // + /{id}/mark-paid
  static const String myDebtsEndpoint = '/debts/my-debts';
  static const String theirDebtsEndpoint = '/debts/their-debts';
  static const String overdueDebtsEndpoint = '/debts/overdue';
  static const String debtsByContactEndpoint = '/debts/by-contact'; // + /{contactId}
  static const String debtsSummaryEndpoint = '/debts/summary';

  // Payment endpoints
  static const String paymentsEndpoint = '/payments';
  static const String createPaymentEndpoint = '/payments';
  static const String myPaymentsEndpoint = '/payments/my-payments';
  static const String theirPaymentsEndpoint = '/payments/their-payments';
  static const String recentPaymentsEndpoint = '/payments/recent';
  static const String paymentsByContactEndpoint = '/payments/by-contact'; // + /{contactName}

  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}