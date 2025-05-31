// lib/utils/helpers.dart
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_constants.dart';

class AppHelpers {
  // Date Formatting
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat(AppConstants.shortDateFormat).format(date);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat(AppConstants.timeFormat).format(dateTime);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      return formatShortDate(date);
    }
  }

  // Currency Formatting
  static String formatCurrency(double amount) {
    return '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}';
  }

  static String formatCurrencyCompact(double amount) {
    if (amount >= 1000000) {
      return '${AppConstants.currencySymbol}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${AppConstants.currencySymbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatCurrency(amount);
  }

  // Phone Number Formatting
  static String formatPhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.startsWith('998') && digitsOnly.length == 12) {
      return '+${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 5)} ${digitsOnly.substring(5, 8)} ${digitsOnly.substring(8, 10)} ${digitsOnly.substring(10)}';
    }

    return phoneNumber;
  }

  // Validation Helpers
  static bool isValidEmail(String email) {
    return AppConstants.emailRegex.hasMatch(email.trim());
  }

  static bool isValidPhoneNumber(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.length >= 9 && digitsOnly.length <= 15;
  }

  static bool isValidName(String name) {
    return name.trim().length >= AppConstants.minNameLength &&
        name.trim().length <= AppConstants.maxNameLength &&
        AppConstants.nameRegex.hasMatch(name.trim());
  }

  static bool isValidAmount(double amount) {
    return amount >= AppConstants.minDebtAmount &&
        amount <= AppConstants.maxDebtAmount;
  }

  // Text Processing
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    return text.split(' ')
        .map((word) => word.isEmpty ? word : capitalizeFirst(word))
        .join(' ');
  }

  // Color Helpers
  static Color getDebtColor(bool isMyDebt) {
    return isMyDebt ? Colors.red[400]! : Colors.green[400]!;
  }

  static Color getStatusColor(bool isPaid, bool isOverdue) {
    if (isPaid) return Colors.blue[400]!;
    if (isOverdue) return Colors.orange[400]!;
    return Colors.grey[400]!;
  }

  // Due Date Helpers
  static bool isOverdue(DateTime dueDate) {
    return DateTime.now().isAfter(dueDate);
  }

  static int daysDifference(DateTime date) {
    return date.difference(DateTime.now()).inDays;
  }

  static String getDueDateStatus(DateTime dueDate, bool isPaid) {
    if (isPaid) return 'Paid';

    final days = daysDifference(dueDate);

    if (days < 0) {
      return 'Overdue by ${days.abs()} day${days.abs() == 1 ? '' : 's'}';
    } else if (days == 0) {
      return 'Due today';
    } else if (days == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $days day${days == 1 ? '' : 's'}';
    }
  }

  // Error Message Helpers
  static String getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socketexception') || errorStr.contains('network')) {
      return AppConstants.errorMessages['networkError']!;
    }
    if (errorStr.contains('timeout')) {
      return AppConstants.errorMessages['timeoutError']!;
    }
    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return AppConstants.errorMessages['unauthorizedError']!;
    }
    if (errorStr.contains('500')) {
      return AppConstants.errorMessages['serverError']!;
    }

    return AppConstants.errorMessages['unknownError']!;
  }

  // Feature Flag Helpers
  static bool isFeatureEnabled(String featureName) {
    return AppConstants.features[featureName] ?? false;
  }
}