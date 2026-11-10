import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/header_block.dart';
import '../base_block_editor.dart';

class HeaderEditor extends BlockEditor<HeaderBlock> {
  const HeaderEditor({
    super.key,
    required super.block,
    required super.onChanged,
  });

  @override
  State<HeaderEditor> createState() => _HeaderEditorState();
}

class _HeaderEditorState extends State<HeaderEditor> {
  static const int _minLevel = 1;
  static const int _maxLevel = 6;

  late final TextEditingController _textController;
  late int _level;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.block.text);
    _level = widget.block.level;
  }

  @override
  void didUpdateWidget(covariant HeaderEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.level != widget.block.level) {
      _level = widget.block.level;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    widget.onChanged(HeaderBlock(text: value, level: _level));
  }

  void _setLevel(int? level) {
    if (level == null || level == _level) return;
    setState(() => _level = level);
    widget.onChanged(HeaderBlock(text: _textController.text, level: level));
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = switch (_level) {
      1 => 32.0,
      2 => 24.0,
      3 => 20.0,
      4 => 16.0,
      5 => 14.0,
      _ => 12.0,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, right: 8),
            child: Tooltip(
              message: 'Heading level',
              child: DropdownButton<int>(
                // A document can carry a level outside H1–H6; show the
                // nearest one rather than failing to build.
                value: _level.clamp(_minLevel, _maxLevel),
                onChanged: _setLevel,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: [
                  for (var level = _minLevel; level <= _maxLevel; level++)
                    DropdownMenuItem(value: level, child: Text('H$level')),
                ],
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              onChanged: _onTextChanged,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: _level <= 3 ? FontWeight.bold : FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Heading $_level',
                border: InputBorder.none,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
          ),
        ],
      ),
    );
  }
}
