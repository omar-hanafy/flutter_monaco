/// A Monaco editor language identifier.
///
/// This is an extension type over [String]: it erases to a plain [String] at
/// runtime, so `jsonEncode` works on it directly and equality is string
/// equality. Because of the erasure, `is MonacoLanguage` checks are not
/// meaningful at runtime. Custom language ids are constructed directly, for
/// example `MonacoLanguage('my-dsl')`.
extension type const MonacoLanguage(
  /// The raw language id string sent to the Monaco editor.
  String id,
) {
  /// Plain Text
  static const plaintext = MonacoLanguage('plaintext');

  /// ABAP
  static const abap = MonacoLanguage('abap');

  /// Apex
  static const apex = MonacoLanguage('apex');

  /// Azure CLI
  static const azcli = MonacoLanguage('azcli');

  /// Batch
  static const bat = MonacoLanguage('bat');

  /// Bicep
  static const bicep = MonacoLanguage('bicep');

  /// Cameligo
  static const cameligo = MonacoLanguage('cameligo');

  /// Clojure
  static const clojure = MonacoLanguage('clojure');

  /// CoffeeScript
  static const coffeescript = MonacoLanguage('coffeescript');

  /// C
  static const c = MonacoLanguage('c');

  /// C++
  static const cpp = MonacoLanguage('cpp');

  /// C#
  static const csharp = MonacoLanguage('csharp');

  /// Content Security Policy
  static const csp = MonacoLanguage('csp');

  /// CSS
  static const css = MonacoLanguage('css');

  /// Cypher
  static const cypher = MonacoLanguage('cypher');

  /// Dart
  static const dart = MonacoLanguage('dart');

  /// Dockerfile
  static const dockerfile = MonacoLanguage('dockerfile');

  /// ECL
  static const ecl = MonacoLanguage('ecl');

  /// Elixir
  static const elixir = MonacoLanguage('elixir');

  /// Flow9
  static const flow9 = MonacoLanguage('flow9');

  /// F#
  static const fsharp = MonacoLanguage('fsharp');

  /// Freemarker2
  static const freemarker2 = MonacoLanguage('freemarker2');

  /// Go
  static const go = MonacoLanguage('go');

  /// GraphQL
  static const graphql = MonacoLanguage('graphql');

  /// Handlebars
  static const handlebars = MonacoLanguage('handlebars');

  /// HCL
  static const hcl = MonacoLanguage('hcl');

  /// HTML
  static const html = MonacoLanguage('html');

  /// INI
  static const ini = MonacoLanguage('ini');

  /// Java
  static const java = MonacoLanguage('java');

  /// JavaScript
  static const javascript = MonacoLanguage('javascript');

  /// Julia
  static const julia = MonacoLanguage('julia');

  /// Kotlin
  static const kotlin = MonacoLanguage('kotlin');

  /// Less
  static const less = MonacoLanguage('less');

  /// Lexon
  static const lexon = MonacoLanguage('lexon');

  /// Lua
  static const lua = MonacoLanguage('lua');

  /// Liquid
  static const liquid = MonacoLanguage('liquid');

  /// M3
  static const m3 = MonacoLanguage('m3');

  /// Markdown
  static const markdown = MonacoLanguage('markdown');

  /// MDX
  static const mdx = MonacoLanguage('mdx');

  /// MIPS
  static const mips = MonacoLanguage('mips');

  /// MSDAX
  static const msdax = MonacoLanguage('msdax');

  /// MySQL
  static const mysql = MonacoLanguage('mysql');

  /// Objective-C
  static const objectiveC = MonacoLanguage('objective-c');

  /// Pascal
  static const pascal = MonacoLanguage('pascal');

  /// Pascaligo
  static const pascaligo = MonacoLanguage('pascaligo');

  /// Perl
  static const perl = MonacoLanguage('perl');

  /// PostgreSQL
  static const pgsql = MonacoLanguage('pgsql');

  /// PHP
  static const php = MonacoLanguage('php');

  /// PLA
  static const pla = MonacoLanguage('pla');

  /// Postiats
  static const postiats = MonacoLanguage('postiats');

  /// Power Query
  static const powerquery = MonacoLanguage('powerquery');

  /// PowerShell
  static const powershell = MonacoLanguage('powershell');

  /// Protocol Buffers
  static const proto = MonacoLanguage('proto');

  /// Pug
  static const pug = MonacoLanguage('pug');

  /// Python
  static const python = MonacoLanguage('python');

  /// Q#
  static const qsharp = MonacoLanguage('qsharp');

  /// R
  static const r = MonacoLanguage('r');

  /// Razor
  static const razor = MonacoLanguage('razor');

  /// Redis
  static const redis = MonacoLanguage('redis');

  /// Redshift
  static const redshift = MonacoLanguage('redshift');

  /// reStructuredText
  static const restructuredtext = MonacoLanguage('restructuredtext');

  /// Ruby
  static const ruby = MonacoLanguage('ruby');

  /// Rust
  static const rust = MonacoLanguage('rust');

  /// Small Basic
  static const sb = MonacoLanguage('sb');

  /// Scala
  static const scala = MonacoLanguage('scala');

  /// Scheme
  static const scheme = MonacoLanguage('scheme');

  /// SCSS
  static const scss = MonacoLanguage('scss');

  /// Shell Script
  static const shell = MonacoLanguage('shell');

  /// Solidity
  static const sol = MonacoLanguage('sol');

  /// AES
  static const aes = MonacoLanguage('aes');

  /// SPARQL
  static const sparql = MonacoLanguage('sparql');

  /// SQL
  static const sql = MonacoLanguage('sql');

  /// Structured Text
  static const st = MonacoLanguage('st');

  /// Swift
  static const swift = MonacoLanguage('swift');

  /// SystemVerilog
  static const systemverilog = MonacoLanguage('systemverilog');

  /// Verilog
  static const verilog = MonacoLanguage('verilog');

  /// Tcl
  static const tcl = MonacoLanguage('tcl');

  /// Twig
  static const twig = MonacoLanguage('twig');

  /// TypeScript
  static const typescript = MonacoLanguage('typescript');

  /// TypeSpec
  static const typespec = MonacoLanguage('typespec');

  /// Visual Basic
  static const vb = MonacoLanguage('vb');

  /// WGSL
  static const wgsl = MonacoLanguage('wgsl');

  /// XML
  static const xml = MonacoLanguage('xml');

  /// YAML
  static const yaml = MonacoLanguage('yaml');

  /// JSON
  static const json = MonacoLanguage('json');

  /// All languages bundled with the Monaco editor.
  static const List<MonacoLanguage> builtIn = [
    plaintext,
    abap,
    apex,
    azcli,
    bat,
    bicep,
    cameligo,
    clojure,
    coffeescript,
    c,
    cpp,
    csharp,
    csp,
    css,
    cypher,
    dart,
    dockerfile,
    ecl,
    elixir,
    flow9,
    fsharp,
    freemarker2,
    go,
    graphql,
    handlebars,
    hcl,
    html,
    ini,
    java,
    javascript,
    julia,
    kotlin,
    less,
    lexon,
    lua,
    liquid,
    m3,
    markdown,
    mdx,
    mips,
    msdax,
    mysql,
    objectiveC,
    pascal,
    pascaligo,
    perl,
    pgsql,
    php,
    pla,
    postiats,
    powerquery,
    powershell,
    proto,
    pug,
    python,
    qsharp,
    r,
    razor,
    redis,
    redshift,
    restructuredtext,
    ruby,
    rust,
    sb,
    scala,
    scheme,
    scss,
    shell,
    sol,
    aes,
    sparql,
    sql,
    st,
    swift,
    systemverilog,
    verilog,
    tcl,
    twig,
    typescript,
    typespec,
    vb,
    wgsl,
    xml,
    yaml,
    json,
  ];

  /// Whether this language is one of the languages bundled with the Monaco
  /// editor.
  bool get isBuiltIn => builtIn.contains(this);

  /// A human-readable display name for built-in languages, or `null` for
  /// custom ids.
  String? get label => switch (id) {
    'plaintext' => 'Plain Text',
    'abap' => 'ABAP',
    'apex' => 'Apex',
    'azcli' => 'Azure CLI',
    'bat' => 'Batch',
    'bicep' => 'Bicep',
    'cameligo' => 'Cameligo',
    'clojure' => 'Clojure',
    'coffeescript' => 'CoffeeScript',
    'c' => 'C',
    'cpp' => 'C++',
    'csharp' => 'C#',
    'csp' => 'CSP',
    'css' => 'CSS',
    'cypher' => 'Cypher',
    'dart' => 'Dart',
    'dockerfile' => 'Dockerfile',
    'ecl' => 'ECL',
    'elixir' => 'Elixir',
    'flow9' => 'Flow9',
    'fsharp' => 'F#',
    'freemarker2' => 'Freemarker2',
    'go' => 'Go',
    'graphql' => 'GraphQL',
    'handlebars' => 'Handlebars',
    'hcl' => 'HCL',
    'html' => 'HTML',
    'ini' => 'INI',
    'java' => 'Java',
    'javascript' => 'JavaScript',
    'julia' => 'Julia',
    'kotlin' => 'Kotlin',
    'less' => 'Less',
    'lexon' => 'Lexon',
    'lua' => 'Lua',
    'liquid' => 'Liquid',
    'm3' => 'M3',
    'markdown' => 'Markdown',
    'mdx' => 'MDX',
    'mips' => 'MIPS',
    'msdax' => 'MSDAX',
    'mysql' => 'MySQL',
    'objective-c' => 'Objective-C',
    'pascal' => 'Pascal',
    'pascaligo' => 'Pascaligo',
    'perl' => 'Perl',
    'pgsql' => 'PostgreSQL',
    'php' => 'PHP',
    'pla' => 'PLA',
    'postiats' => 'Postiats',
    'powerquery' => 'Power Query',
    'powershell' => 'PowerShell',
    'proto' => 'Protocol Buffers',
    'pug' => 'Pug',
    'python' => 'Python',
    'qsharp' => 'Q#',
    'r' => 'R',
    'razor' => 'Razor',
    'redis' => 'Redis',
    'redshift' => 'Redshift',
    'restructuredtext' => 'reStructuredText',
    'ruby' => 'Ruby',
    'rust' => 'Rust',
    'sb' => 'Small Basic',
    'scala' => 'Scala',
    'scheme' => 'Scheme',
    'scss' => 'SCSS',
    'shell' => 'Shell Script',
    'sol' => 'Solidity',
    'aes' => 'AES',
    'sparql' => 'SPARQL',
    'sql' => 'SQL',
    'st' => 'Structured Text',
    'swift' => 'Swift',
    'systemverilog' => 'SystemVerilog',
    'verilog' => 'Verilog',
    'tcl' => 'Tcl',
    'twig' => 'Twig',
    'typescript' => 'TypeScript',
    'typespec' => 'TypeSpec',
    'vb' => 'Visual Basic',
    'wgsl' => 'WGSL',
    'xml' => 'XML',
    'yaml' => 'YAML',
    'json' => 'JSON',
    _ => null,
  };
}
