import 'package:flutter/material.dart';

/// UI font family (bundled variable font).
const String kSansFamily = 'Inter';

/// Monospace font family (bundled variable font), for code and labels.
const String kMonoFamily = 'JetBrains Mono';

/// Text styles for the showcase. Styles are color-agnostic; apply color with
/// `.copyWith(color: ...)` from [ShowcaseColors] at the use site.
///
/// Both families are variable fonts, so weight is driven by a `wght`
/// [FontVariation] (with [FontWeight] set too as a graceful fallback).
abstract final class ShowcaseText {
  static TextStyle get displayXl =>
      _style(kSansFamily, 56, 800, height: 1.04, spacing: -1.6);
  static TextStyle get display =>
      _style(kSansFamily, 42, 800, height: 1.08, spacing: -1.0);
  static TextStyle get h1 =>
      _style(kSansFamily, 30, 700, height: 1.15, spacing: -0.5);
  static TextStyle get h2 =>
      _style(kSansFamily, 23, 700, height: 1.2, spacing: -0.3);
  static TextStyle get h3 => _style(kSansFamily, 18, 600, height: 1.3);
  static TextStyle get bodyLg => _style(kSansFamily, 18, 400, height: 1.55);
  static TextStyle get body => _style(kSansFamily, 15, 400, height: 1.55);
  static TextStyle get small => _style(kSansFamily, 13, 500, height: 1.45);
  static TextStyle get label =>
      _style(kSansFamily, 12, 600, height: 1.2, spacing: 0.3);
  static TextStyle get eyebrow =>
      _style(kSansFamily, 12.5, 600, height: 1.2, spacing: 0.6);
  static TextStyle get button => _style(kSansFamily, 14.5, 600, height: 1.1);

  static TextStyle get mono => _style(kMonoFamily, 13.5, 400, height: 1.55);
  static TextStyle get monoSm => _style(kMonoFamily, 12.5, 400, height: 1.5);
  static TextStyle get monoLabel =>
      _style(kMonoFamily, 12, 500, height: 1.2, spacing: 0.2);
}

TextStyle _style(
  String family,
  double size,
  int weight, {
  double? height,
  double? spacing,
}) {
  return TextStyle(
    fontFamily: family,
    fontSize: size,
    height: height,
    letterSpacing: spacing,
    fontWeight: _nearestWeight(weight),
    fontVariations: [FontVariation('wght', weight.toDouble())],
  );
}

FontWeight _nearestWeight(int weight) {
  final index = (weight ~/ 100 - 1).clamp(0, FontWeight.values.length - 1);
  return FontWeight.values[index];
}
