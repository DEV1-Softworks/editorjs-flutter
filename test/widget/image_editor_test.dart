import 'dart:async';

import 'package:editorjs_flutter/editorjs_flutter.dart';
import 'package:editorjs_flutter/src/presentation/blocks/image/image_editor.dart';
import 'package:editorjs_flutter/src/presentation/widgets/image_upload_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _pickerChannel = MethodChannel('plugins.flutter.io/image_picker');

const _existing = ImageBlock(
  url: 'https://example.com/old.png',
  caption: 'Old caption',
  withBorder: true,
  stretched: true,
  withBackground: true,
  fileExtras: {'width': 800},
);

Widget _host(Widget child, {ImageUploader? uploader}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ImageUploadScope(
            uploader: uploader,
            child: SizedBox(width: 400, child: child),
          ),
        ),
      ),
    );

void main() {
  /// What the fake picker hands back: a path, null (cancelled), or an
  /// exception to throw.
  Object? picked;

  setUp(() {
    picked = '/tmp/picked/photo.png';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pickerChannel, (call) async {
      final result = picked;
      if (result is Exception) throw result;
      return result;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pickerChannel, null);
  });

  Future<List<ImageBlock>> pumpEditor(
    WidgetTester tester,
    ImageBlock block, {
    ImageUploader? uploader,
  }) async {
    final changes = <ImageBlock>[];
    await tester.pumpWidget(_host(
      ImageEditor(block: block, onChanged: changes.add),
      uploader: uploader,
    ));
    await tester.pumpAndSettle();
    return changes;
  }

  Future<void> pickFromGallery(WidgetTester tester) async {
    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();
  }

  group('fields', () {
    testWidgets('show the URL and caption of the block', (tester) async {
      await pumpEditor(tester, _existing);
      expect(
        find.widgetWithText(TextField, 'https://example.com/old.png'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Old caption'), findsOneWidget);
    });

    testWidgets('editing the caption keeps everything else', (tester) async {
      final changes = await pumpEditor(tester, _existing);
      await tester.enterText(
        find.widgetWithText(TextField, 'Old caption'),
        'New caption',
      );

      final block = changes.last;
      expect(block.caption, 'New caption');
      expect(block.url, _existing.url);
      expect(block.withBorder, isTrue);
      expect(block.fileExtras, {'width': 800});
    });

    testWidgets('typing a URL replaces the image and drops its file fields',
        (tester) async {
      final changes = await pumpEditor(tester, _existing);
      await tester.enterText(
        find.widgetWithText(TextField, 'https://example.com/old.png'),
        '  https://example.com/new.png ',
      );

      final block = changes.last;
      expect(block.url, 'https://example.com/new.png');
      expect(block.fileExtras, isEmpty);
      expect(block.caption, 'Old caption');
      expect(block.stretched, isTrue);
    });

    testWidgets('the three display options toggle independently',
        (tester) async {
      final changes = await pumpEditor(
        tester,
        const ImageBlock(url: 'https://example.com/a.png'),
      );

      await tester.tap(find.text('Border'));
      await tester.pump();
      await tester.tap(find.text('Background'));
      await tester.pump();

      // The second change builds on the first even though the parent never
      // handed the updated block back.
      final block = changes.last;
      expect(block.withBorder, isTrue);
      expect(block.withBackground, isTrue);
      expect(block.stretched, isFalse);

      await tester.tap(find.text('Stretch'));
      await tester.pump();
      await tester.tap(find.text('Border'));
      await tester.pump();
      expect(changes.last.stretched, isTrue);
      expect(changes.last.withBorder, isFalse);
    });

    testWidgets('follow a block replaced from outside', (tester) async {
      Widget editor(ImageBlock block) =>
          _host(ImageEditor(block: block, onChanged: (_) {}));

      await tester.pumpWidget(editor(_existing));
      await tester.pumpWidget(editor(const ImageBlock(
        url: 'https://example.com/other.png',
        caption: 'Other',
      )));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextField, 'https://example.com/other.png'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Other'), findsOneWidget);
      expect(
        tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Border')).selected,
        isFalse,
      );
    });
  });

  group('picking without an uploader', () {
    testWidgets('stores the local path and keeps caption and options',
        (tester) async {
      final changes = await pumpEditor(tester, _existing);
      await pickFromGallery(tester);

      final block = changes.single;
      expect(block.url, '/tmp/picked/photo.png');
      expect(block.caption, 'Old caption');
      expect(block.withBorder, isTrue);
      expect(block.stretched, isTrue);
      expect(block.withBackground, isTrue);
      // Described the previous file, so it does not carry over.
      expect(block.fileExtras, isEmpty);
      expect(
        find.widgetWithText(TextField, '/tmp/picked/photo.png'),
        findsOneWidget,
      );
    });

    testWidgets('the camera button picks too', (tester) async {
      final changes = await pumpEditor(tester, const ImageBlock(url: ''));
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();
      expect(changes.single.url, '/tmp/picked/photo.png');
    });

    testWidgets('cancelling the picker changes nothing', (tester) async {
      picked = null;
      final changes = await pumpEditor(tester, _existing);
      await pickFromGallery(tester);
      expect(changes, isEmpty);
    });

    testWidgets('a picker failure shows an error and changes nothing',
        (tester) async {
      picked = PlatformException(code: 'photo_access_denied');
      final changes = await pumpEditor(tester, _existing);
      await pickFromGallery(tester);

      expect(changes, isEmpty);
      expect(find.text('Could not open the image.'), findsOneWidget);
    });
  });

  group('picking with an uploader', () {
    testWidgets('uploads the file and stores the returned URL and fields',
        (tester) async {
      PickedImage? received;
      final changes = await pumpEditor(
        tester,
        _existing,
        uploader: (image) async {
          received = image;
          return const UploadedImage(
            url: 'https://cdn.example.com/photo.png',
            extras: {'width': 1024, 'id': 'asset-7'},
          );
        },
      );
      await pickFromGallery(tester);

      expect(received!.path, '/tmp/picked/photo.png');
      expect(received!.name, 'photo.png');

      final block = changes.single;
      expect(block.url, 'https://cdn.example.com/photo.png');
      expect(block.fileExtras, {'width': 1024, 'id': 'asset-7'});
      expect(block.caption, 'Old caption');
      expect(block.toJson()['file'], {
        'width': 1024,
        'id': 'asset-7',
        'url': 'https://cdn.example.com/photo.png',
      });
    });

    testWidgets('shows progress and blocks picking while uploading',
        (tester) async {
      final upload = Completer<UploadedImage>();
      final changes = await pumpEditor(
        tester,
        _existing,
        uploader: (_) => upload.future,
      );

      await tester.tap(find.text('Gallery'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Gallery'))
            .onPressed,
        isNull,
      );
      expect(changes, isEmpty);

      upload.complete(const UploadedImage(url: 'https://cdn.example.com/x'));
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(changes.single.url, 'https://cdn.example.com/x');
    });

    testWidgets('a failed upload shows an error and keeps the old image',
        (tester) async {
      final changes = await pumpEditor(
        tester,
        _existing,
        uploader: (_) async => throw StateError('server said no'),
      );
      await pickFromGallery(tester);

      expect(tester.takeException(), isNull);
      expect(changes, isEmpty);
      expect(find.text('Upload failed. Try again.'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      // The error clears on the next attempt.
      picked = null;
      await pickFromGallery(tester);
      expect(find.text('Upload failed. Try again.'), findsNothing);
    });

    testWidgets('EditorConfig.imageUploader reaches the image editor',
        (tester) async {
      final controller = EditorController(
        initialBlocks: const [ImageBlock(url: '')],
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EditorJSEditor(
            controller: controller,
            config: EditorConfig(
              imageUploader: (_) async =>
                  const UploadedImage(url: 'https://cdn.example.com/y.png'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await pickFromGallery(tester);

      expect(
        (controller.blocks.single as ImageBlock).url,
        'https://cdn.example.com/y.png',
      );
    });
  });

  group('value types', () {
    test('ImageBlock.copyWith replaces only what is passed', () {
      final copy = _existing.copyWith(url: 'u', withBorder: false);
      expect(copy.url, 'u');
      expect(copy.withBorder, isFalse);
      expect(copy.caption, 'Old caption');
      expect(copy.stretched, isTrue);
      expect(copy.withBackground, isTrue);
      expect(copy.fileExtras, {'width': 800});

      final other = _existing.copyWith(
        caption: 'c',
        stretched: false,
        withBackground: false,
        fileExtras: const {},
      );
      expect(other.caption, 'c');
      expect(other.stretched, isFalse);
      expect(other.withBackground, isFalse);
      expect(other.fileExtras, isEmpty);
      expect(other.url, _existing.url);
    });

    test('PickedImage reads its bytes through the given reader', () async {
      final image = PickedImage(
        path: '/p/a.jpg',
        name: 'a.jpg',
        mimeType: 'image/jpeg',
        readAsBytes: () async => Uint8List.fromList([1, 2, 3]),
      );
      expect(await image.readAsBytes(), [1, 2, 3]);
      expect(image.mimeType, 'image/jpeg');
    });

    test('UploadedImage has no extra fields by default', () {
      expect(const UploadedImage(url: 'u').extras, isEmpty);
    });

    test('ImageUploadScope notifies only when the uploader changes', () {
      Future<UploadedImage> uploader(PickedImage image) async =>
          const UploadedImage(url: 'u');
      const child = SizedBox();
      final scope = ImageUploadScope(uploader: uploader, child: child);
      expect(
        scope.updateShouldNotify(
          ImageUploadScope(uploader: uploader, child: child),
        ),
        isFalse,
      );
      expect(
        scope.updateShouldNotify(
          const ImageUploadScope(uploader: null, child: child),
        ),
        isTrue,
      );
    });
  });
}
