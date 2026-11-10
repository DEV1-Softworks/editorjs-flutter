import '../block_entity.dart';

class LinkToolMeta {
  final String? title;
  final String? description;
  final String? imageUrl;

  /// Any fields the link-fetching backend returned besides `title`,
  /// `description` and `image` (for example `site_name`). Preserved on
  /// serialize.
  final Map<String, dynamic> extras;

  const LinkToolMeta({
    this.title,
    this.description,
    this.imageUrl,
    this.extras = const {},
  });

  Map<String, dynamic> toJson() => {
        ...extras,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (imageUrl != null) 'image': {'url': imageUrl},
      };
}

class LinkToolBlock extends BlockEntity {
  final String link;
  final LinkToolMeta? meta;

  const LinkToolBlock({required this.link, this.meta});

  @override
  String get type => 'linkTool';

  @override
  Map<String, dynamic> toJson() => {
        'link': link,
        if (meta != null) 'meta': meta!.toJson(),
      };
}
