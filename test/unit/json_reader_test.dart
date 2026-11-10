import 'package:editorjs_flutter/src/data/utils/json_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonReader.string', () {
    test('passes strings through', () {
      expect(JsonReader.string('abc'), 'abc');
    });

    test('stringifies numbers and booleans', () {
      expect(JsonReader.string(42), '42');
      expect(JsonReader.string(1.5), '1.5');
      expect(JsonReader.string(true), 'true');
    });

    test('uses the fallback for null, maps and lists', () {
      expect(JsonReader.string(null), '');
      expect(JsonReader.string(<String, dynamic>{}), '');
      expect(JsonReader.string(<dynamic>[], fallback: 'x'), 'x');
    });
  });

  test('nullableString returns null for anything but a string', () {
    expect(JsonReader.nullableString('a'), 'a');
    expect(JsonReader.nullableString(1), isNull);
    expect(JsonReader.nullableString(null), isNull);
  });

  group('JsonReader.integer', () {
    test('passes ints through and truncates doubles', () {
      expect(JsonReader.integer(7), 7);
      expect(JsonReader.integer(7.9), 7);
    });

    test('returns null for non-numbers and non-finite doubles', () {
      expect(JsonReader.integer('7'), isNull);
      expect(JsonReader.integer(null), isNull);
      expect(JsonReader.integer(double.nan), isNull);
      expect(JsonReader.integer(double.infinity), isNull);
    });
  });

  test('boolean falls back for non-bool values', () {
    expect(JsonReader.boolean(true), isTrue);
    expect(JsonReader.boolean('true'), isFalse);
    expect(JsonReader.boolean(null, fallback: true), isTrue);
  });

  test('map and list reject values of the wrong shape', () {
    expect(JsonReader.map(<String, dynamic>{'a': 1}), {'a': 1});
    expect(JsonReader.map(<dynamic>[]), isNull);
    expect(JsonReader.list(<dynamic>[1, 2]), [1, 2]);
    expect(JsonReader.list('nope'), isEmpty);
  });

  group('JsonReader.extras', () {
    test('keeps only the keys that are not known', () {
      expect(
        JsonReader.extras({'url': 'u', 'width': 800, 'id': 'x'}, {'url'}),
        {'width': 800, 'id': 'x'},
      );
    });

    test('returns an empty map for a null source', () {
      expect(JsonReader.extras(null, {'url'}), isEmpty);
    });
  });
}
