import 'package:flutter/material.dart';

import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';

/// Visual variants for [GradientButton].
enum GradientButtonVariant { filled, outline, ghost }

/// The primary call-to-action button.
///
/// [GradientButtonVariant.filled] paints the signature accent gradient;
/// [GradientButtonVariant.outline] and [ghost] are lower-emphasis siblings.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GradientButtonVariant.filled,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final GradientButtonVariant variant;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    final filled = widget.variant == GradientButtonVariant.filled;
    final outline = widget.variant == GradientButtonVariant.outline;

    final Color fg = filled
        ? Colors.white
        : outline
        ? c.textPrimary
        : c.textSecondary;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: Insets.sm),
        ],
        Text(widget.label, style: ShowcaseText.button.copyWith(color: fg)),
      ],
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            gradient: filled ? accentGradient : null,
            color: filled
                ? null
                : outline
                ? Colors.transparent
                : (_hovered ? c.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(Radii.md),
            border: outline ? Border.all(color: c.border) : null,
            boxShadow: filled && _hovered
                ? [
                    BoxShadow(
                      color: ShowcaseColors.accentBlue.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: content,
        ),
      ),
    );
  }
}
