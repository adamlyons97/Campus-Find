import 'package:flutter/material.dart';

/// Centralised theming for CampusFind.
///
/// A clean, modern identity: a confident royal blue for primary actions and
/// "found" items, a warm red for "lost", crisp white surfaces and soft
/// tinted cards. Member names are kept stable so existing screens that
/// reference [AppTheme.primary], [AppTheme.danger] etc. keep working.
class AppTheme {
  AppTheme._();

  // ---- Brand palette ----
  static const Color primary = Color(0xFF2D5BE8); // royal blue
  static const Color primaryLight = Color(0xFF5B82F0);
  static const Color accent = Color(0xFF2D5BE8);

  // Semantic
  static const Color lost = Color(0xFFEF4444); // red
  static const Color found = Color(0xFF2D5BE8); // blue
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFE0820B);
  static const Color success = Color(0xFF16A34A);

  // Neutrals / surfaces
  static const Color scaffold = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F7FC); // soft section background
  static const Color cardBg = Color(0xFFF6F8FD);
  static const Color cardBorder = Color(0xFFE9EEF7);
  static const Color tintBlue = Color(0xFFEAF0FF); // browse-catalog card
  static const Color fieldFill = Color(0xFFF3F5FA);

  // Text
  static const Color textDark = Color(0xFF131A2E);
  static const Color textMuted = Color(0xFF7C8499);

  // ---- Badge helpers ----
  static Color badgeBg(String typeOrStatus) {
    switch (typeOrStatus) {
      case 'found':
        return const Color(0xFFE7EDFF);
      case 'resolved':
      case 'returned':
        return const Color(0xFFE3F6EA);
      case 'lost':
      default:
        return const Color(0xFFFDE6E6);
    }
  }

  static Color badgeFg(String typeOrStatus) {
    switch (typeOrStatus) {
      case 'found':
        return primary;
      case 'resolved':
      case 'returned':
        return success;
      case 'lost':
      default:
        return danger;
    }
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: scaffold,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: base.textTheme.apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: textDark,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        hintStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        labelStyle: const TextStyle(color: textDark),
        side: BorderSide.none,
      ),
    );
  }
}

/// Small uppercase, letter-spaced blue label used above sections and fields.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color ?? AppTheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}

/// The little "••• CampusFind" brand marker shown top-right on main screens.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('•••',
            style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
        SizedBox(width: 6),
        Text('CampusFind',
            style: TextStyle(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2)),
      ],
    );
  }
}
