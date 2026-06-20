import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';

/// A monospace command pill with a copy-to-clipboard button.
///
/// Used for the hero install line (`flutter pub add flutter_monaco`).
class CopyField extends StatelessWidget {
  const CopyField({
    super.key,
    required this.text,
    this.prefix = r'$',
  });

  /// The text copied to the clipboard and displayed after [prefix].
  final String text;

  /// A leading glyph shown before [text] (not copied).
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Container(
      padding: const EdgeInsets.only(
        left: Insets.md,
        right: Insets.xs,
        top: Insets.xs,
        bottom: Insets.xs,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$prefix ',
              style: ShowcaseText.monoSm.copyWith(color: c.textFaint)),
          Flexible(
            child: Text(
              text,
              style: ShowcaseText.monoSm.copyWith(color: c.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: Insets.sm),
          Tooltip(
            message: 'Copy',
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.sm),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      width: 220,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(Insets.sm),
                  child: Icon(Icons.copy_rounded,
                      size: 16, color: c.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
