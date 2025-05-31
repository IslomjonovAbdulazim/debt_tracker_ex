import 'package:flutter/material.dart';

/// Financial-focused color palette for debt tracker application
/// Designed to convey trust, professionalism, and financial clarity
class AppColors {
  AppColors._();

  // Primary Brand Colors - Deep Financial Blue
  static const Color primary = Color(0xFF1E3A8A); // Deep Blue-800 - Trust & Security
  static const Color primaryLight = Color(0xFF3B82F6); // Blue-500 - Interactive elements
  static const Color primaryDark = Color(0xFF1E40AF); // Blue-700 - Pressed states
  static const Color primaryShade = Color(0xFFEFF6FF); // Blue-50 - Light backgrounds

  // Secondary Colors - Professional Slate
  static const Color secondary = Color(0xFF475569); // Slate-600 - Professional gray-blue
  static const Color secondaryLight = Color(0xFF64748B); // Slate-500 - Secondary text
  static const Color secondaryDark = Color(0xFF334155); // Slate-700 - Dark elements
  static const Color secondaryShade = Color(0xFFF8FAFC); // Slate-50 - Subtle backgrounds

  // Financial Status Colors
  static const Color debt = Color(0xFFDC2626); // Red-600 - Debt/Owed amounts
  static const Color debtLight = Color(0xFFEF4444); // Red-500 - Debt indicators
  static const Color debtDark = Color(0xFFB91C1C); // Red-700 - Critical debt
  static const Color debtShade = Color(0xFFFEF2F2); // Red-50 - Debt backgrounds

  static const Color credit = Color(0xFF059669); // Emerald-600 - Credit/Positive amounts
  static const Color creditLight = Color(0xFF10B981); // Emerald-500 - Credit indicators
  static const Color creditDark = Color(0xFF047857); // Emerald-700 - Confirmed payments
  static const Color creditShade = Color(0xFFF0FDF4); // Green-50 - Credit backgrounds

  static const Color pending = Color(0xFFD97706); // Amber-600 - Pending transactions
  static const Color pendingLight = Color(0xFFF59E0B); // Amber-500 - Pending indicators
  static const Color pendingDark = Color(0xFFB45309); // Amber-700 - Urgent pending
  static const Color pendingShade = Color(0xFFFFFBEB); // Amber-50 - Pending backgrounds

  // Neutral Colors (Professional Gray Scale)
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // Status Colors
  static const Color success = Color(0xFF059669); // Emerald-600 - Same as credit
  static const Color successLight = Color(0xFF10B981); // Emerald-500
  static const Color successDark = Color(0xFF047857); // Emerald-700
  static const Color successShade = Color(0xFFF0FDF4); // Green-50

  static const Color warning = Color(0xFFD97706); // Amber-600 - Same as pending
  static const Color warningLight = Color(0xFFF59E0B); // Amber-500
  static const Color warningDark = Color(0xFFB45309); // Amber-700
  static const Color warningShade = Color(0xFFFFFBEB); // Amber-50

  static const Color error = Color(0xFFDC2626); // Red-600 - Same as debt
  static const Color errorLight = Color(0xFFEF4444); // Red-500
  static const Color errorDark = Color(0xFFB91C1C); // Red-700
  static const Color errorShade = Color(0xFFFEF2F2); // Red-50

  static const Color info = Color(0xFF2563EB); // Blue-600 - Information
  static const Color infoLight = Color(0xFF3B82F6); // Blue-500
  static const Color infoDark = Color(0xFF1D4ED8); // Blue-700
  static const Color infoShade = Color(0xFFEFF6FF); // Blue-50

  // Financial Category Colors
  static const Color housing = Color(0xFF7C3AED); // Violet-600 - Housing/Rent
  static const Color food = Color(0xFFEC4899); // Pink-500 - Food/Dining
  static const Color transport = Color(0xFF0EA5E9); // Sky-500 - Transportation
  static const Color utilities = Color(0xFF06B6D4); // Cyan-500 - Utilities
  static const Color entertainment = Color(0xFFF59E0B); // Amber-500 - Entertainment
  static const Color healthcare = Color(0xFFEF4444); // Red-500 - Healthcare
  static const Color education = Color(0xFF3B82F6); // Blue-500 - Education
  static const Color shopping = Color(0xFF8B5CF6); // Violet-500 - Shopping
  static const Color personal = Color(0xFF10B981); // Emerald-500 - Personal

