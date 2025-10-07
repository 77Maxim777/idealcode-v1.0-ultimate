import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_constants.dart';

/// Определение тем приложения (light/dark)
/// Использует Material 3 с кастомными цветами
class AppTheme {
  /// Светлая тема
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.light,
      secondary: AppConstants.secondaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      textTheme: GoogleFonts.robotoTextTheme(ThemeData(brightness: Brightness.light).textTheme).copyWith(
        headlineMedium: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.roboto(fontWeight: FontWeight.w600),
        bodyMedium: GoogleFonts.roboto(),
        bodySmall: GoogleFonts.roboto(fontSize: 12),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 20,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 4,
      ),
      // Кастомные цвета для холста
      extensions: <ThemeExtension<dynamic>>[
        CanvasTheme(
          itemShadow: BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          connectionLineColor: colorScheme.primary,
        ),
      ],
    );
  }

  /// Темная тема
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.dark,
      secondary: AppConstants.secondaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      cardTheme: CardTheme(
        color: colorScheme.surfaceVariant,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: colorScheme.outline),
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: colorScheme.surfaceVariant,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        tileColor: colorScheme.surfaceVariant,
      ),
      textTheme: GoogleFonts.robotoTextTheme(ThemeData(brightness: Brightness.dark).textTheme).copyWith(
        headlineMedium: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: GoogleFonts.roboto(fontWeight: FontWeight.w600, color: Colors.white),
        bodyMedium: GoogleFonts.roboto(color: Colors.white70),
        bodySmall: GoogleFonts.roboto(fontSize: 12, color: Colors.white54),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 4,
      ),
      extensions: <ThemeExtension<dynamic>>[
        CanvasTheme(
          itemShadow: BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          connectionLineColor: colorScheme.primary,
        ),
      ],
    );
  }
}

/// Кастомная тема для холста (расширение ThemeExtension)
class CanvasTheme extends ThemeExtension<CanvasTheme> {
  const CanvasTheme({
    required this.itemShadow,
    required this.connectionLineColor,
  });

  final BoxShadow itemShadow;
  final Color connectionLineColor;

  @override
  CanvasTheme copyWith({
    BoxShadow? itemShadow,
    Color? connectionLineColor,
  }) {
    return CanvasTheme(
      itemShadow: itemShadow ?? this.itemShadow,
      connectionLineColor: connectionLineColor ?? this.connectionLineColor,
    );
  }

  @override
  CanvasTheme lerp(CanvasTheme? other, double t) {
    if (other == null) return this;
    return CanvasTheme(
      itemShadow: BoxShadow.lerp(itemShadow, other.itemShadow, t) ?? itemShadow,
      connectionLineColor: Color.lerp(connectionLineColor, other.connectionLineColor, t) ?? connectionLineColor,
    );
  }
}

/// Расширение для удобства
extension CanvasThemeExtension on BuildContext {
  CanvasTheme get canvasTheme => Theme.of(this).extension<CanvasTheme>() ?? const CanvasTheme(
    itemShadow: BoxShadow(),
    connectionLineColor: Colors.blue,
  );
}
