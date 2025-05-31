import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography styles for consistent text appearance throughout the app
/// Based on Material Design 3 typography scale with custom adaptations
class AppTextStyles {
  AppTextStyles._();

  // Base font family
  static const String fontFamily = 'Inter';

  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // Letter spacing values
  static const double tightLetterSpacing = -0.5;
  static const double normalLetterSpacing = 0.0;
  static const double wideLetterSpacing = 0.5;

  // Line heights
  static const double tightLineHeight = 1.2;
  static const double normalLineHeight = 1.4;
  static const double relaxedLineHeight = 1.6;

  // Display Styles (Largest text)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: regular,
    height: tightLineHeight,
    letterSpacing: tightLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: regular,
    height: tightLineHeight,
    letterSpacing: tightLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: regular,
    height: tightLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  // Headline Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: semiBold,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: semiBold,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: semiBold,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: medium,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: medium,
    height: normalLineHeight,
    letterSpacing: wideLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    height: normalLineHeight,
    letterSpacing: wideLetterSpacing,
    fontFamily: fontFamily,
  );

  // Body Styles (Main content text)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: relaxedLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: regular,
    height: relaxedLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: regular,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  // Label Styles (UI elements)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    height: normalLineHeight,
    letterSpacing: wideLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: medium,
    height: normalLineHeight,
    letterSpacing: wideLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: medium,
    height: normalLineHeight,
    letterSpacing: wideLetterSpacing,
    fontFamily: fontFamily,
  );

  // Custom App-Specific Styles

  // Button styles
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: semiBold,
    height: tightLineHeight,
    letterSpacing: wideLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: semiBold,
    height: tightLineHeight,
    letterSpacing: wideLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: semiBold,
    height: tightLineHeight,
    letterSpacing: wideLetterSpacing,
    fontFamily: fontFamily,
  );

  // Input field styles
  static const TextStyle inputText = TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle inputLabel = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle inputError = TextStyle(
    fontSize: 12,
    fontWeight: regular,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  // Navigation styles
  static const TextStyle navigationLabel = TextStyle(
    fontSize: 12,
    fontWeight: medium,
    height: tightLineHeight,
    letterSpacing: wideLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle tabLabel = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    height: tightLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  // Card and list styles
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: semiBold,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: regular,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle listTitle = TextStyle(
    fontSize: 16,
    fontWeight: medium,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle listSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: regular,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  // Status and badge styles
  static const TextStyle statusText = TextStyle(
    fontSize: 12,
    fontWeight: semiBold,
    height: tightLineHeight,
    letterSpacing: wideLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 10,
    fontWeight: bold,
    height: tightLineHeight,
    letterSpacing: wideLetterSpacing,
    fontFamily: fontFamily,
  );

  // Special styles
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: regular,
    height: normalLineHeight,
    letterSpacing: normalLetterSpacing,
    fontFamily: fontFamily,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: medium,
    height: tightLineHeight,
    letterSpacing: wideLetterSpacing,
    fontFamily: fontFamily,
  );
}

/// Light theme text styles with colors
class LightTextStyles {
  // Primary text colors
  static TextStyle get displayLarge => AppTextStyles.displayLarge.copyWith(color: LightColors.textPrimary);
  static TextStyle get displayMedium => AppTextStyles.displayMedium.copyWith(color: LightColors.textPrimary);
  static TextStyle get displaySmall => AppTextStyles.displaySmall.copyWith(color: LightColors.textPrimary);

  static TextStyle get headlineLarge => AppTextStyles.headlineLarge.copyWith(color: LightColors.textPrimary);
  static TextStyle get headlineMedium => AppTextStyles.headlineMedium.copyWith(color: LightColors.textPrimary);
  static TextStyle get headlineSmall => AppTextStyles.headlineSmall.copyWith(color: LightColors.textPrimary);

  static TextStyle get titleLarge => AppTextStyles.titleLarge.copyWith(color: LightColors.textPrimary);
  static TextStyle get titleMedium => AppTextStyles.titleMedium.copyWith(color: LightColors.textPrimary);
  static TextStyle get titleSmall => AppTextStyles.titleSmall.copyWith(color: LightColors.textPrimary);

  static TextStyle get bodyLarge => AppTextStyles.bodyLarge.copyWith(color: LightColors.textPrimary);
  static TextStyle get bodyMedium => AppTextStyles.bodyMedium.copyWith(color: LightColors.textSecondary);
  static TextStyle get bodySmall => AppTextStyles.bodySmall.copyWith(color: LightColors.textSecondary);

  static TextStyle get labelLarge => AppTextStyles.labelLarge.copyWith(color: LightColors.textPrimary);
  static TextStyle get labelMedium => AppTextStyles.labelMedium.copyWith(color: LightColors.textSecondary);
  static TextStyle get labelSmall => AppTextStyles.labelSmall.copyWith(color: LightColors.textTertiary);

  // Input styles
  static TextStyle get inputText => AppTextStyles.inputText.copyWith(color: LightColors.textPrimary);
  static TextStyle get inputLabel => AppTextStyles.inputLabel.copyWith(color: LightColors.textSecondary);
  static TextStyle get inputHint => AppTextStyles.inputHint.copyWith(color: LightColors.textTertiary);
  static TextStyle get inputError => AppTextStyles.inputError.copyWith(color: AppColors.error);

  // Special styles
  static TextStyle get caption => AppTextStyles.caption.copyWith(color: LightColors.textTertiary);
  static TextStyle get overline => AppTextStyles.overline.copyWith(color: LightColors.textTertiary);
}

/// Dark theme text styles with colors
class DarkTextStyles {
  // Primary text colors
  static TextStyle get displayLarge => AppTextStyles.displayLarge.copyWith(color: DarkColors.textPrimary);
  static TextStyle get displayMedium => AppTextStyles.displayMedium.copyWith(color: DarkColors.textPrimary);
  static TextStyle get displaySmall => AppTextStyles.displaySmall.copyWith(color: DarkColors.textPrimary);

  static TextStyle get headlineLarge => AppTextStyles.headlineLarge.copyWith(color: DarkColors.textPrimary);
  static TextStyle get headlineMedium => AppTextStyles.headlineMedium.copyWith(color: DarkColors.textPrimary);
  static TextStyle get headlineSmall => AppTextStyles.headlineSmall.copyWith(color: DarkColors.textPrimary);

  static TextStyle get titleLarge => AppTextStyles.titleLarge.copyWith(color: DarkColors.textPrimary);
  static TextStyle get titleMedium => AppTextStyles.titleMedium.copyWith(color: DarkColors.textPrimary);
  static TextStyle get titleSmall => AppTextStyles.titleSmall.copyWith(color: DarkColors.textPrimary);

  static TextStyle get bodyLarge => AppTextStyles.bodyLarge.copyWith(color: DarkColors.textPrimary);
  static TextStyle get bodyMedium => AppTextStyles.bodyMedium.copyWith(color: DarkColors.textSecondary);
  static TextStyle get bodySmall => AppTextStyles.bodySmall.copyWith(color: DarkColors.textSecondary);

  static TextStyle get labelLarge => AppTextStyles.labelLarge.copyWith(color: DarkColors.textPrimary);
  static TextStyle get labelMedium => AppTextStyles.labelMedium.copyWith(color: DarkColors.textSecondary);
  static TextStyle get labelSmall => AppTextStyles.labelSmall.copyWith(color: DarkColors.textTertiary);

  // Input styles
  static TextStyle get inputText => AppTextStyles.inputText.copyWith(color: DarkColors.textPrimary);
  static TextStyle get inputLabel => AppTextStyles.inputLabel.copyWith(color: DarkColors.textSecondary);
  static TextStyle get inputHint => AppTextStyles.inputHint.copyWith(color: DarkColors.textTertiary);
  static TextStyle get inputError => AppTextStyles.inputError.copyWith(color: AppColors.errorLight);

  // Special styles
  static TextStyle get caption => AppTextStyles.caption.copyWith(color: DarkColors.textTertiary);
  static TextStyle get overline => AppTextStyles.overline.copyWith(color: DarkColors.textTertiary);
}

/// Text style utilities
class TextStyleUtils {
  TextStyleUtils._();

  /// Apply color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply different font weight to any text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Apply different font size to any text style
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Apply opacity to any text style
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withOpacity(opacity));
  }

  /// Apply underline decoration
  static TextStyle withUnderline(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.underline);
  }

  /// Apply line through decoration
  static TextStyle withLineThrough(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.lineThrough);
  }

  /// Get responsive font size based on screen width
  static double getResponsiveFontSize(double baseFontSize, double screenWidth) {
    if (screenWidth < 360) {
      return baseFontSize * 0.9; // Smaller screens
    } else if (screenWidth > 768) {
      return baseFontSize * 1.1; // Larger screens/tablets
    }
    return baseFontSize; // Default
  }
}