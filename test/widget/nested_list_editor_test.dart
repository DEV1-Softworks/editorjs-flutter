import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:editorjs_flutter/src/presentation/blocks/list/list_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: 400, child: child),
        ),
      ),
    );

/// Renders a tree as an indented outline, e.g. `a\n  b\nc`, so structure
/// assertions read like the list they describe.
String _outline(List<ListItem> items, [int depth = 0]) => [
      for (final item in items) ...[
        '${'  ' * depth}${item.content}${item.checked ? ' [x]' : ''}',
        if (item.items.isNotEmpty) _outline(item.items, depth + 1),
      ],
    ].join('\n');

const _nested = ListBlock(
  style: ListStyle.unordered,
  items: [
    ListItem(
      content: 'a',
      items: [
        ListItem(content: 'a1', items: [ListItem(content: 'a1x')]),
        ListItem(content: 'a2'),
      ],
    ),
    ListItem(content: 'b'),
  ],
);

void main() {
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

  /// The nth button with [tooltip], counting rows from the top.
  Finder button(String tooltip, int row) => find.byTooltip(tooltip).at(row);

  bool enabled(WidgetTester tester, String tooltip, int row) =>
      tester
          .widget<IconButton>(find
              .ancestor(
                of: button(tooltip, row),
                matching: find.byType(IconButton),
              )
              .first)
          .onPressed !=
      null;

  testWidgets('every item is editable, nested ones included', (tester) async {
    final changes = await pumpEditor(tester, _nested);

    for (final text in ['a', 'a1', 'a1x', 'a2', 'b']) {
      expect(find.widgetWithText(TextField, text), findsOneWidget);
    }

    await tester.enterText(find.widgetWithText(TextField, 'a1x'), 'deep');
    expect(_outline(changes.last.items), 'a\n  a1\n    deep\n  a2\nb');
  });

  testWidgets('nested rows are indented under their parent', (tester) async {
    await pumpEditor(tester, _nested);
    double left(String text) =>
        tester.getTopLeft(find.widgetWithText(TextField, text)).dx;

    expect(left('a1'), greaterThan(left('a')));
    expect(left('a1x'), greaterThan(left('a1')));
    expect(left('a2'), left('a1'));
    expect(left('b'), left('a'));
  });

  testWidgets('indent makes an item a child of the one above it',
      (tester) async {
    final changes = await pumpEditor(
      tester,
      const ListBlock(
        style: ListStyle.unordered,
        items: [
          ListItem(content: 'a'),
          ListItem(content: 'b'),
          ListItem(content: 'c'),
        ],
      ),
    );

    await tester.tap(button('Indent', 1));
    await tester.pump();
    expect(_outline(changes.last.items), 'a\n  b\nc');

    await tester.tap(button('Indent', 2));
    await tester.pump();
    await tester.tap(button('Indent', 2));
    await tester.pump();
    expect(_outline(changes.last.items), 'a\n  b\n    c');
  });

  testWidgets('indent is offered only where there is a parent to nest under',
      (tester) async {
    await pumpEditor(tester, _nested);
    // Rows: a, a1, a1x, a2, b
    expect(enabled(tester, 'Indent', 0), isFalse, reason: 'first row');
    expect(enabled(tester, 'Indent', 1), isFalse, reason: 'already a child');
    expect(enabled(tester, 'Indent', 2), isFalse, reason: 'already a child');
    expect(enabled(tester, 'Indent', 3), isTrue, reason: 'can go under a1');
    expect(enabled(tester, 'Indent', 4), isTrue, reason: 'can go under a');
  });

  testWidgets('outdent is offered only below the top level', (tester) async {
    await pumpEditor(tester, _nested);
    expect(enabled(tester, 'Outdent', 0), isFalse);
    expect(enabled(tester, 'Outdent', 1), isTrue);
    expect(enabled(tester, 'Outdent', 4), isFalse);
  });

  testWidgets('indent and outdent move an item together with its children',
      (tester) async {
    final changes = await pumpEditor(tester, _nested);

    // Outdent a1: it leaves `a`, takes a1x along, and adopts the sibling
    // that followed it.
    await tester.tap(button('Outdent', 1));
    await tester.pump();
    expect(_outline(changes.last.items), 'a\na1\n  a1x\n  a2\nb');

    // Indent it back under `a`.
    await tester.tap(button('Indent', 1));
    await tester.pump();
    expect(_outline(changes.last.items), 'a\n  a1\n    a1x\n    a2\nb');
  });

  testWidgets('removing an item removes its children too', (tester) async {
    final changes = await pumpEditor(tester, _nested);

    await tester.tap(button('Remove item', 1)); // a1, parent of a1x
    await tester.pump();
    expect(_outline(changes.last.items), 'a\n  a2\nb');
    expect(find.widgetWithText(TextField, 'a1'), findsNothing);
    expect(find.widgetWithText(TextField, 'a1x'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(3));
  });

  testWidgets('removing a top-level item removes its whole subtree',
      (tester) async {
    final changes = await pumpEditor(tester, _nested);

    await tester.tap(button('Remove item', 0)); // a, with a1, a1x and a2
    await tester.pump();
    expect(_outline(changes.last.items), 'b');
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('removing an item without children leaves the rest alone',
      (tester) async {
    final changes = await pumpEditor(tester, _nested);

    await tester.tap(button('Remove item', 3)); // a2
    await tester.pump();
    expect(_outline(changes.last.items), 'a\n  a1\n    a1x\nb');
  });

  testWidgets('the last remaining item cannot be removed', (tester) async {
    await pumpEditor(
      tester,
      const ListBlock(
        style: ListStyle.unordered,
        items: [ListItem(content: 'only')],
      ),
    );
    expect(enabled(tester, 'Remove item', 0), isFalse);
  });

  testWidgets('an item cannot be removed if that would empty the list',
      (tester) async {
    await pumpEditor(
      tester,
      const ListBlock(
        style: ListStyle.unordered,
        items: [
          ListItem(content: 'root', items: [ListItem(content: 'child')]),
        ],
      ),
    );
    // Removing `root` would take `child` with it and leave nothing.
    expect(enabled(tester, 'Remove item', 0), isFalse);
    expect(enabled(tester, 'Remove item', 1), isTrue);
  });

  testWidgets('Enter adds a sibling after the item and its children',
      (tester) async {
    final changes = await pumpEditor(tester, _nested);

    await tester.tap(find.widgetWithText(TextField, 'a1'));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    // The new item sits beside a1, below a1's own child.
    expect(_outline(changes.last.items), 'a\n  a1\n    a1x\n  \n  a2\nb');

    // The cursor is in the new item: typing fills it.
    tester.testTextInput.enterText('new');
    await tester.pump();
    expect(_outline(changes.last.items), 'a\n  a1\n    a1x\n  new\n  a2\nb');
  });

  testWidgets('Add item appends at the top level', (tester) async {
    final changes = await pumpEditor(tester, _nested);
    await tester.tap(find.text('Add item'));
    await tester.pump();
    expect(_outline(changes.last.items), 'a\n  a1\n    a1x\n  a2\nb\n');
    expect(changes.last.items.length, 3);
  });

  testWidgets('an empty list can be started with Add item', (tester) async {
    final changes = await pumpEditor(
      tester,
      const ListBlock(style: ListStyle.unordered, items: []),
    );
    expect(find.byTooltip('Remove item'), findsNothing);

    await tester.tap(find.text('Add item'));
    await tester.pump();
    expect(changes.last.items.single.content, '');
  });

  testWidgets('ordered markers follow the nesting', (tester) async {
    await pumpEditor(
      tester,
      ListBlock(
        style: ListStyle.ordered,
        start: 3,
        items: _nested.items,
      ),
    );
    for (final marker in ['3.', '3.1.', '3.1.1.', '3.2.', '4.']) {
      expect(find.text(marker), findsOneWidget);
    }

    // Restructuring renumbers.
    await tester.tap(button('Outdent', 3)); // a2 leaves `a`
    await tester.pump();
    for (final marker in ['3.', '3.1.', '3.1.1.', '4.', '5.']) {
      expect(find.text(marker), findsOneWidget);
    }
  });

  testWidgets('nested checklist items can be ticked', (tester) async {
    final changes = await pumpEditor(
      tester,
      ListBlock(style: ListStyle.checklist, items: _nested.items),
    );

    await tester.tap(find.byType(Checkbox).at(2)); // a1x
    await tester.pump();
    expect(_outline(changes.last.items), 'a\n  a1\n    a1x [x]\n  a2\nb');
  });

  testWidgets('ticks survive restructuring', (tester) async {
    final changes = await pumpEditor(
      tester,
      const ListBlock(
        style: ListStyle.checklist,
        items: [
          ListItem(content: 'a'),
          ListItem(content: 'b', checked: true),
        ],
      ),
    );

    await tester.tap(button('Indent', 1));
    await tester.pump();
    expect(_outline(changes.last.items), 'a\n  b [x]');
  });

  testWidgets('follows a block replaced from outside', (tester) async {
    Widget editor(ListBlock block) =>
        _host(ListEditor(block: block, onChanged: (_) {}));

    await tester.pumpWidget(editor(_nested));
    await tester.pumpWidget(editor(const ListBlock(
      style: ListStyle.unordered,
      items: [
        ListItem(content: 'x', items: [ListItem(content: 'y')]),
      ],
    )));
    await tester.pump();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(TextField, 'x'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'y'), findsOneWidget);

    // And grows again when the new block has more rows.
    await tester.pumpWidget(editor(_nested));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('nested edits made in the full editor are saved',
      (tester) async {
    final controller = EditorController(
      initialBlocks: const [
        ListBlock(
          style: ListStyle.unordered,
          items: [ListItem(content: 'a'), ListItem(content: 'b')],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: EditorJSEditor(controller: controller)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Indent').at(1));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'b'), 'child');
    await tester.pumpAndSettle();

    final block = controller.blocks.single as ListBlock;
    expect(_outline(block.items), 'a\n  child');
    expect(
      controller.getContent(),
      contains('"items":[{"content":"child","meta":{},"items":[]}]'),
    );
  });
}
