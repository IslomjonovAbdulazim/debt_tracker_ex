// lib/config/app_constants.dart
class AppConstants {
  // App Information
  static const String appName = 'Debt Tracker';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Cache Configuration
  static const Duration cacheTimeout = Duration(minutes: 5);
  static const Duration sessionTimeout = Duration(hours: 24);

  // UI Configuration
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double iconSize = 24.0;

  // Validation Limits
  static const int maxNameLength = 50;
  static const int minNameLength = 2;
  static const int maxDescriptionLength = 500;
  static const int minDescriptionLength = 3;
  static const double maxDebtAmount = 999999.99;
  static const double minDebtAmount = 0.01;

  // Phone Number Configuration
  static const String uzbekistanCountryCode = '+998';
  static const String phoneNumberMask = '+998 ## ### ## ##';

  // Date Formats
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String shortDateFormat = 'MMM dd';
  static const String timeFormat = 'h:mm a';

  // API Configuration
  static const int maxRetries = 3;
  static const Duration requestTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 50;
  static const int maxPageSize = 100;

  // File Upload (if needed later)
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];

  // Colors (as hex strings for consistency)
  static const Map<String, int> colors = {
    'primary': 0xFF2196F3,
    'primaryDark': 0xFF1976D2,
    'accent': 0xFF03DAC6,
    'error': 0xFFB00020,
    'success': 0xFF4CAF50,
    'warning': 0xFFFF9800,
    'info': 0xFF2196F3,
  };

  // Default Values
  static const int defaultDueDays = 30;
  static const String defaultCurrency = 'USD';
  static const String currencySymbol = '\$';

  // Regular Expressions
  static final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final RegExp phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
  static final RegExp nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");

  // Error Messages
  static const Map<String, String> errorMessages = {
  'networkError': 'No internet connection. Please check your network.',
  'timeoutError': 'Request timed out. Please try again.',
  'serverError': 'Server error occurred. Please try again later.',
  'unauthorizedError': 'Session expired. Please login again.',
  'validationError': 'Please check your input and try again.',
  'unknownError': 'An unexpected error occurred.',
  };

  // Success Messages
  static const Map<String, String> successMessages = {
  'contactCreated': 'Contact added successfully!',
  'contactUpdated': 'Contact updated successfully!',
  'contactDeleted': 'Contact deleted successfully!',
  'debtCreated': 'Debt record added successfully!',
  'debtUpdated': 'Debt record updated successfully!',
  'debtMarkedPaid': 'Debt marked as paid successfully!',
  'loginSuccess': 'Welcome back!',
  'registrationSuccess': 'Registration successful!',
  'passwordReset': 'Password reset successfully!',
  };

  // Feature Flags (for gradual rollout)
  static const Map<String, bool> features = {
  'enablePushNotifications': false,
  'enableBiometricAuth': false,
  'enableDataExport': true,
  'enableDarkMode': true,
  'enableAdvancedSearch': true,
  'enableMultipleCurrencies': false,
  };
}

