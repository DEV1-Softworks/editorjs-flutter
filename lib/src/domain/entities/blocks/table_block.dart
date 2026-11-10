import '../block_entity.dart';

class TableBlock extends BlockEntity {
  /// Whether the first row is a header row.
  final bool withHeadings;

  /// Whether the table is stretched to the full width of its container.
  final bool stretched;

  /// 2-D list: content[row][column]. Each cell is plain text; any HTML will be rendered literally.
  final List<List<String>> content;

  const TableBlock({
    required this.content,
    this.withHeadings = false,
    this.stretched = false,
  });

  @override
  String get type => 'table';

  @override
  Map<String, dynamic> toJson() => {
        'withHeadings': withHeadings,
        'stretched': stretched,
        'content': content,
      };
}
