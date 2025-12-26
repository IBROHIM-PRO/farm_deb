import 'package:flutter/material.dart';

class AppTheme {
  // Color palette inspired by the Limitless template
  static const Color primaryBlue = Color(0xFF2c3e50);
  static const Color primaryIndigo = Color(0xFF3F51B5);
  static const Color accentBlue = Color(0xFF3498db);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color dangerRed = Color(0xFFE53935);
  static const Color infoTeal = Color(0xFF00ACC1);
  
  // Background colors
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Text colors
  static const Color textPrimary = Color(0xFF2c3e50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textMuted = Color(0xFFBDC3C7);

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryIndigo,
        brightness: Brightness.light,
        primary: primaryIndigo,
        secondary: accentBlue,
        surface: cardBackground,
        error: dangerRed,
      ),
      
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryIndigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryIndigo,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 8,
        backgroundColor: Colors.white,
        indicatorColor: primaryIndigo.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
      
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textMuted,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryIndigo,
        brightness: Brightness.dark,
        primary: accentBlue,
        secondary: primaryIndigo,
        surface: const Color(0xFF2D2D2D),
      ),
      
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Gradient decorations
  static BoxDecoration primaryGradientDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryIndigo,
          accentBlue,
        ],
      ),
      borderRadius: BorderRadius.circular(12),
    );
  }

  static BoxDecoration successGradientDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          successGreen,
          successGreen.withOpacity(0.7),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
    );
  }

  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Icon background colors
  static Color getIconBackgroundColor(String category) {
    switch (category) {
      case 'debt':
        return const Color(0xFFE3F2FD); // Blue
      case 'cotton':
        return const Color(0xFFE8F5E9); // Green
      case 'cattle':
        return const Color(0xFFFFF3E0); // Orange
      case 'report':
        return const Color(0xFFF3E5F5); // Purple
      case 'stock':
        return const Color(0xFFE0F2F1); // Teal
      default:
        return const Color(0xFFF5F5F5); // Grey
    }
  }

  static Color getIconColor(String category) {
    switch (category) {
      case 'debt':
        return const Color(0xFF1976D2);
      case 'cotton':
        return const Color(0xFF388E3C);
      case 'cattle':
        return const Color(0xFFF57C00);
      case 'report':
        return const Color(0xFF7B1FA2);
      case 'stock':
        return const Color(0xFF00796B);
      default:
        return textPrimary;
    }
  }
}
