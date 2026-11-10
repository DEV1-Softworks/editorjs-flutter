import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../domain/entities/blocks/warning_block.dart';
import '../../widgets/inline_html.dart';
import '../base_block_renderer.dart';

class WarningRenderer extends BlockRenderer<WarningBlock> {
  const WarningRenderer({super.key, required super.block, super.styleConfig});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFE082)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 10, top: 2),
            child: Icon(Icons.warning_amber_rounded,
                color: Color(0xFFF9A825), size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (block.title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InlineHtml(
                      block.title,
                      styleConfig: styleConfig,
                      bodyStyle: Style(fontWeight: FontWeight.bold),
                    ),
                  ),
                InlineHtml(block.message, styleConfig: styleConfig),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
