/// Envelope-level attributes of an EditorJS block: everything that sits next
/// to `type` and `data` in the saved JSON rather than inside `data`.
///
/// ```json
/// { "id": "aB3xK9pQ2z", "type": "paragraph", "data": {...}, "tunes": {...} }
/// ```
class BlockMetadata {
  /// The EditorJS block id (written by EditorJS 2.21 and later).
  /// Null when the source document had none.
  final String? id;

  /// Block Tunes data keyed by tune name (e.g. `{"alignment": {...}}`).
  /// Null when the block carries no tunes.
  final Map<String, dynamic>? tunes;

  const BlockMetadata({this.id, this.tunes});

  /// Metadata for a block that has neither an id nor tunes.
  static const BlockMetadata none = BlockMetadata();
}
