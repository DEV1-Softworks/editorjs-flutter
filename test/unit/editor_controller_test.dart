import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:editorjs_flutter/editorjs_flutter.dart';

void main() {
  HeaderBlock header(String text, {int level = 1}) =>
      HeaderBlock(text: text, level: level);
  ParagraphBlock para(String html) => ParagraphBlock(html: html);

  EditorController makeController({List<BlockEntity>? initialBlocks}) =>
      EditorController(initialBlocks: initialBlocks);

  // ---------------------------------------------------------------------------
  // addBlock
  // ---------------------------------------------------------------------------
  group('addBlock', () {
    test('adds block and increments blockCount', () {
      final ctrl = makeController();
      expect(ctrl.blockCount, 0);
      ctrl.addBlock(header('Hello'));
      expect(ctrl.blockCount, 1);
    });

    test('blocks list is updated', () {
      final ctrl = makeController();
      ctrl.addBlock(header('A'));
      ctrl.addBlock(para('<p>B</p>'));
      expect(ctrl.blocks.length, 2);
      expect(ctrl.blocks[0], isA<HeaderBlock>());
      expect(ctrl.blocks[1], isA<ParagraphBlock>());
    });
  });

  // ---------------------------------------------------------------------------
  // insertBlock
  // ---------------------------------------------------------------------------
  group('insertBlock', () {
    test('inserts at correct index', () {
      final ctrl = makeController(initialBlocks: [header('A'), header('C')]);
      ctrl.insertBlock(1, header('B'));
      expect(ctrl.blockCount, 3);
      expect((ctrl.blocks[1] as HeaderBlock).text, 'B');
    });

    test('insert at 0 makes block first', () {
      final ctrl = makeController(initialBlocks: [header('Second')]);
      ctrl.insertBlock(0, header('First'));
      expect((ctrl.blocks[0] as HeaderBlock).text, 'First');
    });
  });

  // ---------------------------------------------------------------------------
  // updateBlock
  // ---------------------------------------------------------------------------
  group('updateBlock', () {
    test('replaces block, count unchanged', () {
      final ctrl = makeController(initialBlocks: [header('Old')]);
      ctrl.updateBlock(0, header('New'));
      expect(ctrl.blockCount, 1);
      expect((ctrl.blocks[0] as HeaderBlock).text, 'New');
    });
  });

  // ---------------------------------------------------------------------------
  // removeBlock
  // ---------------------------------------------------------------------------
  group('removeBlock', () {
    test('removes block and decrements count', () {
      final ctrl = makeController(initialBlocks: [header('A'), header('B')]);
      ctrl.removeBlock(0);
      expect(ctrl.blockCount, 1);
      expect((ctrl.blocks[0] as HeaderBlock).text, 'B');
    });
  });

  // ---------------------------------------------------------------------------
  // moveBlock
  // ---------------------------------------------------------------------------
  group('moveBlock', () {
    test('block appears at new index', () {
      final ctrl = makeController(
          initialBlocks: [header('A'), header('B'), header('C')]);
      ctrl.moveBlock(0, 2);
      expect((ctrl.blocks[2] as HeaderBlock).text, 'A');
      expect((ctrl.blocks[0] as HeaderBlock).text, 'B');
    });
  });

  // ---------------------------------------------------------------------------
  // clear
  // ---------------------------------------------------------------------------
  group('clear', () {
    test('blocks list is empty after clear', () {
      final ctrl = makeController(initialBlocks: [header('A'), header('B')]);
      ctrl.clear();
      expect(ctrl.blocks, isEmpty);
      expect(ctrl.blockCount, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // undo / redo
  // ---------------------------------------------------------------------------
  group('undo/redo', () {
    test('canUndo is false initially', () {
      final ctrl = makeController();
      expect(ctrl.canUndo, isFalse);
    });

    test('canUndo is true after addBlock', () {
      final ctrl = makeController();
      ctrl.addBlock(header('Hello'));
      expect(ctrl.canUndo, isTrue);
    });

    test('undo restores previous state', () {
      final ctrl = makeController();
      ctrl.addBlock(header('Hello'));
      ctrl.undo();
      expect(ctrl.blockCount, 0);
    });

    test('canRedo is true after undo', () {
      final ctrl = makeController();
      ctrl.addBlock(header('Hello'));
      ctrl.undo();
      expect(ctrl.canRedo, isTrue);
    });

    test('redo restores undone state', () {
      final ctrl = makeController();
      ctrl.addBlock(header('Hello'));
      ctrl.undo();
      ctrl.redo();
      expect(ctrl.blockCount, 1);
      expect((ctrl.blocks[0] as HeaderBlock).text, 'Hello');
    });

    test('new structural change after undo discards forward history', () {
      final ctrl = makeController();
      ctrl.addBlock(header('A'));
      ctrl.addBlock(header('B'));
      ctrl.undo(); // back to just A
      ctrl.addBlock(header('C')); // discards the B snapshot
      expect(ctrl.canRedo, isFalse);
      expect(ctrl.blockCount, 2);
      expect((ctrl.blocks[1] as HeaderBlock).text, 'C');
    });

    test('updateBlock does not create undo entry', () {
      final ctrl = makeController(initialBlocks: [header('Old')]);
      // After construction there is 1 snapshot (snapshot 0).
      // canUndo is false at the initial snapshot.
      expect(ctrl.canUndo, isFalse);
      ctrl.updateBlock(0, header('New'));
      // Should still not be undoable (no new snapshot created).
      expect(ctrl.canUndo, isFalse);
    });

    test('cannot undo past initial snapshot', () {
      final ctrl = makeController();
      ctrl.addBlock(header('A'));
      ctrl.undo();
      ctrl.undo(); // already at initial – should be a no-op
      expect(ctrl.blockCount, 0);
      expect(ctrl.canUndo, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // getContent
  // ---------------------------------------------------------------------------
  group('getContent', () {
    test('returns valid JSON string containing block data', () {
      final ctrl = makeController(
          initialBlocks: [header('Title', level: 2), para('<p>Body</p>')]);
      final json = ctrl.getContent();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['blocks'], isA<List>());
      final blocks = decoded['blocks'] as List<dynamic>;
      expect(blocks.length, 2);

      final first = blocks[0] as Map<String, dynamic>;
      expect(first['type'], 'header');
      expect((first['data'] as Map<String, dynamic>)['text'], 'Title');
      expect((first['data'] as Map<String, dynamic>)['level'], 2);

      final second = blocks[1] as Map<String, dynamic>;
      expect(second['type'], 'paragraph');
      expect((second['data'] as Map<String, dynamic>)['text'], '<p>Body</p>');
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson
  // ---------------------------------------------------------------------------
  group('fromJson', () {
    test('pre-populates blocks from valid JSON', () {
      const json =
          '{"blocks":[{"type":"header","data":{"text":"Hello","level":1}}]}';
      final ctrl = EditorController.fromJson(json);
      expect(ctrl.blockCount, 1);
      expect(ctrl.blocks.first, isA<HeaderBlock>());
      expect((ctrl.blocks.first as HeaderBlock).text, 'Hello');
    });

    test('empty controller on invalid JSON', () {
      final ctrl = EditorController.fromJson('not valid json');
      expect(ctrl.blockCount, 0);
    });

    test('empty controller on empty string', () {
      final ctrl = EditorController.fromJson('');
      expect(ctrl.blockCount, 0);
    });

    test('unknown block types are kept as UnknownBlock', () {
      const json =
          '{"blocks":[{"type":"unknown_xyz","data":{}},{"type":"header","data":{"text":"Known","level":1}}]}';
      final ctrl = EditorController.fromJson(json);
      expect(ctrl.blockCount, 2);
      expect(ctrl.blocks.first, isA<UnknownBlock>());
      expect(ctrl.blocks.last, isA<HeaderBlock>());
    });

    test('multiple blocks parsed correctly', () {
      const json = '''
      {
        "blocks": [
          {"type": "header", "data": {"text": "Title", "level": 2}},
          {"type": "paragraph", "data": {"text": "<b>Bold</b>"}},
          {"type": "delimiter", "data": {}}
        ]
      }
      ''';
      final ctrl = EditorController.fromJson(json);
      expect(ctrl.blockCount, 3);
      expect(ctrl.blocks[0], isA<HeaderBlock>());
      expect(ctrl.blocks[1], isA<ParagraphBlock>());
      expect(ctrl.blocks[2], isA<DelimiterBlock>());
    });

    test('getContent round-trip from fromJson', () {
      const json =
          '{"blocks":[{"type":"header","data":{"text":"Round Trip","level":3}}]}';
      final ctrl = EditorController.fromJson(json);
      final output = ctrl.getContent();
      final decoded = jsonDecode(output) as Map<String, dynamic>;
      final blocks = decoded['blocks'] as List<dynamic>;
      expect(blocks.length, 1);
      expect((blocks[0] as Map<String, dynamic>)['type'], 'header');
    });

    test('respects custom typeRegistry parameter', () {
      const json =
          '{"blocks":[{"type":"header","data":{"text":"Hi","level":1}}]}';

      // Custom registry that alters how header blocks are created
      final customRegistry = BlockTypeRegistry()
        ..register(const _PrefixedHeaderMapper('Custom: '));

      final ctrl = EditorController.fromJson(
        json,
        typeRegistry: customRegistry,
      );

      expect(ctrl.blockCount, 1);
      expect(ctrl.blocks.first, isA<HeaderBlock>());
      final headerBlock = ctrl.blocks.first as HeaderBlock;
      expect(headerBlock.text, 'Custom: Hi');
      expect(headerBlock.level, 1);
    });
  });
}

/// A [BlockMapper] that prefixes header text — used to verify custom
/// registries are respected by [EditorController.fromJson].
class _PrefixedHeaderMapper implements BlockMapper<HeaderBlock> {
  final String prefix;
  const _PrefixedHeaderMapper(this.prefix);

  @override
  String get supportedType => 'header';

  @override
  HeaderBlock fromJson(Map<String, dynamic> data) => HeaderBlock(
        text: '$prefix${data['text'] ?? ''}',
        level: data['level'] is int ? data['level'] as int : 1,
      );
}
