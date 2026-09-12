import 'package:flutter/material.dart';

/// Palet Smart Kantin Kampus — Desain Modern
/// Green-to-teal gradient sebagai identitas utama kantin kampus.
/// Warna hangat (amber/oranye) untuk aksen makanan & promo.
/// Netral hangat untuk background agar terasa appetizing.
class AppColors {
  // ── Primary: Hijau kantin (teal-ish green yang cerah & modern) ──
  static const primary = Color(0xFF16A34A);
  static const primaryLight = Color(0xFF4ADE80);
  static const primaryDark = Color(0xFF15803D);
  static const primaryContainer = Color(0xFFBBF7D0);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF064E2A);

  // ── Secondary: Teal / Cyan untuk aksen pelengkap ──
  static const secondary = Color(0xFF0D9488);
  static const secondaryContainer = Color(0xFFCCFBF1);
  static const onSecondaryContainer = Color(0xFF064E3B);

  // ── Tertiary: Amber/Orange untuk promo & highlight ──
  static const tertiary = Color(0xFFF59E0B);
  static const tertiaryContainer = Color(0xFFFEF3C7);
  static const onTertiary = Color(0xFF78350F);

  // ── Error / Danger ──
  static const error = Color(0xFFDC2626);
  static const errorContainer = Color(0xFFFEE2E2);
  static const onError = Color(0xFFFFFFFF);
  static const onErrorContainer = Color(0xFF7F1D1D);

  // ── Surface & Background: Hangat, bersih, appetizing ──
  static const background = Color(0xFFFAFAF9);
  static const surface = Color(0xFFFAFAF9);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F5F4);

  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFFAFAF9);
  static const surfaceContainer = Color(0xFFF5F5F4);
  static const surfaceContainerHigh = Color(0xFFE7E5E4);
  static const surfaceContainerHighest = Color(0xFFD6D3D1);

  // ── Outline & Border ──
  static const outline = Color(0xFF78716C);
  static const outlineVariant = Color(0xFFE7E5E4);

  // ── On-surface text ──
  static const onSurface = Color(0xFF1C1917);
  static const onSurfaceVariant = Color(0xFF57534E);
  static const onSurfaceMuted = Color(0xFF8A857E);

  // ── Aksen khusus untuk brand & fitur ──
  // SISTEM 2 WARNA: Hijau-Teal (identitas) + Amber-Orange (makanan/promo).
  static const mint = Color(0xFFD1FAE5);
  static const amber = Color(0xFFFBBF24);
  static const blue = Color(0xFF2DD4BF);
  static const blueLight = Color(0xFFCCFBF1);
  static const purple = Color(0xFFF59E0B);
  static const purpleLight = Color(0xFFFEF3C7);
  static const rose = Color(0xFFF97316);
  static const roseLight = Color(0xFFFFEDD5);
  static const yellow = Color(0xFFF59E0B);
  static const accentOrange = Color(0xFFF97316);

  // ── Gradient constants (maksimal 2 warna) ──
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
  );

  // Header hero / splash memakai gradasi brand 2 warna.
  static const gradientHero = gradientPrimary;
  static const gradientSplash = gradientPrimary;

  // Warna hangat untuk promo/diskon — cukup 2 warna (amber → orange).
  static const gradientWarm = gradientAccent;
  static const gradientPromo = gradientAccent;

  static const gradientBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF0FDF4), Color(0xFFFAFAF9)],
  );

  static const gradientSoftGreen = LinearGradient(
    colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
  );
}

class AppTheme {
  // ═══════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════════
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryContainer,
      tertiary: AppColors.tertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      surface: AppColors.surface,
      error: AppColors.error,
      errorContainer: AppColors.errorContainer,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      // ── AppBar ──
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      // ── Card: elegan, border halus, shadow lembut ──
      cardTheme: CardTheme(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      // ── Elevated Button: solid green modern ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.surfaceContainerHigh,
          disabledForegroundColor: AppColors.onSurfaceMuted,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shadowColor: AppColors.primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // ── Text Button ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // ── Bottom Navigation Bar ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      // ── Navigation Bar (Material 3) ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryDark, size: 24);
          }
          return const IconThemeData(color: AppColors.onSurfaceMuted, size: 24);
        }),
      ),
      // ── Chip: modern pill ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        selectedColor: AppColors.primaryContainer,
        disabledColor: AppColors.surfaceContainer,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        showCheckmark: false,
      ),
      // ── Dialog ──
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      // ── Bottom Sheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.outlineVariant,
      ),
      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.onSurface,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      // ── Tab Bar ──
      tabBarTheme: const TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceMuted,
        indicatorColor: AppColors.primary,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      // ── Splash Theme ──
      splashColor: AppColors.primary.withOpacity(0.08),
      highlightColor: AppColors.primary.withOpacity(0.04),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════════════
  static const _darkOnSurfaceDark = Color(0xFFE7E5E4);
  static const _darkSurfaceDark = Color(0xFF171717);
  static const _darkSurfaceDarkBright = Color(0xFF1F1F1F);
  static const _darkSurfaceContainerDark = Color(0xFF262626);
  static const _darkOutlineVariantDark = Color(0xFF3F3F3F);
  static const _darkMuted = Color(0xFFA3A3A3);

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: const Color(0xFF052E16),
      primaryContainer: AppColors.primaryDark.withOpacity(0.35),
      onPrimaryContainer: AppColors.primaryContainer,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryContainer.withOpacity(0.2),
      tertiary: AppColors.tertiary,
      tertiaryContainer: AppColors.tertiaryContainer.withOpacity(0.2),
      surface: _darkSurfaceDark,
      error: const Color(0xFFF87171),
      errorContainer: const Color(0xFF450A0A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkSurfaceDark,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _darkOnSurfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _darkOnSurfaceDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardTheme(
        color: _darkSurfaceDarkBright,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _darkOutlineVariantDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceDarkBright,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: _darkMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkOutlineVariantDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkOutlineVariantDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF87171)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: const Color(0xFF052E16),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurfaceDarkBright,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: _darkMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkSurfaceDarkBright,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryDark.withOpacity(0.4),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryLight,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _darkMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryLight, size: 24);
          }
          return const IconThemeData(color: _darkMuted, size: 24);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurfaceDarkBright,
        selectedColor: AppColors.primaryDark.withOpacity(0.4),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _darkOnSurfaceDark),
        secondaryLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _darkOutlineVariantDark),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        showCheckmark: false,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: _darkSurfaceDarkBright,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurfaceDarkBright,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        showDragHandle: true,
        dragHandleColor: _darkOutlineVariantDark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurfaceContainerDark,
        contentTextStyle: const TextStyle(color: _darkOnSurfaceDark, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: _darkMuted,
        indicatorColor: AppColors.primaryLight,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      splashColor: AppColors.primary.withOpacity(0.1),
      highlightColor: AppColors.primary.withOpacity(0.05),
    );
  }
}
