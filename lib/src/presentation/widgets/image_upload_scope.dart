import 'package:flutter/widgets.dart';

import '../config/image_uploader.dart';

/// Carries `EditorConfig.imageUploader` down to the image editor, which is
/// built by the block registry and therefore cannot receive it as an argument.
class ImageUploadScope extends InheritedWidget {
  final ImageUploader? uploader;

  const ImageUploadScope({
    super.key,
    required this.uploader,
    required super.child,
  });

  /// The uploader configured for the surrounding editor, if any.
  static ImageUploader? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ImageUploadScope>()?.uploader;

  @override
  bool updateShouldNotify(ImageUploadScope oldWidget) =>
      uploader != oldWidget.uploader;
}
