import 'package:flutter/widgets.dart';

import '../../domain/entities/block_entity.dart';
import '../../domain/entities/blocks/checklist_block.dart';
import '../../domain/entities/blocks/code_block.dart';
import '../../domain/entities/blocks/delimiter_block.dart';
import '../../domain/entities/blocks/header_block.dart';
import '../../domain/entities/blocks/image_block.dart';
import '../../domain/entities/blocks/list_block.dart';
import '../../domain/entities/blocks/paragraph_block.dart';
import '../../domain/entities/blocks/quote_block.dart';
import '../../domain/entities/blocks/table_block.dart';
import '../../domain/entities/blocks/unknown_block.dart';
import '../../domain/entities/blocks/attaches_block.dart';
import '../../domain/entities/blocks/embed_block.dart';
import '../../domain/entities/blocks/link_tool_block.dart';
import '../../domain/entities/blocks/raw_block.dart';
import '../../domain/entities/blocks/warning_block.dart';
import '../../domain/entities/style_config.dart';
import '../blocks/attaches/attaches_renderer.dart';
import '../blocks/checklist/checklist_editor.dart';
import '../blocks/embed/embed_renderer.dart';
import '../blocks/link_tool/link_tool_renderer.dart';
import '../blocks/raw/raw_renderer.dart';
import '../blocks/checklist/checklist_renderer.dart';
import '../blocks/code/code_editor.dart';
import '../blocks/code/code_renderer.dart';
import '../blocks/delimiter/delimiter_editor.dart';
import '../blocks/delimiter/delimiter_renderer.dart';
import '../blocks/header/header_editor.dart';
import '../blocks/header/header_renderer.dart';
import '../blocks/image/image_editor.dart';
import '../blocks/image/image_renderer.dart';
import '../blocks/list/list_editor.dart';
import '../blocks/list/list_renderer.dart';
import '../blocks/paragraph/paragraph_editor.dart';
import '../blocks/paragraph/paragraph_renderer.dart';
import '../blocks/quote/quote_editor.dart';
import '../blocks/quote/quote_renderer.dart';
import '../blocks/table/table_editor.dart';
import '../blocks/table/table_renderer.dart';
import '../blocks/warning/warning_editor.dart';
import '../blocks/warning/warning_renderer.dart';

typedef BlockRendererBuilder = Widget Function(
  BlockEntity block,
  StyleConfig? styleConfig,
);

typedef BlockEditorBuilder = Widget Function(
  BlockEntity block,
  ValueChanged<BlockEntity> onChanged,
);

/// Maps EditorJS block type strings to their renderer and editor widget builders.
///
/// Built-in block types are pre-registered. Call [registerRenderer] and
/// [registerEditor] to add custom blocks without modifying core package files.
class BlockRendererRegistry {
  final Map<String, BlockRendererBuilder> _renderers = {};
  final Map<String, BlockEditorBuilder> _editors = {};

  BlockRendererRegistry() {
    _registerBuiltIns();
  }

  void _registerBuiltIns() {
    registerRenderer('header',
        (b, s) => HeaderRenderer(block: b as HeaderBlock, styleConfig: s));
    registerRenderer('paragraph',
        (b, s) => ParagraphRenderer(block: b as ParagraphBlock, styleConfig: s));
    registerRenderer('list',
        (b, s) => ListRenderer(block: b as ListBlock, styleConfig: s));
    registerRenderer('delimiter',
        (b, s) => DelimiterRenderer(block: b as DelimiterBlock, styleConfig: s));
    registerRenderer('image',
        (b, s) => ImageRenderer(block: b as ImageBlock, styleConfig: s));
    registerRenderer('quote',
        (b, s) => QuoteRenderer(block: b as QuoteBlock, styleConfig: s));
    registerRenderer('code',
        (b, s) => CodeRenderer(block: b as CodeBlock, styleConfig: s));
    registerRenderer('checklist',
        (b, s) => ChecklistRenderer(block: b as ChecklistBlock, styleConfig: s));
    registerRenderer('table',
        (b, s) => TableRenderer(block: b as TableBlock, styleConfig: s));
    registerRenderer('warning',
        (b, s) => WarningRenderer(block: b as WarningBlock, styleConfig: s));
    registerRenderer('embed',
        (b, s) => EmbedRenderer(block: b as EmbedBlock, styleConfig: s));
    registerRenderer('linkTool',
        (b, s) => LinkToolRenderer(block: b as LinkToolBlock, styleConfig: s));
    registerRenderer('attaches',
        (b, s) => AttachesRenderer(block: b as AttachesBlock, styleConfig: s));
    registerRenderer('raw',
        (b, s) => RawRenderer(block: b as RawBlock, styleConfig: s));

    registerEditor('header',
        (b, cb) => HeaderEditor(block: b as HeaderBlock, onChanged: (u) => cb(u)));
    registerEditor('paragraph',
        (b, cb) => ParagraphEditor(block: b as ParagraphBlock, onChanged: (u) => cb(u)));
    registerEditor('list',
        (b, cb) => ListEditor(block: b as ListBlock, onChanged: (u) => cb(u)));
    registerEditor('delimiter',
        (b, cb) => DelimiterEditor(block: b as DelimiterBlock, onChanged: (u) => cb(u)));
    registerEditor('image',
        (b, cb) => ImageEditor(block: b as ImageBlock, onChanged: (u) => cb(u)));
    registerEditor('quote',
        (b, cb) => QuoteEditor(block: b as QuoteBlock, onChanged: (u) => cb(u)));
    registerEditor('code',
        (b, cb) => CodeEditor(block: b as CodeBlock, onChanged: (u) => cb(u)));
    registerEditor('checklist',
        (b, cb) => ChecklistEditor(block: b as ChecklistBlock, onChanged: (u) => cb(u)));
    registerEditor('table',
        (b, cb) => TableEditor(block: b as TableBlock, onChanged: (u) => cb(u)));
    registerEditor('warning',
        (b, cb) => WarningEditor(block: b as WarningBlock, onChanged: (u) => cb(u)));
  }

  void registerRenderer(String type, BlockRendererBuilder builder) {
    _renderers[type] = builder;
  }

  void registerEditor(String type, BlockEditorBuilder builder) {
    _editors[type] = builder;
  }

  /// Returns the renderer widget, or `null` for unregistered types.
  ///
  /// An [UnknownBlock] always yields `null`, even when its type string has a
  /// registered builder: it holds raw data the builder's entity cast would
  /// reject (this is how a block with unreadable `data` is represented).
  Widget? buildRenderer(BlockEntity block, StyleConfig? styleConfig) {
    if (block is UnknownBlock) return null;
    return _renderers[block.type]?.call(block, styleConfig);
  }

  /// Returns the editor widget, or `null` for unregistered types and for
  /// [UnknownBlock]s (see [buildRenderer]).
  Widget? buildEditor(BlockEntity block, ValueChanged<BlockEntity> onChanged) {
    if (block is UnknownBlock) return null;
    return _editors[block.type]?.call(block, onChanged);
  }

  bool supportsRendering(String type) => _renderers.containsKey(type);
  bool supportsEditing(String type) => _editors.containsKey(type);
}
