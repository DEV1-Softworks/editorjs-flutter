import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/blocks/list_block.dart';
import '../../config/editor_strings.dart';
import '../../utils/list_counter_formatter.dart';
import '../base_block_editor.dart';
import '../../widgets/editor_config_scope.dart';

class ListEditor extends BlockEditor<ListBlock> {
  const ListEditor({super.key, required super.block, required super.onChanged});

  @override
  State<ListEditor> createState() => _ListEditorState();
}

/// One editable line of the list.
///
/// The nested [ListItem] tree is edited as a flat outline: every item is a
/// row with a depth, and a row's children are the deeper rows that follow it.
/// Indenting and outdenting then only change depths, and the tree is rebuilt
/// from the rows whenever the block is reported upward.
class _Row {
  _Row({required String text, required this.depth, required this.checked})
      : controller = TextEditingController(text: text);

  final TextEditingController controller;
  final FocusNode focusNode = FocusNode();
  int depth;
  bool checked;

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class _ListEditorState extends State<ListEditor> {
  /// Order of the buttons in the style selector.
  static const _styles = [
    ListStyle.unordered,
    ListStyle.ordered,
    ListStyle.checklist,
  ];

  static const double _indentPerLevel = 16;

  late List<_Row> _rows;
  late ListStyle _style;
  late int? _start;
  late ListCounterType? _counterType;
  late final TextEditingController _startController;

  @override
  void initState() {
    super.initState();
    _rows = _flatten(widget.block.items);
    _style = widget.block.style;
    _start = widget.block.start;
    _counterType = widget.block.counterType;
    _startController = TextEditingController(text: _start?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    _startController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ListEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block != widget.block) {
      setState(() {
        _syncRows(widget.block.items);
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

  // ---------------------------------------------------------------------------
  // Tree <-> rows
  // ---------------------------------------------------------------------------

  /// The items of a tree in display order, each with its nesting depth.
  static List<(ListItem, int)> _outline(List<ListItem> items) {
    final outline = <(ListItem, int)>[];
    void visit(List<ListItem> level, int depth) {
      for (final item in level) {
        outline.add((item, depth));
        visit(item.items, depth + 1);
      }
    }

    visit(items, 0);
    return outline;
  }

  static List<_Row> _flatten(List<ListItem> items) => [
        for (final (item, depth) in _outline(items))
          _Row(text: item.content, depth: depth, checked: item.checked),
      ];

  /// Brings the rows in line with [items], reusing the existing rows so that
  /// text fields keep their cursor and focus across the parent's rebuilds.
  void _syncRows(List<ListItem> items) {
    final outline = _outline(items);
    final synced = <_Row>[];
    for (var i = 0; i < outline.length; i++) {
      final (item, depth) = outline[i];
      if (i < _rows.length) {
        final row = _rows[i];
        // Only update text when the content actually differs to avoid
        // resetting the cursor during normal typing round-trips.
        if (row.controller.text != item.content) {
          row.controller.text = item.content;
        }
        row
          ..depth = depth
          ..checked = item.checked;
        synced.add(row);
      } else {
        synced.add(
          _Row(text: item.content, depth: depth, checked: item.checked),
        );
      }
    }
    // Dispose extra rows only after building the new list so that an
    // unexpected error cannot leave _rows in a partial state.
    for (var i = outline.length; i < _rows.length; i++) {
      _rows[i].dispose();
    }
    _rows = synced;
  }

  List<ListItem> _toTree() {
    var index = 0;
    List<ListItem> build(int depth) {
      final items = <ListItem>[];
      while (index < _rows.length && _rows[index].depth >= depth) {
        final row = _rows[index++];
        items.add(ListItem(
          content: row.controller.text,
          checked: row.checked,
          items: build(depth + 1),
        ));
      }
      return items;
    }

    return build(0);
  }

  /// Index just past the last descendant of the row at [index].
  int _subtreeEnd(int index) {
    var end = index + 1;
    while (end < _rows.length && _rows[end].depth > _rows[index].depth) {
      end++;
    }
    return end;
  }

  // ---------------------------------------------------------------------------
  // Edits
  // ---------------------------------------------------------------------------

  void _notify() {
    widget.onChanged(ListBlock(
      style: _style,
      items: _toTree(),
      start: _start,
      counterType: _counterType,
    ));
  }

  void _addItem() {
    setState(() {
      _rows.add(_Row(text: '', depth: 0, checked: false));
    });
    _notify();
  }

  /// Adds an empty sibling below the row at [index] (after its children) and
  /// moves the cursor into it.
  void _insertAfter(int index) {
    final row = _Row(text: '', depth: _rows[index].depth, checked: false);
    setState(() => _rows.insert(_subtreeEnd(index), row));
    _notify();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _rows.contains(row)) row.focusNode.requestFocus();
    });
  }

  /// Removes a row together with all of its children.
  void _removeItem(int index) {
    setState(() {
      final end = _subtreeEnd(index);
      for (var i = index; i < end; i++) {
        _rows[i].dispose();
      }
      _rows.removeRange(index, end);
    });
    _notify();
  }

  /// A row can be removed unless that would empty the list: the list always
  /// keeps at least one item.
  bool _canRemove(int index) => _subtreeEnd(index) - index < _rows.length;

  /// A row can become a child of the row above it.
  bool _canIndent(int index) =>
      index > 0 && _rows[index].depth <= _rows[index - 1].depth;

  bool _canOutdent(int index) => _rows[index].depth > 0;

  /// Moves a row and its children one level in ([delta] 1) or out (-1).
  void _shift(int index, int delta) {
    setState(() {
      final end = _subtreeEnd(index);
      for (var i = index; i < end; i++) {
        _rows[i].depth += delta;
      }
    });
    _notify();
  }

  void _toggleChecked(int index) {
    setState(() => _rows[index].checked = !_rows[index].checked);
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final strings = EditorConfigScope.stringsOf(context);
    final markers = _style == ListStyle.ordered ? _orderedMarkers() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettings(strings),
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: EdgeInsets.only(left: _rows[i].depth * _indentPerLevel),
            child: Row(
              children: [
                _buildMarker(i, markers?[i]),
                Expanded(
                  child: TextField(
                    controller: _rows[i].controller,
                    focusNode: _rows[i].focusNode,
                    onChanged: (_) => _notify(),
                    // Enter starts the next item, as in any list editor.
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => _insertAfter(i),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                _RowButton(
                  icon: Icons.format_indent_decrease,
                  tooltip: strings.outdent,
                  onPressed: _canOutdent(i) ? () => _shift(i, -1) : null,
                ),
                _RowButton(
                  icon: Icons.format_indent_increase,
                  tooltip: strings.indent,
                  onPressed: _canIndent(i) ? () => _shift(i, 1) : null,
                ),
                _RowButton(
                  icon: Icons.remove_circle_outline,
                  tooltip: strings.removeItem,
                  onPressed: _canRemove(i) ? () => _removeItem(i) : null,
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add, size: 16),
          label: Text(strings.addItem),
        ),
      ],
    );
  }

  /// Style selector, plus the numbering options when the list is ordered.
  Widget _buildSettings(EditorStrings strings) {
    final counterTypeLabels = {
      ListCounterType.numeric: strings.counterNumeric,
      ListCounterType.lowerRoman: strings.counterLowerRoman,
      ListCounterType.upperRoman: strings.counterUpperRoman,
      ListCounterType.lowerAlpha: strings.counterLowerAlpha,
      ListCounterType.upperAlpha: strings.counterUpperAlpha,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ToggleButtons(
            isSelected: [for (final style in _styles) style == _style],
            onPressed: (index) => _setStyle(_styles[index]),
            constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
            borderRadius: BorderRadius.circular(4),
            children: [
              Tooltip(
                message: strings.listUnordered,
                child: const Icon(Icons.format_list_bulleted, size: 18),
              ),
              Tooltip(
                message: strings.listOrdered,
                child: const Icon(Icons.format_list_numbered, size: 18),
              ),
              Tooltip(
                message: strings.listChecklist,
                child: const Icon(Icons.checklist, size: 18),
              ),
            ],
          ),
          if (_style == ListStyle.ordered) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 72,
              child: TextField(
                controller: _startController,
                onChanged: _setStart,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: strings.startWith,
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
                for (final entry in counterTypeLabels.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// The marker of every row of an ordered list, numbered as the viewer
  /// numbers them: `start` applies to the top level, children count from 1.
  List<String> _orderedMarkers() {
    // Counter of each open level, outermost first, for the row being visited.
    final counters = <int>[];
    final markers = <String>[];
    for (final row in _rows) {
      if (counters.length > row.depth + 1) {
        counters.removeRange(row.depth + 1, counters.length);
      }
      if (counters.length == row.depth + 1) {
        counters[row.depth]++;
      } else {
        counters.add(row.depth == 0 ? (_start ?? 1) : 1);
      }
      markers.add(ListCounterFormatter.marker(counters, _counterType));
    }
    return markers;
  }

  Widget _buildMarker(int index, String? orderedMarker) {
    if (_style == ListStyle.checklist) {
      return Checkbox(
        value: _rows[index].checked,
        onChanged: (_) => _toggleChecked(index),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        orderedMarker ?? '•',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

/// Compact per-row action button.
class _RowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _RowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Three of these sit in every row, so they are narrower than the default
    // 48 px icon button to leave room for the item text on a phone.
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(36, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
