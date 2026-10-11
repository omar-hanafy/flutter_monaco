import 'package:material_ui/material_ui.dart';

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
    this.dense = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final GradientButtonVariant variant;

  /// A tighter size for use inside chrome like the top nav, where the default
  /// hero-scale button would dominate the row.
  final bool dense;

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

    final dense = widget.dense;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: dense ? 16 : 18, color: fg),
          SizedBox(width: dense ? Insets.xs : Insets.sm),
        ],
        Text(
          widget.label,
          style: (dense ? ShowcaseText.small : ShowcaseText.button).copyWith(
            color: fg,
          ),
        ),
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
          transform: Matrix4.translationValues(
            0,
            _hovered ? (dense ? -1 : -2) : 0,
            0,
          ),
          padding: dense
              ? const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: 14),
          decoration: BoxDecoration(
            gradient: filled ? accentGradient : null,
            color: filled
                ? null
                : outline
                ? Colors.transparent
                : (_hovered ? c.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(dense ? Radii.sm : Radii.md),
            border: outline ? Border.all(color: c.border) : null,
            boxShadow: filled && _hovered
                ? [
                    BoxShadow(
                      color: ShowcaseColors.accentBlue.withValues(alpha: 0.35),
                      blurRadius: dense ? 16 : 24,
                      offset: Offset(0, dense ? 5 : 8),
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
