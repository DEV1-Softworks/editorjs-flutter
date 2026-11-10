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

  /// Returns a copy with the given fields replaced.
  ImageBlock copyWith({
    String? url,
    String? caption,
    bool? withBorder,
    bool? stretched,
    bool? withBackground,
    Map<String, dynamic>? fileExtras,
  }) =>
      ImageBlock(
        url: url ?? this.url,
        caption: caption ?? this.caption,
        withBorder: withBorder ?? this.withBorder,
        stretched: stretched ?? this.stretched,
        withBackground: withBackground ?? this.withBackground,
        fileExtras: fileExtras ?? this.fileExtras,
      );

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
