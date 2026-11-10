import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/warning_block.dart';
import '../base_block_editor.dart';
import '../../widgets/editor_config_scope.dart';

class WarningEditor extends BlockEditor<WarningBlock> {
  const WarningEditor({super.key, required super.block, required super.onChanged});

  @override
  State<WarningEditor> createState() => _WarningEditorState();
}

class _WarningEditorState extends State<WarningEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.block.title);
    _messageController = TextEditingController(text: widget.block.message);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged(WarningBlock(
        title: _titleController.text,
        message: _messageController.text,
      ));

  @override
  Widget build(BuildContext context) {
    final strings = EditorConfigScope.stringsOf(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFE082)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 10, top: 14),
            child: Icon(Icons.warning_amber_rounded,
                color: Color(0xFFF9A825), size: 20),
          ),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  onChanged: (_) => _notify(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: strings.warningTitleHint,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
                TextField(
                  controller: _messageController,
                  onChanged: (_) => _notify(),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: strings.warningMessageHint,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
