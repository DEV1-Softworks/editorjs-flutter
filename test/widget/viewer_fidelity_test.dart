import 'dart:convert';

import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:editorjs_flutter/src/presentation/blocks/header/header_renderer.dart';
import 'package:editorjs_flutter/src/presentation/blocks/table/table_renderer.dart';
import 'package:editorjs_flutter/src/presentation/widgets/inline_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const double _hostWidth = 600;

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: _hostWidth, child: child),
          ),
        ),
      ),
    );

String _doc(List<Map<String, dynamic>> blocks) => jsonEncode({'blocks': blocks});

Map<String, dynamic> _block(String type, Map<String, dynamic> data) =>
    {'type': type, 'data': data};

/// Pumps a viewer whose link taps are collected into the returned list.
Future<List<String>> _pumpView(
  WidgetTester tester,
  List<Map<String, dynamic>> blocks,
) async {
  final tapped = <String>[];
  await tester.pumpWidget(_host(EditorJSView(
    jsonData: _doc(blocks),
    config: EditorConfig(onLinkTap: tapped.add),
  )));
  await tester.pumpAndSettle();
  return tapped;
}

/// Taps the start of the text [label]. A block-level text widget spans the
/// full width, so its centre is usually empty space rather than the link.
Future<void> _tapText(WidgetTester tester, String label) {
  final rect = tester.getRect(find.text(label));
  return tester.tapAt(Offset(rect.left + 8, rect.center.dy));
}

