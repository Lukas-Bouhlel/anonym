import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Base palette
  static const Color c393566 = Color(0xFF393566);
  static const Color cB1BCFB = Color(0xFFB1BCFB);
  static const Color cDBE7FE = Color(0xFFDBE7FE);
  static const Color cCCD4F4 = Color(0xFFCCD4F4);
  static const Color cABB7DF = Color(0xFFABB7DF);
  static const Color cFCFAFE = Color(0xFFFCFAFE);
  static const Color cFEF2F3 = Color(0xFFFEF2F3);
  static const Color cCFFFDD = Color(0xFFCFFFDD);
  static const Color cFF6565 = Color(0xFFFF6565);
  static const Color cD0BAFF = Color(0xFFD0BAFF);
  static const Color cD09EFE = Color(0xFFD09EFE);
  static const Color cB57EFF = Color(0xFFB57EFF);
  static const Color c9D5EDF = Color(0xFF9D5EDF);
  static const Color c292929 = Color(0xFF292929);
  static const Color c121212 = Color(0xFF121212);

  // Common aliases
  static const Color primary = c393566;
  static const Color secondary = cB1BCFB;
  static const Color surface = cFCFAFE;
  static const Color surfaceSoft = cDBE7FE;
  static const Color border = cABB7DF;
  static const Color success = cCFFFDD;
  static const Color danger = cFF6565;
  static const Color textPrimary = c121212;
  static const Color textSecondary = c292929;
  static const Color whiteColor = cFCFAFE;
  static const Color outlineColor = Color(0x3DFCFAFE);
}

class AppGradients {
  const AppGradients._();

  static const LinearGradient gB1BCFBTo393566 = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.c393566, AppColors.cB1BCFB],
  );

  static const LinearGradient gB1BCFBToDBE7FE = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cB1BCFB, AppColors.cDBE7FE],
  );

  static const LinearGradient gB1BCFBToFCFAFE = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cB1BCFB, AppColors.cFCFAFE],
  );

  static const LinearGradient gB1BCFBToFEF2F3 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cB1BCFB, AppColors.cFEF2F3],
  );

  static const LinearGradient gCFFFDDToFCFAFE = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cCFFFDD, AppColors.cFCFAFE],
  );

  static const LinearGradient gD09EFEToD0BAFF = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cD09EFE, AppColors.cD0BAFF],
  );

  static const LinearGradient g9D5EDFToD0BAFF = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.c9D5EDF, AppColors.cD0BAFF],
  );

  static const LinearGradient g292929To121212 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.c292929, AppColors.c121212],
  );
}

class AppTypography {
  AppTypography._();

  static const String primaryFontFamily = 'SFProDisplay';
  static const String displayFontFamily = 'ClashDisplay';
  static const String accentFontFamily = 'EricaOne';

  // Same scale as MojiMobile
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: displayFontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 30,
      letterSpacing: 0,
      color: AppColors.whiteColor,
    ),
    displayMedium: TextStyle(
      fontFamily: displayFontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 40,
      letterSpacing: -1,
      height: 1.1,
      color: AppColors.whiteColor,
    ),
    displaySmall: TextStyle(
      fontFamily: displayFontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 30,
      letterSpacing: -0.8,
      height: 1.1,
      color: AppColors.whiteColor,
    ),
    headlineLarge: TextStyle(
      fontFamily: displayFontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 28,
      letterSpacing: -0.5,
      height: 1.1,
      color: AppColors.whiteColor,
    ),
    headlineMedium: TextStyle(
      fontFamily: displayFontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 24,
      letterSpacing: -0.3,
      height: 1.15,
      color: AppColors.whiteColor,
    ),
    headlineSmall: TextStyle(
      fontFamily: displayFontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 20,
      letterSpacing: -0.2,
      height: 1.15,
      color: AppColors.whiteColor,
    ),
    titleLarge: TextStyle(
      fontFamily: primaryFontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 20,
      height: 1.2,
      color: AppColors.whiteColor,
    ),
    titleMedium: TextStyle(
      fontFamily: primaryFontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 1.3,
      color: AppColors.whiteColor,
    ),
    titleSmall: TextStyle(
      fontFamily: primaryFontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 14,
      height: 1.3,
      color: AppColors.whiteColor,
    ),
    bodyLarge: TextStyle(
      fontFamily: primaryFontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 1.5,
      color: AppColors.whiteColor,
    ),
    bodyMedium: TextStyle(
      fontFamily: primaryFontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 1.5,
      color: AppColors.whiteColor,
    ),
    bodySmall: TextStyle(
      fontFamily: primaryFontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 1.4,
      color: AppColors.whiteColor,
    ),
    labelLarge: TextStyle(
      fontFamily: primaryFontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      letterSpacing: 0.1,
      height: 1.2,
      color: AppColors.whiteColor,
    ),
    labelMedium: TextStyle(
      fontFamily: primaryFontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 12,
      letterSpacing: 0.3,
      height: 1.2,
      color: AppColors.whiteColor,
    ),
    labelSmall: TextStyle(
      fontFamily: primaryFontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 11,
      letterSpacing: 0.4,
      height: 1.2,
      color: AppColors.whiteColor,
    ),
  );
}

class AppTheme {
  const AppTheme._();

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.cFCFAFE,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textPrimary,
      tertiary: AppColors.cD09EFE,
      onTertiary: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.cFCFAFE,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: AppTypography.textTheme,
    fontFamily: AppTypography.primaryFontFamily,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: AppColors.c393566,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.whiteColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.displayFontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 28,
        letterSpacing: -0.5,
        color: AppColors.whiteColor,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cB1BCFB.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.whiteColor.withValues(alpha: 0.2)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cB1BCFB.withValues(alpha: 0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.outlineColor),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.outlineColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.cFCFAFE, width: 1.4),
      ),
      hintStyle: const TextStyle(
        fontFamily: AppTypography.primaryFontFamily,
        color: AppColors.cDBE7FE,
      ),
      labelStyle: const TextStyle(
        fontFamily: AppTypography.primaryFontFamily,
        color: AppColors.cDBE7FE,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.c292929,
      contentTextStyle: TextStyle(
        fontFamily: AppTypography.primaryFontFamily,
        color: AppColors.cFCFAFE,
      ),
    ),
    dividerColor: AppColors.whiteColor.withValues(alpha: 0.2),
  );

  static final ThemeData dark = light.copyWith(brightness: Brightness.dark);
}
