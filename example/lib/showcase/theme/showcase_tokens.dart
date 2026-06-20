import 'package:flutter/material.dart';

/// Color tokens for the showcase, resolved per [Brightness].
///
/// The dark palette is the editor-native default (GitHub-dark inspired); the
/// light palette is the bright counterpart. Accent stops are shared so the
/// signature gradient reads the same in both modes.
@immutable
class ShowcaseColors {
  const ShowcaseColors({
    required this.brightness,
    required this.page,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textFaint,
  });

  final Brightness brightness;
  final Color page;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textFaint;

  /// Shared accent stops used by [accentGradient] and accent fills.
  static const Color accentBlue = Color(0xFF0098FF);
  static const Color accentCyan = Color(0xFF00D8FF);
  static const Color accentIndigo = Color(0xFF6E5BFF);

  static const ShowcaseColors dark = ShowcaseColors(
    brightness: Brightness.dark,
    page: Color(0xFF0D1117),
    surface: Color(0xFF161B22),
    surfaceAlt: Color(0xFF1C2230),
    border: Color(0xFF30363D),
    textPrimary: Color(0xFFE6EDF3),
    textSecondary: Color(0xFF8B949E),
    textFaint: Color(0xFF6E7681),
  );

  static const ShowcaseColors light = ShowcaseColors(
    brightness: Brightness.light,
    page: Color(0xFFFFFFFF),
    surface: Color(0xFFF6F8FA),
    surfaceAlt: Color(0xFFEDF1F5),
    border: Color(0xFFD0D7DE),
    textPrimary: Color(0xFF1F2328),
    textSecondary: Color(0xFF656D76),
    textFaint: Color(0xFF8C959F),
  );

  static ShowcaseColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// A translucent accent wash for hover/active chip backgrounds.
  Color get accentWash => ShowcaseColors.accentBlue.withValues(alpha: 0.14);
}

/// Resolves the active [ShowcaseColors] from the ambient [Theme] brightness.
extension ShowcaseColorsX on BuildContext {
  ShowcaseColors get showcaseColors =>
      ShowcaseColors.of(Theme.of(this).brightness);
}

/// The signature accent gradient (blue -> cyan -> indigo).
const LinearGradient accentGradient = LinearGradient(
  colors: [
    ShowcaseColors.accentBlue,
    ShowcaseColors.accentCyan,
    ShowcaseColors.accentIndigo,
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Spacing scale (px).
abstract final class Insets {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;
  static const double xxl = 64;
  static const double section = 96;
}

/// Corner radii (px).
abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double pill = 999;
}

/// Responsive breakpoints and content width.
abstract final class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double maxContent = 1120;

  static bool isMobile(double width) => width < tablet;
  static bool isTablet(double width) => width >= tablet && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
}
