import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/checklist_block.dart';
import '../base_block_editor.dart';
import '../../widgets/editor_config_scope.dart';

class ChecklistEditor extends BlockEditor<ChecklistBlock> {
  const ChecklistEditor({super.key, required super.block, required super.onChanged});

  @override
  State<ChecklistEditor> createState() => _ChecklistEditorState();
}

class _ChecklistEditorState extends State<ChecklistEditor> {
  late List<ChecklistItem> _items;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.block.items);
    _controllers =
        _items.map((i) => TextEditingController(text: i.text)).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify() =>
      widget.onChanged(ChecklistBlock(items: List.unmodifiable(_items)));

  void _toggle(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(checked: !_items[index].checked);
    });
    _notify();
  }

  void _addItem() {
    setState(() {
      _items.add(const ChecklistItem(text: ''));
      _controllers.add(TextEditingController());
    });
    _notify();
  }

  void _removeItem(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      _items.removeAt(index);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final strings = EditorConfigScope.stringsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _items.length; i++)
          Row(
            children: [
              Checkbox(
                value: _items[i].checked,
                onChanged: (_) => _toggle(i),
              ),
              Expanded(
                child: TextField(
                  controller: _controllers[i],
                  onChanged: (v) {
                    _items[i] = _items[i].copyWith(text: v);
                    _notify();
                  },
                  decoration: InputDecoration(
                    hintText: strings.checklistItemHint,
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                onPressed: _items.length > 1 ? () => _removeItem(i) : null,
              ),
            ],
          ),
        TextButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add, size: 16),
          label: Text(strings.addItem),
        ),
      ],
    );
  }
}
