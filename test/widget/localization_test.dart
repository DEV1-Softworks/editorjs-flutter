import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:editorjs_flutter/src/presentation/blocks/paragraph/paragraph_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every text replaced by a recognisable "translation": the English default
/// with a § in front. Anything on screen without the § was not looked up.
final _marked = EditorStrings(
  paragraph: '§Paragraph',
  paragraphLabel: '§T',
  heading: (level) => '§Heading $level',
  headingLabel: (level) => '§H$level',
  quote: '§Quote',
  code: '§Code',
  unorderedList: '§Unordered list',
  orderedList: '§Ordered list',
  checklist: '§Checklist',
  legacyChecklist: '§Checklist (legacy)',
  table: '§Table',
  delimiter: '§Delimiter',
  warning: '§Warning',
  image: '§Image',
  embed: '§Embed',
  linkPreview: '§Link preview',
  attachment: '§Attachment',
  rawHtml: '§Raw HTML',
  hyperlink: '§Hyperlink',
  undo: '§Undo',
  redo: '§Redo',
  removeLastBlock: '§Remove last block',
  addHyperlinkTitle: '§Add hyperlink',
  hyperlinkTitleHint: '§Link title',
  add: '§Add',
  cancel: '§Cancel',
  save: '§Save',
  caption: '§Caption',
  title: '§Title',
  addItem: '§Add item',
  moveUp: '§Move up',
  moveDown: '§Move down',
  deleteBlock: '§Delete block',
  unsupportedBlock: (type) => '§Unsupported $type',
  paragraphHint: '§Write something...',
  bold: '§Bold',
  boldLabel: '§B',
  italic: '§Italic',
  italicLabel: '§I',
  underline: '§Underline',
  underlineLabel: '§U',
  strikethrough: '§Strikethrough',
  strikethroughLabel: '§S',
  inlineCode: '§Inline code',
  highlight: '§Highlight',
  highlightLabel: '§mark',
  link: '§Link',
  linkLabel: '§link',
  addLinkTitle: '§Add link',
  editLinkTitle: '§Edit link',
  linkAddress: '§Link address',
  removeLink: '§Remove link',
  headingLevel: '§Heading level',
  listUnordered: '§Unordered',
  listOrdered: '§Ordered',
  listChecklist: '§Checklist',
  startWith: '§Start with',
  counterNumeric: '§Numeric',
  counterLowerRoman: '§Lower Roman',
  counterUpperRoman: '§Upper Roman',
  counterLowerAlpha: '§Lower Alpha',
  counterUpperAlpha: '§Upper Alpha',
  outdent: '§Outdent',
  indent: '§Indent',
  removeItem: '§Remove item',
  checklistItemHint: '§List item...',
  quoteHint: '§Quote text...',
  quoteCaptionHint: '§Caption (optional)',
  align: '§Align:',
  alignLeft: '§left',
  alignCenter: '§center',
  alignRight: '§right',
  codeHint: '§Enter code...',
  copy: '§Copy',
  warningTitleHint: '§Warning title',
  warningMessageHint: '§Warning message...',
  firstRowIsHeader: '§First row is header',
  removeRow: '§Remove row',
  removeColumn: '§Remove column',
  addRow: '§Row',
  addColumn: '§Column',
  camera: '§Camera',
  gallery: '§Gallery',
  imageUrl: '§Image URL',
  imageBorder: '§Border',
  imageStretch: '§Stretch',
  imageBackground: '§Background',
  imagePickFailed: '§Could not open the image.',
  imageUploadFailed: '§Upload failed. Try again.',
  embedLink: '§Embed link',
  embedService: (service) => '§Service $service',
  embedUnsupported: '§This link is not from a supported service.',
  embeddedContent: '§Embedded content',
  linkUrl: '§Link',
  fetchPreview: '§Fetch preview',
  description: '§Description',
  previewImageUrl: '§Preview image URL',
  noPreview: '§No preview available for this link.',
  previewFailed: '§Could not fetch the preview.',
  chooseFile: '§Choose file',
  fileUrl: '§File URL',
  fileSize: (bytes) => '§$bytes bytes',
  attachFailed: '§Could not attach the file.',
  downloadFile: '§Download file',
);

/// Text the widgets show that is not language: URL and markup examples and
/// the symbol on the inline-code button.
const _notLanguage = {
  'https://...',
  'https://www.youtube.com/watch?v=...',
  '<div>...</div>',
  '</>',
};

