import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'dart:math' as math;

/// Complete theme configuration for the debt tracker application
/// Designed with financial trust, professionalism, and clarity in mind
class AppTheme {
  AppTheme._();

  /// Light theme configuration - Professional & Trustworthy
  static ThemeData get lightTheme => ThemeData(
    // Color scheme
    colorScheme: const ColorScheme.light(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryShade,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryShade,
      onSecondaryContainer: AppColors.secondaryDark,
      tertiary: AppColors.credit,
      onTertiary: Colors.white,
      error: AppColors.debt,
      onError: Colors.white,
      errorContainer: AppColors.debtShade,
      onErrorContainer: AppColors.debtDark,
      background: LightColors.background,
      onBackground: LightColors.onBackground,
      surface: LightColors.surface,
      onSurface: LightColors.onSurface,
      surfaceVariant: LightColors.surfaceVariant,
      onSurfaceVariant: LightColors.onSurfaceVariant,
      outline: LightColors.border,
      outlineVariant: LightColors.borderLight,
      shadow: LightColors.shadow,
      scrim: Colors.black54,
      inverseSurface: AppColors.grey800,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.primaryLight,
    ),

    // Material 3 design
    useMaterial3: true,

    // App bar theme - Clean financial header
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: LightColors.surface,
      foregroundColor: LightColors.textPrimary,
      surfaceTintColor: AppColors.primary,
      titleTextStyle: AppTextStyles.titleLarge.copyWith(
        color: LightColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(
        color: LightColors.textPrimary,
        size: 24,
      ),
      actionsIconTheme: const IconThemeData(
        color: LightColors.textPrimary,
        size: 24,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: LightColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: LightColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    ),

    // Navigation bar theme (Material 3)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: LightColors.surface,
      indicatorColor: AppColors.primaryShade,
      labelTextStyle: MaterialStateProperty.all(
        AppTextStyles.labelSmall.copyWith(color: LightColors.textPrimary),
      ),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: LightColors.textTertiary);
      }),
    ),

    // Card theme - Clean financial cards
    cardTheme: CardTheme(
      color: LightColors.cardBackground,
      elevation: 2,
      shadowColor: LightColors.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),

    // Elevated button theme - Financial actions
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: AppTextStyles.buttonMedium,
        minimumSize: const Size(88, 52),
      ),
    ),

    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: AppTextStyles.buttonMedium,
        minimumSize: const Size(88, 52),
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: AppTextStyles.buttonMedium,
        minimumSize: const Size(64, 40),
      ),
    ),

    // Floating action button theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: CircleBorder(),
    ),

    // Input decoration theme - Financial forms
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LightColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LightColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LightColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LightColors.inputFocusBorder, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LightColors.inputErrorBorder),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LightColors.inputErrorBorder, width: 2),
      ),
      labelStyle: AppTextStyles.inputLabel.copyWith(color: LightColors.textSecondary),
      hintStyle: AppTextStyles.inputHint.copyWith(color: LightColors.textTertiary),
      errorStyle: AppTextStyles.inputError.copyWith(color: AppColors.debt),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Radio theme
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return LightColors.textTertiary;
      }),
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return AppColors.grey400;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary.withOpacity(0.5);
        }
        return AppColors.grey300;
      }),
    ),

    // Slider theme
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.grey300,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primaryShade,
    ),

    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.grey200,
      circularTrackColor: AppColors.grey200,
    ),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: LightColors.divider,
      thickness: 1,
      space: 1,
    ),

    // Dialog theme
    dialogTheme: DialogTheme(
      backgroundColor: LightColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: AppTextStyles.titleLarge.copyWith(
        color: LightColors.textPrimary,
      ),
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: LightColors.textSecondary,
      ),
    ),

    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.grey800,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    ),

    // Bottom sheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: LightColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Tab bar theme
    tabBarTheme: TabBarTheme(
      labelColor: AppColors.primary,
      unselectedLabelColor: LightColors.textTertiary,
      labelStyle: AppTextStyles.tabLabel.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: AppTextStyles.tabLabel,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    ),

    // List tile theme
    listTileTheme: ListTileThemeData(
      iconColor: LightColors.textSecondary,
      textColor: LightColors.textPrimary,
      titleTextStyle: AppTextStyles.listTitle.copyWith(color: LightColors.textPrimary),
      subtitleTextStyle: AppTextStyles.listSubtitle.copyWith(color: LightColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // Icon theme
    iconTheme: const IconThemeData(
      color: LightColors.textSecondary,
      size: 24,
    ),

    // Primary icon theme
    primaryIconTheme: const IconThemeData(
      color: Colors.white,
      size: 24,
    ),

    // Text theme
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    ),

    // Extensions
    extensions: <ThemeExtension<dynamic>>[
      FinancialColors.light,
    ],
  );

  /// Dark theme configuration - Professional Dark Mode
  static ThemeData get darkTheme => ThemeData(
    // Color scheme
    colorScheme: const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.grey900,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.grey900,
      secondaryContainer: AppColors.secondaryDark,
      onSecondaryContainer: AppColors.secondaryLight,
      tertiary: AppColors.creditLight,
      onTertiary: AppColors.grey900,
      error: AppColors.debtLight,
      onError: AppColors.grey900,
      errorContainer: AppColors.debtDark,
      onErrorContainer: AppColors.debtLight,
      background: DarkColors.background,
      onBackground: DarkColors.onBackground,
      surface: DarkColors.surface,
      onSurface: DarkColors.onSurface,
      surfaceVariant: DarkColors.surfaceVariant,
      onSurfaceVariant: DarkColors.onSurfaceVariant,
      outline: DarkColors.border,
      outlineVariant: DarkColors.borderLight,
      shadow: DarkColors.shadow,
      scrim: Colors.black87,
      inverseSurface: AppColors.grey100,
      onInverseSurface: AppColors.grey900,
      inversePrimary: AppColors.primary,
    ),

    // Material 3 design
    useMaterial3: true,

    // App bar theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: DarkColors.surface,
      foregroundColor: DarkColors.textPrimary,
      surfaceTintColor: AppColors.primaryLight,
      titleTextStyle: AppTextStyles.titleLarge.copyWith(
        color: DarkColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(
        color: DarkColors.textPrimary,
        size: 24,
      ),
      actionsIconTheme: const IconThemeData(
        color: DarkColors.textPrimary,
        size: 24,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    // Card theme
    cardTheme: CardTheme(
      color: DarkColors.cardBackground,
      elevation: 4,
      shadowColor: DarkColors.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.grey900,
        elevation: 3,
        shadowColor: AppColors.primaryLight.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: AppTextStyles.buttonMedium,
        minimumSize: const Size(88, 52),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DarkColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.inputFocusBorder, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.inputErrorBorder),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.inputErrorBorder, width: 2),
      ),
      labelStyle: AppTextStyles.inputLabel.copyWith(color: DarkColors.textSecondary),
      hintStyle: AppTextStyles.inputHint.copyWith(color: DarkColors.textTertiary),
      errorStyle: AppTextStyles.inputError.copyWith(color: AppColors.debtLight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Text theme
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    ),

    // Extensions
    extensions: <ThemeExtension<dynamic>>[
      FinancialColors.dark,
    ],
  );
}

