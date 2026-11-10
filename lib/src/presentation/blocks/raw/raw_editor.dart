import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/raw_block.dart';
import '../base_block_editor.dart';

/// Edits the HTML source of a raw block.
class RawEditor extends BlockEditor<RawBlock> {
  const RawEditor({super.key, required super.block, required super.onChanged});

  @override
  State<RawEditor> createState() => _RawEditorState();
}

class _RawEditorState extends State<RawEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.html);
  }

  @override
  void didUpdateWidget(covariant RawEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.block.html) {
      _controller.text = widget.block.html;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (value) => widget.onChanged(RawBlock(html: value)),
      maxLines: null,
      keyboardType: TextInputType.multiline,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      decoration: const InputDecoration(
        labelText: 'Raw HTML',
        hintText: '<div>...</div>',
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
      ),
    );
  }
}
