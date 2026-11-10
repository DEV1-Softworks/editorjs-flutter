import 'dart:async';

import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:editorjs_flutter/src/presentation/blocks/attaches/attaches_editor.dart';
import 'package:editorjs_flutter/src/presentation/blocks/embed/embed_editor.dart';
import 'package:editorjs_flutter/src/presentation/blocks/link_tool/link_tool_editor.dart';
import 'package:editorjs_flutter/src/presentation/blocks/raw/raw_editor.dart';
import 'package:editorjs_flutter/src/presentation/widgets/editor_config_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {EditorConfig? config}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EditorConfigScope(
            config: config ?? EditorConfig(),
            child: SizedBox(width: 400, child: child),
          ),
        ),
      ),
    );

Finder _field(String label) => find.widgetWithText(TextField, label);

void main() {
  group('RawEditor', () {
    testWidgets('shows and edits the HTML source', (tester) async {
      final changes = <RawBlock>[];
      await tester.pumpWidget(_host(RawEditor(
        block: const RawBlock(html: '<div>old</div>'),
        onChanged: changes.add,
      )));
      expect(find.text('<div>old</div>'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '<p>new</p>');
      expect(changes.single.html, '<p>new</p>');
    });

    testWidgets('follows a block replaced from outside', (tester) async {
      Widget editor(String html) =>
          _host(RawEditor(block: RawBlock(html: html), onChanged: (_) {}));
      await tester.pumpWidget(editor('<b>a</b>'));
      await tester.pumpWidget(editor('<i>b</i>'));
      expect(find.text('<i>b</i>'), findsOneWidget);
    });
  });

  group('EmbedEditor', () {
    Future<List<EmbedBlock>> pumpEditor(
      WidgetTester tester,
      EmbedBlock block,
    ) async {
      final changes = <EmbedBlock>[];
      await tester.pumpWidget(_host(
        EmbedEditor(block: block, onChanged: changes.add),
      ));
      return changes;
    }

    testWidgets('a link from a known service fills in service and embed URL',
        (tester) async {
      final changes = await pumpEditor(
        tester,
        const EmbedBlock(service: '', source: '', embed: '', caption: 'Keep'),
      );

      await tester.enterText(
        _field('Embed link'),
        ' https://www.youtube.com/watch?v=ID123 ',
      );
      await tester.pump();

      final block = changes.last;
      expect(block.service, 'youtube');
      expect(block.source, 'https://www.youtube.com/watch?v=ID123');
      expect(block.embed, 'https://www.youtube.com/embed/ID123');
      expect(block.width, 580);
      expect(block.height, 320);
      expect(block.caption, 'Keep');
      expect(find.text('Service: youtube'), findsOneWidget);
    });

    testWidgets('a link from an unknown site is kept and flagged',
        (tester) async {
      final changes = await pumpEditor(
        tester,
        const EmbedBlock(
          service: 'youtube',
          source: 'https://youtu.be/ID123',
          embed: 'https://www.youtube.com/embed/ID123',
          width: 580,
          height: 320,
        ),
      );

      await tester.enterText(_field('Embed link'), 'https://example.com/clip');
      await tester.pump();

      final block = changes.last;
      expect(block.source, 'https://example.com/clip');
      expect(block.service, '');
      expect(block.embed, '');
      expect(block.width, isNull);
      expect(
        find.text('This link is not from a supported service.'),
        findsOneWidget,
      );
    });

    testWidgets('editing only the caption keeps an unrecognised service',
        (tester) async {
      // A service configured on the web side that this package has no
      // pattern for.
      final changes = await pumpEditor(
        tester,
        const EmbedBlock(
          service: 'my-video-host',
          source: 'https://videos.example.com/42',
          embed: 'https://videos.example.com/embed/42',
          width: 640,
          height: 360,
          caption: 'Old',
        ),
      );

      await tester.enterText(_field('Old'), 'New caption');

      final block = changes.single;
      expect(block.caption, 'New caption');
      expect(block.service, 'my-video-host');
      expect(block.embed, 'https://videos.example.com/embed/42');
      expect(block.width, 640);
      expect(block.height, 360);
    });

    testWidgets('an empty block shows no service line', (tester) async {
      await pumpEditor(
        tester,
        const EmbedBlock(service: '', source: '', embed: ''),
      );
      expect(find.textContaining('Service:'), findsNothing);
      expect(find.textContaining('not from a supported'), findsNothing);
    });

    testWidgets('follows a block replaced from outside', (tester) async {
      Widget editor(EmbedBlock block) =>
          _host(EmbedEditor(block: block, onChanged: (_) {}));
      await tester.pumpWidget(editor(
        const EmbedBlock(service: '', source: 'a', embed: '', caption: 'x'),
      ));
      await tester.pumpWidget(editor(const EmbedBlock(
        service: 'vimeo',
        source: 'https://vimeo.com/1234',
        embed: 'e',
        caption: 'y',
      )));
      expect(_field('https://vimeo.com/1234'), findsOneWidget);
      expect(_field('y'), findsOneWidget);
      expect(find.text('Service: vimeo'), findsOneWidget);
    });
  });

  group('LinkToolEditor', () {
    const existing = LinkToolBlock(
      link: 'https://codex.so',
      meta: LinkToolMeta(
        title: 'CodeX',
        description: 'A team',
        imageUrl: 'https://codex.so/logo.png',
        extras: {'site_name': 'CodeX'},
      ),
    );

    Future<List<LinkToolBlock>> pumpEditor(
      WidgetTester tester,
      LinkToolBlock block, {
      LinkPreviewFetcher? fetcher,
    }) async {
      final changes = <LinkToolBlock>[];
      await tester.pumpWidget(_host(
        LinkToolEditor(block: block, onChanged: changes.add),
        config: EditorConfig(linkPreviewFetcher: fetcher),
      ));
      return changes;
    }

    testWidgets('shows the link and its preview fields', (tester) async {
      await pumpEditor(tester, existing);
      for (final text in [
        'https://codex.so',
        'CodeX',
        'A team',
        'https://codex.so/logo.png',
      ]) {
        expect(_field(text), findsOneWidget);
      }
    });

    testWidgets('editing a field keeps the others and the extra fields',
        (tester) async {
      final changes = await pumpEditor(tester, existing);
      await tester.enterText(_field('CodeX'), 'CodeX Team');

      final block = changes.single;
      expect(block.link, 'https://codex.so');
      expect(block.meta!.title, 'CodeX Team');
      expect(block.meta!.description, 'A team');
      expect(block.meta!.imageUrl, 'https://codex.so/logo.png');
      expect(block.meta!.extras, {'site_name': 'CodeX'});
    });

    testWidgets('a link with no preview data has no meta', (tester) async {
      final changes = await pumpEditor(tester, const LinkToolBlock(link: ''));
      await tester.enterText(_field('Link'), ' https://example.com ');

      expect(changes.single.link, 'https://example.com');
      expect(changes.single.meta, isNull);
      expect(changes.single.toJson(), {'link': 'https://example.com'});
    });

    testWidgets('there is no fetch button without a fetcher', (tester) async {
      await pumpEditor(tester, existing);
      expect(find.text('Fetch preview'), findsNothing);
    });

    testWidgets('fetching fills the preview fields', (tester) async {
      String? requested;
      final changes = await pumpEditor(
        tester,
        const LinkToolBlock(link: 'https://example.com/page'),
        fetcher: (url) async {
          requested = url;
          return const LinkToolMeta(
            title: 'Fetched title',
            description: 'Fetched description',
            imageUrl: 'https://example.com/og.png',
            extras: {'site_name': 'Example'},
          );
        },
      );

      await tester.tap(find.text('Fetch preview'));
      await tester.pumpAndSettle();

      expect(requested, 'https://example.com/page');
      final meta = changes.single.meta!;
      expect(meta.title, 'Fetched title');
      expect(meta.description, 'Fetched description');
      expect(meta.imageUrl, 'https://example.com/og.png');
      expect(meta.extras, {'site_name': 'Example'});
      expect(_field('Fetched title'), findsOneWidget);
    });

    testWidgets('shows progress and blocks a second fetch while one runs',
        (tester) async {
      final pending = Completer<LinkToolMeta?>();
      await pumpEditor(tester, existing, fetcher: (_) => pending.future);

      await tester.tap(find.text('Fetch preview'));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Fetch preview'),
            )
            .onPressed,
        isNull,
      );

      pending.complete(const LinkToolMeta(title: 'Done'));
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('no preview and a failed fetch keep the fields',
        (tester) async {
      var fail = false;
      final changes = await pumpEditor(
        tester,
        existing,
        fetcher: (_) async => fail ? throw StateError('offline') : null,
      );

      await tester.tap(find.text('Fetch preview'));
      await tester.pumpAndSettle();
      expect(find.text('No preview available for this link.'), findsOneWidget);

      fail = true;
      await tester.tap(find.text('Fetch preview'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Could not fetch the preview.'), findsOneWidget);
      expect(find.text('No preview available for this link.'), findsNothing);

      expect(changes, isEmpty);
      expect(_field('CodeX'), findsOneWidget);
    });

    testWidgets('fetching does nothing while the link is empty',
        (tester) async {
      var calls = 0;
      await pumpEditor(
        tester,
        const LinkToolBlock(link: ''),
        fetcher: (_) async {
          calls++;
          return null;
        },
      );
      await tester.tap(find.text('Fetch preview'));
      await tester.pumpAndSettle();
      expect(calls, 0);
    });

    testWidgets('follows a block replaced from outside', (tester) async {
      Widget editor(LinkToolBlock block) =>
          _host(LinkToolEditor(block: block, onChanged: (_) {}));
      await tester.pumpWidget(editor(existing));
      await tester.pumpWidget(editor(const LinkToolBlock(
        link: 'https://other.example',
        meta: LinkToolMeta(title: 'Other'),
      )));
      expect(_field('https://other.example'), findsOneWidget);
      expect(_field('Other'), findsOneWidget);
      expect(_field('A team'), findsNothing);
    });
  });

  group('AttachesEditor', () {
    const existing = AttachesBlock(
      url: 'https://files.example.com/report.pdf',
      name: 'report.pdf',
      extension: 'pdf',
      size: 2048,
      title: 'Annual report',
      fileExtras: {'assetId': 7},
    );

    Future<List<AttachesBlock>> pumpEditor(
      WidgetTester tester,
      AttachesBlock block, {
      AttachmentPicker? picker,
    }) async {
      final changes = <AttachesBlock>[];
      await tester.pumpWidget(_host(
        AttachesEditor(block: block, onChanged: changes.add),
        config: EditorConfig(attachmentPicker: picker),
      ));
      return changes;
    }

    testWidgets('shows the URL, title and file details', (tester) async {
      await pumpEditor(tester, existing);
      expect(_field('https://files.example.com/report.pdf'), findsOneWidget);
      expect(_field('Annual report'), findsOneWidget);
      expect(find.text('report.pdf · 2048 bytes'), findsOneWidget);
    });

    testWidgets('editing the title keeps everything about the file',
        (tester) async {
      final changes = await pumpEditor(tester, existing);
      await tester.enterText(_field('Annual report'), 'Report 2026');

      final block = changes.single;
      expect(block.title, 'Report 2026');
      expect(block.url, existing.url);
      expect(block.name, 'report.pdf');
      expect(block.extension, 'pdf');
      expect(block.size, 2048);
      expect(block.fileExtras, {'assetId': 7});
    });

    testWidgets('typing a URL describes the new file from the URL',
        (tester) async {
      final changes = await pumpEditor(tester, existing);
      await tester.enterText(
        _field('https://files.example.com/report.pdf'),
        ' https://cdn.example.com/docs/slides.final.pptx?dl=1 ',
      );
      await tester.pump();

      final block = changes.last;
      expect(block.url, 'https://cdn.example.com/docs/slides.final.pptx?dl=1');
      expect(block.name, 'slides.final.pptx');
      expect(block.extension, 'pptx');
      expect(block.title, 'Annual report');
      // These described the previous file.
      expect(block.size, isNull);
      expect(block.fileExtras, isEmpty);
      expect(find.text('slides.final.pptx'), findsOneWidget);
    });

    testWidgets('a URL without a file name or extension gives none',
        (tester) async {
      final changes = await pumpEditor(tester, const AttachesBlock(url: ''));

      await tester.enterText(_field('File URL'), 'https://example.com/');
      expect(changes.last.name, isNull);
      expect(changes.last.extension, isNull);

      await tester.enterText(_field('https://example.com/'), 'https://x.io/README');
      expect(changes.last.name, 'README');
      expect(changes.last.extension, isNull);

      await tester.enterText(_field('https://x.io/README'), 'https://x.io/.env');
      expect(changes.last.name, '.env');
      expect(changes.last.extension, isNull);
    });

    testWidgets('there is no picker button without a picker', (tester) async {
      await pumpEditor(tester, existing);
      expect(find.text('Choose file'), findsNothing);
    });

    testWidgets('a picked file replaces the attachment', (tester) async {
      final changes = await pumpEditor(
        tester,
        existing,
        picker: () async => const AttachesBlock(
          url: 'https://cdn.example.com/new.zip',
          name: 'new.zip',
          extension: 'zip',
          size: 99,
          fileExtras: {'assetId': 8},
        ),
      );

      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();

      final block = changes.single;
      expect(block.url, 'https://cdn.example.com/new.zip');
      expect(block.name, 'new.zip');
      expect(block.size, 99);
      expect(block.fileExtras, {'assetId': 8});
      // The picker gave no title, so the one already typed stays.
      expect(block.title, 'Annual report');
      expect(_field('https://cdn.example.com/new.zip'), findsOneWidget);
    });

    testWidgets('a title from the picker replaces the current one',
        (tester) async {
      final changes = await pumpEditor(
        tester,
        existing,
        picker: () async =>
            const AttachesBlock(url: 'https://x.io/a.txt', title: 'Notes'),
      );
      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();
      expect(changes.single.title, 'Notes');
      expect(_field('Notes'), findsOneWidget);
    });

    testWidgets('cancelling and failing keep the current attachment',
        (tester) async {
      var fail = false;
      final changes = await pumpEditor(
        tester,
        existing,
        picker: () async => fail ? throw StateError('denied') : null,
      );

      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      expect(find.text('Could not attach the file.'), findsNothing);

      fail = true;
      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(changes, isEmpty);
      expect(find.text('Could not attach the file.'), findsOneWidget);
    });

    testWidgets('shows progress while the picker runs', (tester) async {
      final pending = Completer<AttachesBlock?>();
      await pumpEditor(tester, existing, picker: () => pending.future);

      await tester.tap(find.text('Choose file'));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      pending.complete(null);
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('follows a block replaced from outside', (tester) async {
      Widget editor(AttachesBlock block) =>
          _host(AttachesEditor(block: block, onChanged: (_) {}));
      await tester.pumpWidget(editor(existing));
      await tester.pumpWidget(editor(
        const AttachesBlock(url: 'https://x.io/b.txt', title: 'B'),
      ));
      expect(_field('https://x.io/b.txt'), findsOneWidget);
      expect(_field('B'), findsOneWidget);
    });
  });

  group('in the full editor', () {
    const document = '{"blocks":['
        '{"id":"embed00001","type":"embed","data":{"service":"coub",'
        '"source":"https://coub.com/view/1czcdf",'
        '"embed":"https://coub.com/embed/1czcdf","caption":"Clip"}},'
        '{"id":"link000001","type":"linkTool","data":'
        '{"link":"https://codex.so","meta":{"title":"CodeX"}}},'
        '{"id":"file000001","type":"attaches","data":'
        '{"file":{"url":"https://x.io/a.pdf","name":"a.pdf"},"title":"Doc"}},'
        '{"id":"raw0000001","type":"raw","data":{"html":"<hr>"}}'
        ']}';

    test('the registry has an editor for all four block types', () {
      final registry = BlockRendererRegistry();
      for (final type in ['embed', 'linkTool', 'attaches', 'raw']) {
        expect(registry.supportsEditing(type), isTrue, reason: type);
      }
    });

    testWidgets('the blocks get editors instead of a placeholder',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = EditorController.fromJson(document);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: EditorJSEditor(controller: controller)),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Unsupported block'), findsNothing);
      expect(find.byType(EmbedEditor), findsOneWidget);
      expect(find.byType(LinkToolEditor), findsOneWidget);
      expect(find.byType(AttachesEditor), findsOneWidget);
      expect(find.byType(RawEditor), findsOneWidget);

      await tester.enterText(_field('Doc'), 'Document');
      await tester.pumpAndSettle();
      expect(controller.getContent(), contains('"title":"Document"'));
      // Untouched blocks are written back as they were read.
      expect(
        controller.getContent(),
        contains('{"id":"raw0000001","type":"raw","data":{"html":"<hr>"}}'),
      );
    });

    testWidgets('EditorConfig hooks reach the link and attachment editors',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EditorJSEditor(
            controller: EditorController.fromJson(document),
            config: EditorConfig(
              linkPreviewFetcher: (_) async => null,
              attachmentPicker: () async => null,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fetch preview'), findsOneWidget);
      expect(find.text('Choose file'), findsOneWidget);
    });
  });
}
