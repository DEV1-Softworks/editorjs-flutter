import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/table_block.dart';
import '../base_block_editor.dart';
import '../../widgets/editor_config_scope.dart';

class TableEditor extends BlockEditor<TableBlock> {
  const TableEditor({super.key, required super.block, required super.onChanged});

  @override
  State<TableEditor> createState() => _TableEditorState();
}

class _TableEditorState extends State<TableEditor> {
  late List<List<TextEditingController>> _controllers;
  late bool _withHeadings;

  @override
  void initState() {
    super.initState();
    _withHeadings = widget.block.withHeadings;
    _controllers = widget.block.content.map((row) {
      // Ensure each row has at least 1 column
      return row.isEmpty
          ? [TextEditingController()]
          : row.map((cell) => TextEditingController(text: cell)).toList();
    }).toList();
    // Ensure at least 1 row × 1 column
    if (_controllers.isEmpty) _controllers = [[TextEditingController()]];
  }

  @override
  void dispose() {
    for (final row in _controllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  int get _colCount => _controllers.isEmpty
      ? 1
      : _controllers.map((r) => r.length).reduce((a, b) => a > b ? a : b);

  void _notify() {
    widget.onChanged(TableBlock(
      withHeadings: _withHeadings,
      stretched: widget.block.stretched,
      content: _controllers
          .map((row) => row.map((c) => c.text).toList())
          .toList(),
    ));
  }

  void _addRow() {
    setState(() {
      _controllers.add(
        List.generate(_colCount, (_) => TextEditingController()),
      );
    });
    _notify();
  }

  void _addColumn() {
    setState(() {
      for (final row in _controllers) {
        row.add(TextEditingController());
      }
    });
    _notify();
  }

  void _removeRow(int index) {
    if (_controllers.length <= 1) return;
    setState(() {
      for (final c in _controllers[index]) {
        c.dispose();
      }
      _controllers.removeAt(index);
    });
    _notify();
  }

  void _removeColumn(int index) {
    if (_colCount <= 1) return;
    setState(() {
      for (final row in _controllers) {
        if (index < row.length) {
          row[index].dispose();
          row.removeAt(index);
        }
      }
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final strings = EditorConfigScope.stringsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _withHeadings,
              onChanged: (v) {
                setState(() => _withHeadings = v ?? false);
                _notify();
              },
            ),
            Text(strings.firstRowIsHeader),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var r = 0; r < _controllers.length; r++)
                Row(
                  children: [
                    for (var c = 0; c < _controllers[r].length; c++)
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _controllers[r][c],
                          onChanged: (_) => _notify(),
                          style: TextStyle(
                            fontWeight: _withHeadings && r == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                      onPressed: () => _removeRow(r),
                      tooltip: strings.removeRow,
                    ),
                  ],
                ),
              // Remove column buttons
              Row(
                children: [
                  for (var c = 0; c < _colCount; c++)
                    SizedBox(
                      width: 120,
                      child: Center(
                        child: IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 16),
                          onPressed: () => _removeColumn(c),
                          tooltip: strings.removeColumn,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, size: 16),
              label: Text(strings.addRow),
            ),
            TextButton.icon(
              onPressed: _addColumn,
              icon: const Icon(Icons.add, size: 16),
              label: Text(strings.addColumn),
            ),
          ],
        ),
      ],
    );
  }
}
