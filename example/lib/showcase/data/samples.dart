import 'dart:convert';

import 'package:flutter_monaco/flutter_monaco.dart';

import 'showcase_metadata.dart';

/// The curated set of languages offered in the playground language picker,
/// in display order. Every entry has a matching sample in [_samples].
const List<MonacoLanguage> kPlaygroundLanguages = [
  MonacoLanguage.dart,
  MonacoLanguage.typescript,
  MonacoLanguage.javascript,
  MonacoLanguage.python,
  MonacoLanguage.json,
  MonacoLanguage.rust,
  MonacoLanguage.go,
  MonacoLanguage.sql,
  MonacoLanguage.yaml,
  MonacoLanguage.html,
  MonacoLanguage.css,
  MonacoLanguage.markdown,
  MonacoLanguage.java,
  MonacoLanguage.kotlin,
  MonacoLanguage.swift,
];

/// Returns the sample source for [language], or a short plaintext placeholder
/// when no curated sample exists.
String sampleFor(
  MonacoLanguage language, {
  ShowcaseMetadata metadata = ShowcaseMetadata.fallback,
}) {
  if (language == MonacoLanguage.json) return _jsonSample(metadata);
  if (language == MonacoLanguage.markdown) return _markdownSample(metadata);
  return _samples[language] ?? '// ${language.label} sample\n';
}

final Map<MonacoLanguage, String> _samples = {
  MonacoLanguage.dart: r'''
import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: MonacoEditor(
          options: EditorOptions(
            language: MonacoLanguage.dart,
            theme: MonacoTheme.vsDark,
          ),
        ),
      ),
    );
  }
}
''',
  MonacoLanguage.typescript: r'''
interface User {
  id: string;
  name: string;
  roles: ReadonlyArray<'admin' | 'editor' | 'viewer'>;
}

async function fetchUser(id: string): Promise<User> {
  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json() as Promise<User>;
}

const isAdmin = (u: User): boolean => u.roles.includes('admin');

fetchUser('42').then((user) => {
  console.log(`${user.name} is admin: ${isAdmin(user)}`);
});
''',
  MonacoLanguage.javascript: r'''
const pipe = (...fns) => (x) => fns.reduce((acc, fn) => fn(acc), x);

const clean = pipe(
  (s) => s.trim(),
  (s) => s.toLowerCase(),
  (s) => s.replace(/\s+/g, '-'),
);

const slugify = (title) => clean(title);

console.log(slugify('  Hello   Monaco World ')); // "hello-monaco-world"
''',
  MonacoLanguage.python: r'''
from dataclasses import dataclass
from typing import Iterable


@dataclass(frozen=True)
class Point:
    x: float
    y: float

    def distance_to(self, other: "Point") -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5


def total_path(points: Iterable[Point]) -> float:
    pts = list(points)
    return sum(a.distance_to(b) for a, b in zip(pts, pts[1:]))


print(total_path([Point(0, 0), Point(3, 4), Point(3, 0)]))
''',
  MonacoLanguage.rust: r'''
#[derive(Debug, Clone)]
struct Stack<T> {
    items: Vec<T>,
}

impl<T> Stack<T> {
    fn new() -> Self {
        Stack { items: Vec::new() }
    }

    fn push(&mut self, value: T) {
        self.items.push(value);
    }

    fn pop(&mut self) -> Option<T> {
        self.items.pop()
    }
}

fn main() {
    let mut stack = Stack::new();
    stack.push(1);
    stack.push(2);
    println!("{:?}", stack.pop());
}
''',
  MonacoLanguage.go: r'''
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	results := make(chan int, 5)

	for i := 1; i <= 5; i++ {
		wg.Add(1)
		go func(n int) {
			defer wg.Done()
			results <- n * n
		}(i)
	}

	wg.Wait()
	close(results)

	for r := range results {
		fmt.Println("square:", r)
	}
}
''',
  MonacoLanguage.sql: r'''
SELECT
  u.id,
  u.name,
  COUNT(o.id) AS order_count,
  SUM(o.total) AS lifetime_value
FROM users AS u
LEFT JOIN orders AS o ON o.user_id = u.id
WHERE u.created_at >= '2025-01-01'
GROUP BY u.id, u.name
HAVING COUNT(o.id) > 3
ORDER BY lifetime_value DESC
LIMIT 20;
''',
  MonacoLanguage.yaml: r'''
name: deploy-web
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter build web --release --wasm
''',
  MonacoLanguage.html: r'''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>flutter_monaco</title>
  </head>
  <body>
    <main class="hero">
      <h1>VS Code's editor, inside Flutter.</h1>
      <a class="cta" href="https://pub.dev/packages/flutter_monaco">
        Get started
      </a>
    </main>
  </body>
</html>
''',
  MonacoLanguage.css: r'''
:root {
  --accent: #0098ff;
  --accent-2: #6e5bff;
}

.button {
  padding: 12px 20px;
  border-radius: 12px;
  color: #fff;
  background: linear-gradient(135deg, var(--accent), var(--accent-2));
  transition: transform 160ms ease;
}

.button:hover {
  transform: translateY(-2px);
}
''',
  MonacoLanguage.java: r'''
import java.util.List;
import java.util.stream.Collectors;

public class Greeter {
    public static void main(String[] args) {
        List<String> names = List.of("Ada", "Linus", "Grace");

        String greeting = names.stream()
            .map(name -> "Hello, " + name + "!")
            .collect(Collectors.joining("\n"));

        System.out.println(greeting);
    }
}
''',
  MonacoLanguage.kotlin: r'''
data class Task(val title: String, val done: Boolean = false)

fun main() {
    val tasks = listOf(
        Task("Wire up the editor"),
        Task("Ship the demo", done = true),
        Task("Tweet about it"),
    )

    val (completed, pending) = tasks.partition { it.done }
    println("Done: ${completed.size}, Pending: ${pending.size}")
    pending.forEach { println(" - ${it.title}") }
}
''',
  MonacoLanguage.swift: r'''
import Foundation

struct Temperature {
    var celsius: Double
    var fahrenheit: Double { celsius * 9 / 5 + 32 }
}

let readings = [Temperature(celsius: 0),
                Temperature(celsius: 37),
                Temperature(celsius: 100)]

for reading in readings {
    print("\(reading.celsius)C = \(reading.fahrenheit)F")
}
''',
};

String _jsonSample(ShowcaseMetadata metadata) {
  const encoder = JsonEncoder.withIndent('  ');
  return '${encoder.convert({
    'name': metadata.packageName,
    'version': metadata.version,
    'description': metadata.productSummary,
    'platforms': [for (final platform in metadata.platforms) platform.id],
    'features': {'typedLanguages': metadata.typedLanguageCount, 'playgroundLanguages': kPlaygroundLanguages.length, 'themes': metadata.showcasedThemeCount, 'intelliSense': true, 'diagnostics': true},
    if (metadata.publishedAt != null) 'publishedAt': metadata.publishedAt!.toUtc().toIso8601String(),
  })}\n';
}

String _markdownSample(ShowcaseMetadata metadata) =>
    '''
# ${metadata.packageName}

> ${metadata.productSummary}

## Current package data

- **Version** - ${metadata.versionLabel}
- **Platforms** - ${metadata.platformSummary}
- **Languages** - ${metadata.typedLanguageCount} typed entries
- **Theming** - ${metadata.showcasedThemeCount} demo themes

```dart
MonacoEditor(
  options: EditorOptions(language: MonacoLanguage.dart),
)
```
''';
