# EditorJS viewer for Flutter

A viewer and editor compatible with the [EditorJS](https://editorjs.io/) JSON schema. Supports 14 built-in block types with a Clean Architecture extension point for custom blocks.

[![pub package](https://img.shields.io/pub/v/editorjs_flutter.svg)](https://pub.dev/packages/editorjs_flutter)
[![CI](https://github.com/DEV1-Softworks/editorjs-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/DEV1-Softworks/editorjs-flutter/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DEV1-Softworks/editorjs-flutter/branch/master/graph/badge.svg)](https://codecov.io/gh/DEV1-Softworks/editorjs-flutter)

# Status
Version 1.0 is the first stable release. It reads and writes the JSON of EditorJS 2.31, including the `@editorjs/list` 2.x format, and saving a document keeps everything that was loaded: block ids, tunes, and blocks from plugins this package does not know.

From 1.0 on the package follows [semantic versioning](https://dart.dev/tools/pub/versioning): the public API changes incompatibly only in a new major version.

Requires **Flutter 3.27+** (Dart 3.6+).

# Installation

Add the following to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  editorjs_flutter: ^1.0.0
```

Then run `flutter pub get`.

The package limits `html` to versions below 0.15.7, because `flutter_html` 3.0.0 does not compile with 0.15.7. If `pub get` reports a conflict on `html`, another of your dependencies requires the newer version.

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

### Handling link taps

Web links (`http` and `https`) in the content open in the external application by default; links with any other scheme do nothing. To allow more schemes, list them:

```dart
EditorJSView(
  jsonData: myJsonString,
  config: EditorConfig(
    allowedLinkSchemes: const {'http', 'https', 'mailto', 'tel'},
  ),
)
```

To handle taps yourself, for example with an in-app browser or your own router, pass `onLinkTap`:

```dart
EditorJSView(
  jsonData: myJsonString,
  config: EditorConfig(
    onLinkTap: (url) => myRouter.open(url),
  ),
)
```

The callback receives the URL exactly as it appears in the document, so check the scheme before opening it.

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

### Uploading images

When the user picks an image, the editor needs somewhere to put it. Pass an `imageUploader` that stores the file and returns its public URL:

```dart
EditorJSEditor(
  controller: _controller,
  config: EditorConfig(
    imageUploader: (image) async {
      final bytes = await image.readAsBytes();
      final url = await myApi.upload(image.name, bytes);
      return UploadedImage(url: url);
    },
  ),
)
```

`UploadedImage` also takes `extras`, a map saved next to `url` in the block's `file` object (for example `width` and `height`). Throw from the uploader to report a failure; the editor keeps the previous image and shows an error.

Without an uploader the image block stores the path of the file on the device, which no other device can load.

### Choosing the toolbar buttons

`toolbarItems` sets which buttons the toolbar shows, and in what order. For example, to offer only the newer of the two checklist kinds:

```dart
EditorConfig(
  toolbarItems: EditorToolbarItem.values
      .where((item) => item != EditorToolbarItem.legacyChecklist)
      .toList(),
)
```

"Checklist" creates a `list` block with the checklist style (`@editorjs/list` 2.x); "Checklist (legacy)" creates the older `checklist` block. Offer the one your EditorJS setup can read.

### Link previews and attachments

Link and attachment blocks can be filled in by hand: a link block has fields for the title, description and preview image, and an attachment block takes the URL of the file. Two optional hooks automate that:

```dart
EditorConfig(
  // Adds a "Fetch preview" button to link blocks.
  linkPreviewFetcher: (url) async {
    final page = await myApi.fetchLinkPreview(url);
    return LinkToolMeta(
      title: page.title,
      description: page.description,
      imageUrl: page.imageUrl,
    );
  },
  // Adds a "Choose file" button to attachment blocks. This package does not
  // bundle a file picker, so the app picks and uploads the file itself.
  attachmentPicker: () async {
    final file = await myFilePicker.pick();
    if (file == null) return null; // cancelled
    final url = await myApi.upload(file);
    return AttachesBlock(url: url, name: file.name, size: file.size);
  },
)
```

Embed blocks need no setup: paste a link from YouTube, Vimeo, X, Instagram, CodePen, Figma or another service the EditorJS embed tool supports, and the embed URL is worked out from it.

### Translating the editor

All the text the editor and the viewer show on their own (button labels, tooltips, field labels, hints, messages) comes from an `EditorStrings` object. English is the default, and Spanish and French ship with the package:

```dart
EditorConfig(strings: EditorTranslations.es) // or EditorTranslations.fr
```

To follow the language of the app instead, look the texts up by language code. A language that is not bundled falls back to English:

```dart
EditorConfig(
  strings: EditorTranslations.forLanguage(
    Localizations.localeOf(context).languageCode,
  ),
)
```

The same `EditorConfig` works for `EditorJSView`, which uses a few of these texts too.

#### Rewording a few texts

Pass an `EditorStrings` with only the texts you want to change. Everything you leave out stays in English:

```dart
EditorConfig(
  strings: EditorStrings(
    addItem: 'New entry',
    removeLastBlock: 'Delete last block',
  ),
)
```

#### Adding a translation in your app

1. Copy [`editor_strings_es.dart`](lib/src/presentation/config/translations/editor_strings_es.dart) into your project as a template. It lists every text, grouped by where it appears.
2. Rename the constant and translate each text. Texts that include a value, such as a heading level or a file size, are functions, written at the bottom of the file:

   ```dart
   const EditorStrings editorStringsDe = EditorStrings(
     paragraph: 'Absatz',
     heading: _heading,
     addItem: 'Element hinzufügen',
     // ... every other text
   );

   String _heading(int level) => 'Überschrift $level';
   ```

3. Pass it to the editor, choosing by locale yourself if you support several languages:

   ```dart
   EditorConfig(strings: editorStringsDe)
   ```

A text you leave out is shown in English, and so is any text a later version of the package adds, until you translate it.

#### Contributing a translation to the package

1. Copy `editor_strings_es.dart` to `editor_strings_<code>.dart` in [`lib/src/presentation/config/translations/`](lib/src/presentation/config/translations/), using the ISO 639-1 language code, and name the constant `editorStrings<Code>`.
2. Translate every text in it.
3. Register it in [`editor_translations.dart`](lib/src/presentation/config/translations/editor_translations.dart): add a `static const` for the language and an entry in `byLanguageCode`.
4. Run `fvm flutter test test/unit/translations_test.dart`. It fails if the file misses a text, contains one that does not exist, or is not registered.
5. Add the language to this section and to `CHANGELOG.md`.

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

1. **Branch before coding.** Claude Code must create and checkout a new branch from `develop` before writing any code, one branch per task and never on top of another work branch. Branch names must follow the `feat/`, `fix/`, `refactor/`, or `chore/` prefix convention (`release/<version>` for a release). Direct commits to `master` or `develop` are never allowed. `CLAUDE.md` describes the full workflow.
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
