import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/paragraph_block.dart';
import '../base_block_renderer.dart';
import '../../widgets/inline_html.dart';

class ParagraphRenderer extends BlockRenderer<ParagraphBlock> {
  const ParagraphRenderer({super.key, required super.block, super.styleConfig});

  @override
  Widget build(BuildContext context) {
    return InlineHtml(
      block.html,
      styleConfig: styleConfig,
      compact: false,
    );
  }
}
