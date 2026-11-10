import '../block_entity.dart';

/// How a list is presented. Matches the `style` values of `@editorjs/list` 2.x,
/// which merged the former nested-list and checklist tools into one.
enum ListStyle { ordered, unordered, checklist }

/// Numbering scheme of an ordered list (`meta.counterType` in EditorJS).
enum ListCounterType {
  numeric('numeric'),
  lowerRoman('lower-roman'),
  upperRoman('upper-roman'),
  lowerAlpha('lower-alpha'),
  upperAlpha('upper-alpha');

  const ListCounterType(this.value);

  /// The string EditorJS stores for this counter type.
  final String value;

  /// Returns the counter type stored as [value], or `null` if it is not one
  /// EditorJS defines.
  static ListCounterType? fromValue(Object? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class ListItem {
  /// HTML content of this item.
  final String content;

  /// Nested child items (empty for flat lists).
  final List<ListItem> items;

  /// Whether the item is ticked. Only meaningful, and only serialized, when
  /// the list's style is [ListStyle.checklist].
  final bool checked;

  const ListItem({
    required this.content,
    this.items = const [],
    this.checked = false,
  });

  ListItem copyWith({String? content, List<ListItem>? items, bool? checked}) =>
      ListItem(
        content: content ?? this.content,
        items: items ?? this.items,
        checked: checked ?? this.checked,
      );

  /// Serializes the item in the `@editorjs/list` 2.x shape.
  ///
  /// Pass [asChecklist] for items of a checklist so that `meta.checked` is
  /// written; items of ordered and unordered lists carry an empty `meta`.
  Map<String, dynamic> toJson({bool asChecklist = false}) => {
        'content': content,
        'meta': <String, dynamic>{if (asChecklist) 'checked': checked},
        'items': items.map((i) => i.toJson(asChecklist: asChecklist)).toList(),
      };
}

class ListBlock extends BlockEntity {
  final ListStyle style;
  final List<ListItem> items;

  /// Number the first top-level item is counted from. Ordered lists only.
  /// Null when the document does not specify it (counting starts at 1).
  final int? start;

  /// Numbering scheme, applied at every nesting level. Ordered lists only.
  /// Null when the document does not specify it (numeric).
  final ListCounterType? counterType;

  const ListBlock({
    required this.style,
    required this.items,
    this.start,
    this.counterType,
  });

  @override
  String get type => 'list';

  @override
  Map<String, dynamic> toJson() => {
        'style': style.name,
        'meta': <String, dynamic>{
          if (style == ListStyle.ordered) ...{
            if (start != null) 'start': start,
            if (counterType != null) 'counterType': counterType!.value,
          },
        },
        'items': items
            .map((i) => i.toJson(asChecklist: style == ListStyle.checklist))
            .toList(),
      };
}
