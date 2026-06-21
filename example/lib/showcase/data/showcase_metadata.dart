import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

import '../util/links.dart';

const String _packageName = 'flutter_monaco';
const String _repositoryPath = 'omar-hanafy/flutter_monaco';

class ShowcasePlatform {
  const ShowcasePlatform({required this.id, required this.label});

  final String id;
  final String label;

  static ShowcasePlatform fromId(String id) {
    final normalized = id.toLowerCase();
    return ShowcasePlatform(
      id: normalized,
      label: switch (normalized) {
        'ios' => 'iOS',
        'macos' => 'macOS',
        'android' => 'Android',
        'windows' => 'Windows',
        'web' => 'Web',
        'linux' => 'Linux',
        _ => id,
      },
    );
  }
}

class ShowcaseMetadata {
  const ShowcaseMetadata({
    required this.packageName,
    required this.version,
    required this.description,
    required this.pubDevUrl,
    required this.repositoryUrl,
    required this.apiDocsUrl,
    required this.issueUrl,
    required this.changelogUrl,
    required this.licenseUrl,
    required this.licenseLabel,
    required this.topics,
    required this.platforms,
    required this.sdkConstraint,
    required this.flutterConstraint,
    this.publishedAt,
    this.repositoryUpdatedAt,
    this.likeCount,
    this.downloadCount30Days,
    this.pubPointsGranted,
    this.pubPointsMax,
    this.starCount,
    this.forkCount,
    this.openIssueCount,
    this.hasLivePubDev = false,
    this.hasLiveGitHub = false,
  });

  static const fallback = ShowcaseMetadata(
    packageName: _packageName,
    version: '2.0.0',
    description:
        "Integrate Monaco Editor (VS Code's editor) in Flutter apps with "
        'syntax highlighting, themes, IntelliSense, and a full Dart API.',
    pubDevUrl: Links.pubDev,
    repositoryUrl: Links.github,
    apiDocsUrl: Links.apiDocs,
    issueUrl: Links.issues,
    changelogUrl: Links.changelog,
    licenseUrl: Links.license,
    licenseLabel: 'MIT',
    topics: ['vscode', 'monaco', 'editor', 'markdown', 'ide'],
    platforms: [
      ShowcasePlatform(id: 'android', label: 'Android'),
      ShowcasePlatform(id: 'ios', label: 'iOS'),
      ShowcasePlatform(id: 'macos', label: 'macOS'),
      ShowcasePlatform(id: 'windows', label: 'Windows'),
      ShowcasePlatform(id: 'web', label: 'Web'),
    ],
    sdkConstraint: '>=3.12.0 <4.0.0',
    flutterConstraint: '>=3.44.0',
  );

  final String packageName;
  final String version;
  final String description;
  final String pubDevUrl;
  final String repositoryUrl;
  final String apiDocsUrl;
  final String issueUrl;
  final String changelogUrl;
  final String licenseUrl;
  final String licenseLabel;
  final List<String> topics;
  final List<ShowcasePlatform> platforms;
  final String sdkConstraint;
  final String flutterConstraint;
  final DateTime? publishedAt;
  final DateTime? repositoryUpdatedAt;
  final int? likeCount;
  final int? downloadCount30Days;
  final int? pubPointsGranted;
  final int? pubPointsMax;
  final int? starCount;
  final int? forkCount;
  final int? openIssueCount;
  final bool hasLivePubDev;
  final bool hasLiveGitHub;

  int get typedLanguageCount => MonacoLanguage.values.length;
  int get builtInThemeCount => MonacoTheme.values.length;
  int get showcasedThemeCount => PlaygroundThemeCount.total;

  String get versionLabel => 'v$version';
  String get sourceLabel => hasLivePubDev ? 'Live pub.dev' : 'Bundled pubspec';

  String get platformSummary =>
      platforms.map((platform) => platform.label).join(', ');

  String get productSummary =>
      "Integrate Monaco Editor (VS Code's editor) in Flutter apps. "
      '$typedLanguageCount typed language entries, ${platforms.length} '
      'supported platforms, theming, IntelliSense, and a full Dart API.';

  String get publishedLabel {
    final date = publishedAt;
    if (date == null) return 'Bundled version';
    return 'Published ${formatShortDate(date)}';
  }

  String get updatedLabel {
    final date = repositoryUpdatedAt;
    if (date == null) return sourceLabel;
    return 'Updated ${formatShortDate(date)}';
  }

