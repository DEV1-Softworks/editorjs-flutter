import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:editorjs_flutter/src/presentation/widgets/editorjs_toolbar.dart';

Widget _wrapToolbar(EditorController controller) => MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            EditorJSToolbar(
              controller: controller,
              rendererRegistry: BlockRendererRegistry(),
            ),
          ],
        ),
      ),
    );

void main() {
  group('EditorJSToolbar', () {
    testWidgets('renders without throwing', (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();
      expect(find.byType(EditorJSToolbar), findsOneWidget);
    });

    testWidgets('tapping Paragraph button adds a paragraph block',
        (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('T'));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 1);
      expect(controller.blocks.first, isA<ParagraphBlock>());
    });

    testWidgets('tapping H1 button adds a header block', (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('H1'));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 1);
      expect(controller.blocks.first, isA<HeaderBlock>());
      expect((controller.blocks.first as HeaderBlock).level, 1);
    });

    testWidgets('tapping Delimiter button adds delimiter block', (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.horizontal_rule));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 1);
      expect(controller.blocks.first, isA<DelimiterBlock>());
    });

    testWidgets('tapping Code button adds code block', (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.code));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 1);
      expect(controller.blocks.first, isA<CodeBlock>());
    });

    testWidgets('tapping Quote button adds quote block', (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.format_quote));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 1);
      expect(controller.blocks.first, isA<QuoteBlock>());
    });

    testWidgets('tapping Warning button adds warning block', (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.warning_amber_outlined));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 1);
      expect(controller.blocks.first, isA<WarningBlock>());
    });

    testWidgets('tapping unordered list button adds list block', (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 1);
      expect(controller.blocks.first, isA<ListBlock>());
      expect((controller.blocks.first as ListBlock).style, ListStyle.unordered);
    });

    testWidgets('tapping ordered list button adds ordered list block',
        (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.format_list_numbered));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 1);
      expect((controller.blocks.first as ListBlock).style, ListStyle.ordered);
    });

    testWidgets('tapping checklist button adds a list 2.x checklist',
        (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Checklist'));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 1);
      final block = controller.blocks.first as ListBlock;
      expect(block.style, ListStyle.checklist);
      expect(block.items.single.checked, isFalse);
      expect(controller.getContent(), contains('"style":"checklist"'));
    });

    testWidgets('tapping legacy checklist button adds a checklist block',
        (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Checklist (legacy)'));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 1);
      expect(controller.blocks.first, isA<ChecklistBlock>());
      expect(controller.getContent(), contains('"type":"checklist"'));
    });

    testWidgets('tapping table button adds table block', (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.table_chart_outlined));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 1);
      expect(controller.blocks.first, isA<TableBlock>());
    });

    testWidgets('tapping image button adds image block', (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.image_outlined));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 1);
      expect(controller.blocks.first, isA<ImageBlock>());
    });

    testWidgets('tapping delete last block button removes last block',
        (tester) async {
      final controller = EditorController(
        initialBlocks: const [
          HeaderBlock(text: 'Block to delete', level: 1),
        ],
      );
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      // Scroll to reveal delete button (it may be off-screen in the horizontal scroll)
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_outline),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 0);
    });

    testWidgets('undo button does nothing when canUndo is false', (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      // Scroll to reveal undo button
      await tester.scrollUntilVisible(
        find.byIcon(Icons.undo),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );
      // Tap undo when nothing to undo — disabled so no-op
      await tester.tap(find.byIcon(Icons.undo), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(controller.blockCount, 0);
    });

    testWidgets('undo button works after adding a block', (tester) async {
      final controller = EditorController();
      controller.addBlock(const HeaderBlock(text: 'A', level: 1));
      expect(controller.blockCount, 1);

      await tester.pumpWidget(_wrapToolbar(controller));
      await tester.pumpAndSettle();

      // Scroll to reveal undo button
      await tester.scrollUntilVisible(
        find.byIcon(Icons.undo),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );

      // Tap undo
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 0);
    });

    testWidgets('hyperlink dialog opens and can be cancelled', (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EditorJSToolbar(
            controller: controller,
            rendererRegistry: BlockRendererRegistry(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // The toolbar scrolls horizontally and the link button sits past the
      // edge of the default test viewport.
      await tester.scrollUntilVisible(
        find.byIcon(Icons.link),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byIcon(Icons.link));
      await tester.pumpAndSettle();

      // Dialog should be showing
      expect(find.text('Add hyperlink'), findsOneWidget);

      // Cancel the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 0);
    });

    testWidgets('hyperlink dialog adds paragraph block with URL', (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EditorJSToolbar(
            controller: controller,
            rendererRegistry: BlockRendererRegistry(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // The toolbar scrolls horizontally and the link button sits past the
      // edge of the default test viewport.
      await tester.scrollUntilVisible(
        find.byIcon(Icons.link),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byIcon(Icons.link));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField).last, 'https://example.com');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(controller.blockCount, 1);
      expect(controller.blocks.first, isA<ParagraphBlock>());
    });
  });
}