/// Financial colors extension for debt tracker specific colors
@immutable
class FinancialColors extends ThemeExtension<FinancialColors> {
  final Color? debt;
  final Color? credit;
  final Color? pending;
  final Color? debtBackground;
  final Color? creditBackground;
  final Color? pendingBackground;
  final Color? positiveAmount;
  final Color? negativeAmount;
  final Color? neutralAmount;

  const FinancialColors({
    required this.debt,
    required this.credit,
    required this.pending,
    required this.debtBackground,
    required this.creditBackground,
    required this.pendingBackground,
    required this.positiveAmount,
    required this.negativeAmount,
    required this.neutralAmount,
  });

  static const light = FinancialColors(
    debt: AppColors.debt,
    credit: AppColors.credit,
    pending: AppColors.pending,
    debtBackground: AppColors.debtShade,
    creditBackground: AppColors.creditShade,
    pendingBackground: AppColors.pendingShade,
    positiveAmount: AppColors.credit,
    negativeAmount: AppColors.debt,
    neutralAmount: AppColors.grey500,
  );

  static const dark = FinancialColors(
    debt: AppColors.debtLight,
    credit: AppColors.creditLight,
    pending: AppColors.pendingLight,
    debtBackground: AppColors.debtDark,
    creditBackground: AppColors.creditDark,
    pendingBackground: AppColors.pendingDark,
    positiveAmount: AppColors.creditLight,
    negativeAmount: AppColors.debtLight,
    neutralAmount: AppColors.grey400,
  );

