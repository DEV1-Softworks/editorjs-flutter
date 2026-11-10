import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../domain/entities/blocks/image_block.dart';
import '../../widgets/inline_html.dart';
import '../base_block_renderer.dart';

class ImageRenderer extends BlockRenderer<ImageBlock> {
  const ImageRenderer({super.key, required super.block, super.styleConfig});

  @override
  Widget build(BuildContext context) {
    Widget image = Image.network(
      block.url,
      fit: block.stretched ? BoxFit.cover : BoxFit.contain,
      errorBuilder: (_, __, ___) => const _ImageErrorPlaceholder(),
    );

    if (block.stretched) {
      image = SizedBox(width: double.infinity, child: image);
    }

    Widget content = image;

    if (block.withBorder) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: content,
      );
    }

    if (block.withBackground) {
      content = ColoredBox(
        color: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: content,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        content,
        if (block.caption != null && block.caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InlineHtml(
              block.caption!,
              styleConfig: styleConfig,
              bodyStyle: Style(
                fontSize: FontSize(12),
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageErrorPlaceholder extends StatelessWidget {
  const _ImageErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }
}
