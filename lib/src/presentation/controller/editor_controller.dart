import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/datasources/json_document_source.dart';
import '../../data/registry/block_type_registry.dart';
import '../../domain/entities/block_document.dart';
import '../../domain/entities/block_entity.dart';
import '../../domain/entities/block_metadata.dart';
import '../../domain/usecases/parse_document.dart';
import '../../domain/usecases/serialize_document.dart';

/// A snapshot of block data together with each block's id and tunes, used by
/// undo/redo.
class _EditorSnapshot {
  final List<BlockEntity> blocks;
  final List<String> ids;
  final List<Map<String, dynamic>?> tunes;
  _EditorSnapshot({
    required this.blocks,
    required this.ids,
    required this.tunes,
  });
}

/// Manages editor state as a list of [BlockEntity] objects.
///
/// Widgets observe changes via [ChangeNotifier]. Call [getContent] to export
/// the current document as an EditorJS-compliant JSON string.
///
/// Undo/redo is supported for structural operations (add, insert, remove, move,
/// clear). Text edits within a block are not tracked individually — each
/// [updateBlock] call replaces the block in place without creating a history
/// entry, keeping the history lean during typing.
class EditorController extends ChangeNotifier {
  /// Same alphabet and length EditorJS uses for its own block ids.
  static const String _idAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';
  static const int _idLength = 10;

  final List<BlockEntity> _blocks;
  final List<String> _blockIds;
  final List<Map<String, dynamic>?> _blockTunes;
  final SerializeDocument _serializer;
  final Random _random = Random();

  /// Every id handed out or loaded by this controller, including those of
  /// removed blocks that undo could still bring back.
  final Set<String> _usedIds = {};

  // --- Undo / redo history ---
  final List<_EditorSnapshot> _history = [];
  int _historyIndex = -1;
  static const int _maxHistorySize = 50;

  /// Creates a controller wired to the default EditorJS JSON serializer.
  /// Pass [typeRegistry] to support custom block types.
  factory EditorController({
    List<BlockEntity>? initialBlocks,
    BlockTypeRegistry? typeRegistry,
  }) {
    final registry = typeRegistry ?? BlockTypeRegistry();
    final serializer = SerializeDocument(JsonDocumentSource(registry: registry));
    return EditorController._internal(
      initialBlocks: initialBlocks,
      serializer: serializer,
    );
  }

  /// Creates a controller pre-populated with blocks parsed from an EditorJS
  /// JSON string.
  ///
  /// The document round-trips losslessly: block ids and tunes are kept, and
  /// blocks of an unregistered type are preserved as `UnknownBlock`s (shown as
  /// a placeholder in the editor) and written back untouched by [getContent].
  /// If [jsonString] is empty or invalid JSON the controller starts empty.
  factory EditorController.fromJson(
    String jsonString, {
    BlockTypeRegistry? typeRegistry,
  }) {
    final registry = typeRegistry ?? BlockTypeRegistry();
    final source = JsonDocumentSource(registry: registry);
    final document = ParseDocument(source)(jsonString);
    return EditorController._internal(
      initialBlocks: document.blocks,
      initialMetadata: document.metadata,
      serializer: SerializeDocument(source),
    );
  }

  EditorController._internal({
    List<BlockEntity>? initialBlocks,
    List<BlockMetadata> initialMetadata = const [],
    required SerializeDocument serializer,
  })  : _blocks = List<BlockEntity>.from(initialBlocks ?? []),
        _blockIds = [],
        _blockTunes = [],
        _serializer = serializer {
    for (var i = 0; i < _blocks.length; i++) {
      final metadata =
          i < initialMetadata.length ? initialMetadata[i] : BlockMetadata.none;
      final id = metadata.id;
      // Keep the document's own id; mint one when it is missing or (in a
      // corrupt document) repeated, since ids double as widget keys.
      _blockIds.add(id != null && _usedIds.add(id) ? id : _nextId());
      _blockTunes.add(metadata.tunes);
    }
    _saveSnapshot(); // record the initial state as snapshot 0
  }

  /// Generates an EditorJS-style block id that is unique within this
  /// controller's lifetime.
  String _nextId() {
    while (true) {
      final id = String.fromCharCodes(Iterable.generate(
        _idLength,
        (_) => _idAlphabet.codeUnitAt(_random.nextInt(_idAlphabet.length)),
      ));
      if (_usedIds.add(id)) return id;
    }
  }

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  /// Whether there is a previous state to restore.
  bool get canUndo => _historyIndex > 0;

  /// Whether there is a forward state to restore after an undo.
  bool get canRedo => _historyIndex < _history.length - 1;

