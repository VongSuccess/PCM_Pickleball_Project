import 'package:flutter/material.dart';

/// App Color System - Highland Fusion Theme
/// Inspired by Central Highlands (Tây Nguyên) - "Vợt Thủ Phố Núi"
class AppColors {
  // Primary Colors - Forest Green (60% - Màu chủ đạo)
  // Đại diện cho núi rừng Tây Nguyên, tạo cảm giác bền vững, sức khỏe
  static const Color primary = Color(0xFF064E3B);        // Forest Green
  static const Color primaryDark = Color(0xFF022C22);    // Darker Forest
  static const Color primaryLight = Color(0xFF047857);   // Light Forest
  
  // Accent Colors - Burnt Orange (10% - Màu nhấn)
  // Tượng trưng cho đất đỏ Bazan và sự nhiệt huyết
  static const Color accent = Color(0xFFF59E0B);         // Sunset Orange
  static const Color accentLight = Color(0xFFFBBF24);    // Light Orange
  static const Color accentDark = Color(0xFFD97706);     // Dark Orange
  
  // Background - Cream (30% - Màu phụ/nền)
  // Tạo cảm giác cao cấp, nhẹ nhàng
  static const Color cream = Color(0xFFFFFBEB);          // Cream
  static const Color creamDark = Color(0xFFFEF3C7);      // Dark Cream
  
  // Gradient Colors - Highland Inspired
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF064E3B), Color(0xFF047857)],     // Forest gradient
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],     // Orange gradient
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF064E3B),  // Forest Green
      Color(0xFF047857),  // Light Forest
      Color(0xFFF59E0B),  // Burnt Orange
    ],
  );
  
  // Status Colors - Highland themed
  static const Color success = Color(0xFF10B981);        // Emerald Green
  static const Color warning = Color(0xFFF59E0B);        // Same as accent
  static const Color error = Color(0xFFDC2626);          // Deep Red
  static const Color info = Color(0xFF3B82F6);           // Blue
  
  // Neutral Colors - Cream based
  static const Color background = Color(0xFFFFFBEB);     // Cream background
  static const Color surface = Color(0xFFFFFFFF);        // Pure white
  static const Color surfaceDark = Color(0xFF1C1917);    // Dark brown
  
  // Text Colors - High contrast for readability
  static const Color textPrimary = Color(0xFF1C1917);    // Almost black
  static const Color textSecondary = Color(0xFF78716C);  // Warm gray
  static const Color textHint = Color(0xFFA8A29E);       // Light warm gray
  static const Color textOnPrimary = Color(0xFFFFFFFF);  // White on green
  static const Color textOnAccent = Color(0xFF1C1917);   // Dark on orange
  
  // Custom Premium Sport Colors
  static const Color premiumGreen = Color(0xFF004D40);   // Deep Teal
  static const Color premiumLime = Color(0xFF00E676);    // Neon Lime
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF004D40), Color(0xFF00695C)],
  );
  
  // Dark Theme Colors (New UI)
  static const Color darkBackground = Color(0xFF0F172A); // Dark Slate
  static const Color darkSurface = Color(0xFF1E293B);    // Slightly lighter dark
  static const Color neonGreen = Color(0xFF00E676);      // Neon Green
  static const Color neonGreenDark = Color(0xFF00C853);
  
  // Shadow Colors
  static Color shadowLight = const Color(0xFF064E3B).withOpacity(0.1);
  static Color shadowMedium = const Color(0xFF064E3B).withOpacity(0.2);
  static Color shadowDark = const Color(0xFF064E3B).withOpacity(0.3);

  // ============================================
  // NEW DARK SPORT THEME (REDEFINED)
  // Background: #052011 (Dark Green Black)
  // Surface: #0B2818 (Card/Section Background)
  // Accent: #00FF85 (Neon Green)
  // Text: White (Primary), #8FAFA0 (Secondary)
  // ============================================
  static const Color darkSportBackground = Color(0xFF052011);
  static const Color darkSportSurface = Color(0xFF0B2818);
  static const Color darkSportAccent = Color(0xFF00FF85);
  static const Color darkSportTextSecondary = Color(0xFF8FAFA0);
  
  static const LinearGradient darkSportGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B2818), Color(0xFF0F3521)],
  );
}
