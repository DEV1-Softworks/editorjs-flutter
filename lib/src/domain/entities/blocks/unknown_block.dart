import '../block_entity.dart';

/// A block this package cannot interpret, kept verbatim so that it survives a
/// parse → edit → serialize round-trip.
///
/// Produced for block types with no registered mapper (for example a custom
/// EditorJS plugin) and for blocks whose `data` a mapper could not read.
/// It is never rendered by the viewer and shows as a placeholder in the editor.
class UnknownBlock extends BlockEntity {
  @override
  final String type;

  /// The untouched `data` payload from the source document.
  final Map<String, dynamic> data;

  const UnknownBlock({required this.type, required this.data});

  @override
  Map<String, dynamic> toJson() => data;
}
