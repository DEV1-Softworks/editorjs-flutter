## [Unreleased] — towards 1.0.0

### Lossless round-trip with current EditorJS (2.31)
* **Block ids and tunes are preserved.** `id` and `tunes` are read into the new `BlockDocument.metadata` (`BlockMetadata`) and written back on serialize. `EditorController.blockIds` now holds the EditorJS ids (kept from the document, generated in EditorJS's own 10-character format for new blocks) and the new `EditorController.blockTunes` exposes each block's tunes. Both follow their block through update, move and undo/redo.
* **Unknown blocks are no longer deleted.** A block with no registered mapper — or whose mapper throws — is kept verbatim as the new `UnknownBlock` entity and written back untouched. The viewer skips it (without leaving a gap) and the editor shows the existing "Unsupported block" placeholder.
* **Backend-defined fields survive.** `TableBlock.stretched`, `ImageBlock.fileExtras`, `AttachesBlock.fileExtras` and `LinkToolMeta.extras` carry fields such as image `width`/`height` or link `site_name` through a round-trip.
* **Version stamp updated.** `getContent()` writes `"version": "2.31.7"` (`BlockDocument.editorJsVersion`) instead of the hard-coded `2.19.0`.

### List 2.x (`@editorjs/list` 2.x: nested lists and checklists in one block)
* **Checklist style.** `ListStyle.checklist` is read, rendered (a tick box per item, at every nesting level), edited and written back; the ticked state lives in the new `ListItem.checked`. Previously a `checklist`-style list was turned into a bullet list and its ticks were lost.
* **Ordered list numbering.** New `ListBlock.start` and `ListBlock.counterType` (`ListCounterType`: numeric, lower/upper roman, lower/upper alpha) are read, rendered and written back. Nested items are numbered `1.1.`, `1.2.`, … as EditorJS renders them, instead of restarting at `1.`.
* **List editor.** A style selector switches a list between unordered, ordered and checklist; ordered lists get "Start with" and counter-type options; checklist items get a tick box.
* **Two checklist buttons in the toolbar.** "Checklist" now adds a list 2.x checklist (a `list` block with `style: "checklist"`); "Checklist (legacy)" adds the older `checklist` block that the button used to create. Which one a site can read depends on the tools installed in its EditorJS instance.
* **Legacy formats are still read:** `@editorjs/list` 1.x string items, `@editorjs/nested-list` items, and old checklist `{text, checked}` items stored under a list block.

### Viewer fidelity
* **Tables are now visible.** The table renderer laid its columns out at zero width, so every table showed as a thin strip with one letter per line. As in EditorJS, a table now spans the full width with equal columns and wraps the text in its cells. A table with too many columns to keep them 96 px wide scrolls sideways instead of squeezing them.
* **Inline formatting and entities are rendered everywhere.** Headers, table cells, legacy checklist items, warning title and message, and image, embed and quote captions showed markup such as `<b>` and `&amp;` literally. All text now goes through one widget, so bold, italic, links, marker, inline code and entities render in every block.
* **Links can be tapped.** `<a>` links did nothing. Web links (`http`, `https`) now open in the external application; other schemes are opt-in through the new `EditorConfig.allowedLinkSchemes` (for example `{'http', 'https', 'mailto', 'tel'}`). To handle taps yourself, pass the new `EditorConfig.onLinkTap`. Link, embed and attachment cards go through the same path. Custom renderers can join in with `EditorLinkScope.open(context, url)`.
* **Blocks line up.** Paragraph, quote and raw text had an extra 8 px left and right margin that headers and tables did not; list markers sat about 6 px above their item's text. Both are fixed, and list items are spaced 8 px apart.

### Parser hardening
* A field of the wrong type no longer throws out of `EditorJSView` / `EditorController.fromJson`. Every built-in mapper now reads through tolerant helpers; previously `linkTool.meta: []`, a non-string list `style`, a non-string paragraph `text` and a non-integer document `time` each raised a `TypeError`.
* `time` accepts integers, doubles and numeric strings; header `level` accepts doubles.

### Behaviour changes
* `BlockDocument.blocks`, `EditorController.blocks` and `blockCount` now include `UnknownBlock`s for unrecognised types, where such blocks used to be dropped.
* `EditorController.blockIds` values are EditorJS-style ids rather than `b0`, `b1`, …
* `getContent()` output now contains `id` on every block, `tunes` where present, and `stretched` on tables.
* `BlockRendererRegistry.buildRenderer` / `buildEditor` return `null` for an `UnknownBlock` even when a builder is registered for its type string.
* Blocks with a missing or non-string `type` are still dropped: they cannot be written back.
* The toolbar's "Checklist" button creates a `list` block with the checklist style, no longer a `checklist` block; the previous behaviour moved to the new "Checklist (legacy)" button.
* Link, embed and attachment cards no longer raise an unhandled error when the platform cannot open a link.
* Paragraph, quote and raw blocks are 16 px wider (no horizontal margin) and list rows are closer together.
* `ListStyle` has a third value, `checklist`: an exhaustive `switch` over `ListStyle` in consumer code needs a new case.
* Lists are always written in the list 2.x shape: `ListBlock.toJson()` adds a root `meta`, and `ListItem.toJson()` adds a per-item `meta`.

### Tests
* Added `test/unit/lossless_roundtrip_test.dart`, `test/unit/editor_controller_metadata_test.dart`, `test/unit/json_reader_test.dart`, `test/unit/list_v2_test.dart`, `test/widget/unknown_block_test.dart`, `test/widget/list_v2_test.dart` and `test/widget/viewer_fidelity_test.dart` (340 tests in total, 92 % line coverage).

---

## [0.5.0] - 2026-03-25 — Publication readiness

### New API
* `EditorController.fromJson(String jsonString, {BlockTypeRegistry? typeRegistry})` — creates a controller pre-populated from an existing EditorJS JSON string; gracefully handles invalid JSON.

### Package metadata
* `pubspec.yaml` — updated description and added `topics` (editor, rich-text, editorjs, content).
* `example/` directory added — two-tab demo app showing `EditorJSView` (viewer tab) and `EditorJSEditor` (editor tab).

### CI / CD
* `.github/workflows/ci.yml` added — runs `flutter analyze` + `flutter test --coverage` on every PR and push to `master`; enforces ≥ 80 % line coverage via `VeryGoodOpenSource/very_good_coverage@v3`; uploads report to Codecov.

### Contribution rules
* 80 % minimum test coverage enforced in CI — PRs that drop below this threshold cannot be merged.
* `CLAUDE.md` updated with contribution rules, refreshed block types table, and updated backlog.

### Tests
* Added `test/unit/block_entities_test.dart` — `toJson()` and `type` getter for all 14 block entities.
* Added `test/unit/html_style_builder_test.dart` — `HtmlStyleBuilder.build()` with various configs.
* Extended `test/widget/renderers_test.dart` — paragraph, quote, list (flat/ordered/nested), table, image, linkTool, raw.
* Added `test/widget/editorjs_view_test.dart` — integration tests for the full parse → render pipeline.
* Added `test/widget/editorjs_editor_test.dart` — editor + block controls + `fromJson` round-trip.
* Added `test/widget/toolbar_test.dart` — toolbar button interactions and hyperlink dialog.
* Added `test/widget/block_editors_test.dart` — individual editor widgets (paragraph, list, checklist, table, image, header, quote, warning, code).

---

## [0.4.0] - 2026-03-25 — Phase 4: Quality & Safety

### Null-safety hardening
* `JsonDocumentSource.parse()` now wraps `jsonDecode` in try/catch — invalid JSON returns an empty `BlockDocument` instead of throwing.
* `HeaderMapper` — `level` field uses `is int` guard instead of a bare `as int?` cast.
* `ImageMapper` — `file` object and all three `bool` fields (`withBorder`, `stretched`, `withBackground`) use safe type checks.
* `AttachesMapper` — `file` object uses `is Map` guard; `size` handles both `int` and `num` (double) via switch expression.
* `EmbedMapper` — `width` and `height` handle both `int` and `num` via switch expression.
* `LinkToolMapper` — `image` sub-map uses `is Map` guard.
* `TableMapper` — `withHeadings` uses `is bool` guard.
* `ChecklistMapper` — `checked` uses `is bool` guard.

### Unknown block type logging
* `JsonDocumentSource` emits a `dart:developer` `log` entry (`name: 'EditorJSFlutter'`) when an unknown block type is silently dropped during parsing.

### Tests (91 total)
* **`test/unit/html_sanitizer_test.dart`** (9 tests) — script tags, iframes, event handlers, edge cases.
* **`test/unit/mappers_test.dart`** (46 tests) — all 14 mappers; happy path, missing fields, wrong-type fields.
* **`test/unit/editor_controller_test.dart`** (17 tests) — all mutations, full undo/redo state machine.
* **`test/unit/json_document_source_test.dart`** — parse, unknown-type drop, invalid JSON, round-trip.
* **`test/widget/renderers_test.dart`** (9 tests) — header, delimiter, code, warning, checklist, embed, attaches.

---

## [0.3.0] - 2026-03-25 — Phase 3: Editor features

### Undo / redo
* `EditorController` maintains a capped (50-entry) history stack.
* `canUndo` / `canRedo` boolean getters, `undo()` / `redo()` methods.
* History recorded on structural operations — `addBlock`, `insertBlock`, `removeBlock`, `moveBlock`, `clear`. Live text edits via `updateBlock` do not pollute the history.
* Toolbar exposes Undo and Redo buttons that disable automatically when no history is available.

### Per-block controls
* Every block in `EditorJSEditor` is now wrapped with three icon buttons: Move up (↑), Move down (↓), Delete (×).
* Move-up is disabled on the first block; move-down is disabled on the last block.
* Delete emits `removeBlock`, which is immediately undoable.

### Inline formatting for paragraph blocks
* `ParagraphEditor` shows an inline format bar when the field is focused.
* Six format actions: Bold (`<b>`), Italic (`<i>`), Underline (`<u>`), Strikethrough (`<s>`), Inline code (`<code>`), Highlight (`<mark>`).
* Applies tags around the current text selection; inserts empty tags with cursor between them when nothing is selected.
* Raw HTML stored in `ParagraphBlock.html` and rendered by `flutter_html` in the viewer.

### Bug fix
* Replaced deprecated `Color.withOpacity()` with `Color.withValues(alpha:)` in `QuoteRenderer`.

---

## [0.2.1] - 2026-03-25 — Viewer completeness: embed, linkTool, attaches, raw

### New block types (viewer only)
* `embed` — tappable card showing service name, source URL, and optional caption; opens URL via `url_launcher`.
* `linkTool` — link preview card with thumbnail, title, description, and URL; opens link via `url_launcher`.
* `attaches` — file download card with type-specific icon, file size, and `url_launcher` download action.
* `raw` — raw HTML content rendered through `flutter_html` with full `HtmlSanitizer` protection.

### Cross-cutting renderer improvements
* Extracted `HtmlStyleBuilder` shared utility — applies `defaultFont` to `flutter_html` `body` style and all CSS tag overrides, eliminating duplicate helpers across renderers.
* Applied `HtmlSanitizer.sanitize()` to `QuoteRenderer` and `ListRenderer` (HTML content fields).
* `ImageRenderer` caption now respects `styleConfig.defaultFont`.

### Exports
* All four new block entity classes (`EmbedBlock`, `LinkToolBlock`, `AttachesBlock`, `RawBlock`) exported from the public barrel file.

---

## [0.2.0] - 2026-03-25 — Phase 2: Viewer & editor completeness

### New block types (viewer + editor)
* `quote` — blockquote with optional caption and left/center/right alignment.
* `code` — monospace code block with horizontal scroll, selectable text, and a copy-to-clipboard button.
* `checklist` — checkbox list with checked/unchecked state; strikethrough rendered on checked items.
* `table` — 2-D table with optional heading row, horizontal scroll, and add/remove row & column controls in the editor.
* `warning` — highlighted alert box with title and message fields.

### Nested list support
* `ListBlock` items are now `ListItem` objects with a recursive `items` field.
* `ListMapper` handles both flat string items (`@editorjs/list`) and nested object items (`@editorjs/nested-list`) transparently.
* `ListRenderer` renders nested items with indentation per depth level.

### HTML sanitization
* Added `HtmlSanitizer` utility in the data layer that strips `<script>`, `<iframe>`, and `on*` event handler attributes before passing HTML to `flutter_html`.
* Applied in `ParagraphRenderer` and will apply to any renderer that calls `HtmlSanitizer.sanitize()`.

### Toolbar
* Added toolbar buttons for all new block types: Quote, Code, Checklist, Table, Warning.

### Exports
* All five new block entity classes are exported from the public barrel file.

---

## [0.1.0] - 2026-03-25 — Clean Architecture refactor (breaking)

This release is a full architectural rewrite. The public API has changed.
See the migration notes below.

### Breaking changes
* `EditorJSView` parameter renamed: `editorJSData` → `jsonData`, `styles` → `config` (accepts `EditorConfig`).
* `EditorJSEditor` now requires an `EditorController` passed via `controller:`.
* Old `src/model/` and `src/widgets/` packages removed entirely.

### Architecture
* Adopted Clean Architecture with three strict layers: `domain`, `data`, `presentation`. Dependencies flow inward only; `domain` has zero Flutter imports.
* Applied SOLID principles throughout: one class per block type (SRP), block registry for extensibility without modifying core files (OCP), all renderers/editors implement typed abstract bases (LSP/DIP).
* New block type registry pattern: register custom block types at runtime via `BlockTypeRegistry` and `BlockRendererRegistry` without touching any package file.

### New: `EditorController`
* Replaces the previous `List<Widget>` anti-pattern in the editor.
* Holds `List<BlockEntity>` as the source of truth.
* Exposes `getContent()` → EditorJS-compliant JSON string (previously impossible).
* Zero-arg factory `EditorController()` wires the default serializer automatically.
* Full block management API: `addBlock`, `insertBlock`, `updateBlock`, `removeBlock`, `moveBlock`, `clear`.

### New: domain entities
* `BlockEntity` — abstract base class for all block types.
* `BlockDocument` — root document entity with full `toJson()` serialization.
* `StyleConfig` / `CssTagConfig` — styling configuration entities replacing old JSON-only models.
* Typed block entities: `HeaderBlock`, `ParagraphBlock`, `ListBlock`, `DelimiterBlock`, `ImageBlock` — each owns only its relevant fields and serializes itself.

### New: data layer
* `BlockMapper<T>` — abstract interface for deserializing a block type from EditorJS JSON.
* Five concrete mappers (`HeaderMapper`, `ParagraphMapper`, `ListMapper`, `DelimiterMapper`, `ImageMapper`) with safe, non-throwing parsing.
* `BlockTypeRegistry` — pre-registered with all built-in mappers; callers call `.register()` for custom blocks.
* `JsonDocumentSource` — implements `DocumentRepository`; unknown block types are silently skipped (never throws on unrecognized data).

### New: presentation layer
* `BlockRenderer<T>` / `BlockEditor<T>` — abstract base widgets for custom block authors.
* `BlockRendererRegistry` — maps type strings to renderer/editor builder functions.
* `EditorConfig` — single configuration object accepted by both `EditorJSView` and `EditorJSEditor`.
* Five renderer widgets: fully stateless, receive an immutable entity.
* Five editor widgets: push updates upward via `ValueChanged<T>` callback; no direct parent coupling.
* `EditorJSToolbar` — decoupled from editor widget; communicates exclusively through `EditorController`.
* Image renderer now respects `caption`, `withBorder`, `stretched`, and `withBackground` fields.
* Image load errors show a placeholder widget instead of crashing.

### Dependency upgrades
* Dart SDK constraint: `>=2.14.0 <3.0.0` → `>=3.0.0 <4.0.0`
* Flutter constraint: `>=2.10.0` → `>=3.10.0`
* `flutter_html`: `^2.2.1` → `^3.0.0-beta.2` (API breaking: `Style.padding` now uses `HtmlPaddings`)
* `image_picker`: `^0.8.6` → `^1.0.0`
* `url_launcher`: `^6.1.6` → `^6.2.0`

### Bug fixes
* Replaced deprecated `launch()` with `launchUrl(Uri.parse(...))` in toolbar.
* Replaced deprecated `MaterialStateProperty` with `WidgetStateProperty`.
* Fixed `stretched` field never being assigned in the old `EditorJSBlockData.fromJson`.
* Removed duplicate `toolbar.dart` import in `editor.dart`.
* Fixed `MyHomePage` constructor to use `Key?` and `required this.title` (null safety).
* Removed dead toolbar buttons (quote, list) that previously rendered with no functionality.

### Migration guide
```dart
// Before
EditorJSView(editorJSData: json, styles: stylesJson)

// After
EditorJSView(jsonData: json, config: EditorConfig(styleConfig: styleConfig))

// Before — editor had no save mechanism
EditorJSEditor()

// After — create a controller, pass it in, call getContent() to export
final controller = EditorController();
EditorJSEditor(controller: controller)
final json = controller.getContent();
```

---

## [0.0.5] - Links support
* Now you may add links in the editor. Just set the name and the url to set.
NOTE: Right now is a basic implementation. I'll make it adhoc to EditorJS standard later

## [0.0.4] - Image, text block and horizontal ruler insertion completed

* You may use image insertion from camera and gallery. You must give permissions from your device for enabling it. Also, now you can create new text blocks and horizontal rulers. Soon you'll be able to change header on each block.

## [0.0.3] - Added Toolbar

* The toolbar scaffolding is ready. You may check it out in the Demo.

## [0.0.2] - Added Styles for Paragraphs

* Now you can add a paragraph with some styles.

## [0.0.1] - Initial Release

* The Viewer has been completed with the basic structures of an EditorJS JSON file.
