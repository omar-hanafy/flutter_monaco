import 'package:flutter/material.dart';

import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';

/// A single feature card: gradient icon chip, title, body, optional inline
/// snippet, and an optional "Try it" action that drives the playground.
class FeatureCard extends StatefulWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.snippet,
    this.onTry,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? snippet;
  final VoidCallback? onTry;

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(Insets.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(
            color: _hovered
                ? ShowcaseColors.accentBlue.withValues(alpha: 0.5)
                : c.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: accentGradient,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Icon(widget.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: Insets.md),
            Text(
              widget.title,
              style: ShowcaseText.h3.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: Insets.sm),
            Text(
              widget.body,
              style: ShowcaseText.body.copyWith(color: c.textSecondary),
            ),
            if (widget.snippet != null) ...[
              const SizedBox(height: Insets.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.md,
                  vertical: Insets.sm,
                ),
                decoration: BoxDecoration(
                  color: c.page,
                  borderRadius: BorderRadius.circular(Radii.sm),
                  border: Border.all(color: c.border),
                ),
                child: Text(
                  widget.snippet!,
                  style: ShowcaseText.monoSm.copyWith(color: c.textSecondary),
                ),
              ),
            ],
            if (widget.onTry != null) ...[
              const SizedBox(height: Insets.md),
              _TryLink(onTap: widget.onTry!),
            ],
          ],
        ),
      ),
    );
  }
}

class _TryLink extends StatelessWidget {
  const _TryLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Try it',
              style: ShowcaseText.small.copyWith(
                color: ShowcaseColors.accentBlue,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward,
              size: 15,
              color: ShowcaseColors.accentBlue,
            ),
          ],
        ),
      ),
    );
  }
}
