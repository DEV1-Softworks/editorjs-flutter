import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:editorjs_flutter/src/data/datasources/json_document_source.dart';
import 'package:editorjs_flutter/editorjs_flutter.dart';

void main() {
  late JsonDocumentSource source;

  setUp(() {
    source = JsonDocumentSource(registry: BlockTypeRegistry());
  });

  // ---------------------------------------------------------------------------
  // parse – valid EditorJS JSON
  // ---------------------------------------------------------------------------
  group('parse', () {
    test('valid EditorJS JSON returns correct BlockDocument', () {
      const json = '''
      {
        "time": 1610000000000,
        "version": "2.19.0",
        "blocks": [
          {"type": "header", "data": {"text": "Hello", "level": 1}},
          {"type": "paragraph", "data": {"text": "<p>World</p>"}}
        ]
      }
      ''';
      final doc = source.parse(json);
      expect(doc.version, '2.19.0');
      expect(doc.time, 1610000000000);
      expect(doc.blocks.length, 2);
      expect(doc.blocks[0], isA<HeaderBlock>());
      expect((doc.blocks[0] as HeaderBlock).text, 'Hello');
      expect(doc.blocks[1], isA<ParagraphBlock>());
    });

    test('unknown block type is kept verbatim as an UnknownBlock', () {
      const json = '''
      {
        "time": 1610000000000,
        "version": "2.19.0",
        "blocks": [
          {"type": "header", "data": {"text": "Keep me", "level": 2}},
          {"type": "unknownCustomType", "data": {"foo": "bar"}},
          {"type": "paragraph", "data": {"text": "<p>Also keep</p>"}}
        ]
      }
      ''';
      final doc = source.parse(json);
      expect(doc.blocks.length, 3);
      expect(doc.blocks[0], isA<HeaderBlock>());
      final unknown = doc.blocks[1] as UnknownBlock;
      expect(unknown.type, 'unknownCustomType');
      expect(unknown.data, {'foo': 'bar'});
      expect(doc.blocks[2], isA<ParagraphBlock>());
    });

    test('invalid JSON string returns empty BlockDocument without throwing', () {
      final doc = source.parse('not valid json {{{}}}');
      expect(doc.blocks, isEmpty);
      expect(doc.version, '');
    });

    test('missing blocks key returns empty blocks list', () {
      const json = '{"time": 1000, "version": "2.19.0"}';
      final doc = source.parse(json);
      expect(doc.blocks, isEmpty);
      expect(doc.version, '2.19.0');
    });

    test('blocks list contains non-map entries – they are ignored', () {
      const json = '''
      {
        "time": 1000,
        "version": "2.19.0",
        "blocks": [
          "not-a-map",
          42,
          {"type": "delimiter", "data": {}}
        ]
      }
      ''';
      final doc = source.parse(json);
      expect(doc.blocks.length, 1);
      expect(doc.blocks[0], isA<DelimiterBlock>());
    });
  });

  // ---------------------------------------------------------------------------
  // serialize – round trip
  // ---------------------------------------------------------------------------
  group('serialize', () {
    test('round-trip: parse then serialize contains original block data', () {
      const originalJson = '''
      {
        "time": 1610000000000,
        "version": "2.19.0",
        "blocks": [
          {"type": "header", "data": {"text": "Round Trip", "level": 3}},
          {"type": "paragraph", "data": {"text": "<p>Body</p>"}}
        ]
      }
      ''';
      final doc = source.parse(originalJson);
      final serialized = source.serialize(doc);
      final decoded = jsonDecode(serialized) as Map<String, dynamic>;

      expect(decoded['version'], '2.19.0');
      final blocks = decoded['blocks'] as List<dynamic>;
      expect(blocks.length, 2);

      final headerData =
          (blocks[0] as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      expect(headerData['text'], 'Round Trip');
      expect(headerData['level'], 3);

      final paraData =
          (blocks[1] as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      expect(paraData['text'], '<p>Body</p>');
    });

    test('serialize empty document produces valid JSON with empty blocks', () {
      const emptyJson =
          '{"time": 1000, "version": "2.19.0", "blocks": []}';
      final doc = source.parse(emptyJson);
      final serialized = source.serialize(doc);
      final decoded = jsonDecode(serialized) as Map<String, dynamic>;
      expect((decoded['blocks'] as List), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // blockIds (via blocks list) – data integrity
  // ---------------------------------------------------------------------------
  group('blockIds', () {
    test('after parse, all blocks have their data intact', () {
      const json = '''
      {
        "time": 1610000000000,
        "version": "2.19.0",
        "blocks": [
          {"type": "header", "data": {"text": "H1 Title", "level": 1}},
          {"type": "checklist", "data": {
            "items": [
              {"text": "Task A", "checked": true},
              {"text": "Task B", "checked": false}
            ]
          }},
          {"type": "delimiter", "data": {}}
        ]
      }
      ''';
      final doc = source.parse(json);
      expect(doc.blocks.length, 3);

      final header = doc.blocks[0] as HeaderBlock;
      expect(header.text, 'H1 Title');
      expect(header.level, 1);

      final checklist = doc.blocks[1] as ChecklistBlock;
      expect(checklist.items.length, 2);
      expect(checklist.items[0].text, 'Task A');
      expect(checklist.items[0].checked, isTrue);
      expect(checklist.items[1].checked, isFalse);

      expect(doc.blocks[2], isA<DelimiterBlock>());
    });
  });
}