/// A document with one block of every type the editor can edit.
const _everyBlock = '{"blocks":['
    '{"type":"header","data":{"text":"","level":2}},'
    '{"type":"paragraph","data":{"text":""}},'
    '{"type":"list","data":{"style":"ordered","meta":{},"items":'
    '[{"content":"","meta":{},"items":[]}]}},'
    '{"type":"checklist","data":{"items":[{"text":"","checked":false}]}},'
    '{"type":"quote","data":{"text":"","caption":"","alignment":"left"}},'
    '{"type":"code","data":{"code":""}},'
    '{"type":"warning","data":{"title":"","message":""}},'
    '{"type":"table","data":{"withHeadings":false,"content":[[""]]}},'
    '{"type":"delimiter","data":{}},'
    '{"type":"image","data":{"file":{"url":""},"caption":""}},'
    '{"type":"embed","data":{"service":"coub",'
    '"source":"https://coub.com/view/1","embed":"e"}},'
    '{"type":"linkTool","data":{"link":""}},'
    '{"type":"attaches","data":{"file":{"url":"","size":10}}},'
    '{"type":"raw","data":{"html":""}},'
    '{"type":"mystery","data":{}}'
    ']}';

/// Every piece of text the widget tree currently shows to the user: plain
/// text, tooltips, and the labels and hints of text fields.
Set<String> _visibleTexts(WidgetTester tester) {
  final texts = <String>{};
  for (final widget in tester.allWidgets) {
    if (widget is Text && widget.data != null) texts.add(widget.data!);
    if (widget is Tooltip && widget.message != null) texts.add(widget.message!);
    if (widget is TextField) {
      texts.addAll([
        widget.decoration?.labelText,
        widget.decoration?.hintText,
      ].nonNulls);
    }
  }
  return texts;
}

/// The visible texts that are words but did not come from [_marked].
Iterable<String> _untranslated(WidgetTester tester) =>
    _visibleTexts(tester).where((text) =>
        !text.startsWith('§') &&
        !_notLanguage.contains(text) &&
        RegExp(r'[A-Za-z]{2,}').hasMatch(text));

Widget _editor(EditorController controller, {EditorStrings? strings}) =>
    MaterialApp(
      home: Scaffold(
        body: EditorJSEditor(
          controller: controller,
          config: EditorConfig(
            strings: strings ?? const EditorStrings(),
            // Configured so that the buttons they add are on screen too.
            linkPreviewFetcher: (_) async => null,
            attachmentPicker: () async => null,
          ),
        ),
      ),
    );

