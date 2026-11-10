import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../domain/entities/blocks/table_block.dart';
import '../../widgets/inline_html.dart';
import '../base_block_renderer.dart';

class TableRenderer extends BlockRenderer<TableBlock> {
  const TableRenderer({super.key, required super.block, super.styleConfig});

  @override
  Widget build(BuildContext context) {
    if (block.content.isEmpty) return const SizedBox.shrink();

    final columnCount = block.content.map((r) => r.length).reduce(
          (a, b) => a > b ? a : b,
        );
    if (columnCount == 0) return const SizedBox.shrink();

    final table = Table(
      // Columns are as wide as their content. The table scrolls sideways, so
      // its width is unbounded and a flex-only column would collapse to zero.
      // A stretched table additionally shares out any leftover width.
      defaultColumnWidth: IntrinsicColumnWidth(
        flex: block.stretched ? 1 : null,
      ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final fillWidth = block.stretched && constraints.hasBoundedWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: fillWidth
              ? ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: table,
                )
              : table,
        );
      },
    );
  }
}
