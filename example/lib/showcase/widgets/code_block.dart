import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';

/// A styled, static code snippet (not a Monaco instance) with an optional
/// filename header and a copy button. Keeps the page to a single live editor.
class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.code, this.filename});

  final String code;
  final String? filename;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    final trimmed = code.trim();
    return Container(
      decoration: BoxDecoration(
        color: c.brightness == Brightness.dark
            ? const Color(0xFF0B0E14)
            : const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              Insets.md,
              Insets.sm,
              Insets.sm,
              Insets.sm,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F56)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF27C93F)),
                const SizedBox(width: Insets.md),
                if (filename != null)
                  Text(
                    filename!,
                    style: ShowcaseText.monoLabel.copyWith(color: c.textFaint),
                  ),
                const Spacer(),
                Tooltip(
                  message: 'Copy',
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: trimmed));
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
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 15,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(Insets.md),
            child: SelectableText(
              trimmed,
              style: ShowcaseText.monoSm.copyWith(color: c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 11,
    height: 11,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