  // Gradient Colors for Financial Charts
  static const LinearGradient debtGradient = LinearGradient(
    colors: [debt, debtLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient creditGradient = LinearGradient(
    colors: [credit, creditLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient balanceGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Chart Colors for Data Visualization
  static const List<Color> chartColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFDC2626), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
  ];
}

/// Light theme colors
class LightColors {
  static const Color background = Color(0xFFFAFAFA); // Slightly warm white
  static const Color surface = AppColors.white;
  static const Color surfaceVariant = AppColors.grey50;
  static const Color onBackground = AppColors.grey900;
  static const Color onSurface = AppColors.grey900;
  static const Color onSurfaceVariant = AppColors.grey600;

  // Text colors
  static const Color textPrimary = AppColors.grey900;
  static const Color textSecondary = AppColors.grey600;
  static const Color textTertiary = AppColors.grey400;
  static const Color textDisabled = AppColors.grey300;

  // Border colors
  static const Color border = AppColors.grey200;
  static const Color borderLight = AppColors.grey100;
  static const Color borderDark = AppColors.grey300;

  // Shadow colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowDark = Color(0x26000000);

  // Input colors
  static const Color inputFill = AppColors.grey50;
  static const Color inputBorder = AppColors.grey200;
  static const Color inputFocusBorder = AppColors.primary;
  static const Color inputErrorBorder = AppColors.error;

  // Card colors
  static const Color cardBackground = AppColors.white;
  static const Color cardShadow = Color(0x1A000000);

  // Financial specific colors
  static const Color positiveBalance = AppColors.credit;
  static const Color negativeBalance = AppColors.debt;
  static const Color neutralBalance = AppColors.grey500;

  // Divider colors
  static const Color divider = AppColors.grey200;
  static const Color dividerLight = AppColors.grey100;
}

/// Dark theme colors
class DarkColors {
  static const Color background = Color(0xFF0F172A); // Slate-900 - Deep professional dark
  static const Color surface = Color(0xFF1E293B); // Slate-800 - Card surfaces
  static const Color surfaceVariant = Color(0xFF334155); // Slate-700 - Elevated surfaces
  static const Color onBackground = AppColors.white;
  static const Color onSurface = AppColors.white;
  static const Color onSurfaceVariant = AppColors.grey300;

  // Text colors
  static const Color textPrimary = AppColors.white;
  static const Color textSecondary = AppColors.grey300;
  static const Color textTertiary = AppColors.grey500;
  static const Color textDisabled = AppColors.grey600;

  // Border colors
  static const Color border = AppColors.grey600;
  static const Color borderLight = AppColors.grey700;
  static const Color borderDark = AppColors.grey500;

  // Shadow colors
  static const Color shadow = Color(0x33000000);
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x4D000000);

  // Input colors
  static const Color inputFill = Color(0xFF334155); // Slate-700
  static const Color inputBorder = AppColors.grey600;
  static const Color inputFocusBorder = AppColors.primaryLight;
  static const Color inputErrorBorder = AppColors.errorLight;

  // Card colors
  static const Color cardBackground = Color(0xFF1E293B); // Slate-800
  static const Color cardShadow = Color(0x33000000);

  // Financial specific colors (adjusted for dark theme)
  static const Color positiveBalance = AppColors.creditLight;
  static const Color negativeBalance = AppColors.debtLight;
  static const Color neutralBalance = AppColors.grey400;

  // Divider colors
  static const Color divider = AppColors.grey600;
  static const Color dividerLight = AppColors.grey700;
}

/// Color utilities specific to debt tracking
class FinancialColorUtils {
  FinancialColorUtils._();

  /// Get color based on amount (positive = green, negative = red, zero = neutral)
  static Color getAmountColor(double amount, {bool isDarkTheme = false}) {
    if (amount > 0) {
      return isDarkTheme ? DarkColors.positiveBalance : LightColors.positiveBalance;
    } else if (amount < 0) {
      return isDarkTheme ? DarkColors.negativeBalance : LightColors.negativeBalance;
    } else {
      return isDarkTheme ? DarkColors.neutralBalance : LightColors.neutralBalance;
    }
  }

  /// Get debt status color
  static Color getDebtStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'settled':
        return AppColors.success;
      case 'overdue':
      case 'late':
        return AppColors.error;
      case 'pending':
      case 'due_soon':
        return AppColors.warning;
      case 'partial':
        return AppColors.info;
      default:
        return AppColors.grey500;
    }
  }

  /// Get category color
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'housing':
      case 'rent':
      case 'mortgage':
        return AppColors.housing;
      case 'food':
      case 'dining':
      case 'groceries':
        return AppColors.food;
      case 'transport':
      case 'car':
      case 'fuel':
        return AppColors.transport;
      case 'utilities':
      case 'electricity':
      case 'water':
        return AppColors.utilities;
      case 'entertainment':
      case 'movies':
      case 'games':
        return AppColors.entertainment;
      case 'healthcare':
      case 'medical':
      case 'insurance':
        return AppColors.healthcare;
      case 'education':
      case 'books':
      case 'courses':
        return AppColors.education;
      case 'shopping':
      case 'clothes':
      case 'electronics':
        return AppColors.shopping;
      case 'personal':
      case 'other':
        return AppColors.personal;
      default:
        return AppColors.grey500;
    }
  }

  /// Get contrasting text color (black or white) for a given background color
  static Color getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? AppColors.black : AppColors.white;
  }

  /// Darken a color by percentage
  static Color darken(Color color, [double percent = 10]) {
    assert(1 <= percent && percent <= 100);
    final f = 1 - percent / 100;
    return Color.fromARGB(
      color.alpha,
      (color.red * f).round(),
      (color.green * f).round(),
      (color.blue * f).round(),
    );
  }

  /// Lighten a color by percentage
  static Color lighten(Color color, [double percent = 10]) {
    assert(1 <= percent && percent <= 100);
    final f = percent / 100;
    return Color.fromARGB(
      color.alpha,
      (color.red + ((255 - color.red) * f)).round(),
      (color.green + ((255 - color.green) * f)).round(),
      (color.blue + ((255 - color.blue) * f)).round(),
    );
  }
}