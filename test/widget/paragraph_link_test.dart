import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:editorjs_flutter/src/presentation/blocks/paragraph/paragraph_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 400, child: child)),
    );

void main() {
  late List<String> changes;

  /// Pumps the editor with [html], focuses it and puts the caret or selection
  /// at [selection].
  Future<void> pumpEditor(
    WidgetTester tester,
    String html,
    TextSelection selection,
  ) async {
    changes = [];
    await tester.pumpWidget(_host(ParagraphEditor(
      // A fresh editor every time: a focused editor deliberately ignores a
      // block replaced from outside, which would carry text over between the
      // cases of one test.
      key: UniqueKey(),
      block: ParagraphBlock(html: html),
      onChanged: (block) => changes.add(block.html),
    )));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    tester.widget<TextField>(find.byType(TextField)).controller!.selection =
        selection;
    await tester.pump();
  }

  TextSelection select(String html, String part) {
    final start = html.indexOf(part);
    return TextSelection(baseOffset: start, extentOffset: start + part.length);
  }

  TextSelection caretIn(String html, String part) =>
      TextSelection.collapsed(offset: html.indexOf(part) + 1);

  Finder addressField() => find.widgetWithText(TextField, 'Link address');

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Link'));
    await tester.pumpAndSettle();
  }

  Future<void> saveLink(WidgetTester tester, String address) async {
    await openDialog(tester);
    await tester.enterText(addressField(), address);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('the link button is part of the format bar', (tester) async {
    await tester.pumpWidget(_host(ParagraphEditor(
      block: const ParagraphBlock(html: 'Text'),
      onChanged: (_) {},
    )));
    expect(find.byTooltip('Link'), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(find.byTooltip('Link'), findsOneWidget);
  });

  group('adding a link', () {
    testWidgets('wraps the selected text', (tester) async {
      const html = 'Visit our site today';
      await pumpEditor(tester, html, select(html, 'our site'));
      await saveLink(tester, 'https://example.com');

      expect(
        changes.last,
        'Visit <a href="https://example.com">our site</a> today',
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('keeps formatting inside the selection', (tester) async {
      const html = 'See <b>this</b> page';
      await pumpEditor(tester, html, select(html, '<b>this</b> page'));
      await saveLink(tester, 'https://example.com');
      expect(
        changes.last,
        'See <a href="https://example.com"><b>this</b> page</a>',
      );
    });

    testWidgets('with nothing selected the address becomes the text',
        (tester) async {
      const html = 'Docs: ';
      await pumpEditor(
        tester,
        html,
        const TextSelection.collapsed(offset: html.length),
      );
      await saveLink(tester, 'https://example.com/docs');
      expect(
        changes.last,
        'Docs: <a href="https://example.com/docs">https://example.com/docs</a>',
      );
    });

    testWidgets('completes a bare address to a web link', (tester) async {
      const html = 'site';
      await pumpEditor(tester, html, select(html, 'site'));
      await saveLink(tester, '  example.com/page ');
      expect(changes.last, '<a href="https://example.com/page">site</a>');
    });

    testWidgets('leaves mail, phone and in-site targets as typed',
        (tester) async {
      for (final address in [
        'mailto:hi@example.com',
        'tel:+123456',
        '/docs/intro',
        '#section',
        'http://plain.example',
      ]) {
        const html = 'x';
        await pumpEditor(tester, html, select(html, 'x'));
        await saveLink(tester, address);
        expect(changes.last, '<a href="$address">x</a>', reason: address);
      }
    });

    testWidgets('escapes characters that would break the attribute',
        (tester) async {
      const html = 'x';
      await pumpEditor(tester, html, select(html, 'x'));
      await saveLink(tester, 'https://a.b/?q="1"&r=2');
      expect(
        changes.last,
        '<a href="https://a.b/?q=&quot;1&quot;&amp;r=2">x</a>',
      );
    });

    testWidgets('the keyboard action saves too', (tester) async {
      const html = 'x';
      await pumpEditor(tester, html, select(html, 'x'));
      await openDialog(tester);
      await tester.enterText(addressField(), 'https://example.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(changes.last, '<a href="https://example.com">x</a>');
    });

    testWidgets('typing continues after the new link', (tester) async {
      const html = 'ab';
      await pumpEditor(tester, html, select(html, 'a'));
      await saveLink(tester, 'https://e.io');

      final controller =
          tester.widget<TextField>(find.byType(TextField)).controller!;
      expect(controller.text, '<a href="https://e.io">a</a>b');
      expect(controller.selection.baseOffset, controller.text.length - 1);
    });

    testWidgets('cancelling or saving an empty address changes nothing',
        (tester) async {
      const html = 'x';
      await pumpEditor(tester, html, select(html, 'x'));

      await openDialog(tester);
      expect(find.text('Add link'), findsOneWidget);
      expect(find.text('Remove link'), findsNothing);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // An empty address is not accepted: the dialog stays open.
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(changes, isEmpty);
    });
  });

  group('editing an existing link', () {
    const html = 'Go to <a href="https://old.example/?a=1&amp;b=2" '
        'target="_blank">the <b>old</b> page</a> now';

    testWidgets('the dialog opens with the current address', (tester) async {
      await pumpEditor(tester, html, caretIn(html, 'the <b>old'));
      await openDialog(tester);

      expect(find.text('Edit link'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'https://old.example/?a=1&b=2'),
        findsOneWidget,
      );
      expect(find.text('Remove link'), findsOneWidget);
    });

    testWidgets('saving replaces the address and keeps text and attributes',
        (tester) async {
      await pumpEditor(tester, html, caretIn(html, 'the <b>old'));
      await saveLink(tester, 'https://new.example');
      expect(
        changes.last,
        'Go to <a href="https://new.example" target="_blank">'
        'the <b>old</b> page</a> now',
      );
    });

    testWidgets('a caret anywhere in the element counts, tags included',
        (tester) async {
      for (final part in ['<a href', 'target=', 'page</a>', '</a> now']) {
        await pumpEditor(tester, html, caretIn(html, part));
        await openDialog(tester);
        expect(find.text('Edit link'), findsOneWidget, reason: part);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('a caret outside the element adds a new link', (tester) async {
      await pumpEditor(tester, html, caretIn(html, 'Go to'));
      await openDialog(tester);
      expect(find.text('Add link'), findsOneWidget);
    });

    testWidgets('removing the link keeps its text', (tester) async {
      await pumpEditor(tester, html, caretIn(html, 'the <b>old'));
      await openDialog(tester);
      await tester.tap(find.text('Remove link'));
      await tester.pumpAndSettle();
      expect(changes.last, 'Go to the <b>old</b> page now');
    });

    testWidgets('single-quoted and attribute-less anchors are handled',
        (tester) async {
      const single = "<a href='https://one.example'>one</a>";
      await pumpEditor(tester, single, caretIn(single, 'one<'));
      await saveLink(tester, 'https://two.example');
      expect(changes.last, '<a href="https://two.example">one</a>');

      const bare = '<a>anchor</a>';
      await pumpEditor(tester, bare, caretIn(bare, 'anchor'));
      await openDialog(tester);
      // No address yet, but it is still an existing link being edited.
      expect(find.text('Edit link'), findsOneWidget);
      await tester.enterText(addressField(), 'https://x.example');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(changes.last, '<a href="https://x.example">anchor</a>');
    });

    testWidgets('only the link under the caret changes', (tester) async {
      const two = '<a href="https://a.example">A</a> and '
          '<a href="https://b.example">B</a>';
      await pumpEditor(tester, two, caretIn(two, 'B</a>'));
      await saveLink(tester, 'https://c.example');
      expect(
        changes.last,
        '<a href="https://a.example">A</a> and <a href="https://c.example">B</a>',
      );
    });
  });

  testWidgets('a link added in the full editor is saved and rendered',
      (tester) async {
    final controller = EditorController(
      initialBlocks: const [ParagraphBlock(html: 'Read the docs')],
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: EditorJSEditor(controller: controller)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextField, 'Read the docs'));
    await tester.pump();
    tester
        .widget<TextField>(find.widgetWithText(TextField, 'Read the docs'))
        .controller!
        .selection = const TextSelection(baseOffset: 9, extentOffset: 13);
    await tester.pump();

    await saveLink(tester, 'example.com/docs');

    expect(
      (controller.blocks.single as ParagraphBlock).html,
      'Read the <a href="https://example.com/docs">docs</a>',
    );
  });
}
