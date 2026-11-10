import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/entities/blocks/image_block.dart';
import '../../config/image_uploader.dart';
import '../../widgets/editor_config_scope.dart';
import '../base_block_editor.dart';

class ImageEditor extends BlockEditor<ImageBlock> {
  const ImageEditor({
    super.key,
    required super.block,
    required super.onChanged,
  });

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _urlController;
  late final TextEditingController _captionController;

  /// The block as last edited here. Kept locally so that several edits in a
  /// row build on each other even before the parent hands the block back.
  late ImageBlock _block;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _block = widget.block;
    _urlController = TextEditingController(text: _block.url);
    _captionController = TextEditingController(text: _block.caption ?? '');
  }

  @override
  void didUpdateWidget(covariant ImageEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block != widget.block) {
      _block = widget.block;
      // Leave a field alone while it already says the same thing, so the
      // cursor does not jump while the user is typing in it.
      if (_urlController.text.trim() != _block.url) {
        _urlController.text = _block.url;
      }
      if (_captionController.text != (_block.caption ?? '')) {
        _captionController.text = _block.caption ?? '';
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _update(ImageBlock block) {
    setState(() => _block = block);
    widget.onChanged(block);
  }

  /// Replaces the image itself. Fields describing the previous file are
  /// dropped; caption and display options stay.
  void _setImage(String url, {Map<String, dynamic> extras = const {}}) {
    _update(_block.copyWith(url: url, fileExtras: extras));
  }

  Future<void> _pickImage(ImageSource source) async {
    final uploader = EditorConfigScope.maybeOf(context)?.imageUploader;
    setState(() => _error = null);

    final XFile? file;
    try {
      file = await _picker.pickImage(source: source);
    } on PlatformException {
      if (mounted) setState(() => _error = 'Could not open the image.');
      return;
    }
    if (file == null || !mounted) return;

    if (uploader == null) {
      // No upload configured: the block points at the file on this device.
      _urlController.text = file.path;
      _setImage(file.path);
      return;
    }

    setState(() => _uploading = true);
    try {
      final uploaded = await uploader(PickedImage(
        path: file.path,
        name: file.name,
        mimeType: file.mimeType,
        readAsBytes: file.readAsBytes,
      ));
      if (!mounted) return;
      _urlController.text = uploaded.url;
      _setImage(uploaded.url, extras: uploaded.extras);
    } catch (_) {
      // The uploader is app code and may throw anything. The block keeps the
      // image it had.
      if (mounted) setState(() => _error = 'Upload failed. Try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  static bool _isRemote(String url) {
    final scheme = Uri.tryParse(url)?.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_block.url.isNotEmpty) _buildPreview(),
        if (_uploading) const LinearProgressIndicator(),
        Row(
          children: [
            TextButton.icon(
              onPressed:
                  _uploading ? null : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Camera'),
            ),
            TextButton.icon(
              onPressed:
                  _uploading ? null : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gallery'),
            ),
          ],
        ),
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
          onChanged: (value) => _setImage(value.trim()),
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            hintText: 'https://...',
            isDense: true,
          ),
        ),
        TextField(
          controller: _captionController,
          onChanged: (value) => _update(_block.copyWith(caption: value)),
          decoration: const InputDecoration(
            labelText: 'Caption',
            isDense: true,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Border'),
              selected: _block.withBorder,
              onSelected: (value) =>
                  _update(_block.copyWith(withBorder: value)),
            ),
            FilterChip(
              label: const Text('Stretch'),
              selected: _block.stretched,
              onSelected: (value) => _update(_block.copyWith(stretched: value)),
            ),
            FilterChip(
              label: const Text('Background'),
              selected: _block.withBackground,
              onSelected: (value) =>
                  _update(_block.copyWith(withBackground: value)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    // On the web a picked file is a blob URL, which only the network image
    // loader can read.
    if (kIsWeb || _isRemote(_block.url)) {
      return Image.network(
        _block.url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ImageErrorPlaceholder(),
      );
    }
    return Image.file(
      File(_block.url),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _ImageErrorPlaceholder(),
    );
  }
}

class _ImageErrorPlaceholder extends StatelessWidget {
  const _ImageErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }
}