  String get scoreLabel {
    final granted = pubPointsGranted;
    final max = pubPointsMax;
    if (granted == null || max == null) return 'Pub points';
    return '$granted/$max pub points';
  }

  ShowcaseMetadata copyWith({
    String? packageName,
    String? version,
    String? description,
    String? pubDevUrl,
    String? repositoryUrl,
    String? apiDocsUrl,
    String? issueUrl,
    String? changelogUrl,
    String? licenseUrl,
    String? licenseLabel,
    List<String>? topics,
    List<ShowcasePlatform>? platforms,
    String? sdkConstraint,
    String? flutterConstraint,
    DateTime? publishedAt,
    DateTime? repositoryUpdatedAt,
    int? likeCount,
    int? downloadCount30Days,
    int? pubPointsGranted,
    int? pubPointsMax,
    int? starCount,
    int? forkCount,
    int? openIssueCount,
    bool? hasLivePubDev,
    bool? hasLiveGitHub,
  }) {
    return ShowcaseMetadata(
      packageName: packageName ?? this.packageName,
      version: version ?? this.version,
      description: description ?? this.description,
      pubDevUrl: pubDevUrl ?? this.pubDevUrl,
      repositoryUrl: repositoryUrl ?? this.repositoryUrl,
      apiDocsUrl: apiDocsUrl ?? this.apiDocsUrl,
      issueUrl: issueUrl ?? this.issueUrl,
      changelogUrl: changelogUrl ?? this.changelogUrl,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      licenseLabel: licenseLabel ?? this.licenseLabel,
      topics: topics ?? this.topics,
      platforms: platforms ?? this.platforms,
      sdkConstraint: sdkConstraint ?? this.sdkConstraint,
      flutterConstraint: flutterConstraint ?? this.flutterConstraint,
      publishedAt: publishedAt ?? this.publishedAt,
      repositoryUpdatedAt: repositoryUpdatedAt ?? this.repositoryUpdatedAt,
      likeCount: likeCount ?? this.likeCount,
      downloadCount30Days: downloadCount30Days ?? this.downloadCount30Days,
      pubPointsGranted: pubPointsGranted ?? this.pubPointsGranted,
      pubPointsMax: pubPointsMax ?? this.pubPointsMax,
      starCount: starCount ?? this.starCount,
      forkCount: forkCount ?? this.forkCount,
      openIssueCount: openIssueCount ?? this.openIssueCount,
      hasLivePubDev: hasLivePubDev ?? this.hasLivePubDev,
      hasLiveGitHub: hasLiveGitHub ?? this.hasLiveGitHub,
    );
  }
}

abstract final class PlaygroundThemeCount {
  static const int custom = 1;
  static int get total => MonacoTheme.values.length + custom;
}

class ShowcaseMetadataLoader {
  ShowcaseMetadataLoader({http.Client? client, AssetBundle? bundle})
    : _client = client ?? http.Client(),
      _bundle = bundle ?? rootBundle,
      _ownsClient = client == null;

  final http.Client _client;
  final AssetBundle _bundle;
  final bool _ownsClient;

  static final Uri _pubPackageUri = Uri.https(
    'pub.dev',
    '/api/packages/$_packageName',
  );
  static final Uri _pubScoreUri = Uri.https(
    'pub.dev',
    '/api/packages/$_packageName/score',
  );
  static final Uri _githubRepoUri = Uri.https(
    'api.github.com',
    '/repos/$_repositoryPath',
  );

  Future<ShowcaseMetadata> load() async {
    var metadata = await _loadBundledPubspec();
    metadata = await _mergePubDevPackage(metadata);
    metadata = await _mergePubDevScore(metadata);
    metadata = await _mergeGitHub(metadata);
    return metadata;
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }

  Future<ShowcaseMetadata> _loadBundledPubspec() async {
    try {
      final source = await _bundle.loadString(
        'packages/$_packageName/pubspec.yaml',
      );
      return parseShowcasePubspec(source);
    } catch (_) {
      return ShowcaseMetadata.fallback;
    }
  }

  Future<ShowcaseMetadata> _mergePubDevPackage(
    ShowcaseMetadata metadata,
  ) async {
    try {
      final response = await _client.get(_pubPackageUri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return metadata;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) return metadata;
      return parsePubDevPackage(decoded, base: metadata);
    } catch (_) {
      return metadata;
    }
  }