void main() {
  /// Tall and wide enough that every block and toolbar button is built.
  Future<void> useLargeSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(2400, 6000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  group('defaults', () {
    test('are English', () {
      const strings = EditorStrings();
      expect(strings.paragraph, 'Paragraph');
      expect(strings.addItem, 'Add item');
      expect(strings.heading(3), 'Heading 3');
      expect(strings.headingLabel(3), 'H3');
      expect(strings.unsupportedBlock('x'), '[Unsupported block: x]');
      expect(strings.embedService('vimeo'), 'Service: vimeo');
      expect(strings.fileSize(2048), '2048 bytes');
    });

    test('a partial translation keeps the rest', () {
      const strings = EditorStrings(paragraph: 'Párrafo');
      expect(strings.paragraph, 'Párrafo');
      expect(strings.quote, 'Quote');
    });

    test('EditorConfig uses the defaults unless told otherwise', () {
      expect(EditorConfig().strings.undo, 'Undo');
    });

    testWidgets('the editor shows them', (tester) async {
      await useLargeSurface(tester);
      await tester.pumpWidget(_editor(EditorController.fromJson(_everyBlock)));
      await tester.pumpAndSettle();

      final visible = _visibleTexts(tester);
      for (final text in [
        'Paragraph',
        'Heading 2',
        'Add item',
        'Start with',
        'First row is header',
        'Camera',
        'Fetch preview',
        'Choose file',
        'Raw HTML',
        'Move up',
        '[Unsupported block: mystery]',
      ]) {
        expect(visible, contains(text));
      }
    });
  });

  group('with translated strings', () {
    testWidgets('no editor or toolbar text is left untranslated',
        (tester) async {
      await useLargeSurface(tester);
      await tester.pumpWidget(_editor(
        EditorController.fromJson(_everyBlock),
        strings: _marked,
      ));
      await tester.pumpAndSettle();

      expect(_untranslated(tester), isEmpty);

      // Spot checks that the scan really sees each kind of text.
      final visible = _visibleTexts(tester);
      expect(visible, contains('§Paragraph')); // toolbar tooltip
      expect(visible, contains('§T')); // toolbar label
      expect(visible, contains('§Heading 2')); // function, used as a hint
      expect(visible, contains('§H2')); // function, level selector
      expect(visible, contains('§Lower Roman')); // dropdown entry
      expect(visible, contains('§Service coub')); // function with a value
      expect(visible, contains('§10 bytes'));
      expect(visible, contains('§Unsupported mystery'));
      expect(visible, contains('§Caption')); // field label
      expect(visible, contains('§left')); // quote alignment chip
    });

    testWidgets('the paragraph format bar and its link dialog',
        (tester) async {
      await tester.pumpWidget(_editor(
        EditorController(initialBlocks: const [ParagraphBlock(html: 'Text')]),
        strings: _marked,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ParagraphEditor));
      await tester.pump();
      expect(find.byTooltip('§Bold'), findsOneWidget);
      expect(find.text('§mark'), findsOneWidget);

      await tester.tap(find.byTooltip('§Link'));
      await tester.pumpAndSettle();
      expect(find.text('§Add link'), findsOneWidget);
      expect(find.text('§Link address'), findsOneWidget);
      expect(find.text('§Cancel'), findsOneWidget);
      expect(find.text('§Save'), findsOneWidget);
      expect(_untranslated(tester), isEmpty);
    });

    testWidgets('the link dialog of an existing link', (tester) async {
      await tester.pumpWidget(_editor(
        EditorController(
          initialBlocks: const [
            ParagraphBlock(html: '<a href="https://a.example">a</a>'),
          ],
        ),
        strings: _marked,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ParagraphEditor));
      await tester.pump();
      tester
          .widget<TextField>(find.descendant(
            of: find.byType(ParagraphEditor),
            matching: find.byType(TextField),
          ))
          .controller!
          .selection = const TextSelection.collapsed(offset: 5);
      await tester.pump();

      await tester.tap(find.byTooltip('§Link'));
      await tester.pumpAndSettle();
      expect(find.text('§Edit link'), findsOneWidget);
      expect(find.text('§Remove link'), findsOneWidget);
    });

    testWidgets('the toolbar hyperlink dialog', (tester) async {
      await useLargeSurface(tester);
      await tester.pumpWidget(_editor(EditorController(), strings: _marked));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('§Hyperlink'));
      await tester.pumpAndSettle();
      expect(find.text('§Add hyperlink'), findsOneWidget);
      expect(find.text('§Link title'), findsOneWidget);
      expect(find.text('§Add'), findsOneWidget);
      expect(find.text('§Cancel'), findsOneWidget);
    });

    testWidgets('error and status messages', (tester) async {
      await useLargeSurface(tester);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EditorJSEditor(
            controller: EditorController.fromJson('{"blocks":['
                '{"type":"linkTool","data":{"link":"https://x.example"}},'
                '{"type":"attaches","data":{"file":{"url":""}}},'
                '{"type":"embed","data":{"service":"",'
                '"source":"https://unknown.example","embed":""}}'
                ']}'),
            config: EditorConfig(
              strings: _marked,
              linkPreviewFetcher: (_) async => null,
              attachmentPicker: () async => throw StateError('no'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('§This link is not from a supported service.'),
        findsOneWidget,
      );

      await tester.tap(find.text('§Fetch preview'));
      await tester.pumpAndSettle();
      expect(find.text('§No preview available for this link.'), findsOneWidget);

      await tester.tap(find.text('§Choose file'));
      await tester.pumpAndSettle();
      expect(find.text('§Could not attach the file.'), findsOneWidget);
    });

    testWidgets('the viewer', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EditorJSView(
              config: EditorConfig(strings: _marked),
              jsonData: '{"blocks":['
                  '{"type":"code","data":{"code":"x"}},'
                  '{"type":"embed","data":{"service":"",'
                  '"source":"https://x.example","embed":""}},'
                  '{"type":"attaches","data":{"file":{"url":"https://x/f"}}}'
                  ']}',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byTooltip('§Copy'), findsOneWidget);
      expect(find.text('§Embedded content'), findsOneWidget);
      expect(find.text('§Download file'), findsOneWidget);
    });
  });
}
