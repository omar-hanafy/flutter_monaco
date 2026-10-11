import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:material_ui/material_ui.dart';

/// Example demonstrating edge scroll handoff.
///
/// A documentation-style page hosts three editors inside one scrollable:
///
/// * a short editor whose content never scrolls, so every wheel tick over
///   it hands off to the page immediately;
/// * a long editor that consumes the wheel until it reaches its top or
///   bottom edge and only then lets the page continue scrolling;
/// * a control editor with handoff disabled, which traps the wheel the way
///   every release before 2.3.0 did.
///
/// The app bar toggles the feature live (exercising enable/disable without
/// reloading the editor), the experimental touch source, and
/// `scrollBeyondLastLine` (whose blank space counts as editor-scrollable).
///
/// Run with: flutter run -t lib/scroll_handoff_example.dart
void main() {
  runApp(const ScrollHandoffExampleApp());
}

/// Root widget for the scroll handoff example.
class ScrollHandoffExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ScrollHandoffExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monaco Edge Scroll Handoff',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const ScrollHandoffExamplePage(),
    );
  }
}

/// The demo page.
class ScrollHandoffExamplePage extends StatefulWidget {
  /// Creates the demo page.
  const ScrollHandoffExamplePage({super.key});

  @override
  State<ScrollHandoffExamplePage> createState() =>
      _ScrollHandoffExamplePageState();
}

class _ScrollHandoffExamplePageState extends State<ScrollHandoffExamplePage> {
  final ScrollController _pageScrollController = ScrollController();
  bool _handoffEnabled = true;
  bool _mobileTouch = false;
  bool _scrollBeyondLastLine = true;
  bool _continuousChaining = false;
  MonacoScrollHandoffDetails? _lastHandoff;

  static final String _shortSnippet = [
    "import 'package:flutter_monaco/flutter_monaco.dart';",
    '',
    '// This editor has nothing to scroll, so the page keeps',
    '// scrolling straight through it.',
    'const editor = MonacoEditor(',
    '  scrollHandoff: MonacoScrollHandoff.edge(),',
    ');',
  ].join('\n');

  static final String _longSnippet = List.generate(
    220,
    (index) =>
        'final step$index = process(input: $index); '
        '// line ${index + 1} of 220',
  ).join('\n');

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  MonacoScrollHandoff get _activeConfig {
    if (!_handoffEnabled) return const MonacoScrollHandoff.disabled();
    return MonacoScrollHandoff.edge(
      controller: _pageScrollController,
      mobileTouch: _mobileTouch,
      // newGestureOnly (default) absorbs a gesture's momentum at the
      // editor edge; continuous lets it spill into the page mid-gesture.
      policy: _continuousChaining
          ? MonacoScrollBoundaryPolicy.continuous
          : MonacoScrollBoundaryPolicy.newGestureOnly,
      onHandoff: (details) {
        // Observe only: returning false keeps the built-in page scrolling.
        if (_lastHandoff != details) {
          setState(() => _lastHandoff = details);
        }
        return false;
      },
    );
  }

  EditorOptions _options({required bool longContent}) {
    return EditorOptions(
      language: MonacoLanguage.dart,
      theme: Theme.of(context).brightness == Brightness.dark
          ? MonacoTheme.vsDark
          : MonacoTheme.vs,
      fontSize: 13,
      minimap: MonacoMinimapOptions(enabled: longContent),
      scrollBeyondLastLine: longContent && _scrollBeyondLastLine,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edge Scroll Handoff'),
        actions: [
          _ToggleAction(
            label: 'Handoff',
            value: _handoffEnabled,
            onChanged: (value) => setState(() => _handoffEnabled = value),
          ),
          _ToggleAction(
            label: 'Touch (experimental)',
            value: _mobileTouch,
            onChanged: _handoffEnabled
                ? (value) => setState(() => _mobileTouch = value)
                : null,
          ),
          _ToggleAction(
            label: 'Continuous chaining',
            value: _continuousChaining,
            onChanged: _handoffEnabled
                ? (value) => setState(() => _continuousChaining = value)
                : null,
          ),
          _ToggleAction(
            label: 'scrollBeyondLastLine',
            value: _scrollBeyondLastLine,
            onChanged: (value) => setState(() => _scrollBeyondLastLine = value),
          ),
        ],
      ),
      bottomNavigationBar: _HandoffReadout(details: _lastHandoff),
      body: Scrollbar(
        controller: _pageScrollController,
        child: SingleChildScrollView(
          controller: _pageScrollController,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionText(
                    title: 'A page that scrolls through its editors',
                    body:
                        'Scroll this page with the wheel or trackpad. With '
                        'handoff enabled, the pointer can stay over an '
                        'editor: Monaco scrolls while it has somewhere to '
                        'go, and the gesture that reaches its edge stops '
                        'there, momentum included. Start a new gesture at '
                        'the edge to continue into the page (or enable '
                        'continuous chaining to spill mid-gesture, the '
                        'pre-3.3 behavior). Reversing direction gives the '
                        'wheel back to the editor. Ctrl/meta wheel (zoom) '
                        'and Monaco popups are never handed off.',
                  ),
                  const SizedBox(height: 16),
                  _EditorCard(
                    label:
                        'Short editor: nothing to consume, page keeps '
                        'scrolling',
                    height: 180,
                    child: MonacoEditor(
                      initialText: _shortSnippet,
                      options: _options(longContent: false),
                      scrollHandoff: _activeConfig,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionText(
                    title: 'Long editor: scrolls itself first',
                    body:
                        'This one holds 220 lines. Wheel over it and it '
                        'consumes the input until the bottom (including '
                        'the scrollBeyondLastLine blank space when that '
                        'toggle is on), then the page takes over.',
                  ),
                  const SizedBox(height: 16),
                  _EditorCard(
                    label: 'Long editor with edge handoff',
                    height: 380,
                    child: MonacoEditor(
                      initialText: _longSnippet,
                      options: _options(longContent: true),
                      scrollHandoff: _activeConfig,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionText(
                    title: 'Control editor: handoff disabled',
                    body:
                        'This editor keeps the pre-2.3.0 behavior and traps '
                        'the wheel forever, so you can feel the difference. '
                        'Events from the other editors never leak here: '
                        'each editor routes through its own controller.',
                  ),
                  const SizedBox(height: 16),
                  _EditorCard(
                    label: 'Handoff always disabled',
                    height: 260,
                    child: MonacoEditor(
                      initialText: _longSnippet,
                      options: _options(longContent: true),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 500,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'End of page: room to prove the page really scrolled.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleAction extends StatelessWidget {
  const _ToggleAction({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SectionText extends StatelessWidget {
  const _SectionText({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(body, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({
    required this.label,
    required this.height,
    required this.child,
  });

  final String label;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _HandoffReadout extends StatelessWidget {
  const _HandoffReadout({required this.details});

  final MonacoScrollHandoffDetails? details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = details;
    final text = current == null
        ? 'No handoff yet: scroll with the pointer over an enabled editor.'
        : 'Last handoff: ${current.source.name} '
              'deltaY ${current.deltaY.toStringAsFixed(1)} '
              '(atTop: ${current.atTop}, atBottom: ${current.atBottom})';
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(text, style: theme.textTheme.bodySmall),
      ),
    );
  }
}
