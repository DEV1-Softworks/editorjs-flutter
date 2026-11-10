import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../domain/entities/blocks/quote_block.dart';
import '../../widgets/inline_html.dart';
import '../base_block_renderer.dart';

class QuoteRenderer extends BlockRenderer<QuoteBlock> {
  const QuoteRenderer({super.key, required super.block, super.styleConfig});

  @override
  Widget build(BuildContext context) {
    final align = switch (block.alignment) {
      QuoteAlignment.center => TextAlign.center,
      QuoteAlignment.right => TextAlign.right,
      QuoteAlignment.left => TextAlign.left,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 4,
          ),
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: _crossAlignment(block.alignment),
        children: [
          InlineHtml(
            block.text,
            styleConfig: styleConfig,
            bodyStyle: Style(textAlign: align),
            compact: false,
          ),
          if (block.caption != null && block.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InlineHtml(
                '— ${block.caption}',
                styleConfig: styleConfig,
                bodyStyle: Style(
                  textAlign: align,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                  fontSize: FontSize(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  CrossAxisAlignment _crossAlignment(QuoteAlignment a) => switch (a) {
        QuoteAlignment.center => CrossAxisAlignment.center,
        QuoteAlignment.right => CrossAxisAlignment.end,
        QuoteAlignment.left => CrossAxisAlignment.start,
      };
}
