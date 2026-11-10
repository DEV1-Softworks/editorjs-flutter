import 'dart:typed_data';

/// An image the user picked from the camera or gallery, handed to an
/// [ImageUploader].
class PickedImage {
  /// Location of the file on the device. On the web this is a blob URL.
  final String path;

  /// File name, including the extension.
  final String name;

  /// MIME type reported by the platform, when it knows it.
  final String? mimeType;

  final Future<Uint8List> Function() _readAsBytes;

  const PickedImage({
    required this.path,
    required this.name,
    this.mimeType,
    required Future<Uint8List> Function() readAsBytes,
  }) : _readAsBytes = readAsBytes;

  /// Reads the whole file. Works on every platform, including the web.
  Future<Uint8List> readAsBytes() => _readAsBytes();
}

/// What an [ImageUploader] returns once the image is stored.
///
/// Mirrors the `file` object of the EditorJS image tool: the public [url],
/// plus any additional fields the backend wants saved with the block.
class UploadedImage {
  /// Public URL of the stored image.
  final String url;

  /// Extra fields to save in the block's `file` object next to `url`
  /// (for example `width`, `height` or an asset id).
  final Map<String, dynamic> extras;

  const UploadedImage({required this.url, this.extras = const {}});
}

/// Stores a picked image where readers of the document can reach it and
/// returns its public URL. Throw to report a failed upload; the editor keeps
/// the previous image and shows an error.
typedef ImageUploader = Future<UploadedImage> Function(PickedImage image);