  Future<ShowcaseMetadata> _mergePubDevScore(ShowcaseMetadata metadata) async {
    try {
      final response = await _client.get(_pubScoreUri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return metadata;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) return metadata;
      return metadata.copyWith(
        likeCount: _int(decoded['likeCount']),
        downloadCount30Days: _int(decoded['downloadCount30Days']),
        pubPointsGranted: _int(decoded['grantedPoints']),
        pubPointsMax: _int(decoded['maxPoints']),
      );
    } catch (_) {
      return metadata;
    }
  }

  Future<ShowcaseMetadata> _mergeGitHub(ShowcaseMetadata metadata) async {
    try {
      final response = await _client.get(_githubRepoUri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return metadata;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) return metadata;
      final license = decoded['license'];
      return metadata.copyWith(
        repositoryUrl: _string(decoded['html_url']) ?? metadata.repositoryUrl,
        starCount: _int(decoded['stargazers_count']),
        forkCount: _int(decoded['forks_count']),
        openIssueCount: _int(decoded['open_issues_count']),
        repositoryUpdatedAt:
            _date(decoded['pushed_at']) ?? _date(decoded['updated_at']),
        licenseLabel: license is Map<String, Object?>
            ? _string(license['spdx_id']) ?? metadata.licenseLabel
            : metadata.licenseLabel,
        hasLiveGitHub: true,
      );
    } catch (_) {
      return metadata;
    }
  }
}

ShowcaseMetadata parseShowcasePubspec(
  String source, {
  ShowcaseMetadata base = ShowcaseMetadata.fallback,
}) {
  final decoded = loadYaml(source);
  if (decoded is! YamlMap) return base;
  return _metadataFromPubspecMap(decoded, base: base);
}

ShowcaseMetadata parsePubDevPackage(
  Map<String, Object?> packageJson, {
  ShowcaseMetadata base = ShowcaseMetadata.fallback,
}) {
  final latest = packageJson['latest'];
  if (latest is! Map<String, Object?>) return base;
  final pubspec = latest['pubspec'];
  final published = _date(latest['published']);
  final metadata = pubspec is Map
      ? _metadataFromPubspecMap(pubspec, base: base)
      : base;
  return metadata.copyWith(publishedAt: published, hasLivePubDev: true);
}

ShowcaseMetadata _metadataFromPubspecMap(
  Map pubspec, {
  required ShowcaseMetadata base,
}) {
  final packageName = _string(pubspec['name']) ?? base.packageName;
  final repository = _string(pubspec['repository']) ?? base.repositoryUrl;
  final environment = pubspec['environment'];

  return base.copyWith(
    packageName: packageName,
    version: _string(pubspec['version']) ?? base.version,
    description: _string(pubspec['description']) ?? base.description,
    pubDevUrl: 'https://pub.dev/packages/$packageName',
    repositoryUrl: repository,
    apiDocsUrl: 'https://pub.dev/documentation/$packageName/latest/',
    issueUrl: _string(pubspec['issue_tracker']) ?? '$repository/issues',
    changelogUrl: '$repository/blob/main/CHANGELOG.md',
    licenseUrl: '$repository/blob/main/LICENSE',
    topics: _stringList(pubspec['topics']) ?? base.topics,
    platforms: _platforms(pubspec['platforms']) ?? base.platforms,
    sdkConstraint: environment is Map
        ? _string(environment['sdk']) ?? base.sdkConstraint
        : base.sdkConstraint,
    flutterConstraint: environment is Map
        ? _string(environment['flutter']) ?? base.flutterConstraint
        : base.flutterConstraint,
  );
}

List<ShowcasePlatform>? _platforms(Object? value) {
  if (value is Map) {
    return value.keys
        .map((key) => key.toString())
        .where((key) => key.trim().isNotEmpty)
        .map(ShowcasePlatform.fromId)
        .toList();
  }
  return null;
}

List<String>? _stringList(Object? value) {
  if (value is Iterable) {
    return value.map((item) => item.toString()).toList();
  }
  return null;
}

String? _string(Object? value) => value is String ? value : null;

int? _int(Object? value) => value is int ? value : null;

DateTime? _date(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

String compactNumber(int value) {
  if (value < 1000) return '$value';
  final thousands = value / 1000;
  final text = thousands >= 10
      ? thousands.toStringAsFixed(0)
      : thousands.toStringAsFixed(1);
  return '${text.replaceAll(RegExp(r'\.0$'), '')}k';
}

String formatShortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = date.toLocal();
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}
