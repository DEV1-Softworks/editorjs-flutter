import 'dart:convert';

import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:editorjs_flutter/src/data/datasources/json_document_source.dart';
import 'package:editorjs_flutter/src/data/mappers/attaches_mapper.dart';
import 'package:editorjs_flutter/src/data/mappers/image_mapper.dart';
import 'package:editorjs_flutter/src/data/mappers/link_tool_mapper.dart';
import 'package:editorjs_flutter/src/data/mappers/table_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

/// A document in the shape EditorJS 2.31 writes: every block has an id, one
/// carries tunes, and one comes from a plugin this package does not know.
const _modernDocument = '''
{
  "time": 1762700000000,
  "version": "2.31.7",
  "blocks": [
    {"id": "aB3xK9pQ2z", "type": "paragraph", "data": {"text": "Hello"},
     "tunes": {"alignment": {"alignment": "center"}}},
    {"id": "T1aaaaaaaa", "type": "table", "data": {
      "withHeadings": true, "stretched": true, "content": [["a", "b"]]}},
    {"id": "I1aaaaaaaa", "type": "image", "data": {
      "file": {"url": "https://x/y.png", "width": 800, "height": 600},
      "caption": "c", "withBorder": false, "stretched": false,
      "withBackground": false}},
    {"id": "K1aaaaaaaa", "type": "linkTool", "data": {
      "link": "https://codex.so",
      "meta": {"title": "CodeX", "site_name": "CodeX",
               "image": {"url": "https://x/i.png"}}}},
    {"id": "A1aaaaaaaa", "type": "attaches", "data": {
      "file": {"url": "https://x/f.pdf", "size": 91, "name": "f.pdf",
               "extension": "pdf", "assetId": 12},
      "title": "File"}},
    {"id": "U1aaaaaaaa", "type": "toggle",
     "data": {"text": "custom plugin block", "items": [1, 2]}}
  ]
}
''';

class _ThrowingMapper implements BlockMapper<HeaderBlock> {
  const _ThrowingMapper();

  @override
  String get supportedType => 'header';

  @override
  HeaderBlock fromJson(Map<String, dynamic> data) =>
      throw StateError('mapper bug');
}