  /// Saves the current block list, IDs and tunes as a history snapshot.
  ///
  /// Any snapshots ahead of [_historyIndex] (from a prior undo) are discarded.
  /// The block list is stored as an unmodifiable copy so that mutable
  /// collections inside block entities (e.g. ListBlock.items) cannot
  /// retroactively corrupt an older snapshot.
  void _saveSnapshot() {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(_EditorSnapshot(
      blocks: List<BlockEntity>.unmodifiable(_blocks),
      ids: List<String>.unmodifiable(_blockIds),
      tunes: List<Map<String, dynamic>?>.unmodifiable(_blockTunes),
    ));
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
    }
    _historyIndex = _history.length - 1;
  }

  /// Restores the previous snapshot, if any.
  void undo() {
    if (!canUndo) return;
    _historyIndex--;
    _restore(_history[_historyIndex]);
  }

  /// Restores the next snapshot after an undo, if any.
  void redo() {
    if (!canRedo) return;
    _historyIndex++;
    _restore(_history[_historyIndex]);
  }

  void _restore(_EditorSnapshot snapshot) {
    _blocks
      ..clear()
      ..addAll(snapshot.blocks);
    _blockIds
      ..clear()
      ..addAll(snapshot.ids);
    _blockTunes
      ..clear()
      ..addAll(snapshot.tunes);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Block mutations
  // ---------------------------------------------------------------------------

  /// Unmodifiable view of the current block list.
  List<BlockEntity> get blocks => List.unmodifiable(_blocks);

  /// Unmodifiable view of the EditorJS block ids, parallel to [blocks].
  ///
  /// Blocks loaded through [EditorController.fromJson] keep the id they had in
  /// the document; every other block gets a freshly generated one. The ids are
  /// written to the `id` field by [getContent].
  ///
  /// They are stable across [updateBlock] calls and are preserved by
  /// [undo]/[redo], making them suitable as Flutter widget keys to ensure
  /// State objects follow the correct block when the list is reordered.
  List<String> get blockIds => List.unmodifiable(_blockIds);

  /// Unmodifiable view of each block's Block Tunes data, parallel to [blocks].
  ///
  /// An entry is `null` when the block has no tunes. Tunes are carried through
  /// from the loaded document and written back by [getContent]; they follow
  /// their block through [updateBlock], [moveBlock] and [undo]/[redo].
  List<Map<String, dynamic>?> get blockTunes => List.unmodifiable(_blockTunes);

  int get blockCount => _blocks.length;

  void addBlock(BlockEntity block) {
    _blocks.add(block);
    _blockIds.add(_nextId());
    _blockTunes.add(null);
    _saveSnapshot();
    notifyListeners();
  }

  void insertBlock(int index, BlockEntity block) {
    _blocks.insert(index, block);
    _blockIds.insert(index, _nextId());
    _blockTunes.insert(index, null);
    _saveSnapshot();
    notifyListeners();
  }

  /// Replaces the block at [index] in place.
  ///
  /// Does NOT create a history snapshot — use this for live text updates.
  /// Structural changes (add, remove, move) are the undo boundaries.
  /// The block's id and tunes are preserved, so widget State objects bound
  /// via [blockIds] are not recreated on every keystroke.
  void updateBlock(int index, BlockEntity updated) {
    assert(index >= 0 && index < _blocks.length);
    _blocks[index] = updated;
    notifyListeners();
  }

  void removeBlock(int index) {
    assert(index >= 0 && index < _blocks.length);
    _blocks.removeAt(index);
    _blockIds.removeAt(index);
    _blockTunes.removeAt(index);
    _saveSnapshot();
    notifyListeners();
  }

  void moveBlock(int fromIndex, int toIndex) {
    assert(fromIndex >= 0 && fromIndex < _blocks.length);
    assert(toIndex >= 0 && toIndex < _blocks.length);
    final block = _blocks.removeAt(fromIndex);
    _blocks.insert(toIndex, block);
    final id = _blockIds.removeAt(fromIndex);
    _blockIds.insert(toIndex, id);
    final tunes = _blockTunes.removeAt(fromIndex);
    _blockTunes.insert(toIndex, tunes);
    _saveSnapshot();
    notifyListeners();
  }

  void clear() {
    _blocks.clear();
    _blockIds.clear();
    _blockTunes.clear();
    _saveSnapshot();
    notifyListeners();
  }

  /// Exports the current document as an EditorJS-compliant JSON string.
  String getContent() {
    final document = BlockDocument(
      time: DateTime.now().millisecondsSinceEpoch,
      version: BlockDocument.editorJsVersion,
      blocks: _blocks,
      metadata: [
        for (var i = 0; i < _blocks.length; i++)
          BlockMetadata(id: _blockIds[i], tunes: _blockTunes[i]),
      ],
    );
    return _serializer(document);
  }
}
