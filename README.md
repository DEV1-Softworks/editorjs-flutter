# EditorJS viewer for Flutter

A viewer and editor compatible with the [EditorJS](https://editorjs.io/) JSON schema. Supports 14 built-in block types with a Clean Architecture extension point for custom blocks.

[![pub package](https://img.shields.io/pub/v/editorjs_flutter.svg)](https://pub.dev/packages/editorjs_flutter)
[![CI](https://github.com/DEV1-Softworks/editorjs-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/DEV1-Softworks/editorjs-flutter/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DEV1-Softworks/editorjs-flutter/branch/master/graph/badge.svg)](https://codecov.io/gh/DEV1-Softworks/editorjs-flutter)

# DISCLAIMER
This package is in active development (pre-1.0). The public API is stable and the Clean Architecture foundation is solid, but some editor features are still being refined. Suitable for early production use with the understanding that minor API changes may occur in future minor versions.

Requires **Flutter 3.10+** and **Dart 3.0+**.

# Installation

Add the following to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  editorjs_flutter: ^0.5.0-beta.1
```

Then run `flutter pub get`.

# Usage

## Viewer

`EditorJSView` is a stateless widget — pass your EditorJS JSON string directly.

```dart
import 'package:editorjs_flutter/editorjs_flutter.dart';

// Minimal usage — no custom styling
EditorJSView(jsonData: myJsonString)
```

### Viewer with custom styles

You can customize the appearance of inline HTML tags (e.g. `<code>`, `<mark>`) by passing an `EditorConfig` with a `StyleConfig`:

```dart
EditorJSView(
  jsonData: myJsonString,
  config: EditorConfig(
    styleConfig: StyleConfig(
      defaultFont: 'Roboto',
      cssTags: [
        CssTagConfig(
          tag: 'code',
          backgroundColor: '#33ff0000',
          color: '#ffff0000',
          padding: 5.0,
        ),
        CssTagConfig(
          tag: 'mark',
          backgroundColor: '#ffffff00',
          padding: 5.0,
        ),
      ],
    ),
  ),
)
```

### Full viewer example

```dart
class _MyHomePageState extends State<MyHomePage> {
  String? _jsonData;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final data = await DefaultAssetBundle.of(context)
        .loadString('assets/example.json');
    setState(() => _jsonData = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EditorJS Viewer')),
      body: _jsonData == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [EditorJSView(jsonData: _jsonData!)],
            ),
    );
  }
}
```

## Editor

`EditorJSEditor` is driven by an `EditorController`. Create the controller in `initState`, dispose it in `dispose`, and call `getContent()` to export the document as an EditorJS-compliant JSON string.

```dart
import 'package:editorjs_flutter/editorjs_flutter.dart';

class CreateNoteState extends State<CreateNote> {
  late final EditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EditorController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSave() {
    final String json = _controller.getContent(); // EditorJS-compliant JSON
    // persist or send json as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Note'),
        actions: [
          IconButton(onPressed: _onSave, icon: const Icon(Icons.save_outlined)),
        ],
      ),
      body: EditorJSEditor(controller: _controller),
    );
  }
}
```

### Pre-loading existing content into the editor

Load a previously saved JSON string directly:

```dart
_controller = EditorController.fromJson(savedJsonString);
```

Loading and saving is lossless: block ids, block tunes, and blocks from EditorJS plugins this package does not know are written back by `getContent()` exactly as they were read. Unknown blocks appear in the editor as an "Unsupported block" placeholder and are skipped by the viewer.

Or pass a parsed block list if you already have one:

```dart
_controller = EditorController(initialBlocks: parsedDocument.blocks);
```

### Registering custom block types

```dart
final config = EditorConfig(
  typeRegistry: BlockTypeRegistry()..register(MyBlockMapper()),
  rendererRegistry: BlockRendererRegistry()
    ..registerRenderer('my_block', (b, s) => MyBlockRenderer(block: b as MyBlock))
    ..registerEditor('my_block', (b, cb) => MyBlockEditor(block: b as MyBlock, onChanged: cb)),
);

EditorJSView(jsonData: json, config: config)
EditorJSEditor(controller: controller, config: config)
```
# Collaborators
I want to say thank you to all collaborators on this development. Kudos for you :D

@Dhi13man - Flutter 2 compatibility and Null Safety.

@mnomanmemon - H1 to H6 behavior for the framework and Flutter v3 compatibility.

# Want to Collaborate?
Please send me a message to Twitter (@RZEROSTERN) or an email to marco.ramirez@rzerocorp.com for getting in touch.

Also if you have an issue or want to propose a fix, please leave it in the Issues tab on Github. I'll fix it ASAP.

# AI-Assisted Contributions

AI tools (including Claude Code) are permitted to assist with contributions to this project, subject to the following rules.

## Allowed uses

- Code generation, refactoring, and bug fixes within the scope of an explicitly described task.
- Writing or updating tests, documentation, and changelog entries.
- Architectural analysis and design recommendations, provided a human reviews and approves them before implementation.

## Rules for Claude Code (default)

The following rules apply when using Claude Code (`claude` CLI) on this repository:

1. **Branch before coding.** Claude Code must create and checkout a new branch from `master` before writing any code. Branch names must follow the `feat/`, `fix/`, `refactor/`, or `chore/` prefix convention. Direct commits to `master` are never allowed.
2. **Generate a PR description before finishing.** At the end of every coding session, Claude Code must produce a `PR_DESCRIPTION.md` file at the repo root summarising the changes (title, type of change, summary, breaking changes, migration notes, test plan checklist). This file is ephemeral — delete it after the PR is merged.
3. **No autonomous commits.** Claude Code must never commit or push changes without explicit human instruction. Every commit requires a human to review the diff and approve it first.
4. **No force pushes.** Claude Code must never run `git push --force` or any destructive git operation (`reset --hard`, `branch -D`, etc.) without explicit human confirmation.
5. **Scope discipline.** Claude Code must only modify files directly related to the described task. It must not refactor, reformat, or add documentation to files it was not asked to touch.
6. **No secret handling.** Claude Code must never read, write, or commit files that may contain credentials, API keys, or environment secrets (`.env`, `*.pem`, `*.key`, etc.).
7. **Dependency changes require approval.** Any addition, removal, or version change to dependencies in `pubspec.yaml` must be explicitly requested by the human contributor before being applied.
8. **Architecture changes require prior agreement.** Changes that affect the package's public API, layer boundaries, or the block registry must be discussed and agreed upon before Claude Code implements them.
9. **CLAUDE.md is the source of truth.** Claude Code must read and follow `CLAUDE.md` at the start of every session. Any conflict between `CLAUDE.md` and a user instruction must be surfaced to the human before proceeding.

## Committer responsibility disclaimer

The human who commits and/or merges AI-assisted code bears full responsibility for its correctness, security, and compliance with this project's standards. By submitting a pull request that includes AI-generated code, the committer explicitly acknowledges that:

- They have reviewed every AI-generated change line by line.
- They have run `fvm flutter analyze` and all tests locally before submitting.
- They accept sole responsibility for any defects, regressions, or security issues introduced by the AI-assisted code.
- The project maintainers bear no liability for damages arising from unreviewed AI-generated contributions.

---

**Made in Mexico with love by RZEROSTERN**
