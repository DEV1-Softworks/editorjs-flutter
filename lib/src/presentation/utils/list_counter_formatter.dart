import '../../domain/entities/blocks/list_block.dart';

/// Formats ordered-list counters the way a browser renders the EditorJS list
/// tool, whose marker is CSS `counters(item, ".", <counter type>) "."`.
class ListCounterFormatter {
  ListCounterFormatter._();

  static const _romanNumerals = [
    (1000, 'M'),
    (900, 'CM'),
    (500, 'D'),
    (400, 'CD'),
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ];

  /// Builds the marker for an item from the counter values of its ancestors
  /// and itself, outermost first: `[2, 1]` → `2.1.`, or `II.I.` in upper
  /// roman.
  static String marker(List<int> path, ListCounterType? type) =>
      '${path.map((value) => format(value, type)).join('.')}.';

  /// Formats a single counter [value]. Values a scheme cannot express (zero
  /// and negatives, or roman numerals above 3999) fall back to plain digits,
  /// as CSS does.
  static String format(int value, ListCounterType? type) =>
      switch (type ?? ListCounterType.numeric) {
        ListCounterType.numeric => '$value',
        ListCounterType.upperRoman => _roman(value) ?? '$value',
        ListCounterType.lowerRoman =>
          _roman(value)?.toLowerCase() ?? '$value',
        ListCounterType.upperAlpha => _alpha(value) ?? '$value',
        ListCounterType.lowerAlpha =>
          _alpha(value)?.toLowerCase() ?? '$value',
      };

  static String? _roman(int value) {
    if (value < 1 || value > 3999) return null;
    final buffer = StringBuffer();
    var remaining = value;
    for (final (amount, numeral) in _romanNumerals) {
      while (remaining >= amount) {
        buffer.write(numeral);
        remaining -= amount;
      }
    }
    return buffer.toString();
  }

  /// A, B, … Z, AA, AB, … (bijective base 26).
  static String? _alpha(int value) {
    if (value < 1) return null;
    final letters = <String>[];
    var remaining = value;
    while (remaining > 0) {
      remaining--;
      letters.add(String.fromCharCode(0x41 + remaining % 26));
      remaining ~/= 26;
    }
    return letters.reversed.join();
  }
}
