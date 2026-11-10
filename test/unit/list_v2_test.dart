import 'dart:convert';

import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:editorjs_flutter/src/data/mappers/list_mapper.dart';
import 'package:editorjs_flutter/src/presentation/utils/list_counter_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The three examples from the @editorjs/list 2.x README.
const _listV2Document = '''
{
  "time": 1762700000000,
  "version": "2.31.7",
  "blocks": [
    {"id": "unordered1", "type": "list", "data": {
      "style": "unordered", "meta": {},
      "items": [
        {"content": "Apples", "meta": {}, "items": [
          {"content": "Red", "meta": {}, "items": []}
        ]}
      ]}},
    {"id": "ordered001", "type": "list", "data": {
      "style": "ordered",
      "meta": {"start": 2, "counterType": "upper-roman"},
      "items": [
        {"content": "Apples", "meta": {}, "items": [
          {"content": "Red", "meta": {}, "items": []}
        ]}
      ]}},
    {"id": "checklist1", "type": "list", "data": {
      "style": "checklist", "meta": {},
      "items": [
        {"content": "Apples", "meta": {"checked": false}, "items": [
          {"content": "Red", "meta": {"checked": true}, "items": []}
        ]}
      ]}}
  ]
}
''';

void main() {
  const mapper = ListMapper();

  group('ListMapper — list 2.x', () {
    test('checklist style keeps the checked state at every level', () {
      final block = mapper.fromJson({
        'style': 'checklist',
        'meta': <String, dynamic>{},
        'items': [
          {
            'content': 'Parent',
            'meta': {'checked': false},
            'items': [
              {
                'content': 'Child',
                'meta': {'checked': true},
                'items': <dynamic>[],
              },
            ],
          },
        ],
      });
      expect(block.style, ListStyle.checklist);
      expect(block.items.single.checked, isFalse);
      expect(block.items.single.items.single.checked, isTrue);
    });

    test('ordered style reads start and counterType', () {
      final block = mapper.fromJson({
        'style': 'ordered',
        'meta': {'start': 5, 'counterType': 'lower-alpha'},
        'items': <dynamic>[],
      });
      expect(block.start, 5);
      expect(block.counterType, ListCounterType.lowerAlpha);
    });

    test('missing, mistyped or unknown meta values become null', () {
      expect(mapper.fromJson({'style': 'ordered'}).start, isNull);
      expect(mapper.fromJson({'style': 'ordered'}).counterType, isNull);

      final block = mapper.fromJson({
        'style': 'ordered',
        'meta': {'start': 'three', 'counterType': 'hieroglyphs'},
      });
      expect(block.start, isNull);
      expect(block.counterType, isNull);

      expect(mapper.fromJson({'style': 'ordered', 'meta': []}).start, isNull);
    });

    test('a mistyped checked flag reads as unchecked', () {
      final block = mapper.fromJson({
        'style': 'checklist',
        'items': [
          {
            'content': 'a',
            'meta': {'checked': 'yes'},
          },
          {'content': 'b', 'meta': 7},
        ],
      });
      expect(block.items.map((i) => i.checked), [false, false]);
    });
  });

  group('ListMapper — legacy formats', () {
    test('list 1.x string items are unchecked and childless', () {
      final block = mapper.fromJson({
        'style': 'unordered',
        'items': ['a', 'b'],
      });
      expect(block.items.map((i) => i.content), ['a', 'b']);
      expect(block.items.every((i) => !i.checked && i.items.isEmpty), isTrue);
    });

    test('old checklist data under a list block becomes a checklist', () {
      final block = mapper.fromJson({
        'items': [
          {'text': 'Done', 'checked': true},
          {'text': 'Todo', 'checked': false},
        ],
      });
      expect(block.style, ListStyle.checklist);
      expect(block.items.map((i) => i.content), ['Done', 'Todo']);
      expect(block.items.map((i) => i.checked), [true, false]);
    });
  });

  group('ListBlock.toJson', () {
    test('writes style, meta and items in the list 2.x shape', () {
      const block = ListBlock(
        style: ListStyle.unordered,
        items: [ListItem(content: 'a')],
      );
      expect(block.toJson(), {
        'style': 'unordered',
        'meta': <String, dynamic>{},
        'items': [
          {'content': 'a', 'meta': <String, dynamic>{}, 'items': <dynamic>[]},
        ],
      });
      expect(block.toJson().keys, ['style', 'meta', 'items']);
    });

    test('ordered writes only the meta values that are set', () {
      List<String> metaKeys(ListBlock block) =>
          (block.toJson()['meta'] as Map<String, dynamic>).keys.toList();

      expect(
        metaKeys(const ListBlock(style: ListStyle.ordered, items: [])),
        isEmpty,
      );
      expect(
        metaKeys(const ListBlock(
          style: ListStyle.ordered,
          items: [],
          start: 3,
        )),
        ['start'],
      );
      expect(
        const ListBlock(
          style: ListStyle.ordered,
          items: [],
          start: 3,
          counterType: ListCounterType.upperAlpha,
        ).toJson()['meta'],
        {'start': 3, 'counterType': 'upper-alpha'},
      );
    });

    test('start and counterType are not written for other styles', () {
      const block = ListBlock(
        style: ListStyle.unordered,
        items: [],
        start: 3,
        counterType: ListCounterType.upperAlpha,
      );
      expect(block.toJson()['meta'], isEmpty);
    });

    test('checklist writes checked for every item, nested ones included', () {
      const block = ListBlock(
        style: ListStyle.checklist,
        items: [
          ListItem(
            content: 'p',
            checked: true,
            items: [ListItem(content: 'c')],
          ),
        ],
      );
      final parent =
          (block.toJson()['items'] as List).single as Map<String, dynamic>;
      expect(parent['meta'], {'checked': true});
      final child = (parent['items'] as List).single as Map<String, dynamic>;
      expect(child['meta'], {'checked': false});
    });

    test('checked is not written outside a checklist', () {
      const block = ListBlock(
        style: ListStyle.ordered,
        items: [ListItem(content: 'a', checked: true)],
      );
      final item =
          (block.toJson()['items'] as List).single as Map<String, dynamic>;
      expect(item['meta'], isEmpty);
    });
  });

  test('ListItem.copyWith changes only what is passed', () {
    const item = ListItem(content: 'a', items: [ListItem(content: 'b')]);
    final ticked = item.copyWith(checked: true);
    expect(ticked.checked, isTrue);
    expect(ticked.content, 'a');
    expect(ticked.items.single.content, 'b');
    expect(ticked.copyWith(content: 'z').checked, isTrue);
  });

  test('ListCounterType.fromValue maps every EditorJS value', () {
    for (final type in ListCounterType.values) {
      expect(ListCounterType.fromValue(type.value), type);
    }
    expect(ListCounterType.fromValue('nope'), isNull);
    expect(ListCounterType.fromValue(null), isNull);
  });

  group('round-trip', () {
    List<dynamic> blocksOf(String json) =>
        (jsonDecode(json) as Map<String, dynamic>)['blocks'] as List<dynamic>;

    test('the list 2.x README examples survive fromJson → getContent', () {
      final content = EditorController.fromJson(_listV2Document).getContent();
      expect(blocksOf(content), blocksOf(_listV2Document));
    });

    test('a legacy nested list is written back in the 2.x shape', () {
      const legacy = '{"blocks":[{"id":"legacy0001","type":"list","data":'
          '{"style":"ordered","items":[{"content":"a","items":[]}]}}]}';
      final content = EditorController.fromJson(legacy).getContent();
      expect((blocksOf(content).single as Map<String, dynamic>)['data'], {
        'style': 'ordered',
        'meta': <String, dynamic>{},
        'items': [
          {'content': 'a', 'meta': <String, dynamic>{}, 'items': <dynamic>[]},
        ],
      });
    });
  });

  group('ListCounterFormatter', () {
    test('numeric is the default', () {
      expect(ListCounterFormatter.format(7, null), '7');
      expect(ListCounterFormatter.format(7, ListCounterType.numeric), '7');
    });

    test('roman numerals', () {
      const upper = ListCounterType.upperRoman;
      expect(ListCounterFormatter.format(1, upper), 'I');
      expect(ListCounterFormatter.format(4, upper), 'IV');
      expect(ListCounterFormatter.format(9, upper), 'IX');
      expect(ListCounterFormatter.format(14, upper), 'XIV');
      expect(ListCounterFormatter.format(1994, upper), 'MCMXCIV');
      expect(ListCounterFormatter.format(3999, upper), 'MMMCMXCIX');
      expect(
        ListCounterFormatter.format(8, ListCounterType.lowerRoman),
        'viii',
      );
    });

    test('alphabetic counters continue past Z', () {
      const upper = ListCounterType.upperAlpha;
      expect(ListCounterFormatter.format(1, upper), 'A');
      expect(ListCounterFormatter.format(26, upper), 'Z');
      expect(ListCounterFormatter.format(27, upper), 'AA');
      expect(ListCounterFormatter.format(52, upper), 'AZ');
      expect(ListCounterFormatter.format(703, upper), 'AAA');
      expect(ListCounterFormatter.format(3, ListCounterType.lowerAlpha), 'c');
    });

    test('values a scheme cannot express fall back to digits', () {
      expect(ListCounterFormatter.format(0, ListCounterType.upperRoman), '0');
      expect(
        ListCounterFormatter.format(4000, ListCounterType.lowerRoman),
        '4000',
      );
      expect(ListCounterFormatter.format(0, ListCounterType.upperAlpha), '0');
      expect(ListCounterFormatter.format(-2, ListCounterType.lowerAlpha), '-2');
    });

    test('marker joins the levels with dots', () {
      expect(ListCounterFormatter.marker([3], null), '3.');
      expect(ListCounterFormatter.marker([2, 1, 4], null), '2.1.4.');
      expect(
        ListCounterFormatter.marker([2, 1], ListCounterType.upperRoman),
        'II.I.',
      );
    });
  });
}
