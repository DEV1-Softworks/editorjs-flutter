import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/raw_block.dart';
import '../../widgets/inline_html.dart';
import '../base_block_renderer.dart';

/// Renders raw HTML content. Content is sanitized before display.
class RawRenderer extends BlockRenderer<RawBlock> {
  const RawRenderer({super.key, required super.block, super.styleConfig});

  @override
  Widget build(BuildContext context) {
    return InlineHtml(
      block.html,
      styleConfig: styleConfig,
      compact: false,
    );
  }
}
