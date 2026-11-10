import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:editorjs_flutter/src/presentation/blocks/header/header_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 400, child: child)),
    );

Future<void> _pickLevel(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButton<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the level selector shows the current level', (tester) async {
    await tester.pumpWidget(_host(HeaderEditor(
      block: const HeaderBlock(text: 'Title', level: 3),
      onChanged: (_) {},
    )));
    expect(
      tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>)).value,
      3,
    );
  });

  testWidgets('choosing a level changes the block and keeps the text',
      (tester) async {
    final changes = <HeaderBlock>[];
    await tester.pumpWidget(_host(HeaderEditor(
      block: const HeaderBlock(text: 'Title', level: 2),
      onChanged: changes.add,
    )));

    await _pickLevel(tester, 'H5');

    expect(changes.single.level, 5);
    expect(changes.single.text, 'Title');
    expect(
      tester.widget<TextField>(find.byType(TextField)).style!.fontSize,
      14,
    );
  });

  testWidgets('choosing the current level changes nothing', (tester) async {
    final changes = <HeaderBlock>[];
    await tester.pumpWidget(_host(HeaderEditor(
      block: const HeaderBlock(text: 'Title', level: 2),
      onChanged: changes.add,
    )));

    await _pickLevel(tester, 'H2');
    expect(changes, isEmpty);
  });

  testWidgets('text typed after a level change keeps the new level',
      (tester) async {
    final changes = <HeaderBlock>[];
    await tester.pumpWidget(_host(HeaderEditor(
      block: const HeaderBlock(text: 'Title', level: 2),
      onChanged: changes.add,
    )));

    await _pickLevel(tester, 'H4');
    await tester.enterText(find.byType(TextField), 'Renamed');

    expect(changes.last.text, 'Renamed');
    expect(changes.last.level, 4);
  });

  testWidgets('a level outside H1–H6 still builds', (tester) async {
    for (final (level, shown) in [(0, 1), (9, 6)]) {
      await tester.pumpWidget(_host(HeaderEditor(
        key: ValueKey(level),
        block: HeaderBlock(text: 'Odd', level: level),
        onChanged: (_) {},
      )));
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .value,
        shown,
      );
    }
  });

  testWidgets('follows a level changed from outside', (tester) async {
    Widget editor(int level) => _host(HeaderEditor(
          block: HeaderBlock(text: 'Title', level: level),
          onChanged: (_) {},
        ));

    await tester.pumpWidget(editor(1));
    await tester.pumpWidget(editor(6));
    expect(
      tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>)).value,
      6,
    );
  });

  testWidgets('the level can be changed inside the full editor',
      (tester) async {
    final controller = EditorController(
      initialBlocks: const [HeaderBlock(text: 'Title', level: 1)],
    );
    await tester.pumpWidget(_host(EditorJSEditor(controller: controller)));
    await tester.pumpAndSettle();

    await _pickLevel(tester, 'H3');

    expect((controller.blocks.single as HeaderBlock).level, 3);
    expect(controller.getContent(), contains('"level":3'));
  });
}
