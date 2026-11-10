import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/attaches_block.dart';
import '../../config/block_editor_hooks.dart';
import '../../widgets/editor_config_scope.dart';
import '../base_block_editor.dart';

/// Edits an attachment block: where the file is and the title shown for it.
///
/// The file can be given as a URL, or chosen and uploaded through
/// `EditorConfig.attachmentPicker` when the app provides one.
class AttachesEditor extends BlockEditor<AttachesBlock> {
  const AttachesEditor({
    super.key,
    required super.block,
    required super.onChanged,
  });

  @override
  State<AttachesEditor> createState() => _AttachesEditorState();
}

class _AttachesEditorState extends State<AttachesEditor> {
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;
  late AttachesBlock _block;
  bool _picking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _block = widget.block;
    _urlController = TextEditingController(text: _block.url);
    _titleController = TextEditingController(text: _block.title ?? '');
  }

  @override
  void didUpdateWidget(covariant AttachesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block != widget.block) {
      _block = widget.block;
      if (_urlController.text.trim() != _block.url) {
        _urlController.text = _block.url;
      }
      if (_titleController.text != (_block.title ?? '')) {
        _titleController.text = _block.title ?? '';
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _update(AttachesBlock block) {
    setState(() => _block = block);
    widget.onChanged(block);
  }

  /// A typed URL points at a different file, so the name and extension are
  /// read from the URL and the size and backend fields of the previous file
  /// are dropped.
  void _setUrl(String value) {
    final url = value.trim();
    final name = _fileName(url);
    _update(AttachesBlock(
      url: url,
      name: name,
      extension: _extension(name),
      title: _block.title,
    ));
  }

  void _setTitle(String value) {
    _update(AttachesBlock(
      url: _block.url,
      name: _block.name,
      extension: _block.extension,
      size: _block.size,
      title: value,
      fileExtras: _block.fileExtras,
    ));
  }

  static String? _fileName(String url) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    final last = segments.isEmpty ? '' : segments.last;
    return last.isEmpty ? null : last;
  }

  static String? _extension(String? name) {
    if (name == null) return null;
    final dot = name.lastIndexOf('.');
    return dot <= 0 || dot == name.length - 1 ? null : name.substring(dot + 1);
  }

  Future<void> _pick(AttachmentPicker pick) async {
    final strings = EditorConfigScope.stringsOf(context);
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final picked = await pick();
      if (!mounted || picked == null) return;

      final title = picked.title;
      // A title the user already typed wins over an empty one from the picker.
      final block = AttachesBlock(
        url: picked.url,
        name: picked.name,
        extension: picked.extension,
        size: picked.size,
        title: title == null || title.isEmpty ? _block.title : title,
        fileExtras: picked.fileExtras,
      );
      _urlController.text = block.url;
      _titleController.text = block.title ?? '';
      _update(block);
    } catch (_) {
      // The picker is app code and may throw anything. The block keeps the
      // file it had.
      if (mounted) setState(() => _error = strings.attachFailed);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = EditorConfigScope.stringsOf(context);
    final picker = EditorConfigScope.maybeOf(context)?.attachmentPicker;
    final details = [
      if (_block.name != null) _block.name!,
      if (_block.size != null) strings.fileSize(_block.size!),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (picker != null)
          TextButton.icon(
            onPressed: _picking ? null : () => _pick(picker),
            icon: const Icon(Icons.attach_file, size: 18),
            label: Text(strings.chooseFile),
          ),
        if (_picking) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        TextField(
          controller: _urlController,
          onChanged: _setUrl,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: strings.fileUrl,
            hintText: 'https://...',
            isDense: true,
          ),
        ),
        if (details.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              details,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        TextField(
          controller: _titleController,
          onChanged: _setTitle,
          decoration: InputDecoration(labelText: strings.title, isDense: true),
        ),
      ],
    );
  }
}
