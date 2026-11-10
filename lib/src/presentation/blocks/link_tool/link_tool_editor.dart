import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/link_tool_block.dart';
import '../../config/block_editor_hooks.dart';
import '../../widgets/editor_config_scope.dart';
import '../base_block_editor.dart';

/// Edits a link block: the link and the preview shown with it.
///
/// The preview fields can be filled in by hand, or fetched for the link when
/// `EditorConfig.linkPreviewFetcher` is set.
class LinkToolEditor extends BlockEditor<LinkToolBlock> {
  const LinkToolEditor({
    super.key,
    required super.block,
    required super.onChanged,
  });

  @override
  State<LinkToolEditor> createState() => _LinkToolEditorState();
}

class _LinkToolEditorState extends State<LinkToolEditor> {
  late final TextEditingController _linkController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageController;

  /// Preview fields the backend sent that this editor has no input for.
  late Map<String, dynamic> _extras;
  bool _fetching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final block = widget.block;
    _extras = block.meta?.extras ?? const {};
    _linkController = TextEditingController(text: block.link);
    _titleController = TextEditingController(text: block.meta?.title ?? '');
    _descriptionController =
        TextEditingController(text: block.meta?.description ?? '');
    _imageController = TextEditingController(text: block.meta?.imageUrl ?? '');
  }

  @override
  void didUpdateWidget(covariant LinkToolEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block != widget.block) {
      final block = widget.block;
      _extras = block.meta?.extras ?? const {};
      _sync(_linkController, block.link, trimmed: true);
      _sync(_titleController, block.meta?.title ?? '');
      _sync(_descriptionController, block.meta?.description ?? '');
      _sync(_imageController, block.meta?.imageUrl ?? '', trimmed: true);
    }
  }

  /// Leaves a field alone while it already says the same thing, so the cursor
  /// does not jump while the user is typing in it.
  static void _sync(
    TextEditingController controller,
    String value, {
    bool trimmed = false,
  }) {
    final current = trimmed ? controller.text.trim() : controller.text;
    if (current != value) controller.text = value;
  }

  @override
  void dispose() {
    _linkController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  static String? _orNull(String text) => text.isEmpty ? null : text;

  void _notify() {
    final title = _orNull(_titleController.text);
    final description = _orNull(_descriptionController.text);
    final imageUrl = _orNull(_imageController.text.trim());
    final hasMeta = title != null ||
        description != null ||
        imageUrl != null ||
        _extras.isNotEmpty;

    widget.onChanged(LinkToolBlock(
      link: _linkController.text.trim(),
      meta: hasMeta
          ? LinkToolMeta(
              title: title,
              description: description,
              imageUrl: imageUrl,
              extras: _extras,
            )
          : null,
    ));
  }

  Future<void> _fetchPreview(LinkPreviewFetcher fetch) async {
    final link = _linkController.text.trim();
    if (link.isEmpty) return;
    final strings = EditorConfigScope.stringsOf(context);

    setState(() {
      _fetching = true;
      _error = null;
    });
    try {
      final meta = await fetch(link);
      if (!mounted) return;
      if (meta == null) {
        setState(() => _error = strings.noPreview);
        return;
      }
      _titleController.text = meta.title ?? '';
      _descriptionController.text = meta.description ?? '';
      _imageController.text = meta.imageUrl ?? '';
      _extras = meta.extras;
      _notify();
    } catch (_) {
      // The fetcher is app code and may throw anything. The fields keep what
      // they had.
      if (mounted) setState(() => _error = strings.previewFailed);
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = EditorConfigScope.stringsOf(context);
    final fetcher = EditorConfigScope.maybeOf(context)?.linkPreviewFetcher;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _linkController,
          onChanged: (_) => _notify(),
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: strings.linkUrl,
            hintText: 'https://...',
            isDense: true,
          ),
        ),
        if (fetcher != null)
          TextButton.icon(
            onPressed: _fetching ? null : () => _fetchPreview(fetcher),
            icon: const Icon(Icons.travel_explore, size: 18),
            label: Text(strings.fetchPreview),
          ),
        if (_fetching) const LinearProgressIndicator(),
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
          controller: _titleController,
          onChanged: (_) => _notify(),
          decoration: InputDecoration(labelText: strings.title, isDense: true),
        ),
        TextField(
          controller: _descriptionController,
          onChanged: (_) => _notify(),
          maxLines: null,
          decoration: InputDecoration(
            labelText: strings.description,
            isDense: true,
          ),
        ),
        TextField(
          controller: _imageController,
          onChanged: (_) => _notify(),
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: strings.previewImageUrl,
            isDense: true,
          ),
        ),
      ],
    );
  }
}
