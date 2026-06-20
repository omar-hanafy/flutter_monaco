import 'package:flutter/material.dart';

import '../theme/showcase_tokens.dart';

/// Centers content to [maxWidth] and applies responsive horizontal padding.
///
/// Used to wrap every page section so they share a consistent reading width
/// and gutters across breakpoints.
class SectionContainer extends StatelessWidget {
  const SectionContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContent,
    this.verticalPadding = Insets.section,
    this.background,
  });

  final Widget child;
  final double maxWidth;
  final double verticalPadding;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = Breakpoints.isMobile(width)
        ? Insets.lg
        : Breakpoints.isTablet(width)
        ? Insets.xl
        : Insets.xxl;
    final vertical = Breakpoints.isMobile(width)
        ? verticalPadding * 0.55
        : verticalPadding;

    return Container(
      width: double.infinity,
      color: background,
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
