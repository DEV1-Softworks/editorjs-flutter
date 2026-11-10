/// Tolerant readers for the loosely-typed values found in EditorJS JSON.
///
/// Documents come from many backends and plugin versions, so a field is not
/// guaranteed to hold the type the EditorJS docs describe. These helpers never
/// throw: a value of the wrong shape yields the fallback instead.
class JsonReader {
  JsonReader._();

  /// Strings pass through; numbers and booleans are stringified.
  static String string(dynamic value, {String fallback = ''}) =>
      switch (value) {
        String v => v,
        num v => v.toString(),
        bool v => v.toString(),
        _ => fallback,
      };

  static String? nullableString(dynamic value) =>
      value is String ? value : null;

  /// Integers pass through; finite doubles are truncated.
  static int? integer(dynamic value) => switch (value) {
        int v => v,
        num v when v.isFinite => v.toInt(),
        _ => null,
      };

  static bool boolean(dynamic value, {bool fallback = false}) =>
      value is bool ? value : fallback;

  static Map<String, dynamic>? map(dynamic value) =>
      value is Map<String, dynamic> ? value : null;

  static List<dynamic> list(dynamic value) =>
      value is List ? value : const <dynamic>[];

  /// Returns the entries of [source] whose keys are not in [knownKeys].
  ///
  /// Used to carry backend-defined fields through a round-trip untouched.
  static Map<String, dynamic> extras(
    Map<String, dynamic>? source,
    Set<String> knownKeys,
  ) {
    if (source == null) return const <String, dynamic>{};
    return {
      for (final entry in source.entries)
        if (!knownKeys.contains(entry.key)) entry.key: entry.value,
    };
  }
}
