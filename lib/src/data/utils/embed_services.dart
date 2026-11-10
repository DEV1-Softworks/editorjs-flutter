/// What a pasted URL resolves to when it belongs to a known embed service.
class EmbedMatch {
  /// Service name as the EditorJS embed tool stores it (e.g. `youtube`).
  final String service;

  /// URL of the embeddable page (the iframe `src` on the web).
  final String embed;

  /// Default size EditorJS gives the embed, when the service defines one.
  final int? width;
  final int? height;

  const EmbedMatch({
    required this.service,
    required this.embed,
    this.width,
    this.height,
  });
}

/// Recognizes the services of the EditorJS embed tool and builds their embed
/// URLs.
///
/// The patterns and URL templates are those of `@editorjs/embed`, so an embed
/// block created here carries the same `service` and `embed` values the web
/// editor would have written for the same link. The discontinued Vine and
/// Gfycat services are left out.
class EmbedServices {
  EmbedServices._();

  /// Returns the service [url] belongs to, or `null` if it is not a link the
  /// embed tool understands.
  static EmbedMatch? resolve(String url) {
    final source = url.trim();
    if (source.isEmpty) return null;

    for (final service in _services) {
      final match = service.pattern.firstMatch(source);
      if (match == null) continue;

      final groups = [
        for (var i = 1; i <= match.groupCount; i++) match.group(i),
      ];
      final id = service.id(groups);
      if (id == null || id.isEmpty) continue;

      return EmbedMatch(
        service: service.name,
        embed: service.template.replaceAll(_placeholder, id),
        width: service.width,
        height: service.height,
      );
    }
    return null;
  }

  static const _placeholder = '{id}';

  /// The embed tool's default: the first captured group is the id.
  static String? _first(List<String?> groups) =>
      groups.isEmpty ? null : groups.first;

  static String? _second(List<String?> groups) =>
      groups.length < 2 ? null : groups[1];

  static String? Function(List<String?>) _joined(String separator) =>
      (groups) => groups.any((g) => g == null || g.isEmpty)
          ? null
          : groups.join(separator);

  /// Query parameters YouTube's player understands, keyed by the names they
  /// have in a watch URL.
  static const _youtubeParams = {
    'start': 'start',
    'end': 'end',
    't': 'start',
    'time_continue': 'start',
    'list': 'list',
  };

  static String? _youtubeId(List<String?> groups) {
    var id = groups.isNotEmpty ? groups[0] ?? '' : '';
    final query = groups.length > 1 ? groups[1] ?? '' : '';
    if (query.isEmpty) return id;

    final params = <String>[];
    for (final param in query.substring(1).split('&')) {
      final separator = param.indexOf('=');
      if (separator < 0) continue;
      final name = param.substring(0, separator);
      final value = param.substring(separator + 1);

      // `watch?feature=share&v=ID` carries the id as a parameter.
      if (id.isEmpty && name == 'v') {
        id = value;
        continue;
      }
      final playerName = _youtubeParams[name];
      if (playerName == null) continue;
      // Personal lists (liked videos, mixes, favourites) cannot be embedded.
      if (value == 'LL' || value.startsWith('RDMM') || value.startsWith('FL')) {
        continue;
      }
      params.add('$playerName=$value');
    }
    if (id.isEmpty) return null;
    return params.isEmpty ? id : '$id?${params.join('&')}';
  }

