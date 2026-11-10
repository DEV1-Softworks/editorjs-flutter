import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/link_tool_block.dart';
import '../../widgets/editor_link_scope.dart';
import '../base_block_renderer.dart';

class LinkToolRenderer extends BlockRenderer<LinkToolBlock> {
  const LinkToolRenderer(
      {super.key, required super.block, super.styleConfig});

  @override
  Widget build(BuildContext context) {
    final meta = block.meta;

    return InkWell(
      onTap: block.link.isNotEmpty
          ? () => EditorLinkScope.open(context, block.link)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (meta?.imageUrl != null && meta!.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8)),
                child: Image.network(
                  meta.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const _LinkPlaceholderIcon(),
                ),
              )
            else
              const _LinkPlaceholderIcon(),
            // Text content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meta?.title != null && meta!.title!.isNotEmpty)
                      Text(
                        meta.title!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          fontFamily: styleConfig?.defaultFont,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (meta?.description != null &&
                        meta!.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          meta.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: styleConfig?.defaultFont,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        block.link,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontFamily: styleConfig?.defaultFont,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkPlaceholderIcon extends StatelessWidget {
  const _LinkPlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            const BorderRadius.horizontal(left: Radius.circular(8)),
      ),
      child: const Icon(Icons.link, color: Colors.grey),
    );
  }
}
