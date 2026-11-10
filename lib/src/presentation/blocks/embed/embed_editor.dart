import 'package:flutter/material.dart';

import '../../../data/utils/embed_services.dart';
import '../../../domain/entities/blocks/embed_block.dart';
import '../base_block_editor.dart';

/// Edits an embed block: the link to the content and its caption.
///
/// The service and the embed URL are worked out from the link, as the
/// EditorJS embed tool does when a link is pasted.
class EmbedEditor extends BlockEditor<EmbedBlock> {
  const EmbedEditor({
    super.key,
    required super.block,
    required super.onChanged,
  });

  @override
  State<EmbedEditor> createState() => _EmbedEditorState();
}

class _EmbedEditorState extends State<EmbedEditor> {
  late final TextEditingController _sourceController;
  late final TextEditingController _captionController;
  late EmbedBlock _block;

  @override
  void initState() {
    super.initState();
    _block = widget.block;
    _sourceController = TextEditingController(text: _block.source);
    _captionController = TextEditingController(text: _block.caption ?? '');
  }

  @override
  void didUpdateWidget(covariant EmbedEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block != widget.block) {
      _block = widget.block;
      if (_sourceController.text.trim() != _block.source) {
        _sourceController.text = _block.source;
      }
      if (_captionController.text != (_block.caption ?? '')) {
        _captionController.text = _block.caption ?? '';
      }
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _update(EmbedBlock block) {
    setState(() => _block = block);
    widget.onChanged(block);
  }

  void _setSource(String value) {
    final source = value.trim();
    final match = EmbedServices.resolve(source);
    _update(EmbedBlock(
      service: match?.service ?? '',
      source: source,
      embed: match?.embed ?? '',
      width: match?.width,
      height: match?.height,
      caption: _block.caption,
    ));
  }

  void _setCaption(String value) {
    // Only the caption changes: a block from a service this package does not
    // know keeps the service and embed URL it was saved with.
    _update(EmbedBlock(
      service: _block.service,
      source: _block.source,
      embed: _block.embed,
      width: _block.width,
      height: _block.height,
      caption: value,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final recognized = _block.service.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _sourceController,
          onChanged: _setSource,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Embed link',
            hintText: 'https://www.youtube.com/watch?v=...',
            isDense: true,
          ),
        ),
        if (_block.source.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              recognized
                  ? 'Service: ${_block.service}'
                  : 'This link is not from a supported service.',
              style: TextStyle(
                fontSize: 12,
                color: recognized
                    ? Colors.grey.shade600
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        TextField(
          controller: _captionController,
          onChanged: _setCaption,
          decoration: const InputDecoration(
            labelText: 'Caption',
            isDense: true,
          ),
        ),
      ],
    );
  }
}
