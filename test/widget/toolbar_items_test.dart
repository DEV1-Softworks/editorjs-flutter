import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:editorjs_flutter/src/presentation/widgets/editorjs_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _tooltips = {
  EditorToolbarItem.paragraph: 'Paragraph',
  EditorToolbarItem.heading1: 'Heading 1',
  EditorToolbarItem.heading2: 'Heading 2',
  EditorToolbarItem.heading3: 'Heading 3',
  EditorToolbarItem.heading4: 'Heading 4',
  EditorToolbarItem.heading5: 'Heading 5',
  EditorToolbarItem.heading6: 'Heading 6',
  EditorToolbarItem.quote: 'Quote',
  EditorToolbarItem.code: 'Code',
  EditorToolbarItem.unorderedList: 'Unordered list',
  EditorToolbarItem.orderedList: 'Ordered list',
  EditorToolbarItem.checklist: 'Checklist',
  EditorToolbarItem.legacyChecklist: 'Checklist (legacy)',
  EditorToolbarItem.table: 'Table',
  EditorToolbarItem.delimiter: 'Delimiter',
  EditorToolbarItem.warning: 'Warning',
  EditorToolbarItem.image: 'Image',
  EditorToolbarItem.embed: 'Embed',
  EditorToolbarItem.linkPreview: 'Link preview',
  EditorToolbarItem.attachment: 'Attachment',
  EditorToolbarItem.rawHtml: 'Raw HTML',
  EditorToolbarItem.hyperlink: 'Hyperlink',
  EditorToolbarItem.undo: 'Undo',
  EditorToolbarItem.redo: 'Redo',
  EditorToolbarItem.removeLastBlock: 'Remove last block',
};

Widget _toolbar(
  EditorController controller, [
  List<EditorToolbarItem> items = EditorToolbarItem.values,
]) =>
    MaterialApp(
      home: Scaffold(
        // Wide enough that every button is laid out without scrolling.
        body: OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: 2000,
          child: EditorJSToolbar(
            controller: controller,
            rendererRegistry: BlockRendererRegistry(),
            items: items,
          ),
        ),
      ),
    );

List<String> _shownTooltips(WidgetTester tester) => tester
    .widgetList<Tooltip>(find.descendant(
      of: find.byType(EditorJSToolbar),
      matching: find.byType(Tooltip),
    ))
    .map((t) => t.message!)
    .toList();

void main() {
  test('every toolbar item is covered by this test', () {
    expect(_tooltips.keys, EditorToolbarItem.values);
  });

  testWidgets('shows every button, in enum order, by default', (tester) async {
    await tester.pumpWidget(_toolbar(EditorController()));
    expect(_shownTooltips(tester), _tooltips.values);
  });

  testWidgets('shows only the chosen buttons, in the chosen order',
      (tester) async {
    await tester.pumpWidget(_toolbar(EditorController(), const [
      EditorToolbarItem.undo,
      EditorToolbarItem.checklist,
      EditorToolbarItem.paragraph,
    ]));
    expect(_shownTooltips(tester), ['Undo', 'Checklist', 'Paragraph']);
  });

  testWidgets('an empty selection shows no buttons', (tester) async {
    await tester.pumpWidget(_toolbar(EditorController(), const []));
    expect(_shownTooltips(tester), isEmpty);
  });

  testWidgets('each block button adds the block it names', (tester) async {
    // Wide enough that every button is on screen and can be tapped.
    await tester.binding.setSurfaceSize(const Size(2000, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final expected = <EditorToolbarItem, bool Function(BlockEntity)>{
      EditorToolbarItem.paragraph: (b) => b is ParagraphBlock,
      for (var level = 1; level <= 6; level++)
        EditorToolbarItem.values[level]: (b) =>
            b is HeaderBlock && b.level == level,
      EditorToolbarItem.quote: (b) => b is QuoteBlock,
      EditorToolbarItem.code: (b) => b is CodeBlock,
      EditorToolbarItem.unorderedList: (b) =>
          b is ListBlock && b.style == ListStyle.unordered,
      EditorToolbarItem.orderedList: (b) =>
          b is ListBlock && b.style == ListStyle.ordered,
      EditorToolbarItem.checklist: (b) =>
          b is ListBlock && b.style == ListStyle.checklist,
      EditorToolbarItem.legacyChecklist: (b) => b is ChecklistBlock,
      EditorToolbarItem.table: (b) => b is TableBlock,
      EditorToolbarItem.delimiter: (b) => b is DelimiterBlock,
      EditorToolbarItem.warning: (b) => b is WarningBlock,
      EditorToolbarItem.image: (b) => b is ImageBlock,
      EditorToolbarItem.embed: (b) => b is EmbedBlock,
      EditorToolbarItem.linkPreview: (b) => b is LinkToolBlock,
      EditorToolbarItem.attachment: (b) => b is AttachesBlock,
      EditorToolbarItem.rawHtml: (b) => b is RawBlock,
    };

    for (final entry in expected.entries) {
      final controller = EditorController();
      await tester.pumpWidget(_toolbar(controller));
      await tester.tap(find.byTooltip(_tooltips[entry.key]!));
      expect(
        entry.value(controller.blocks.single),
        isTrue,
        reason: '${entry.key} added ${controller.blocks.single.runtimeType}',
      );
    }
  });

  testWidgets('EditorConfig.toolbarItems reaches the editor toolbar',
      (tester) async {
    final controller = EditorController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditorJSEditor(
          controller: controller,
          config: EditorConfig(
            toolbarItems: EditorToolbarItem.values
                .where((item) => item != EditorToolbarItem.legacyChecklist)
                .toList(),
          ),
        ),
      ),
    ));

    expect(find.byTooltip('Checklist (legacy)'), findsNothing);
    expect(find.byTooltip('Checklist'), findsOneWidget);
  });

  test('EditorConfig shows every button unless told otherwise', () {
    expect(EditorConfig().toolbarItems, EditorToolbarItem.values);
  });
}
