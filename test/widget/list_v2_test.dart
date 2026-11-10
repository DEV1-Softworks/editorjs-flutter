import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:editorjs_flutter/src/presentation/blocks/list/list_editor.dart';
import 'package:editorjs_flutter/src/presentation/blocks/list/list_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: 400, child: child),
        ),
      ),
    );

void main() {
  group('ListRenderer', () {
    testWidgets('ordered list numbers nested items as 1.1.', (tester) async {
      await tester.pumpWidget(_host(const ListRenderer(
        block: ListBlock(
          style: ListStyle.ordered,
          items: [
            ListItem(
              content: 'One',
              items: [ListItem(content: 'A'), ListItem(content: 'B')],
            ),
            ListItem(content: 'Two'),
          ],
        ),
      )));

      for (final marker in ['1.', '1.1.', '1.2.', '2.']) {
        expect(find.text(marker), findsOneWidget);
      }
    });

    testWidgets('ordered list honours start and counterType', (tester) async {
      await tester.pumpWidget(_host(const ListRenderer(
        block: ListBlock(
          style: ListStyle.ordered,
          start: 4,
          counterType: ListCounterType.upperRoman,
          items: [
            ListItem(content: 'Four', items: [ListItem(content: 'Child')]),
            ListItem(content: 'Five'),
          ],
        ),
      )));

      expect(find.text('IV.'), findsOneWidget);
      // `start` shifts the top level only; children still count from one.
      expect(find.text('IV.I.'), findsOneWidget);
      expect(find.text('V.'), findsOneWidget);
    });

    testWidgets('unordered list shows a bullet per item', (tester) async {
      await tester.pumpWidget(_host(const ListRenderer(
        block: ListBlock(
          style: ListStyle.unordered,
          items: [ListItem(content: 'a'), ListItem(content: 'b')],
        ),
      )));

      expect(find.text('•'), findsNWidgets(2));
      expect(find.byIcon(Icons.check_box_outlined), findsNothing);
    });

    testWidgets('checklist shows a box per item reflecting its state',
        (tester) async {
      await tester.pumpWidget(_host(const ListRenderer(
        block: ListBlock(
          style: ListStyle.checklist,
          items: [
            ListItem(
              content: 'Done',
              checked: true,
              items: [ListItem(content: 'Nested todo')],
            ),
            ListItem(content: 'Todo'),
          ],
        ),
      )));

      expect(find.byIcon(Icons.check_box_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_box_outline_blank), findsNWidgets(2));
      expect(find.text('•'), findsNothing);
    });

    testWidgets('a v2 checklist renders through EditorJSView', (tester) async {
      await tester.pumpWidget(_host(EditorJSView(
        jsonData: '{"blocks":[{"type":"list","data":{"style":"checklist",'
            '"items":[{"content":"Ship it","meta":{"checked":true},'
            '"items":[]}]}}]}',
      )));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box_outlined), findsOneWidget);
    });
  });

  group('ListEditor', () {
    Future<List<ListBlock>> pumpEditor(
      WidgetTester tester,
      ListBlock block,
    ) async {
      final changes = <ListBlock>[];
      await tester.pumpWidget(_host(
        ListEditor(block: block, onChanged: changes.add),
      ));
      return changes;
    }

    testWidgets('checklist items toggle and keep the rest of the block',
        (tester) async {
      final changes = await pumpEditor(
        tester,
        const ListBlock(
          style: ListStyle.checklist,
          items: [
            ListItem(
              content: 'a',
              items: [ListItem(content: 'child', checked: true)],
            ),
            ListItem(content: 'b', checked: true),
          ],
        ),
      );

      expect(find.byType(Checkbox), findsNWidgets(2));
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      final block = changes.single;
      expect(block.style, ListStyle.checklist);
      expect(block.items.map((i) => i.checked), [true, true]);
      // Nested items are not editable here, but must not be lost.
      expect(block.items.first.items.single.checked, isTrue);
    });

    testWidgets('editing text keeps style, start and counterType',
        (tester) async {
      final changes = await pumpEditor(
        tester,
        const ListBlock(
          style: ListStyle.ordered,
          start: 3,
          counterType: ListCounterType.lowerAlpha,
          items: [ListItem(content: 'a')],
        ),
      );

      expect(find.text('c.'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'a'), 'edited');
      await tester.pump();

      final block = changes.last;
      expect(block.items.single.content, 'edited');
      expect(block.style, ListStyle.ordered);
      expect(block.start, 3);
      expect(block.counterType, ListCounterType.lowerAlpha);
    });

    testWidgets('the style selector switches the list style', (tester) async {
      final changes = await pumpEditor(
        tester,
        const ListBlock(
          style: ListStyle.unordered,
          items: [ListItem(content: 'a')],
        ),
      );
      expect(find.byType(Checkbox), findsNothing);

      await tester.tap(find.byTooltip('Checklist'));
      await tester.pump();
      expect(changes.last.style, ListStyle.checklist);
      expect(find.byType(Checkbox), findsOneWidget);

      await tester.tap(find.byTooltip('Ordered'));
      await tester.pump();
      expect(changes.last.style, ListStyle.ordered);
      expect(find.text('1.'), findsOneWidget);

      // Selecting the current style again changes nothing.
      final count = changes.length;
      await tester.tap(find.byTooltip('Ordered'));
      await tester.pump();
      expect(changes.length, count);

      await tester.tap(find.byTooltip('Unordered'));
      await tester.pump();
      expect(changes.last.style, ListStyle.unordered);
    });

    testWidgets('numbering options appear only for ordered lists',
        (tester) async {
      await pumpEditor(
        tester,
        const ListBlock(
          style: ListStyle.unordered,
          items: [ListItem(content: 'a')],
        ),
      );
      expect(find.text('Start with'), findsNothing);
      expect(find.byType(DropdownButton<ListCounterType>), findsNothing);

      await tester.tap(find.byTooltip('Ordered'));
      await tester.pump();
      expect(find.text('Start with'), findsOneWidget);
      expect(find.byType(DropdownButton<ListCounterType>), findsOneWidget);
    });

    testWidgets('start number updates the markers and the block',
        (tester) async {
      final changes = await pumpEditor(
        tester,
        const ListBlock(
          style: ListStyle.ordered,
          items: [ListItem(content: 'a'), ListItem(content: 'b')],
        ),
      );

      final startField = find.widgetWithText(TextField, 'Start with');
      await tester.enterText(startField, '7');
      await tester.pump();
      expect(changes.last.start, 7);
      expect(find.text('7.'), findsOneWidget);
      expect(find.text('8.'), findsOneWidget);

      await tester.enterText(startField, '');
      await tester.pump();
      expect(changes.last.start, isNull);
      expect(find.text('1.'), findsOneWidget);
    });

    testWidgets('counter type can be changed from the dropdown',
        (tester) async {
      final changes = await pumpEditor(
        tester,
        const ListBlock(
          style: ListStyle.ordered,
          items: [ListItem(content: 'a')],
        ),
      );

      await tester.tap(find.byType(DropdownButton<ListCounterType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upper Roman').last);
      await tester.pumpAndSettle();

      expect(changes.last.counterType, ListCounterType.upperRoman);
      expect(find.text('I.'), findsOneWidget);
    });

    testWidgets('follows a block replaced from outside', (tester) async {
      Widget editor(ListBlock block) =>
          _host(ListEditor(block: block, onChanged: (_) {}));

      await tester.pumpWidget(editor(const ListBlock(
        style: ListStyle.ordered,
        start: 2,
        items: [ListItem(content: 'a')],
      )));
      expect(find.text('2.'), findsOneWidget);

      await tester.pumpWidget(editor(const ListBlock(
        style: ListStyle.ordered,
        start: 9,
        counterType: ListCounterType.upperAlpha,
        items: [ListItem(content: 'a')],
      )));
      expect(find.text('I.'), findsOneWidget);
      expect(find.widgetWithText(TextField, '9'), findsOneWidget);

      await tester.pumpWidget(editor(const ListBlock(
        style: ListStyle.checklist,
        items: [ListItem(content: 'a', checked: true)],
      )));
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });
  });
}
