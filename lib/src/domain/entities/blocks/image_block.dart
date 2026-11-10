import '../block_entity.dart';

class ImageBlock extends BlockEntity {
  final String url;
  final String? caption;
  final bool withBorder;
  final bool stretched;
  final bool withBackground;

  /// Any fields the upload backend stored in the `file` object besides `url`
  /// (for example `width`, `height` or an asset id). Preserved on serialize.
  final Map<String, dynamic> fileExtras;

  const ImageBlock({
    required this.url,
    this.caption,
    this.withBorder = false,
    this.stretched = false,
    this.withBackground = false,
    this.fileExtras = const {},
  });

  @override
  String get type => 'image';

  @override
  Map<String, dynamic> toJson() => {
        'file': {...fileExtras, 'url': url},
        'caption': caption ?? '',
        'withBorder': withBorder,
        'stretched': stretched,
        'withBackground': withBackground,
      };
}
