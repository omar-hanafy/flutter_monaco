import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

import 'sections/features_section.dart';
import 'sections/get_started_section.dart';
import 'sections/hero_section.dart';
import 'sections/playground_section.dart';
import 'sections/site_footer.dart';
import 'sections/site_nav.dart';
import 'state/showcase_controller.dart';
import 'theme/showcase_text.dart';
import 'theme/showcase_tokens.dart';

/// Root of the showcase: owns the [ShowcaseController], the scroll/section
/// wiring, and the light/dark [MaterialApp] theme.
class ShowcaseApp extends StatefulWidget {
  const ShowcaseApp({super.key});

  @override
  State<ShowcaseApp> createState() => _ShowcaseAppState();
}

class _ShowcaseAppState extends State<ShowcaseApp> {
  final ShowcaseController _controller = ShowcaseController();
  final MonacoRouteObserver _routeObserver = MonacoRouteObserver();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _playgroundKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller.onRequestScrollToPlayground = () => _scrollTo(_playgroundKey);
    unawaited(_controller.loadMetadata());
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isDark = _controller.brightness == Brightness.dark;
        final metadata = _controller.metadata;
        return MaterialApp(
          title: "flutter_monaco - VS Code's editor in Flutter",
          debugShowCheckedModeBanner: false,
          navigatorObservers: [_routeObserver],
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: Scaffold(
            body: Column(
              children: [
                SiteNav(
                  controller: _controller,
                  onTapFeatures: () => _scrollTo(_featuresKey),
                  onTapPlayground: () => _scrollTo(_playgroundKey),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        HeroSection(
                          metadata: metadata,
                          onTryPlayground: () => _scrollTo(_playgroundKey),
                        ),
                        PlaygroundSection(
                          key: _playgroundKey,
                          controller: _controller,
                          routeObserver: _routeObserver,
                        ),
                        FeaturesSection(
                          key: _featuresKey,
                          controller: _controller,
                          metadata: metadata,
                        ),
                        GetStartedSection(metadata: metadata),
                        SiteFooter(metadata: metadata),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ThemeData _theme(Brightness brightness) {
    final colors = ShowcaseColors.of(brightness);
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: colors.page,
      canvasColor: colors.surface,
      dividerColor: colors.border,
      colorScheme: base.colorScheme.copyWith(
        primary: ShowcaseColors.accentBlue,
        surface: colors.surface,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: kSansFamily,
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),
    );
  }
}
