import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/blocks/list_block.dart';
import '../../utils/list_counter_formatter.dart';
import '../base_block_editor.dart';

class ListEditor extends BlockEditor<ListBlock> {
  const ListEditor({super.key, required super.block, required super.onChanged});

  @override
  State<ListEditor> createState() => _ListEditorState();
}

class _ListEditorState extends State<ListEditor> {
  /// Order of the buttons in the style selector.
  static const _styles = [
    ListStyle.unordered,
    ListStyle.ordered,
    ListStyle.checklist,
  ];

  static const _counterTypeLabels = {
    ListCounterType.numeric: 'Numeric',
    ListCounterType.lowerRoman: 'Lower Roman',
    ListCounterType.upperRoman: 'Upper Roman',
    ListCounterType.lowerAlpha: 'Lower Alpha',
    ListCounterType.upperAlpha: 'Upper Alpha',
  };

  late List<TextEditingController> _controllers;
  late List<ListItem> _items;
  late ListStyle _style;
  late int? _start;
  late ListCounterType? _counterType;
  late final TextEditingController _startController;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.block.items);
    _controllers =
        _items.map((i) => TextEditingController(text: i.content)).toList();
    _style = widget.block.style;
    _start = widget.block.start;
    _counterType = widget.block.counterType;
    _startController = TextEditingController(text: _start?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _startController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ListEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block != widget.block) {
      final newItems = widget.block.items;
      setState(() {
        final updated = <TextEditingController>[];
        for (var i = 0; i < newItems.length; i++) {
          if (i < _controllers.length) {
            // Only update text when the content actually differs to avoid
            // resetting the cursor during normal typing round-trips.
            if (_controllers[i].text != newItems[i].content) {
              _controllers[i].text = newItems[i].content;
            }
            updated.add(_controllers[i]);
          } else {
            updated.add(TextEditingController(text: newItems[i].content));
          }
        }
        // Dispose extra controllers only after building the updated list so
        // that an unexpected error cannot leave _controllers in a partial state.
        for (var i = newItems.length; i < _controllers.length; i++) {
          _controllers[i].dispose();
        }
        _controllers = updated;
        _items = List.from(newItems);
        _style = widget.block.style;
        _counterType = widget.block.counterType;
        // Same rule as the item fields: leave the text alone while it already
        // says the same thing, so the cursor does not jump while typing.
        if (_start != widget.block.start) {
          _start = widget.block.start;
          _startController.text = _start?.toString() ?? '';
        }
      });
    }
  }

  void _notify() {
    widget.onChanged(ListBlock(
      style: _style,
      items: List.unmodifiable(_items),
      start: _start,
      counterType: _counterType,
    ));
  }

  void _addItem() {
    setState(() {
      _items.add(const ListItem(content: ''));
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

  void _toggleChecked(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(checked: !_items[index].checked);
    });
    _notify();
  }

  void _setStyle(ListStyle style) {
    if (style == _style) return;
    setState(() => _style = style);
    _notify();
  }

  void _setStart(String text) {
    setState(() => _start = int.tryParse(text));
    _notify();
  }

  void _setCounterType(ListCounterType? type) {
    setState(() => _counterType = type);
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettings(),
        for (var i = 0; i < _controllers.length; i++)
          Row(
            children: [
              _buildMarker(i),
              Expanded(
                child: TextField(
                  controller: _controllers[i],
                  onChanged: (v) {
                    _items[i] = _items[i].copyWith(content: v);
                    _notify();
                  },
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                onPressed: _controllers.length > 1 ? () => _removeItem(i) : null,
              ),
            ],
          ),
        TextButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add item'),
        ),
      ],
    );
  }

  /// Style selector, plus the numbering options when the list is ordered.
  Widget _buildSettings() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ToggleButtons(
            isSelected: [for (final style in _styles) style == _style],
            onPressed: (index) => _setStyle(_styles[index]),
            constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
            borderRadius: BorderRadius.circular(4),
            children: const [
              Tooltip(
                message: 'Unordered',
                child: Icon(Icons.format_list_bulleted, size: 18),
              ),
              Tooltip(
                message: 'Ordered',
                child: Icon(Icons.format_list_numbered, size: 18),
              ),
              Tooltip(
                message: 'Checklist',
                child: Icon(Icons.checklist, size: 18),
              ),
            ],
          ),
          if (_style == ListStyle.ordered) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 88,
              child: TextField(
                controller: _startController,
                onChanged: _setStart,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Start with',
                  hintText: '1',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<ListCounterType>(
              value: _counterType ?? ListCounterType.numeric,
              onChanged: _setCounterType,
              isDense: true,
              underline: const SizedBox.shrink(),
              items: [
                for (final entry in _counterTypeLabels.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarker(int index) {
    if (_style == ListStyle.checklist) {
      return Checkbox(
        value: _items[index].checked,
        onChanged: (_) => _toggleChecked(index),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        _style == ListStyle.ordered
            ? ListCounterFormatter.marker([(_start ?? 1) + index], _counterType)
            : '•',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
