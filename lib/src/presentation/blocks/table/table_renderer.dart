import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../domain/entities/blocks/table_block.dart';
import '../../widgets/inline_html.dart';
import '../base_block_renderer.dart';

class TableRenderer extends BlockRenderer<TableBlock> {
  const TableRenderer({super.key, required super.block, super.styleConfig});

  /// Narrowest a column may get before the table scrolls instead of shrinking.
  static const double _minColumnWidth = 96;

  @override
  Widget build(BuildContext context) {
    if (block.content.isEmpty) return const SizedBox.shrink();

    final columnCount = block.content.map((r) => r.length).reduce(
          (a, b) => a > b ? a : b,
        );
    if (columnCount == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Without a width to fill (e.g. inside a horizontal scroll view),
        // fall back to columns as wide as their content.
        if (!constraints.hasBoundedWidth) {
          return _buildTable(columnCount, const IntrinsicColumnWidth());
        }

        // Like EditorJS, a table spans the full width with equal columns and
        // wraps the text in its cells.
        final table = _buildTable(columnCount, const FlexColumnWidth());
        final minWidth = columnCount * _minColumnWidth;
        if (minWidth <= constraints.maxWidth) return table;

        // Too many columns to stay readable: keep them at the minimum width
        // and let the table scroll sideways instead.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: table),
        );
      },
    );
  }

  Widget _buildTable(int columnCount, TableColumnWidth columnWidth) {
    return Table(
      defaultColumnWidth: columnWidth,
      border: TableBorder.all(color: Colors.grey.shade300),
      children: block.content.asMap().entries.map((entry) {
        final rowIndex = entry.key;
        final row = entry.value;
        final isHeader = block.withHeadings && rowIndex == 0;

        return TableRow(
          decoration: isHeader
              ? BoxDecoration(color: Colors.grey.shade100)
              : null,
          children: List.generate(columnCount, (colIndex) {
            final cell =
                colIndex < row.length ? row[colIndex] : '';
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: InlineHtml(
                cell,
                styleConfig: styleConfig,
                bodyStyle:
                    isHeader ? Style(fontWeight: FontWeight.bold) : null,
              ),
            );
          }),
        );
      }).toList(),
    );
  }
}
