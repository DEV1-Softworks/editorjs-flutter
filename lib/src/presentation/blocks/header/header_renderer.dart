import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../domain/entities/blocks/header_block.dart';
import '../../widgets/inline_html.dart';
import '../base_block_renderer.dart';

class HeaderRenderer extends BlockRenderer<HeaderBlock> {
  const HeaderRenderer({super.key, required super.block, super.styleConfig});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InlineHtml(
        block.text,
        styleConfig: styleConfig,
        bodyStyle: Style(
          fontSize: FontSize(_fontSize(block.level)),
          fontWeight: _fontWeight(block.level),
        ),
      ),
    );
  }

  double _fontSize(int level) => switch (level) {
        1 => 32,
        2 => 24,
        3 => 20,
        4 => 16,
        5 => 14,
        _ => 12,
      };

  FontWeight _fontWeight(int level) =>
      level <= 3 ? FontWeight.bold : FontWeight.w500;
}
