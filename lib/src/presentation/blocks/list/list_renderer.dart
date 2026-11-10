import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../domain/entities/blocks/list_block.dart';
import '../../utils/list_counter_formatter.dart';
import '../../widgets/inline_html.dart';
import '../base_block_renderer.dart';

class ListRenderer extends BlockRenderer<ListBlock> {
  const ListRenderer({super.key, required super.block, super.styleConfig});

  static const double _indentPerLevel = 16;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildItems(context, block.items, const []),
    );
  }

  /// Builds the rows for [items] and, recursively, their children.
  ///
  /// [parentPath] holds the counter values of the ancestors, outermost first,
  /// so an ordered list can number nested items `1.1.`, `1.2.`, …
  List<Widget> _buildItems(
    BuildContext context,
    List<ListItem> items,
    List<int> parentPath,
  ) {
    // Only the top level honours `start`; nested levels count from 1.
    var counter = parentPath.isEmpty ? (block.start ?? 1) : 1;

    final rows = <Widget>[];
    for (final item in items) {
      final path = [...parentPath, counter++];
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: parentPath.length * _indentPerLevel),
            _buildMarker(context, item, path),
            Expanded(
              child: InlineHtml(
                item.content,
                styleConfig: styleConfig,
                bodyStyle: _contentStyle(item),
              ),
            ),
          ],
        ),
      ));
      rows.addAll(_buildItems(context, item.items, path));
    }
    return rows;
  }

  Widget _buildMarker(BuildContext context, ListItem item, List<int> path) {
    if (block.style == ListStyle.checklist) {
      return Padding(
        padding: const EdgeInsets.only(top: 1, right: 8),
        child: Icon(
          item.checked
              ? Icons.check_box_outlined
              : Icons.check_box_outline_blank,
          size: 18,
          color: item.checked
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        block.style == ListStyle.ordered
            ? ListCounterFormatter.marker(path, block.counterType)
            : '•',
        style: TextStyle(
          fontSize: 14,
          fontFamily: styleConfig?.defaultFont,
        ),
      ),
    );
  }

  /// Ticked checklist items are struck through, like the checklist block.
  Style? _contentStyle(ListItem item) {
    if (block.style != ListStyle.checklist || !item.checked) return null;
    return Style(
      textDecoration: TextDecoration.lineThrough,
      color: Colors.grey,
    );
  }
}
