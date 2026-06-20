import 'package:flutter/material.dart';

import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';
import '../util/links.dart';
import '../widgets/code_block.dart';
import '../widgets/copy_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/section_container.dart';

const String _widgetSnippet = '''
MonacoEditor(
  options: EditorOptions(
    language: MonacoLanguage.dart,
    theme: MonacoTheme.vsDark,
  ),
)''';

const String _controllerSnippet = '''
MonacoEditor(
  onReady: (controller) async {
    await controller.setValue('void main() {}');
    final code = await controller.getValue();
  },
)''';

/// "Get started in seconds" - three numbered steps with copyable code.
class GetStartedSection extends StatelessWidget {
  const GetStartedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get started in seconds',
            style: ShowcaseText.h1.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: Insets.md),
          Text(
            'Add the package, drop in the widget, and you have a working '
            'editor.',
            style: ShowcaseText.bodyLg.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: Insets.xl),
          const _Step(
            number: 1,
            title: 'Add the dependency',
            child: CopyField(text: 'flutter pub add flutter_monaco'),
          ),
          const _Step(
            number: 2,
            title: 'Drop in the widget',
            child: CodeBlock(code: _widgetSnippet, filename: 'editor.dart'),
          ),
          const _Step(
            number: 3,
            title: 'Grab the controller for full control',
            isLast: true,
            child: CodeBlock(code: _controllerSnippet, filename: 'editor.dart'),
          ),
          const SizedBox(height: Insets.sm),
          GradientButton(
            label: 'Read the docs',
            icon: Icons.menu_book_outlined,
            variant: GradientButtonVariant.outline,
            onPressed: () => openUrl(Links.apiDocs),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.child,
    this.isLast = false,
  });

  final int number;
  final String title;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: accentGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: ShowcaseText.label.copyWith(color: Colors.white),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: c.border)),
            ],
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Insets.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: Insets.md),
                    child: Text(
                      title,
                      style: ShowcaseText.h3.copyWith(color: c.textPrimary),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
