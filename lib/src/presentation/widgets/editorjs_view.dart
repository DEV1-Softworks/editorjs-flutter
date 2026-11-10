import 'package:flutter/material.dart';

import '../../data/datasources/json_document_source.dart';
import '../../domain/usecases/parse_document.dart';
import '../config/editor_config.dart';
import 'editor_config_scope.dart';
import 'editor_link_scope.dart';

/// Read-only viewer for EditorJS JSON content.
///
/// Parses [jsonData] and renders each block using the registered renderers.
/// Blocks without a registered renderer are skipped and take up no space.
///
/// Example:
/// ```dart
/// EditorJSView(jsonData: myJsonString)
/// ```
class EditorJSView extends StatelessWidget {
  final String jsonData;
  final EditorConfig config;

  EditorJSView({
    super.key,
    required this.jsonData,
    EditorConfig? config,
  }) : config = config ?? EditorConfig();

  @override
  Widget build(BuildContext context) {
    final source = JsonDocumentSource(registry: config.typeRegistry);
    final document = ParseDocument(source)(jsonData);

    final rendered = [
      for (final block in document.blocks)
        config.rendererRegistry.buildRenderer(block, config.styleConfig),
    ].nonNulls;

    return EditorConfigScope(
      config: config,
      child: EditorLinkScope(
        onLinkTap: config.onLinkTap,
        allowedSchemes: config.allowedLinkSchemes,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final widget in rendered) ...[
              widget,
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
