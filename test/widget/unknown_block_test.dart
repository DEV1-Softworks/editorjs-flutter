import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:editorjs_flutter/src/presentation/blocks/table/table_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingHeaderMapper implements BlockMapper<HeaderBlock> {
  const _ThrowingHeaderMapper();

  @override
  String get supportedType => 'header';

  @override
  HeaderBlock fromJson(Map<String, dynamic> data) =>
      throw StateError('mapper bug');
}

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BlockRendererRegistry', () {
    test('never dispatches an UnknownBlock, even for a registered type', () {
      final registry = BlockRendererRegistry();
      const block = UnknownBlock(type: 'header', data: {'text': 1});
      expect(registry.buildRenderer(block, null), isNull);
      expect(registry.buildEditor(block, (_) {}), isNull);
    });
  });

  group('EditorJSView', () {
    testWidgets('an unknown block renders nothing and leaves no gap',
        (tester) async {
      await tester.pumpWidget(_host(
        EditorJSView(jsonData: '{"blocks":[{"type":"toggle","data":{}}]}'),
      ));
      final column = tester.widget<Column>(
        find.descendant(
          of: find.byType(EditorJSView),
          matching: find.byType(Column),
        ),
      );
      expect(column.children, isEmpty);
    });

    testWidgets('a block its mapper cannot read does not break the document',
        (tester) async {
      final config = EditorConfig(
        typeRegistry: BlockTypeRegistry()
          ..register(const _ThrowingHeaderMapper()),
      );
      await tester.pumpWidget(_host(
        EditorJSView(
          config: config,
          jsonData: '{"blocks":['
              '{"type":"header","data":{"text":"Broken","level":1}},'
              '{"type":"warning","data":{"title":"Still shown","message":"m"}}'
              ']}',
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('Broken'), findsNothing);
      expect(find.text('Still shown'), findsOneWidget);
    });
  });

  group('EditorJSEditor', () {
    testWidgets('an unknown block shows a placeholder and is kept on save',
        (tester) async {
      final controller = EditorController.fromJson(
        '{"blocks":[{"id":"keep_me_01","type":"toggle","data":{"text":"x"}}]}',
      );
      await tester.pumpWidget(_host(EditorJSEditor(controller: controller)));

      expect(find.text('[Unsupported block: toggle]'), findsOneWidget);
      expect(
        controller.getContent(),
        contains('{"id":"keep_me_01","type":"toggle","data":{"text":"x"}}'),
      );
    });
  });

  group('TableEditor', () {
    testWidgets('editing keeps the stretched flag', (tester) async {
      TableBlock? changed;
      await tester.pumpWidget(_host(
        TableEditor(
          block: const TableBlock(
            stretched: true,
            content: [
              ['a'],
            ],
          ),
          onChanged: (block) => changed = block,
        ),
      ));

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(changed, isNotNull);
      expect(changed!.withHeadings, isTrue);
      expect(changed!.stretched, isTrue);
    });
  });
}
