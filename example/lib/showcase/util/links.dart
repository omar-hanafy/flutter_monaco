import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// External destinations referenced across the showcase.
abstract final class Links {
  static const String pubDev = 'https://pub.dev/packages/flutter_monaco';
  static const String github = 'https://github.com/omar-hanafy/flutter_monaco';
  static const String apiDocs =
      'https://pub.dev/documentation/flutter_monaco/latest/';
  static const String issues =
      'https://github.com/omar-hanafy/flutter_monaco/issues';
  static const String changelog =
      'https://github.com/omar-hanafy/flutter_monaco/blob/main/CHANGELOG.md';
  static const String license =
      'https://github.com/omar-hanafy/flutter_monaco/blob/main/LICENSE';
  static const String portfolio = 'https://omar-hanafy.github.io';
  static const String buyMeACoffee = 'https://www.buymeacoffee.com/omar.hanafy';
}

/// Opens [url] in a new tab/external app, swallowing failures.
Future<void> openUrl(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('[showcase] could not launch $url: $e');
  }
}
