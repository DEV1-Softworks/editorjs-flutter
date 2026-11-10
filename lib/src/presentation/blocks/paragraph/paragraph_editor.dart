import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/paragraph_block.dart';
import '../base_block_editor.dart';

class ParagraphEditor extends BlockEditor<ParagraphBlock> {
  const ParagraphEditor({
    super.key,
    required super.block,
    required super.onChanged,
  });

  @override
  State<ParagraphEditor> createState() => _ParagraphEditorState();
}

/// An `<a>` element found in the paragraph's HTML.
class _Anchor {
  const _Anchor({
    required this.start,
    required this.end,
    required this.attributes,
    required this.href,
    required this.inner,
  });

  /// Range of the whole element, tags included.
  final int start;
  final int end;

  /// Everything inside the opening tag after `<a`, as written.
  final String attributes;

  /// The link target, with HTML entities decoded.
  final String href;

  /// The HTML between the opening and closing tag.
  final String inner;
}

/// What the user chose in the link dialog.
class _LinkChoice {
  const _LinkChoice.save(String this.url);
  const _LinkChoice.remove() : url = null;

  /// The target to link to, or `null` to remove the link.
  final String? url;
}

class _ParagraphEditorState extends State<ParagraphEditor> {
  static final _anchorPattern = RegExp(
    r'<a\b([^>]*)>(.*?)</a>',
    caseSensitive: false,
    dotAll: true,
  );
  static final _hrefPattern = RegExp(
    r'''href\s*=\s*(?:"([^"]*)"|'([^']*)')''',
    caseSensitive: false,
  );
  static final _explicitScheme = RegExp(
    r'^(?:[a-z][a-z0-9+.-]*://|mailto:|tel:)',
    caseSensitive: false,
  );

  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _showFormatBar = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.block.html);
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _showFormatBar = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ParagraphEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.html != widget.block.html && !_focusNode.hasFocus) {
      final newText = widget.block.html;
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  void _onTextChanged(String value) {
    widget.onChanged(ParagraphBlock(html: value));
  }

  void _applyFormat(String openTag, String closeTag) {
    final sel = _textController.selection;
    if (!sel.isValid) return;
    final text = _textController.text;
    final String newText;
    final int newCursor;

    if (sel.isCollapsed) {
      // No selection — insert tags with cursor between them
      newText = text.replaceRange(sel.start, sel.end, '$openTag$closeTag');
      newCursor = sel.start + openTag.length;
    } else {
      final selected = text.substring(sel.start, sel.end);
      newText = text.replaceRange(sel.start, sel.end, '$openTag$selected$closeTag');
      newCursor = sel.start + openTag.length + selected.length + closeTag.length;
    }

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _onTextChanged(newText);
  }

  // ---------------------------------------------------------------------------
  // Links
  // ---------------------------------------------------------------------------

  /// The link the caret at [offset] is in or next to, if any.
  static _Anchor? _anchorAt(String html, int offset) {
    for (final match in _anchorPattern.allMatches(html)) {
      if (offset < match.start || offset > match.end) continue;
      final href = _hrefPattern.firstMatch(match.group(1)!);
      return _Anchor(
        start: match.start,
        end: match.end,
        attributes: match.group(1)!,
        href: _decodeAttribute(href?.group(1) ?? href?.group(2) ?? ''),
        inner: match.group(2)!,
      );
    }
    return null;
  }

  static String _encodeAttribute(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _decodeAttribute(String value) => value
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');

  /// Returns the attributes of an opening `<a` tag with the target replaced by
  /// [url], keeping any others (`target`, `rel`, …) as they were.
  static String _withHref(String attributes, String url) {
    final href = 'href="${_encodeAttribute(url)}"';
    return _hrefPattern.hasMatch(attributes)
        ? attributes.replaceFirst(_hrefPattern, href)
        : ' $href$attributes';
  }

  /// Completes a typed address such as `example.com` to a web link. Absolute
  /// URLs, `mailto:`/`tel:` links and in-site targets (`/path`, `#section`)
  /// are left as typed.
  static String _normalizeUrl(String input) {
    final url = input.trim();
    if (url.isEmpty ||
        url.startsWith('/') ||
        url.startsWith('#') ||
        _explicitScheme.hasMatch(url)) {
      return url;
    }
    return 'https://$url';
  }

  /// Adds a link to the selected text, or edits or removes the link the caret
  /// is in.
  Future<void> _editLink() async {
    // The dialog takes the focus, so remember where the caret was.
    final selection = _textController.selection;
    if (!selection.isValid) return;
    final html = _textController.text;
    final anchor = _anchorAt(html, selection.start);

    final choice = await showDialog<_LinkChoice>(
      context: context,
      builder: (_) => _LinkDialog(initialUrl: anchor?.href),
    );
    if (!mounted || choice == null) return;

    final url = choice.url == null ? null : _normalizeUrl(choice.url!);
    if (url != null && url.isEmpty) return;

    final int start;
    final int end;
    final String replacement;
    if (anchor != null) {
      start = anchor.start;
      end = anchor.end;
      replacement = url == null
          ? anchor.inner
          : '<a${_withHref(anchor.attributes, url)}>${anchor.inner}</a>';
    } else {
      if (url == null) return;
      start = selection.start;
      end = selection.end;
      // With nothing selected the address itself becomes the link text.
      final label = selection.isCollapsed ? url : html.substring(start, end);
      replacement = '<a href="${_encodeAttribute(url)}">$label</a>';
    }

    final updated = html.replaceRange(start, end, replacement);
    _textController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
    _focusNode.requestFocus();
    _onTextChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showFormatBar)
            _InlineFormatBar(onFormat: _applyFormat, onLink: _editLink),
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            onChanged: _onTextChanged,
            decoration: const InputDecoration(
              hintText: 'Write something...',
              border: InputBorder.none,
            ),
            maxLines: null,
            keyboardType: TextInputType.multiline,
          ),
        ],
      ),
    );
  }
}

