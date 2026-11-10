import '../../domain/entities/blocks/list_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

/// Reads the `@editorjs/list` 2.x format and the three formats it replaced,
/// normalizing them the same way the EditorJS tool does:
///
/// * `@editorjs/list` 1.x: items are plain strings
/// * `@editorjs/nested-list`: items are `{content, items}` without `meta`
/// * `@editorjs/checklist` data saved under a list block: items are
///   `{text, checked}`
class ListMapper implements BlockMapper<ListBlock> {
  const ListMapper();

  @override
  String get supportedType => 'list';

  @override
  ListBlock fromJson(Map<String, dynamic> data) {
    final rawItems = JsonReader.list(data['items']);
    final meta = JsonReader.map(data['meta']);

    return ListBlock(
      style: _isLegacyChecklist(rawItems)
          ? ListStyle.checklist
          : _parseStyle(data['style']),
      items: rawItems.map(_parseItem).toList(),
      start: JsonReader.integer(meta?['start']),
      counterType: ListCounterType.fromValue(meta?['counterType']),
    );
  }

  static ListStyle _parseStyle(dynamic style) => switch (style) {
        'ordered' => ListStyle.ordered,
        'checklist' => ListStyle.checklist,
        _ => ListStyle.unordered,
      };

  /// Same test EditorJS applies: the first item has the old checklist shape.
  static bool _isLegacyChecklist(List<dynamic> rawItems) {
    final first = rawItems.isEmpty ? null : rawItems.first;
    return first is Map<String, dynamic> &&
        first['text'] is String &&
        first['checked'] is bool;
  }

  ListItem _parseItem(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return ListItem(content: JsonReader.string(raw));
    }

    final meta = JsonReader.map(raw['meta']);
    return ListItem(
      // `text` and a top-level `checked` are the old checklist spelling.
      content: JsonReader.string(raw['content'] ?? raw['text']),
      checked: JsonReader.boolean(meta?['checked'] ?? raw['checked']),
      items: JsonReader.list(raw['items']).map(_parseItem).toList(),
    );
  }
}
