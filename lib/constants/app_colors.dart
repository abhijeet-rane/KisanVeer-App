import 'package:flutter/material.dart';

/// App color constants for KisanVeer
class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF0E7C3F);      // Deep Green
  static const Color primaryLight = Color(0xFF4CAF50); // Light Green
  static const Color secondary = Color(0xFFFF7A00);    // Orange
  static const Color accent = Color(0xFFFFC107);       // Amber/Yellow
  
  // Neutrals
  static const Color background = Color(0xFFF9F9F9);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF212121);  // Nearly black
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  
  // Feedback colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF2196F3);
  
  // Additional colors
  static const Color cropHealthy = Color(0xFF4CAF50);
  static const Color cropWarning = Color(0xFFFFEB3B);
  static const Color cropDanger = Color(0xFFFF5252);
  
  // Gradient colors
  static const List<Color> greenGradient = [
    Color(0xFF0E7C3F),
    Color(0xFF4CAF50),
  ];
  
  static const List<Color> orangeGradient = [
    Color(0xFFFF7A00),
    Color(0xFFFFA726),
  ];
}
