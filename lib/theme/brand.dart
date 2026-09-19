import 'package:flutter/material.dart';
import 'package:liveness_sdk/liveness_sdk.dart';

/// Palette sampled from `assets/icon/app_icon.png` (brand blue `#1784D7`).
abstract final class BrandColors {
  static const Color primary = Color(0xFF1784D7);
  static const Color primaryDark = Color(0xFF0B4E82);
  static const Color primarySoft = Color(0xFF5CACE6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEFF6FC);
  static const Color readOnlyFill = Color(0xFFE3EDF5);
  static const Color border = Color(0xFFCBE1F3);
  static const Color muted = Color(0xFF5C7F9C);
  static const Color danger = Color(0xFFC2361B);
  static const Color success = Color(0xFF1B7A4B);
}

const LivenessTheme kLivenessTheme = LivenessTheme(
  primaryColor: BrandColors.primary,
  onPrimaryColor: BrandColors.onPrimary,
  guideColor: BrandColors.primary,
  landmarkColor: BrandColors.primarySoft,
);

/// Tuned so a completed session lands inside the 5–15 second window the eKYC
/// spec requires for the liveness clip.
const LivenessConfig kLivenessConfig = LivenessConfig(
  timeout: Duration(seconds: 15),
  instructionDelay: Duration(milliseconds: 1500),
  videoTailDuration: Duration(milliseconds: 500),
  shuffleExpressions: false,
);

/// Challenge order announced on the liveness instruction screen.
const List<Expression> kLivenessExpressions = [
  Expression.smile,
  Expression.eyeblink,
  Expression.rightPose,
];

ThemeData buildAppTheme() {
  const inputBorderRadius = BorderRadius.all(Radius.circular(12));

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: BrandColors.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BrandColors.primary,
      primary: BrandColors.primary,
      onPrimary: BrandColors.onPrimary,
      secondary: BrandColors.primarySoft,
      surface: BrandColors.surface,
      error: BrandColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: BrandColors.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: BrandColors.primaryDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: BrandColors.primaryDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BrandColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide(color: BrandColors.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide(color: BrandColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide(color: BrandColors.primary, width: 1.6),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide(color: BrandColors.danger),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide(color: BrandColors.danger, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColors.primary,
        foregroundColor: BrandColors.onPrimary,
        disabledBackgroundColor: BrandColors.primary.withValues(alpha: 0.35),
        disabledForegroundColor: BrandColors.onPrimary,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BrandColors.primary,
        side: const BorderSide(color: BrandColors.primary),
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: BrandColors.primary,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: BrandColors.primaryDark,
      contentTextStyle: TextStyle(color: BrandColors.onPrimary),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: BrandColors.primary,
      linearTrackColor: BrandColors.border,
      circularTrackColor: BrandColors.border,
    ),
    dividerTheme: const DividerThemeData(
      color: BrandColors.border,
      thickness: 1,
      space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? BrandColors.primary
            : BrandColors.surface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? BrandColors.primary.withValues(alpha: 0.35)
            : BrandColors.border,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? BrandColors.primary
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(BrandColors.onPrimary),
      side: const BorderSide(color: BrandColors.muted, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: const RadioThemeData(
      fillColor: WidgetStatePropertyAll(BrandColors.primary),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: BrandColors.primary,
      textColor: BrandColors.primaryDark,
    ),
    iconTheme: const IconThemeData(color: BrandColors.primary),
    dialogTheme: const DialogThemeData(
      backgroundColor: BrandColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: BrandColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: BrandColors.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: BrandColors.primary,
      headerForegroundColor: BrandColors.onPrimary,
    ),
  );
}
