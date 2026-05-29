import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Configuração global do tema Material 3 — dark mode exclusivo.
abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface0,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.accent,
        onPrimary: AppColors.textOnAccent,
        primaryContainer: AppColors.accentSubtle,
        onPrimaryContainer: AppColors.accent,
        secondary: AppColors.galaxy,
        onSecondary: AppColors.textOnAccent,
        surface: AppColors.surface1,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surface2,
        error: AppColors.error,
        onError: AppColors.textOnAccent,
        outline: AppColors.border,
        outlineVariant: AppColors.borderActive,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        titleMedium: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary),
        labelSmall: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textDisabled),
        labelStyle: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textSecondary),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textOnAccent,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),

      // Tooltips
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: GoogleFonts.inter(
            fontSize: 12, color: AppColors.textPrimary),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface2,
        contentTextStyle: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // Scrollbar
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.border),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(4),
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.surface2,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2,
        labelStyle: GoogleFonts.inter(
            fontSize: 12, color: AppColors.textSecondary),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: AppColors.border),
        ),
        elevation: 8,
      ),

      // List tile
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.sidebarItemActive,
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textSecondary,
        selectedColor: AppColors.accent,
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}
