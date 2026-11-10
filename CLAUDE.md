# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Flutter/Dart package providing a **viewer** (`EditorJSView`) and **editor** (`EditorJSEditor`) widget compatible with the [EditorJS](https://editorjs.io/) JSON schema. Currently being refactored to Clean Architecture + SOLID for production readiness.

## Commands

```bash
# Install dependencies
fvm flutter pub get

# Run the demo app
cd demo && fvm flutter run

# Run tests
fvm flutter test

# Analyze code
fvm flutter analyze

# Format code
dart format lib/ test/ demo/lib/
```

Single test file:
```bash
fvm flutter test test/editorjs_flutter_test.dart
```

> All Flutter commands must use `fvm flutter ...` — never plain `flutter`.

---

## Architecture

The package follows **Clean Architecture** with three strict layers. Dependencies only flow inward (presentation → data → domain). No new external dependencies — only `flutter_html`, `image_picker`, `url_launcher`, and Flutter's built-in `ChangeNotifier`.

```
lib/src/
├── domain/           ← pure Dart, zero Flutter imports
│   ├── entities/     ← BlockEntity (abstract), BlockDocument, StyleConfig, one class per block type
│   ├── repositories/ ← DocumentRepository (abstract interface)
│   └── usecases/     ← ParseDocument, SerializeDocument
├── data/             ← JSON parsing only
│   ├── mappers/      ← BlockMapper<T> (abstract) + one concrete mapper per block type
│   ├── datasources/  ← JsonDocumentSource implements DocumentRepository
│   └── registry/     ← BlockTypeRegistry — the OCP extension point for custom block types
└── presentation/     ← Flutter widgets
    ├── controller/   ← EditorController (ChangeNotifier, List<BlockEntity>, getContent())
    ├── config/       ← EditorConfig (wires registries + styleConfig)
    ├── registry/     ← BlockRendererRegistry (maps type strings → builder functions)
    ├── blocks/       ← base_block_renderer.dart, base_block_editor.dart, one subdir per block type
    └── widgets/      ← EditorJSView, EditorJSEditor, EditorJSToolbar (thin delegators)
```

### Key Contracts

| Contract | Layer | Responsibility |
|---|---|---|
| `BlockEntity` | Domain | Abstract base: `String get type`, `Map<String,dynamic> toJson()` |
| `DocumentRepository` | Domain | `BlockDocument parse(String)`, `String serialize(BlockDocument)` |
| `BlockMapper<T>` | Data | `String get supportedType`, `T fromJson(Map<String,dynamic>)` |
| `BlockRenderer<T>` | Presentation | Abstract `StatelessWidget` with `T block`, `StyleConfig? styleConfig` |
| `BlockEditor<T>` | Presentation | Abstract `StatefulWidget` with `T block`, `ValueChanged<T> onChanged` |

### EditorController

Replaces the previous `List<Widget>` anti-pattern. The editor stores **data, not widgets**.

```dart
class EditorController extends ChangeNotifier {
  List<BlockEntity> get blocks
  void addBlock(BlockEntity block)
  void updateBlock(int index, BlockEntity updated)
  void removeBlock(int index)
  void moveBlock(int from, int to)
  String getContent()   // returns EditorJS-compliant JSON string
}
```

### Block Registry Pattern (Open/Closed Principle)

New block types are added by registering into the registries — **never by editing switch statements**.

```dart
// Adding a custom block — zero changes to core package files
final config = EditorConfig(
  typeRegistry: BlockTypeRegistry()..register(MyMapper()),
  rendererRegistry: BlockRendererRegistry()
    ..registerRenderer('my_type', (b, s) => MyRenderer(block: b as MyBlock))
    ..registerEditor('my_type', (b, cb) => MyEditor(block: b as MyBlock, onChanged: cb)),
);
```

### SOLID Rules (must be enforced in all PRs)

- **SRP**: Each block type has its own entity, mapper, renderer, and editor — no god objects
- **OCP**: Core files never change to support new block types; extend via registry
- **LSP**: All `BlockRenderer<T>` and `BlockEditor<T>` subclasses are interchangeable
- **ISP**: Viewer callers only need `EditorJSView` + optional `EditorConfig` — never `EditorController`
- **DIP**: `EditorJSToolbar` communicates only via `EditorController`, never holds a parent widget reference

---

## Supported Block Types

| Block | Viewer | Editor | Notes |
|---|---|---|---|
| `header` | H1–H6, inline HTML | ✅ | |
| `paragraph` | HTML via flutter_html | ✅ | Inline format bar (B/I/U/S/code/mark) |
| `list` | Ordered (start, counter type) / unordered / checklist / nested | ✅ | `@editorjs/list` 2.x format; legacy list, nested-list and checklist data is read too. Nested items are rendered but not yet editable |
| `delimiter` | Divider | ✅ | |
| `image` | Network URL | ✅ | caption/border/stretch parsed; image_picker not wired |
| `quote` | With alignment | ✅ | |
| `code` | Monospace + copy button | ✅ | |
| `checklist` | Checked / unchecked | ✅ | Legacy `@editorjs/checklist` block; toolbar button "Checklist (legacy)". The toolbar's "Checklist" button creates a `list` block with the checklist style |
| `table` | Optional heading row, inline HTML in cells | ✅ | Full width with equal columns, text wraps; scrolls horizontally when columns would be narrower than 96 px. `stretched` is preserved but has no visual effect |
| `warning` | Title + message, inline HTML | ✅ | |
| `embed` | Tappable card | Viewer only | |
| `linkTool` | Link preview card | Viewer only | |
| `attaches` | File download card | Viewer only | |
| `raw` | Sanitized HTML | Viewer only | |

