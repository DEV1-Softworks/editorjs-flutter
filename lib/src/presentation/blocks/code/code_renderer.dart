import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/blocks/code_block.dart';
import '../base_block_renderer.dart';
import '../../widgets/editor_config_scope.dart';

class CodeRenderer extends BlockRenderer<CodeBlock> {
  const CodeRenderer({super.key, required super.block, super.styleConfig});

  @override
  Widget build(BuildContext context) {
    final strings = EditorConfigScope.stringsOf(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 48, 16),
            child: SelectableText(
              block.code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFFD4D4D4),
                height: 1.5,
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
              tooltip: strings.copy,
              onPressed: () => Clipboard.setData(ClipboardData(text: block.code)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