void main() {
  late JsonDocumentSource source;

  setUp(() => source = JsonDocumentSource(registry: BlockTypeRegistry()));

  List<dynamic> blocksOf(String json) =>
      (jsonDecode(json) as Map<String, dynamic>)['blocks'] as List<dynamic>;

  group('document round-trip', () {
    test('parse → serialize reproduces every block exactly', () {
      final serialized = source.serialize(source.parse(_modernDocument));
      expect(blocksOf(serialized), blocksOf(_modernDocument));
    });

    test('time and version are carried through', () {
      final doc = source.parse(_modernDocument);
      expect(doc.time, 1762700000000);
      expect(doc.version, '2.31.7');
    });

    test('fromJson → getContent reproduces every block exactly', () {
      final content = EditorController.fromJson(_modernDocument).getContent();
      expect(blocksOf(content), blocksOf(_modernDocument));
    });

    test('getContent stamps the targeted EditorJS version', () {
      final content = EditorController().getContent();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      expect(decoded['version'], BlockDocument.editorJsVersion);
      expect(BlockDocument.editorJsVersion, '2.31.7');
    });
  });

  group('block metadata', () {
    test('ids and tunes are parsed into metadata parallel to blocks', () {
      final doc = source.parse(_modernDocument);
      expect(doc.metadata.length, doc.blocks.length);
      expect(doc.metadata[0].id, 'aB3xK9pQ2z');
      expect(doc.metadata[0].tunes, {
        'alignment': {'alignment': 'center'},
      });
      expect(doc.metadata[1].id, 'T1aaaaaaaa');
      expect(doc.metadata[1].tunes, isNull);
    });

    test('missing, empty or mistyped id and tunes become null', () {
      final doc = source.parse('''
        {"blocks": [
          {"type": "delimiter", "data": {}},
          {"id": "", "type": "delimiter", "data": {}, "tunes": {}},
          {"id": 7, "type": "delimiter", "data": {}, "tunes": []}
        ]}
      ''');
      for (final metadata in doc.metadata) {
        expect(metadata.id, isNull);
        expect(metadata.tunes, isNull);
      }
    });

    test('a document without metadata serializes without id or tunes', () {
      const doc = BlockDocument(
        time: 1,
        version: 'x',
        blocks: [DelimiterBlock()],
      );
      final block =
          (doc.toJson()['blocks'] as List).single as Map<String, dynamic>;
      expect(block.keys, ['type', 'data']);
      expect(doc.metadataAt(0), same(BlockMetadata.none));
      expect(doc.metadataAt(-1), same(BlockMetadata.none));
    });

    test('id is written before type, tunes after data', () {
      const doc = BlockDocument(
        time: 1,
        version: 'x',
        blocks: [DelimiterBlock()],
        metadata: [
          BlockMetadata(id: 'abc', tunes: {'t': true}),
        ],
      );
      final block =
          (doc.toJson()['blocks'] as List).single as Map<String, dynamic>;
      expect(block.keys, ['id', 'type', 'data', 'tunes']);
    });
  });

  group('unknown and unreadable blocks', () {
    test('a block with no type is dropped', () {
      final doc = source.parse('''
        {"blocks": [
          {"data": {"text": "orphan"}},
          {"type": "", "data": {}},
          {"type": 3, "data": {}},
          {"type": "delimiter", "data": {}}
        ]}
      ''');
      expect(doc.blocks.single, isA<DelimiterBlock>());
      expect(doc.metadata.length, 1);
    });

    test('a block whose data is missing still parses', () {
      final doc = source.parse('{"blocks": [{"type": "paragraph"}]}');
      expect((doc.blocks.single as ParagraphBlock).html, '');
    });

    test('a throwing mapper yields an UnknownBlock with the original data', () {
      final throwing = JsonDocumentSource(
        registry: BlockTypeRegistry()..register(const _ThrowingMapper()),
      );
      final doc = throwing.parse('''
        {"blocks": [
          {"type": "header", "data": {"text": "T", "level": 2}},
          {"type": "paragraph", "data": {"text": "still here"}}
        ]}
      ''');
      final unknown = doc.blocks[0] as UnknownBlock;
      expect(unknown.type, 'header');
      expect(unknown.toJson(), {'text': 'T', 'level': 2});
      expect((doc.blocks[1] as ParagraphBlock).html, 'still here');
    });
  });

  group('mistyped fields never throw', () {
    BlockEntity parseOne(String block) =>
        source.parse('{"blocks": [$block]}').blocks.single;

    test('linkTool meta as an array', () {
      final block = parseOne(
        '{"type": "linkTool", "data": {"link": "https://x", "meta": []}}',
      ) as LinkToolBlock;
      expect(block.link, 'https://x');
      expect(block.meta, isNull);
    });

    test('linkTool meta fields of the wrong type', () {
      final block = parseOne(
        '{"type": "linkTool", "data": {"link": 5, '
        '"meta": {"title": 1, "description": [], "image": "str"}}}',
      ) as LinkToolBlock;
      expect(block.link, '5');
      expect(block.meta!.title, isNull);
      expect(block.meta!.description, isNull);
      expect(block.meta!.imageUrl, isNull);
    });

    test('list with a non-string style and non-list items', () {
      final block = parseOne(
        '{"type": "list", "data": {"style": 1, "items": "nope"}}',
      ) as ListBlock;
      expect(block.style, ListStyle.unordered);
      expect(block.items, isEmpty);
    });

    test('list item content of the wrong type', () {
      final block = parseOne(
        '{"type": "list", "data": {"style": "ordered", '
        '"items": [7, {"content": 8, "items": null}]}}',
      ) as ListBlock;
      expect(block.items[0].content, '7');
      expect(block.items[1].content, '8');
      expect(block.items[1].items, isEmpty);
    });

    test('paragraph, code, raw, warning and quote text as numbers', () {
      expect(
        (parseOne('{"type": "paragraph", "data": {"text": 42}}')
                as ParagraphBlock)
            .html,
        '42',
      );
      expect(
        (parseOne('{"type": "code", "data": {"code": 1}}') as CodeBlock).code,
        '1',
      );
      expect(
        (parseOne('{"type": "raw", "data": {"html": 2}}') as RawBlock).html,
        '2',
      );
      final warning =
          parseOne('{"type": "warning", "data": {"title": 3, "message": []}}')
              as WarningBlock;
      expect(warning.title, '3');
      expect(warning.message, '');
      final quote = parseOne(
        '{"type": "quote", "data": {"text": 4, "caption": 5, "alignment": 6}}',
      ) as QuoteBlock;
      expect(quote.text, '4');
      expect(quote.caption, isNull);
      expect(quote.alignment, QuoteAlignment.left);
    });

    test('header level as a double', () {
      final block =
          parseOne('{"type": "header", "data": {"text": "T", "level": 3.0}}')
              as HeaderBlock;
      expect(block.level, 3);
    });

    test('time as a double, a numeric string, or garbage', () {
      expect(source.parse('{"time": 1762700000000.5}').time, 1762700000000);
      expect(source.parse('{"time": "1762700000000"}').time, 1762700000000);
      expect(source.parse('{"time": "soon"}').time, greaterThan(0));
      expect(source.parse('{"time": null, "version": 2}').version, '2');
    });
  });

  group('preserved extra fields', () {
    test('table keeps stretched', () {
      final block = const TableMapper().fromJson({
        'withHeadings': false,
        'stretched': true,
        'content': <dynamic>[],
      });
      expect(block.stretched, isTrue);
      expect(block.toJson()['stretched'], isTrue);
      expect(const TableBlock(content: []).toJson()['stretched'], isFalse);
    });

    test('image keeps extra file fields and url always wins', () {
      final block = const ImageMapper().fromJson({
        'file': {'url': 'u', 'width': 800},
      });
      expect(block.fileExtras, {'width': 800});
      expect(block.toJson()['file'], {'width': 800, 'url': 'u'});
      expect(
        const ImageBlock(url: 'real', fileExtras: {'url': 'stale'})
            .toJson()['file'],
        {'url': 'real'},
      );
    });

    test('attaches keeps extra file fields', () {
      final block = const AttachesMapper().fromJson({
        'file': {'url': 'u', 'size': 1, 'assetId': 12},
        'title': 't',
      });
      expect(block.fileExtras, {'assetId': 12});
      expect(block.toJson()['file'], {'assetId': 12, 'url': 'u', 'size': 1});
    });

    test('linkTool keeps extra meta fields', () {
      final block = const LinkToolMapper().fromJson({
        'link': 'l',
        'meta': {'title': 't', 'site_name': 'CodeX'},
      });
      expect(block.meta!.extras, {'site_name': 'CodeX'});
      expect(block.toJson()['meta'], {'site_name': 'CodeX', 'title': 't'});
    });
  });
}