  @override
  FinancialColors copyWith({
    Color? debt,
    Color? credit,
    Color? pending,
    Color? debtBackground,
    Color? creditBackground,
    Color? pendingBackground,
    Color? positiveAmount,
    Color? negativeAmount,
    Color? neutralAmount,
  }) {
    return FinancialColors(
      debt: debt ?? this.debt,
      credit: credit ?? this.credit,
      pending: pending ?? this.pending,
      debtBackground: debtBackground ?? this.debtBackground,
      creditBackground: creditBackground ?? this.creditBackground,
      pendingBackground: pendingBackground ?? this.pendingBackground,
      positiveAmount: positiveAmount ?? this.positiveAmount,
      negativeAmount: negativeAmount ?? this.negativeAmount,
      neutralAmount: neutralAmount ?? this.neutralAmount,
    );
  }

  @override
  FinancialColors lerp(ThemeExtension<FinancialColors>? other, double t) {
    if (other is! FinancialColors) {
      return this;
    }
    return FinancialColors(
      debt: Color.lerp(debt, other.debt, t),
      credit: Color.lerp(credit, other.credit, t),
      pending: Color.lerp(pending, other.pending, t),
      debtBackground: Color.lerp(debtBackground, other.debtBackground, t),
      creditBackground: Color.lerp(creditBackground, other.creditBackground, t),
      pendingBackground: Color.lerp(pendingBackground, other.pendingBackground, t),
      positiveAmount: Color.lerp(positiveAmount, other.positiveAmount, t),
      negativeAmount: Color.lerp(negativeAmount, other.negativeAmount, t),
      neutralAmount: Color.lerp(neutralAmount, other.neutralAmount, t),
    );
  }
}

/// Theme utility methods for debt tracker
class DebtThemeUtils {
  DebtThemeUtils._();

  /// Get financial colors from context
  static FinancialColors getFinancialColors(BuildContext context) {
    return Theme.of(context).extension<FinancialColors>() ?? FinancialColors.light;
  }

  /// Check if current theme is dark
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get amount color based on value
  static Color getAmountColor(BuildContext context, double amount) {
    final financialColors = getFinancialColors(context);

    if (amount > 0) {
      return financialColors.positiveAmount!;
    } else if (amount < 0) {
      return financialColors.negativeAmount!;
    } else {
      return financialColors.neutralAmount!;
    }
  }

  /// Get debt status color
  static Color getDebtStatusColor(BuildContext context, String status) {
    return FinancialColorUtils.getDebtStatusColor(status);
  }

  /// Get category color
  static Color getCategoryColor(String category) {
    return FinancialColorUtils.getCategoryColor(category);
  }

  /// Get appropriate text color based on background
  static Color getContrastingTextColor(Color backgroundColor) {
    return FinancialColorUtils.getContrastingTextColor(backgroundColor);
  }

  /// Apply elevation overlay for dark theme surfaces
  static Color getElevationOverlay(BuildContext context, Color surfaceColor, double elevation) {
    if (!isDark(context)) return surfaceColor;

    final overlayOpacity = (4.5 * math.log(elevation + 1) + 2) / 100;
    return Color.alphaBlend(
      Colors.white.withOpacity(overlayOpacity),
      surfaceColor,
    );
  }

  /// Get financial card decoration
  static BoxDecoration getFinancialCardDecoration(BuildContext context, {
    Color? backgroundColor,
    double elevation = 2,
    double borderRadius = 16,
  }) {
    final theme = Theme.of(context);
    final isDarkTheme = isDark(context);

    return BoxDecoration(
      color: backgroundColor ?? theme.cardColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: isDarkTheme
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }

  /// Get gradient for amount display
  static LinearGradient getAmountGradient(double amount) {
    if (amount > 0) {
      return AppColors.creditGradient;
    } else if (amount < 0) {
      return AppColors.debtGradient;
    } else {
      return const LinearGradient(
        colors: [AppColors.grey400, AppColors.grey500],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }
}