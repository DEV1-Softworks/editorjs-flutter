import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/code_block.dart';
import '../base_block_editor.dart';
import '../../widgets/editor_config_scope.dart';

class CodeEditor extends BlockEditor<CodeBlock> {
  const CodeEditor({super.key, required super.block, required super.onChanged});

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.code);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = EditorConfigScope.stringsOf(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _controller,
        onChanged: (v) => widget.onChanged(CodeBlock(code: v)),
        maxLines: null,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Color(0xFFD4D4D4),
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: strings.codeHint,
          hintStyle: const TextStyle(color: Colors.white30),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
