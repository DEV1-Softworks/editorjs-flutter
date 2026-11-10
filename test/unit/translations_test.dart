import 'dart:io';

import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _configDir = 'lib/src/presentation/config';

/// The name of every text of [EditorStrings], read from its constructor.
Set<String> _stringNames() {
  final source = File('$_configDir/editor_strings.dart').readAsStringSync();
  final constructor = source.substring(
    source.indexOf('const EditorStrings({'),
    source.indexOf('});'),
  );
  return RegExp(r'this\.(\w+) =')
      .allMatches(constructor)
      .map((m) => m.group(1)!)
      .toSet();
}

/// The bundled translation files by language code.
Map<String, File> _translationFiles() => {
      for (final file in Directory('$_configDir/translations')
          .listSync()
          .whereType<File>())
        if (RegExp(r'editor_strings_(\w+)\.dart$').firstMatch(file.path)
            case final match?)
          match.group(1)!: file,
    };

/// The texts a translation file passes to the [EditorStrings] constructor.
Set<String> _translatedNames(File file) {
  final source = file.readAsStringSync();
  final arguments = source.substring(
    source.indexOf('= EditorStrings('),
    source.indexOf(');'),
  );
  return RegExp(r'^  (\w+):', multiLine: true)
      .allMatches(arguments)
      .map((m) => m.group(1)!)
      .toSet();
}

void main() {
  group('bundled translation files', () {
    final names = _stringNames();
    final files = _translationFiles();

    test('Spanish and French are bundled', () {
      expect(files.keys, containsAll(['es', 'fr']));
      expect(names.length, greaterThan(100));
    });

    for (final entry in files.entries) {
      test('${entry.key} translates every text and nothing else', () {
        final translated = _translatedNames(entry.value);
        expect(
          names.difference(translated),
          isEmpty,
          reason: 'texts missing from ${entry.value.path}',
        );
        expect(
          translated.difference(names),
          isEmpty,
          reason: 'unknown texts in ${entry.value.path}',
        );
      });

      test('${entry.key} is registered in EditorTranslations', () {
        expect(EditorTranslations.byLanguageCode, contains(entry.key));
      });
    }
  });

  group('EditorTranslations', () {
    test('exposes each language', () {
      expect(EditorTranslations.en.paragraph, 'Paragraph');
      expect(EditorTranslations.es.paragraph, 'Párrafo');
      expect(EditorTranslations.fr.paragraph, 'Paragraphe');
      expect(EditorTranslations.byLanguageCode.keys, ['en', 'es', 'fr']);
    });

    test('texts with a value include it', () {
      expect(EditorTranslations.es.heading(2), 'Encabezado 2');
      expect(EditorTranslations.fr.heading(2), 'Titre 2');
      expect(EditorTranslations.es.headingLabel(3), 'H3');
      expect(EditorTranslations.es.fileSize(10), '10 bytes');
      expect(EditorTranslations.fr.fileSize(10), '10 octets');
      expect(EditorTranslations.es.embedService('vimeo'), 'Servicio: vimeo');
      expect(EditorTranslations.fr.embedService('vimeo'), 'Service : vimeo');
      expect(
        EditorTranslations.es.unsupportedBlock('x'),
        '[Bloque no compatible: x]',
      );
      expect(
        EditorTranslations.fr.unsupportedBlock('x'),
        '[Bloc non pris en charge : x]',
      );
    });

    test('forLanguage accepts codes and locale tags, in any case', () {
      expect(EditorTranslations.forLanguage('es'), same(EditorTranslations.es));
      expect(
        EditorTranslations.forLanguage('es-MX'),
        same(EditorTranslations.es),
      );
      expect(
        EditorTranslations.forLanguage('FR_ca'),
        same(EditorTranslations.fr),
      );
      expect(EditorTranslations.forLanguage('en'), same(EditorTranslations.en));
    });

    test('forLanguage falls back to English', () {
      for (final code in ['de', 'pt-BR', '', null]) {
        expect(
          EditorTranslations.forLanguage(code),
          same(EditorTranslations.en),
          reason: '$code',
        );
      }
    });
  });

  group('in the editor', () {
    const document = '{"blocks":['
        '{"type":"list","data":{"style":"ordered","meta":{},"items":'
        '[{"content":"","meta":{},"items":[]}]}},'
        '{"type":"image","data":{"file":{"url":""},"caption":""}}'
        ']}';

    Future<void> pumpEditor(WidgetTester tester, EditorStrings strings) async {
      await tester.binding.setSurfaceSize(const Size(2400, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EditorJSEditor(
            controller: EditorController.fromJson(document),
            config: EditorConfig(strings: strings),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('Spanish', (tester) async {
      await pumpEditor(tester, EditorTranslations.es);
      expect(find.byTooltip('Párrafo'), findsOneWidget);
      expect(find.byTooltip('Encabezado 2'), findsOneWidget);
      expect(find.text('Agregar elemento'), findsOneWidget);
      expect(find.text('Empezar en'), findsOneWidget);
      expect(find.text('Cámara'), findsOneWidget);
      expect(find.byTooltip('Deshacer'), findsOneWidget);
      // None of the English defaults they replace is left.
      expect(find.byTooltip('Paragraph'), findsNothing);
      expect(find.text('Add item'), findsNothing);
      expect(find.text('Camera'), findsNothing);
    });

    testWidgets('French', (tester) async {
      await pumpEditor(tester, EditorTranslations.fr);
      expect(find.byTooltip('Paragraphe'), findsOneWidget);
      expect(find.byTooltip('Titre 2'), findsOneWidget);
      expect(find.text('Ajouter un élément'), findsOneWidget);
      expect(find.text('Commencer à'), findsOneWidget);
      expect(find.text('Appareil photo'), findsOneWidget);
      expect(find.byTooltip('Rétablir'), findsOneWidget);
      expect(find.text('Add item'), findsNothing);
    });
  });
}
