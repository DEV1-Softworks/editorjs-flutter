import '../editor_strings.dart';
import 'editor_strings_es.dart';
import 'editor_strings_fr.dart';

/// The translations of the editor and viewer texts that ship with the package.
///
/// ```dart
/// EditorConfig(strings: EditorTranslations.es)
///
/// // Or follow the language of the app:
/// EditorConfig(
///   strings: EditorTranslations.forLanguage(
///     Localizations.localeOf(context).languageCode,
///   ),
/// )
/// ```
class EditorTranslations {
  EditorTranslations._();

  /// English, the default.
  static const EditorStrings en = EditorStrings();

  /// Spanish.
  static const EditorStrings es = editorStringsEs;

  /// French.
  static const EditorStrings fr = editorStringsFr;

  /// Every bundled translation by its ISO 639-1 language code.
  static const Map<String, EditorStrings> byLanguageCode = {
    'en': en,
    'es': es,
    'fr': fr,
  };

  /// Returns the texts for [languageCode], or English when the language is
  /// not bundled.
  ///
  /// Accepts a bare code (`es`) as well as a full locale tag (`es-MX`,
  /// `fr_CA`); only the language part is used.
  static EditorStrings forLanguage(String? languageCode) {
    final language =
        (languageCode ?? '').split(RegExp('[-_]')).first.toLowerCase();
    return byLanguageCode[language] ?? en;
  }
}