class _InlineFormatBar extends StatelessWidget {
  final void Function(String openTag, String closeTag) onFormat;
  final VoidCallback onLink;

  const _InlineFormatBar({required this.onFormat, required this.onLink});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FormatButton(
            label: 'B',
            bold: true,
            tooltip: 'Bold',
            onTap: () => onFormat('<b>', '</b>'),
          ),
          _FormatButton(
            label: 'I',
            italic: true,
            tooltip: 'Italic',
            onTap: () => onFormat('<i>', '</i>'),
          ),
          _FormatButton(
            label: 'U',
            underline: true,
            tooltip: 'Underline',
            onTap: () => onFormat('<u>', '</u>'),
          ),
          _FormatButton(
            label: 'S',
            strikethrough: true,
            tooltip: 'Strikethrough',
            onTap: () => onFormat('<s>', '</s>'),
          ),
          _FormatButton(
            label: '</>',
            monospace: true,
            tooltip: 'Inline code',
            onTap: () => onFormat('<code>', '</code>'),
          ),
          _FormatButton(
            label: 'mark',
            highlight: true,
            tooltip: 'Highlight',
            onTap: () => onFormat('<mark>', '</mark>'),
          ),
          _FormatButton(
            label: 'link',
            underline: true,
            tooltip: 'Link',
            onTap: onLink,
          ),
        ],
      ),
    );
  }
}

/// Asks for the target of a link. Pops with a [_LinkChoice], or with nothing
/// when cancelled.
class _LinkDialog extends StatefulWidget {
  /// The current target when an existing link is being edited.
  final String? initialUrl;

  const _LinkDialog({this.initialUrl});

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialUrl ?? '');

  bool get _editing => widget.initialUrl != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    Navigator.pop(context, _LinkChoice.save(url));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'Edit link' : 'Add link'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        autocorrect: false,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(
          labelText: 'Link address',
          hintText: 'https://...',
        ),
      ),
      actions: [
        if (_editing)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const _LinkChoice.remove()),
            child: const Text('Remove link'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _FormatButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final bool monospace;
  final bool highlight;

  const _FormatButton({
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.monospace = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          margin: const EdgeInsets.only(right: 2),
          decoration: highlight
              ? BoxDecoration(
                  color: Colors.yellow.shade200,
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                decoration: underline
                    ? TextDecoration.underline
                    : strikethrough
                        ? TextDecoration.lineThrough
                        : null,
                fontFamily: monospace ? 'monospace' : null,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
