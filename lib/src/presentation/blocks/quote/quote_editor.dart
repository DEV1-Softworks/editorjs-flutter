import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/quote_block.dart';
import '../base_block_editor.dart';
import '../../widgets/editor_config_scope.dart';

class QuoteEditor extends BlockEditor<QuoteBlock> {
  const QuoteEditor({super.key, required super.block, required super.onChanged});

  @override
  State<QuoteEditor> createState() => _QuoteEditorState();
}

class _QuoteEditorState extends State<QuoteEditor> {
  late final TextEditingController _textController;
  late final TextEditingController _captionController;
  late QuoteAlignment _alignment;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.block.text);
    _captionController = TextEditingController(text: widget.block.caption ?? '');
    _alignment = widget.block.alignment;
  }

  @override
  void dispose() {
    _textController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged(QuoteBlock(
        text: _textController.text,
        caption: _captionController.text.isEmpty ? null : _captionController.text,
        alignment: _alignment,
      ));

  @override
  Widget build(BuildContext context) {
    final strings = EditorConfigScope.stringsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _textController,
            onChanged: (_) => _notify(),
            maxLines: null,
            style: const TextStyle(fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              hintText: strings.quoteHint,
              border: InputBorder.none,
            ),
          ),
          TextField(
            controller: _captionController,
            onChanged: (_) => _notify(),
            decoration: InputDecoration(
              hintText: strings.quoteCaptionHint,
              border: InputBorder.none,
              isDense: true,
            ),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Row(
            children: [
              Text(strings.align, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              for (final a in QuoteAlignment.values)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ChoiceChip(
                    label: Text(
                      switch (a) {
                        QuoteAlignment.left => strings.alignLeft,
                        QuoteAlignment.center => strings.alignCenter,
                        QuoteAlignment.right => strings.alignRight,
                      },
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _alignment == a,
                    onSelected: (_) => setState(() {
                      _alignment = a;
                      _notify();
                    }),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
