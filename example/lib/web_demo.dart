import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final MonacoRouteObserver _webDemoRouteObserver = MonacoRouteObserver();

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter Monaco - Web Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      // Register the route observer to handle web overlays automatically
      navigatorObservers: [_webDemoRouteObserver],
      home: const WebDemo(),
    ),
  );
}

class WebDemo extends StatefulWidget {
  const WebDemo({super.key});

  @override
  State<WebDemo> createState() => _WebDemoState();
}

class _WebDemoState extends State<WebDemo> {
  MonacoController? _controller;
  bool _showOutput = true;

  // Editor state
  int _activeFileIndex = 0;
  MonacoTheme _currentTheme = MonacoTheme.vsDark;
  double _fontSize = 14.0;
  bool _minimap = true;
  bool _wordWrap = false;
  String _output = '';
  String _appVersion = 'v-';

  // Track content per file (to preserve edits when switching)
  final Map<int, String> _fileContents = {};

  // Sample files to showcase different languages
  final List<_SampleFile> _files = [
    const _SampleFile(
      name: 'main.dart',
      icon: Icons.flutter_dash,
      iconColor: Color(0xFF02569B),
      language: MonacoLanguage.dart,
      content: r'''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
''',
    ),
    const _SampleFile(
      name: 'api.ts',
      icon: Icons.code,
      iconColor: Color(0xFF3178C6),
      language: MonacoLanguage.typescript,
      content: r'''
interface User {
  id: string;
  name: string;
  email: string;
  createdAt: Date;
}

interface ApiResponse<T> {
  data: T;
  status: number;
  message: string;
}

class UserService {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  async getUser(id: string): Promise<ApiResponse<User>> {
    const response = await fetch(`${this.baseUrl}/users/${id}`);

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return response.json();
  }

  async createUser(user: Omit<User, 'id' | 'createdAt'>): Promise<ApiResponse<User>> {
    const response = await fetch(`${this.baseUrl}/users`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(user),
    });

    return response.json();
  }
}

// Usage example
const userService = new UserService('https://api.example.com');

async function main() {
  const user = await userService.getUser('123');
  console.log(user.data.name);
}
''',
    ),
    const _SampleFile(
      name: 'server.py',
      icon: Icons.terminal,
      iconColor: Color(0xFF3776AB),
      language: MonacoLanguage.python,
      content: r'''
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import uvicorn

app = FastAPI(title="Sample API", version="1.0.0")

class Item(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    is_available: bool = True

class ItemResponse(BaseModel):
    id: int
    item: Item
    created_at: datetime

# In-memory storage
items_db: dict[int, ItemResponse] = {}
next_id = 1

@app.get("/")
async def root():
    return {"message": "Welcome to the API", "docs": "/docs"}

@app.get("/items")
async def list_items():
    return {"items": list(items_db.values()), "count": len(items_db)}

@app.post("/items", status_code=201)
async def create_item(item: Item):
    global next_id
    response = ItemResponse(
        id=next_id,
        item=item,
        created_at=datetime.now()
    )
    items_db[next_id] = response
    next_id += 1
    return response

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
''',
    ),
    const _SampleFile(
      name: 'config.json',
      icon: Icons.settings,
      iconColor: Color(0xFFFBC02D),
      language: MonacoLanguage.json,
      content: r'''
{
  "name": "flutter_monaco",
  "version": "1.4.0",
  "description": "Monaco Editor for Flutter - Web, Desktop & Mobile",
  "platforms": {
    "web": { "enabled": true },
    "desktop": { "platforms": ["macos", "windows"] },
    "mobile": { "platforms": ["android", "ios"] }
  },
  "editor": {
    "defaultTheme": "vs-dark",
    "features": ["syntaxHighlighting", "intellisense", "formatting"]
  }
}
''',
    ),
    const _SampleFile(
      name: 'README.md',
      icon: Icons.description,
      iconColor: Colors.white70,
      language: MonacoLanguage.markdown,
      content: r'''
# Flutter Monaco Editor

A powerful code editor for Flutter applications.

## Features

- **Multi-platform** - Web, Desktop, and Mobile
- **100+ languages** - Syntax highlighting for all major languages
- **IntelliSense** - Smart completions
- **Themes** - VS Dark, Light, High Contrast

## Quick Start

```dart
import 'package:flutter_monaco/flutter_monaco.dart';

// Simply use the widget - no controller setup needed!
MonacoEditor(
  initialValue: 'print("Hello!");',
  options: EditorOptions(
    language: MonacoLanguage.dart,
    theme: MonacoTheme.vsDark,
  ),
  onReady: (controller) {
    // Controller available here for advanced usage
  },
)
```
''',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    String? packageVersion;
    String? appVersion;

    try {
      final pubspec = await rootBundle.loadString(
        'packages/flutter_monaco/pubspec.yaml',
      );
      final match = RegExp(
        r'^version:\s*([^\s]+)',
        multiLine: true,
      ).firstMatch(pubspec);
      packageVersion = match?.group(1);
    } catch (_) {
      packageVersion = null;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
    } catch (_) {
      appVersion = null;
    }

    final resolved = packageVersion ?? appVersion;
    if (!mounted) return;
    setState(() => _appVersion = resolved != null ? 'v$resolved' : 'v-');
  }

  /// Called when MonacoEditor is ready - we get the controller here
  void _onEditorReady(MonacoController controller) {
    setState(() => _controller = controller);
    _registerCompletions(controller);
    _registerJsonDiagnostics(controller);
  }

  Future<void> _registerJsonDiagnostics(MonacoController controller) async {
    await controller.setJsonDiagnostics(
      JsonDiagnosticsOptions(
        allowComments: true,
        trailingCommas: DiagnosticsSeverity.warning,
        schemaValidation: DiagnosticsSeverity.error,
        schemas: [
          JsonDiagnosticsSchema(
            uri: Uri.parse("https://example.com/schema.json"),
            fileMatch: ["*"],
            schema: jsonDecode("""
{
  "\$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Example Schema",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "name": {
      "type": "string",
      "description": "The name of the application"
    },
    "version": {
      "type": "string",
      "description": "The version of the application"
    },
    "description": {
      "type": "string",
      "description": "A brief description of the application"
    },
    "platforms": {
      "type": "object",
      "properties": {
        "web": {
          "type": "object",
          "properties": {
            "enabled": {
              "type": "boolean",
              "description": "Enable web platform support"
            }
          },
          "required": ["enabled"]
        },
        "desktop": {
          "type": "object",
          "properties": {
            "platforms": {
              "type": "array",
              "items": {
                "type": "string",
                "enum": ["macos", "windows", "linux"]
              },
              "description": "Supported desktop platforms"
            }
          },
          "required": ["platforms"]
        },
        "mobile": {
          "type": "object",
          "properties": {
            "platforms": {
              "type": "array",
              "items": {
                "type": "string",
                "enum": ["android", "ios"]
              },
              "description": "Supported mobile platforms"
            }
          },
          "required": ["platforms"]
        }
      },
      "required": ["web", "desktop", "mobile"]
    },
    
    "editor": {
      "type": "object",
      "properties": {
        "defaultTheme": {
          "type": "string",
          "enum": ["vs-dark", "vs", "hc-black"],
          "description": "Default theme for the editor"
        },
        "features": {
          "type": "array",
          "items": {
            "type": "string",
            "enum": ["syntaxHighlighting", "intellisense", "formatting"]
          },
          "description": "Enabled editor features"
        }
      },
      "required": ["defaultTheme", "features"]
    }
    }
} """),
          ),
        ],
      ),
    );
  }

  Future<void> _registerCompletions(MonacoController controller) async {
    await controller.registerStaticCompletions(
      id: 'demo-snippets',
      languages: ['dart', 'typescript', 'javascript'],
      triggerCharacters: ['.'],
      items: [
        const CompletionItem(
          label: 'print',
          kind: CompletionItemKind.functionType,
          insertText: r"print('${1:message}');",
          insertTextRules: {InsertTextRule.insertAsSnippet},
          detail: 'Print to console',
          documentation: 'Prints a message to the debug console',
        ),
        const CompletionItem(
          label: 'setState',
          kind: CompletionItemKind.method,
          insertText: r'setState(() {\n  ${1:// update state}\n});',
          insertTextRules: {InsertTextRule.insertAsSnippet},
          detail: 'Update widget state',
          documentation: 'Notify the framework that state has changed',
        ),
      ],
    );
  }

  Future<void> _switchFile(int index) async {
    if (_controller == null || index == _activeFileIndex) return;

    // Save current content
    final currentContent = await _controller!.getValue();
    _fileContents[_activeFileIndex] = currentContent;

    // Load new file
    final file = _files[index];
    final content = _fileContents[index] ?? file.content;

    await _controller!.setLanguage(file.language);
    await _controller!.setValue(content);

    setState(() => _activeFileIndex = index);
  }

  void _runCode() async {
    if (_controller == null) return;

    final timestamp = TimeOfDay.now().format(context);
    final code = await _controller!.getValue();
    final file = _files[_activeFileIndex];

    String output = '[$timestamp] Running ${file.name}...\n\n';

    if (file.language == MonacoLanguage.json) {
      output += 'Validating JSON...\n';
      output += 'Valid JSON document (${code.length} characters)\n';
    } else if (file.language == MonacoLanguage.markdown) {
      final lineCount = code.split('\n').length;
      final wordCount = code
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
      output += 'Markdown Preview\n';
      output += 'Lines: $lineCount | Words: $wordCount\n';
    } else {
      final printRegex = RegExp(r"""print\(['\"](.+?)['\"]\)""");
      final matches = printRegex.allMatches(code);
      if (matches.isNotEmpty) {
        for (final match in matches) {
          output += '> ${match.group(1)}\n';
        }
      }
      output += '\nExecution complete (simulated)';
    }

    setState(() => _output = output);
  }

  void _copyCode() async {
    if (_controller == null) return;
    final code = await _controller!.getValue();
    await Clipboard.setData(ClipboardData(text: code));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copied to clipboard'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          width: 250,
        ),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open link'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          width: 220,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = _files[_activeFileIndex];

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          if (_controller != null)
            MonacoFocusGuard(
              controller: _controller!,
              modalRouteObserver: _webDemoRouteObserver,
              autoDisableInteraction: true,
            ),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      _buildFileTabs(),
                      Expanded(child: _buildEditor(file)),
                      if (_showOutput) _buildOutputPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBar(file),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF323233),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _openUrl('https://pub.dev/packages/flutter_monaco'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0098FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.code, color: Color(0xFF0098FF), size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'flutter_monaco',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _appVersion,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Theme selector
          _HeaderButton(
            icon: _currentTheme == MonacoTheme.vsDark
                ? Icons.dark_mode
                : _currentTheme == MonacoTheme.vs
                ? Icons.light_mode
                : Icons.contrast,
            label: _currentTheme.id,
            onPressed: () => _showThemeMenu(context),
          ),
          const SizedBox(width: 8),

          // Font size
          _HeaderButton(
            icon: Icons.text_fields,
            label: '${_fontSize.toInt()}px',
            onPressed: () => _showFontSizeDialog(context),
          ),
          const SizedBox(width: 8),

          // Minimap toggle
          _HeaderToggle(
            icon: Icons.map_outlined,
            label: 'Minimap',
            value: _minimap,
            onChanged: (val) {
              setState(() => _minimap = val);
              _controller?.updateOptions(EditorOptions(minimap: val));
            },
          ),
          const SizedBox(width: 8),

          // Word wrap toggle
          _HeaderToggle(
            icon: Icons.wrap_text,
            label: 'Wrap',
            value: _wordWrap,
            onChanged: (val) {
              setState(() => _wordWrap = val);
              _controller?.updateOptions(EditorOptions(wordWrap: val));
            },
          ),

          const Spacer(),

          // Actions
          IconButton(
            icon: const Icon(Icons.format_align_left, size: 20),
            tooltip: 'Format Code',
            onPressed: () => _controller?.format(),
            color: Colors.white70,
          ),
          IconButton(
            icon: const Icon(Icons.content_copy, size: 20),
            tooltip: 'Copy Code',
            onPressed: _copyCode,
            color: Colors.white70,
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _runCode,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Run'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2EA043),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'GitHub',
            onPressed: () =>
                _openUrl('https://github.com/omar-hanafy/flutter_monaco'),
            icon: SvgPicture.asset(
              'assets/github.svg',
              package: 'flutter_monaco',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Colors.white70,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showThemeMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset.zero);
    final theme = await showMenu<MonacoTheme>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx + 100, 48, 0, 0),
      items: [
        _buildThemeMenuItem(MonacoTheme.vsDark, 'Dark', Icons.dark_mode),
        _buildThemeMenuItem(MonacoTheme.vs, 'Light', Icons.light_mode),
        _buildThemeMenuItem(
          MonacoTheme.hcBlack,
          'High Contrast',
          Icons.contrast,
        ),
      ],
    );
    if (!mounted || theme == null) return;
    setState(() => _currentTheme = theme);
    _controller?.setTheme(theme);
  }

  PopupMenuItem<MonacoTheme> _buildThemeMenuItem(
    MonacoTheme theme,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: theme,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: _currentTheme == theme
                ? const Color(0xFF0098FF)
                : Colors.white70,
          ),
          const SizedBox(width: 12),
          Text(label),
          if (_currentTheme == theme) ...[
            const Spacer(),
            const Icon(Icons.check, size: 16, color: Color(0xFF0098FF)),
          ],
        ],
      ),
    );
  }

  Future<void> _showFontSizeDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Font Size'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_fontSize.toInt()}px',
                style: const TextStyle(fontSize: 24),
              ),
              Slider(
                value: _fontSize,
                min: 10,
                max: 28,
                divisions: 18,
                onChanged: (val) {
                  setDialogState(() {});
                  setState(() => _fontSize = val);
                  _controller?.updateOptions(EditorOptions(fontSize: val));
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'EXPLORER',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final isActive = index == _activeFileIndex;
                return InkWell(
                  onTap: () => _switchFile(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF37373D)
                          : Colors.transparent,
                      border: isActive
                          ? const Border(
                              left: BorderSide(
                                color: Color(0xFF0098FF),
                                width: 2,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(file.icon, size: 16, color: file.iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.name,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FEATURES',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 8),
                _FeatureChip(label: 'IntelliSense', color: Colors.green),
                _FeatureChip(label: 'Themes', color: Colors.purple),
                _FeatureChip(label: 'Formatting', color: Colors.orange),
                _FeatureChip(label: 'Web Support', color: Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTabs() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < _files.length; i++)
            if (i == _activeFileIndex) _buildFileTab(_files[i]),
        ],
      ),
    );
  }

  Widget _buildFileTab(_SampleFile file) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Color(0xFF0098FF), width: 2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(file.icon, size: 14, color: file.iconColor),
          const SizedBox(width: 8),
          Text(
            file.name,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Build the editor using MonacoEditor widget with onReady callback.
  /// This is the recommended pattern for web platform.
  Widget _buildEditor(_SampleFile file) {
    return MonacoEditor(
      key: ValueKey('editor-${file.name}'),
      initialValue: _fileContents[_activeFileIndex] ?? file.content,
      options: EditorOptions(
        language: file.language,
        theme: _currentTheme,
        fontSize: _fontSize,
        wordWrap: _wordWrap,
        minimap: _minimap,
        automaticLayout: true,
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      onReady: _onEditorReady,
    );
  }

  Widget _buildOutputPanel() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF252526),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 14, color: Colors.white54),
                const SizedBox(width: 8),
                const Text(
                  'OUTPUT',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => setState(() => _output = ''),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _showOutput = false),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                _output.isEmpty
                    ? 'Click "Run" to execute code (simulated)'
                    : _output,
                style: TextStyle(
                  color: _output.isEmpty ? Colors.white38 : Colors.white70,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(_SampleFile file) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF007ACC),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          if (_controller != null)
            ValueListenableBuilder<LiveStats>(
              valueListenable: _controller!.liveStats,
              builder: (context, stats, _) {
                final pos = stats.cursorPosition?.label ?? '1:1';
                return Text(
                  'Ln $pos',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          const Spacer(),
          Text(
            file.language.id.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 16),
          const Text(
            'UTF-8',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 16),
          if (!_showOutput)
            InkWell(
              onTap: () => setState(() => _showOutput = true),
              child: const Row(
                children: [
                  Icon(Icons.terminal, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Output',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SampleFile {
  final String name;
  final IconData icon;
  final Color iconColor;
  final MonacoLanguage language;
  final String content;

  const _SampleFile({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.language,
    required this.content,
  });
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _HeaderToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _HeaderToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF0098FF).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: value
              ? Border.all(
                  color: const Color(0xFF0098FF).withValues(alpha: 0.5),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: value ? const Color(0xFF0098FF) : Colors.white54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: value ? const Color(0xFF0098FF) : Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final Color color;

  const _FeatureChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
