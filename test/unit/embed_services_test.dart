import 'package:editorjs_flutter/src/data/utils/embed_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void expectEmbed(String url, String service, String embed) {
    final match = EmbedServices.resolve(url);
    expect(match, isNotNull, reason: '$url was not recognised');
    expect(match!.service, service, reason: url);
    expect(match.embed, embed, reason: url);
  }

  group('YouTube', () {
    const base = 'https://www.youtube.com/embed/';

    test('watch, short, shorts and embed links', () {
      expectEmbed(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'youtube',
        '${base}dQw4w9WgXcQ',
      );
      expectEmbed('https://youtu.be/dQw4w9WgXcQ', 'youtube', '${base}dQw4w9WgXcQ');
      expectEmbed(
        'https://www.youtube.com/shorts/abc123XYZ_-',
        'youtube',
        '${base}abc123XYZ_-',
      );
      expectEmbed('https://www.youtube.com/embed/ID123', 'youtube', '${base}ID123');
    });

    test('start time and playlist are carried over', () {
      expectEmbed(
        'https://www.youtube.com/watch?v=ID123&t=42',
        'youtube',
        '${base}ID123?start=42',
      );
      expectEmbed(
        'https://www.youtube.com/watch?v=ID123&list=PL123&start=10',
        'youtube',
        '${base}ID123?list=PL123&start=10',
      );
    });

    test('the id is found when it is not the first parameter', () {
      expectEmbed(
        'https://www.youtube.com/watch?feature=share&v=ID123',
        'youtube',
        '${base}ID123',
      );
    });

    test('personal lists and unknown parameters are dropped', () {
      expectEmbed(
        'https://www.youtube.com/watch?v=ID123&list=LL&si=abc',
        'youtube',
        '${base}ID123',
      );
      expectEmbed(
        'https://www.youtube.com/watch?v=ID123&list=RDMMxyz',
        'youtube',
        '${base}ID123',
      );
    });

    test('has the size EditorJS gives it', () {
      final match = EmbedServices.resolve('https://youtu.be/ID123')!;
      expect(match.width, 580);
      expect(match.height, 320);
    });
  });

  test('video services', () {
    expectEmbed(
      'https://vimeo.com/123456789',
      'vimeo',
      'https://player.vimeo.com/video/123456789?title=0&byline=0',
    );
    expectEmbed(
      'https://coub.com/view/1czcdf',
      'coub',
      'https://coub.com/embed/1czcdf',
    );
    expectEmbed(
      'https://www.twitch.tv/ninja',
      'twitch-channel',
      'https://player.twitch.tv/?channel=ninja',
    );
    expectEmbed(
      'https://www.twitch.tv/videos/123456',
      'twitch-video',
      'https://player.twitch.tv/?video=v123456',
    );
    expectEmbed(
      'https://www.aparat.com/v/abc12',
      'aparat',
      'https://www.aparat.com/video/video/embed/videohash/abc12/vt/frame',
    );
  });

  test('social services', () {
    expectEmbed(
      'https://twitter.com/codex_team/status/1234567890',
      'twitter',
      'https://platform.twitter.com/embed/Tweet.html?id=1234567890',
    );
    expectEmbed(
      'https://x.com/someone/status/987',
      'twitter',
      'https://platform.twitter.com/embed/Tweet.html?id=987',
    );
    expectEmbed(
      'https://www.instagram.com/p/CODE123/?utm_source=share',
      'instagram',
      'https://www.instagram.com/p/CODE123/embed',
    );
    expectEmbed(
      'https://www.facebook.com/someone/posts/123',
      'facebook',
      'https://www.facebook.com/plugins/post.php'
          '?href=https://www.facebook.com/someone/posts/123&width=500',
    );
    expectEmbed(
      'https://www.pinterest.com/pin/123456/',
      'pinterest',
      'https://assets.pinterest.com/ext/embed.html?id=123456',
    );
    expectEmbed(
      'https://www.reddit.com/r/flutter/comments/abc/title/',
      'reddit',
      'https://www.redditmedia.com/r/flutter/comments/abc/title/'
          '?ref_source=embed&ref=share&embed=true',
    );
  });

  test('design, code and image services', () {
    expectEmbed(
      'https://codepen.io/team/pen/abcDEF',
      'codepen',
      'https://codepen.io/team/embed/abcDEF'
          '?height=300&theme-id=0&default-tab=css,result&embed-version=2',
    );
    expectEmbed(
      'https://www.figma.com/file/abc/Design',
      'figma',
      'https://www.figma.com/embed?embed_host=share'
          '&url=https://www.figma.com/file/abc/Design',
    );
    expectEmbed(
      'https://miro.com/app/board/o9J_k1JKioQ=/',
      'miro',
      'https://miro.com/app/live-embed/o9J_k1JKioQ=',
    );
    expectEmbed(
      'https://whimsical.com/my-board-ABCDEFGHJKMNPQRS',
      'whimsical',
      'https://whimsical.com/embed/ABCDEFGHJKMNPQRS',
    );
    expectEmbed(
      'https://i.imgur.com/abc123.gifv',
      'imgur',
      'http://imgur.com/abc123/embed',
    );

    final gist = EmbedServices.resolve('https://gist.github.com/user/abcdef123')!;
    expect(gist.service, 'github');
    expect(gist.embed, contains('https://gist.github.com/user/abcdef123.js'));
  });

  test('Yandex Music albums, tracks and playlists', () {
    expectEmbed(
      'https://music.yandex.ru/album/5307396',
      'yandex-music-album',
      'https://music.yandex.ru/iframe/#album/5307396/',
    );
    expectEmbed(
      'https://music.yandex.ru/track/42',
      'yandex-music-track',
      'https://music.yandex.ru/iframe/#track/42/',
    );
    expectEmbed(
      'https://music.yandex.ru/users/someone/playlists/1000',
      'yandex-music-playlist',
      'https://music.yandex.ru/iframe/#playlist/someone/1000'
          '/show/cover/description/',
    );
  });

  test('surrounding whitespace is ignored', () {
    expect(EmbedServices.resolve('  https://youtu.be/ID123 \n')?.service,
        'youtube');
  });

  test('links from unknown sites and non-links resolve to nothing', () {
    for (final url in [
      '',
      '   ',
      'not a link',
      'https://example.com/watch?v=ID123',
      'https://www.youtube.com/',
      'https://vimeo.com/',
    ]) {
      expect(EmbedServices.resolve(url), isNull, reason: url);
    }
  });
}