  static final List<_Service> _services = [
    _Service(
      'vimeo',
      r'(?:http[s]?:\/\/)?(?:www.)?(?:player.)?vimeo\.co(?:.+\/([^\/]\d+)(?:#t=[\d]+)?s?$)',
      'https://player.vimeo.com/video/{id}?title=0&byline=0',
      width: 580,
      height: 320,
    ),
    _Service(
      'youtube',
      r'(?:https?:\/\/)?(?:www\.)?(?:(?:youtu\.be\/)|(?:youtube\.com)\/(?:v\/|u\/\w\/|embed\/|watch|shorts\/))(?:(?:\?v=)?([^#&?=]*))?((?:[?&]\w*=[\w%+]*)*)',
      'https://www.youtube.com/embed/{id}',
      width: 580,
      height: 320,
      id: _youtubeId,
    ),
    _Service(
      'coub',
      r'https?:\/\/coub\.com\/view\/([^\/\?\&]+)',
      'https://coub.com/embed/{id}',
      width: 580,
      height: 320,
    ),
    _Service(
      'imgur',
      r'https?:\/\/(?:i\.)?imgur\.com.*\/([a-zA-Z0-9]+)(?:\.gifv)?',
      'http://imgur.com/{id}/embed',
      width: 540,
      height: 500,
    ),
    _Service(
      'twitch-channel',
      r'https?:\/\/www\.twitch\.tv\/([^\/\?\&]*)\/?$',
      'https://player.twitch.tv/?channel={id}',
      width: 600,
      height: 366,
    ),
    _Service(
      'twitch-video',
      r'https?:\/\/www\.twitch\.tv\/(?:[^\/\?\&]*\/v|videos)\/([0-9]*)',
      'https://player.twitch.tv/?video=v{id}',
      width: 600,
      height: 366,
    ),
    _Service(
      'yandex-music-album',
      r'https?:\/\/music\.yandex\.ru\/album\/([0-9]*)\/?$',
      'https://music.yandex.ru/iframe/#album/{id}/',
      width: 540,
      height: 400,
    ),
    _Service(
      'yandex-music-track',
      r'https?:\/\/music\.yandex\.ru\/track\/([0-9]*)(?:\?.*)?',
      'https://music.yandex.ru/iframe/#track/{id}/',
      width: 540,
      height: 100,
    ),
    _Service(
      'yandex-music-playlist',
      r'https?:\/\/music\.yandex\.ru\/users\/([^\/\?\&]*)\/playlists\/([0-9]*)',
      'https://music.yandex.ru/iframe/#playlist/{id}/show/cover/description/',
      width: 540,
      height: 400,
      id: _joined('/'),
    ),
    _Service(
      'codepen',
      r'https?:\/\/codepen\.io\/([^\/\?\&]*)\/pen\/([^\/\?\&]*)',
      'https://codepen.io/{id}?height=300&theme-id=0&default-tab=css,result&embed-version=2',
      width: 600,
      height: 300,
      id: _joined('/embed/'),
    ),
    _Service(
      'instagram',
      r'^https:\/\/(?:www\.)?instagram\.com\/(?:reel|p)\/(.*)',
      'https://www.instagram.com/p/{id}/embed',
      width: 400,
      height: 505,
      id: (groups) => _first(groups)?.split('/').first,
    ),
    _Service(
      'twitter',
      r'^https?:\/\/(www\.)?(?:twitter\.com|x\.com)\/.+\/status\/(\d+)',
      'https://platform.twitter.com/embed/Tweet.html?id={id}',
      width: 600,
      height: 300,
      id: _second,
    ),
    _Service(
      'reddit',
      r'https:\/\/www\.reddit\.com\/(.*)',
      'https://www.redditmedia.com/{id}?ref_source=embed&ref=share&embed=true',
      width: 600,
      height: 300,
    ),
    _Service(
      'pinterest',
      r'https?:\/\/([^\/\?\&]*).pinterest.com\/pin\/([^\/\?\&]*)\/?$',
      'https://assets.pinterest.com/ext/embed.html?id={id}',
      id: _second,
    ),
    _Service(
      'facebook',
      r'https?:\/\/www.facebook.com\/([^\/\?\&]*)\/(.*)',
      'https://www.facebook.com/plugins/post.php?href=https://www.facebook.com/{id}&width=500',
      id: _joined('/'),
    ),
    _Service(
      'aparat',
      r'(?:http[s]?:\/\/)?(?:www.)?aparat\.com\/v\/([^\/\?\&]+)\/?',
      'https://www.aparat.com/video/video/embed/videohash/{id}/vt/frame',
      width: 600,
      height: 300,
    ),
    _Service(
      'miro',
      r'https:\/\/miro.com\/\S+(\S{12})\/(\S+)?',
      'https://miro.com/app/live-embed/{id}',
    ),
    _Service(
      'github',
      r'https?:\/\/gist.github.com\/([^\/\?\&]*)\/([^\/\?\&]*)',
      'data:text/html;charset=utf-8,<head><base target="_blank" /></head><body><script src="https://gist.github.com/{id}" ></script></body>',
      width: 600,
      height: 300,
      id: (groups) {
        final path = _joined('/')(groups);
        return path == null ? null : '$path.js';
      },
    ),
    _Service(
      'whimsical',
      r'(https:\/\/)?whimsical.com\/(?:[a-zA-Z0-9\-]+\-)?([a-km-zA-HJ-NP-Z1-9]{16,22})(@[a-km-zA-HJ-NP-Z1-9]+)?',
      'https://whimsical.com/embed/{id}',
      width: 600,
      height: 300,
      id: _second,
    ),
    _Service(
      'figma',
      r'(https:\/\/www\.figma\.com\/.+)',
      'https://www.figma.com/embed?embed_host=share&url={id}',
      width: 600,
      height: 300,
    ),
  ];
}

class _Service {
  _Service(
    this.name,
    String pattern,
    this.template, {
    this.width,
    this.height,
    String? Function(List<String?> groups)? id,
  })  : pattern = RegExp(pattern),
        id = id ?? EmbedServices._first;

  final String name;
  final RegExp pattern;

  /// Embed URL with `{id}` where the resource id goes.
  final String template;
  final int? width;
  final int? height;

  /// Builds the resource id from the pattern's captured groups.
  final String? Function(List<String?> groups) id;
}
