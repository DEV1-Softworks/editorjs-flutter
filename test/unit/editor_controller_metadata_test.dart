import 'dart:convert';

import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const _document = '''
{"blocks": [
  {"id": "first_id_1", "type": "header", "data": {"text": "A", "level": 1},
   "tunes": {"anchor": {"name": "intro"}}},
  {"id": "second_id2", "type": "paragraph", "data": {"text": "B"}},
  {"type": "delimiter", "data": {}}
]}
''';

final _idPattern = RegExp(r'^[A-Za-z0-9_-]{10}$');

List<Map<String, dynamic>> _blocksOf(EditorController controller) =>
    ((jsonDecode(controller.getContent()) as Map<String, dynamic>)['blocks']
            as List)
        .cast<Map<String, dynamic>>();

void main() {
  group('block ids', () {
    test('ids from the document are kept', () {
      final ctrl = EditorController.fromJson(_document);
      expect(ctrl.blockIds[0], 'first_id_1');
      expect(ctrl.blockIds[1], 'second_id2');
    });

    test('a block without an id gets an EditorJS-style one', () {
      final ctrl = EditorController.fromJson(_document);
      expect(ctrl.blockIds[2], matches(_idPattern));
    });

    test('new blocks get unique EditorJS-style ids', () {
      final ctrl = EditorController();
      for (var i = 0; i < 200; i++) {
        ctrl.addBlock(const DelimiterBlock());
      }
      ctrl.insertBlock(0, const DelimiterBlock());
      expect(ctrl.blockIds.toSet().length, 201);
      expect(ctrl.blockIds.every(_idPattern.hasMatch), isTrue);
    });

    test('initialBlocks get ids too', () {
      final ctrl = EditorController(
        initialBlocks: const [DelimiterBlock(), DelimiterBlock()],
      );
      expect(ctrl.blockIds.toSet().length, 2);
    });

    test('a repeated id in a corrupt document is replaced', () {
      final ctrl = EditorController.fromJson('''
        {"blocks": [
          {"id": "dup", "type": "delimiter", "data": {}},
          {"id": "dup", "type": "delimiter", "data": {}}
        ]}
      ''');
      expect(ctrl.blockIds[0], 'dup');
      expect(ctrl.blockIds[1], isNot('dup'));
    });

    test('getContent writes an id for every block', () {
      final ctrl = EditorController.fromJson(_document)
        ..addBlock(const ParagraphBlock(html: 'new'));
      final blocks = _blocksOf(ctrl);
      expect(blocks.map((b) => b['id']), ctrl.blockIds);
    });

    test('updateBlock keeps the id', () {
      final ctrl = EditorController.fromJson(_document)
        ..updateBlock(0, const HeaderBlock(text: 'Changed', level: 2));
      expect(ctrl.blockIds[0], 'first_id_1');
    });
  });

  group('block tunes', () {
    test('tunes from the document are exposed and written back', () {
      final ctrl = EditorController.fromJson(_document);
      expect(ctrl.blockTunes[0], {
        'anchor': {'name': 'intro'},
      });
      expect(ctrl.blockTunes[1], isNull);

      final blocks = _blocksOf(ctrl);
      expect(blocks[0]['tunes'], {
        'anchor': {'name': 'intro'},
      });
      expect(blocks[1].containsKey('tunes'), isFalse);
    });

    test('tunes survive updateBlock', () {
      final ctrl = EditorController.fromJson(_document)
        ..updateBlock(0, const HeaderBlock(text: 'Changed', level: 2));
      expect(_blocksOf(ctrl)[0]['tunes'], isNotNull);
    });

    test('tunes follow their block through moveBlock', () {
      final ctrl = EditorController.fromJson(_document)..moveBlock(0, 2);
      expect(ctrl.blockTunes, [isNull, isNull, isNotNull]);
      expect(ctrl.blockIds[2], 'first_id_1');
    });

    test('tunes are removed with their block and restored by undo', () {
      final ctrl = EditorController.fromJson(_document)..removeBlock(0);
      expect(ctrl.blockTunes, [isNull, isNull]);

      ctrl.undo();
      expect(ctrl.blockTunes[0], isNotNull);
      expect(ctrl.blockIds[0], 'first_id_1');

      ctrl.redo();
      expect(ctrl.blockTunes, [isNull, isNull]);
    });

    test('new and inserted blocks start without tunes', () {
      final ctrl = EditorController.fromJson(_document)
        ..addBlock(const DelimiterBlock())
        ..insertBlock(0, const DelimiterBlock());
      expect(ctrl.blockTunes.first, isNull);
      expect(ctrl.blockTunes.last, isNull);
      expect(ctrl.blockTunes[1], isNotNull);
    });

    test('clear empties tunes and ids', () {
      final ctrl = EditorController.fromJson(_document)..clear();
      expect(ctrl.blockTunes, isEmpty);
      expect(ctrl.blockIds, isEmpty);
    });
  });
}