---

## Public API

`lib/editorjs_flutter.dart` is the sole entry point. It exports:

- **Widgets**: `EditorJSView`, `EditorJSEditor`, `EditorLinkScope` (lets custom renderers open links through `EditorConfig.onLinkTap`)
- **Controller**: `EditorController`
- **Config**: `EditorConfig`
- **Registries**: `BlockTypeRegistry`, `BlockRendererRegistry`
- **Contracts** (for custom block authors): `BlockMapper`, `BlockRenderer`, `BlockEditor`, `BlockEntity`, `BlockDocument`, `BlockMetadata`, `StyleConfig`
- **Built-in entities**: `HeaderBlock`, `ParagraphBlock`, `ListBlock`, `DelimiterBlock`, `ImageBlock`, and the other block entities; `UnknownBlock` holds any block the package cannot interpret so it round-trips untouched

Nothing from `lib/src/` should be imported directly by consumers.

---

## Implementation Order

When building new features, always work bottom-up:

1. Domain entity (pure Dart, no Flutter)
2. `BlockMapper<T>` in data layer + register in `BlockTypeRegistry`
3. `BlockRenderer<T>` + `BlockEditor<T>` in presentation + register in `BlockRendererRegistry`
4. Unit tests for mapper, widget tests for renderer

---

## Key Source Locations

- `lib/editorjs_flutter.dart` — public API barrel file
- `lib/src/domain/entities/` — block entity classes
- `lib/src/data/registry/block_type_registry.dart` — JSON parsing extension point
- `lib/src/presentation/registry/block_renderer_registry.dart` — rendering extension point
- `lib/src/presentation/controller/editor_controller.dart` — editor state + `getContent()`
- `lib/src/presentation/widgets/` — thin shell widgets, plus `inline_html.dart`: the one widget every renderer uses to show EditorJS text (sanitizing, styling, link taps)
- `demo/lib/main.dart` — viewer usage example
- `demo/lib/createnote.dart` — editor usage example
- `demo/test_data/` — sample EditorJS JSON and styles JSON

## Contribution Rules

1. All new code must be covered by unit or widget tests.
2. **Minimum test coverage: 80 %** — the CI workflow enforces this via `VeryGoodOpenSource/very_good_coverage`. PRs that drop coverage below 80 % will fail CI and cannot be merged.
3. Run `fvm flutter analyze` locally before pushing — zero issues required.
4. Run `fvm flutter test --coverage` locally and verify the coverage threshold.
5. Follow the Clean Architecture layer rules: no Flutter imports in `domain/`, no direct widget dependencies in `data/`.
6. New block types must be added bottom-up: entity → mapper → renderer → (editor) → register in both registries → export from barrel.

## Git Workflow

**This repo has branch protection. Direct commits to `master` are not allowed.**

### Before starting any coding task

1. Ensure `master` is up to date and create a new branch:
   ```bash
   git checkout master
   git pull
   git checkout -b <prefix>/<short-description>
   ```
2. Use these branch name prefixes:
   - `feat/` — new feature or block type
   - `fix/` — bug fix
   - `refactor/` — internal restructuring with no behaviour change
   - `chore/` — dependency bumps, tooling, docs

### Before finishing any coding task

1. Run `fvm flutter analyze` — must report **no issues** before marking work done.
2. Generate a `PR_DESCRIPTION.md` file at the repo root (see template below).
3. All changes go to `master` via Pull Request only — never push directly.
4. Delete `PR_DESCRIPTION.md` after the PR is merged.

### PR_DESCRIPTION.md template

```markdown
## Title
<concise PR title>

## Type of change
- [ ] Bug fix
- [ ] New feature
- [ ] Refactor
- [ ] Chore / dependency update
- [ ] Documentation

## Summary
- <bullet point summary of what changed and why>

## Breaking changes
<list any public API changes, or "None">

## Migration notes
<instructions for consumers upgrading, or "None">

## Test plan
- [ ] `fvm flutter analyze` passes with no issues
- [ ] Relevant unit/widget tests added or updated
- [ ] Demo app tested manually on at least one platform
```

---

## Versioning

Current version: `0.5.0` (in `pubspec.yaml`).

When making changes, always update `CHANGELOG.md` with a new entry at the top following the existing format:
- Bump the patch version for bug fixes
- Bump the minor version for new features or breaking API changes
- Keep `pubspec.yaml` version in sync with `CHANGELOG.md`

## Known Issues / Backlog

- `image_picker` is declared as a dependency but `ImageEditor` only accepts a URL string — picker not wired up
- No `EditorController` content persistence to local storage (save/load)
- No inline link editor in paragraph (currently inserts a `<a>` paragraph block via dialog)
- No drag-to-reorder for blocks (only up/down buttons)
- Typing history not tracked by undo/redo (only structural operations are undoable)
- pub.dev publication pending — description, topics, and example are ready but package has not been published yet
