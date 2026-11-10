import 'block_entity.dart';
import 'block_metadata.dart';

class BlockDocument {
  /// The EditorJS release whose output format this package reads and writes.
  /// Stamped into the `version` field of documents produced by the editor.
  static const String editorJsVersion = '2.31.7';

  final int time;
  final String version;
  final List<BlockEntity> blocks;

  /// Per-block envelope data (id, tunes), parallel to [blocks].
  ///
  /// May be shorter than [blocks], or empty: a block without a matching entry
  /// is serialized with no `id` and no `tunes`.
  final List<BlockMetadata> metadata;

  const BlockDocument({
    required this.time,
    required this.version,
    required this.blocks,
    this.metadata = const [],
  });

  /// Returns the envelope data for the block at [index].
  BlockMetadata metadataAt(int index) => index >= 0 && index < metadata.length
      ? metadata[index]
      : BlockMetadata.none;

  Map<String, dynamic> toJson() => {
        'time': time,
        'version': version,
        'blocks': [
          for (var i = 0; i < blocks.length; i++)
            _blockToJson(blocks[i], metadataAt(i)),
        ],
      };

  static Map<String, dynamic> _blockToJson(
    BlockEntity block,
    BlockMetadata metadata,
  ) {
    final tunes = metadata.tunes;
    return {
      if (metadata.id != null) 'id': metadata.id,
      'type': block.type,
      'data': block.toJson(),
      if (tunes != null && tunes.isNotEmpty) 'tunes': tunes,
    };
  }
}