void main() {
  group('inline HTML and entities are rendered, not shown as markup', () {
    testWidgets('header', (tester) async {
      await _pumpView(tester, [
        _block('header', {
          'text': 'Fish &amp; <i>chips</i>&nbsp;guide',
          'level': 2,
        }),
      ]);
      expect(find.text('Fish & chips guide'), findsOneWidget);
      expect(find.textContaining('<i>'), findsNothing);
      expect(find.textContaining('&amp;'), findsNothing);
    });

    testWidgets('header size still follows its level', (tester) async {
      Future<double> heightOf(int level) async {
        await tester.pumpWidget(_host(
          HeaderRenderer(block: HeaderBlock(text: 'Title', level: level)),
        ));
        return tester.getSize(find.text('Title')).height;
      }

      final h1 = await heightOf(1);
      final h3 = await heightOf(3);
      final h6 = await heightOf(6);
      expect(h1, greaterThan(h3));
      expect(h3, greaterThan(h6));
    });

    testWidgets('table cells', (tester) async {
      await _pumpView(tester, [
        _block('table', {
          'withHeadings': true,
          'content': [
            ['Pigs &amp; co', 'Chicken'],
            ['1 <b>pcs</b>', '12&nbsp;pcs'],
          ],
        }),
      ]);
      expect(find.text('Pigs & co'), findsOneWidget);
      expect(find.text('1 pcs'), findsOneWidget);
      expect(find.text('12 pcs'), findsOneWidget);
    });

    testWidgets('legacy checklist items', (tester) async {
      await _pumpView(tester, [
        _block('checklist', {
          'items': [
            {'text': 'Done &amp; <b>dusted</b>', 'checked': true},
            {'text': 'Open &lt;item&gt;', 'checked': false},
          ],
        }),
      ]);
      expect(find.text('Done & dusted'), findsOneWidget);
      expect(find.text('Open <item>'), findsOneWidget);
    });

    testWidgets('warning title and message', (tester) async {
      await _pumpView(tester, [
        _block('warning', {
          'title': 'Note &amp; <i>care</i>',
          'message': 'Avoid <b>this</b> method.',
        }),
      ]);
      expect(find.text('Note & care'), findsOneWidget);
      expect(find.text('Avoid this method.'), findsOneWidget);
    });

    testWidgets('quote, embed and image captions', (tester) async {
      await _pumpView(tester, [
        _block('quote', {
          'text': 'Quote',
          'caption': 'Socrates &amp; <b>co</b>',
          'alignment': 'center',
        }),
        _block('embed', {
          'service': 'youtube',
          'source': 'https://youtu.be/x',
          'embed': 'https://youtube.com/embed/x',
          'caption': 'Clip &amp; <i>notes</i>',
        }),
        _block('image', {
          'file': {'url': 'https://example.com/a.png'},
          'caption': 'Photo &amp; <b>credit</b>',
        }),
      ]);
      expect(find.text('— Socrates & co'), findsOneWidget);
      expect(find.text('Clip & notes'), findsOneWidget);
      expect(find.text('Photo & credit'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('a table is as wide as its content, not collapsed',
        (tester) async {
      await _pumpView(tester, [
        _block('table', {
          'content': [
            ['Kine', 'Pigs'],
            ['1 pcs', '3 pcs'],
          ],
        }),
      ]);
      expect(tester.takeException(), isNull);

      final table = tester.getSize(find.byType(Table));
      expect(table.width, greaterThan(0));
      expect(table.width, lessThan(_hostWidth));
      expect(tester.getSize(find.text('Kine')).width, greaterThan(0));
    });

    testWidgets('a stretched table fills the available width', (tester) async {
      await _pumpView(tester, [
        _block('table', {
          'stretched': true,
          'content': [
            ['a', 'b'],
          ],
        }),
      ]);
      expect(tester.getSize(find.byType(Table)).width, _hostWidth);
    });

    testWidgets('a table wider than the screen scrolls instead of overflowing',
        (tester) async {
      final wide = List.filled(12, 'a fairly long cell of text');
      for (final stretched in [false, true]) {
        await _pumpView(tester, [
          _block('table', {
            'stretched': stretched,
            'content': [wide],
          }),
        ]);
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(Table)).width,
          greaterThan(_hostWidth),
        );
      }
    });

    testWidgets('empty and ragged tables do not throw', (tester) async {
      await tester.pumpWidget(_host(const Column(
        children: [
          TableRenderer(block: TableBlock(content: [])),
          TableRenderer(block: TableBlock(content: [[]])),
          TableRenderer(
            block: TableBlock(
              content: [
                ['only one'],
                ['two', 'cells'],
              ],
            ),
          ),
        ],
      )));
      expect(tester.takeException(), isNull);
      expect(find.byType(Table), findsOneWidget);
    });

    testWidgets('blocks share one left edge', (tester) async {
      await _pumpView(tester, [
        _block('header', {'text': 'Title', 'level': 2}),
        _block('paragraph', {'text': 'Body'}),
        _block('raw', {'html': 'Raw'}),
      ]);
      final left = tester.getTopLeft(find.text('Title')).dx;
      expect(tester.getTopLeft(find.text('Body')).dx, left);
      expect(tester.getTopLeft(find.text('Raw')).dx, left);
    });

    testWidgets('a list marker starts on the same line as its item',
        (tester) async {
      await _pumpView(tester, [
        _block('list', {
          'style': 'ordered',
          'items': [
            {'content': 'First', 'meta': <String, dynamic>{}, 'items': []},
          ],
        }),
      ]);
      expect(
        tester.getTopLeft(find.text('1.')).dy,
        closeTo(tester.getTopLeft(find.text('First')).dy, 1),
      );
    });
  });

  group('links', () {
    testWidgets('links inside text reach EditorConfig.onLinkTap',
        (tester) async {
      final tapped = await _pumpView(tester, [
        _block('paragraph', {'text': '<a href="https://p.example">Para</a>'}),
        _block('header', {
          'text': '<a href="https://h.example">Head</a>',
          'level': 3,
        }),
        _block('list', {
          'style': 'unordered',
          'items': [
            {
              'content': '<a href="https://l.example">Item</a>',
              'meta': <String, dynamic>{},
              'items': [],
            },
          ],
        }),
        _block('table', {
          'content': [
            ['<a href="https://t.example">Cell</a>'],
          ],
        }),
        _block('quote', {
          'text': '<a href="https://q.example">Quote</a>',
          'caption': '',
          'alignment': 'left',
        }),
      ]);

      for (final label in ['Para', 'Head', 'Item', 'Cell', 'Quote']) {
        await _tapText(tester, label);
      }
      expect(tapped, [
        'https://p.example',
        'https://h.example',
        'https://l.example',
        'https://t.example',
        'https://q.example',
      ]);
    });

    testWidgets('link, embed and attachment cards reach onLinkTap',
        (tester) async {
      final tapped = await _pumpView(tester, [
        _block('linkTool', {
          'link': 'https://link.example',
          'meta': {'title': 'Link card'},
        }),
        _block('embed', {
          'service': 'vimeo',
          'source': 'https://embed.example',
          'embed': 'https://embed.example/e',
        }),
        _block('attaches', {
          'file': {'url': 'https://file.example/a.pdf'},
          'title': 'Attachment card',
        }),
      ]);

      await tester.tap(find.text('Link card'));
      await tester.tap(find.text('Vimeo'));
      await tester.tap(find.text('Attachment card'));
      expect(tapped, [
        'https://link.example',
        'https://embed.example',
        'https://file.example/a.pdf',
      ]);
    });

    testWidgets('a handler receives the URL unfiltered', (tester) async {
      final tapped = await _pumpView(tester, [
        _block('paragraph', {'text': '<a href="myapp://item/7">Deep</a>'}),
      ]);
      await _tapText(tester, 'Deep');
      expect(tapped, ['myapp://item/7']);
    });
  });

  group('EditorLinkScope default behaviour', () {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    late List<MethodCall> calls;
    late Object? Function(MethodCall call) respond;

    setUp(() {
      calls = [];
      respond = (call) => true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return respond(call);
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    List<Object?> launched() => [
          for (final call in calls)
            if (call.method == 'launch') (call.arguments as Map)['url'],
        ];

    test('opens http, https, mailto and tel links', () async {
      for (final url in [
        'http://a.example',
        'https://a.example/path?q=1',
        'mailto:hi@a.example',
        'tel:+123456',
      ]) {
        expect(await EditorLinkScope.launchExternally(url), isTrue);
      }
      expect(launched(), hasLength(4));
      expect(launched().first, 'http://a.example');
    });

    test('ignores other schemes, relative and malformed URLs', () async {
      for (final url in [
        'javascript:alert(1)',
        'file:///etc/passwd',
        'myapp://item/7',
        '/relative/path',
        'not a url',
        '::::',
      ]) {
        expect(await EditorLinkScope.launchExternally(url), isFalse);
      }
      expect(calls, isEmpty);
    });

    test('reports false when the platform cannot open the link', () async {
      respond = (call) => call.method != 'canLaunch';
      expect(await EditorLinkScope.launchExternally('https://a.example'),
          isFalse);
      expect(launched(), isEmpty);
    });

    test('reports false instead of throwing when the platform fails',
        () async {
      respond = (call) => throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
      expect(await EditorLinkScope.launchExternally('https://a.example'),
          isFalse);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      expect(await EditorLinkScope.launchExternally('https://a.example'),
          isFalse);
    });

    testWidgets('a viewer without onLinkTap opens links externally',
        (tester) async {
      await tester.pumpWidget(_host(EditorJSView(
        jsonData: _doc([
          _block('paragraph', {'text': '<a href="https://d.example">Go</a>'}),
          _block('paragraph', {'text': '<a href="javascript:x()">No</a>'}),
        ]),
      )));
      await tester.pumpAndSettle();

      await _tapText(tester, 'Go');
      await _tapText(tester, 'No');
      await tester.pumpAndSettle();
      expect(launched(), ['https://d.example']);
    });

    testWidgets('a renderer used on its own opens links externally',
        (tester) async {
      await tester.pumpWidget(_host(
        const InlineHtml('<a href="https://s.example">Solo</a>'),
      ));
      await _tapText(tester, 'Solo');
      await tester.pumpAndSettle();
      expect(launched(), ['https://s.example']);
    });

    testWidgets('null and blank URLs are ignored', (tester) async {
      final tapped = <String>[];
      late BuildContext context;
      await tester.pumpWidget(EditorLinkScope(
        onLinkTap: tapped.add,
        child: Builder(builder: (c) {
          context = c;
          return const SizedBox();
        }),
      ));
      EditorLinkScope.open(context, null);
      EditorLinkScope.open(context, '   ');
      EditorLinkScope.open(context, 'https://ok.example');
      expect(tapped, ['https://ok.example']);
      expect(calls, isEmpty);
    });

    test('notifies dependants only when the handler changes', () {
      void handler(String url) {}
      const child = SizedBox();
      final scope = EditorLinkScope(onLinkTap: handler, child: child);
      expect(
        scope.updateShouldNotify(
          EditorLinkScope(onLinkTap: handler, child: child),
        ),
        isFalse,
      );
      expect(
        scope.updateShouldNotify(
          const EditorLinkScope(onLinkTap: null, child: child),
        ),
        isTrue,
      );
    });
  });
}
