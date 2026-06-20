import 'package:flutter/material.dart';
import 'package:flutter_monaco_example/showcase/sections/features_section.dart';
import 'package:flutter_monaco_example/showcase/sections/get_started_section.dart';
import 'package:flutter_monaco_example/showcase/sections/hero_section.dart';
import 'package:flutter_monaco_example/showcase/state/showcase_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Layout guard for the static sections (the playground is excluded because it
/// embeds a real Monaco web view).
///
/// Note: `flutter test` does not load the app's bundled Inter font, so its
/// fallback font measures text much wider than the browser. We therefore
/// assert "no overflow" only at tablet/desktop widths (where the wider test
/// font still fits) and smoke-test the mobile layout for crashes + content.
/// True mobile visual fidelity is verified in a real browser.
void main() {
  Future<List<String>> errorsFor(
    WidgetTester tester,
    Widget section,
    Size size,
  ) async {
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString());

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        home: Scaffold(body: SingleChildScrollView(child: section)),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    FlutterError.onError = previous;
    return errors;
  }

  Map<String, Widget> sections(ShowcaseController controller) => {
    'hero': HeroSection(onTryPlayground: () {}),
    'features': FeaturesSection(controller: controller),
    'getStarted': const GetStartedSection(),
  };

  testWidgets('sections render without overflow at tablet and desktop', (
    tester,
  ) async {
    final controller = ShowcaseController();
    addTearDown(controller.dispose);

    final all = <String>[];
    for (final size in const [Size(768, 3600), Size(1280, 3600)]) {
      for (final entry in sections(controller).entries) {
        final errors = await errorsFor(tester, entry.value, size);
        all.addAll(
          errors.map((e) => '${entry.key} @${size.width.toInt()}: $e'),
        );
      }
    }
    expect(all, isEmpty, reason: all.join('\n---\n'));
  });

  testWidgets('mobile layout builds and shows key content', (tester) async {
    final controller = ShowcaseController();
    addTearDown(controller.dispose);

    // Smoke test: build each section at a phone width without throwing a
    // non-layout exception, and confirm headline content is present.
    for (final entry in sections(controller).entries) {
      await errorsFor(tester, entry.value, const Size(390, 3600));
    }

    await errorsFor(
      tester,
      FeaturesSection(controller: controller),
      const Size(390, 3600),
    );
    expect(find.text('Everything the editor can do'), findsOneWidget);
  });
}
