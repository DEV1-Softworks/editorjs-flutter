import '../../domain/entities/blocks/list_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

class ListMapper implements BlockMapper<ListBlock> {
  const ListMapper();

  @override
  String get supportedType => 'list';

  @override
  ListBlock fromJson(Map<String, dynamic> data) {
    return ListBlock(
      style:
          data['style'] == 'ordered' ? ListStyle.ordered : ListStyle.unordered,
      items: JsonReader.list(data['items']).map(_parseItem).toList(),
    );
  }

  /// Handles both flat string items (standard @editorjs/list) and
  /// nested object items (@editorjs/nested-list).
  ListItem _parseItem(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return ListItem(
        content: JsonReader.string(raw['content']),
        items: JsonReader.list(raw['items']).map(_parseItem).toList(),
      );
    }
    return ListItem(content: JsonReader.string(raw));
  }
}
