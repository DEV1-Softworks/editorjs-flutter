import 'package:flutter/widgets.dart';

import '../config/editor_config.dart';
import '../config/editor_strings.dart';

/// Makes the [EditorConfig] of the surrounding `EditorJSEditor` or
/// `EditorJSView` available to the block widgets below it.
///
/// Block editors and renderers are built by the registry from a block, so
/// they cannot receive configuration as arguments. They read it from here.
class EditorConfigScope extends InheritedWidget {
  final EditorConfig config;

  const EditorConfigScope({
    super.key,
    required this.config,
    required super.child,
  });

  /// The configuration of the surrounding editor or viewer, or `null` when a
  /// block widget is used on its own.
  static EditorConfig? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<EditorConfigScope>()?.config;

  /// The texts to show: those of the surrounding configuration, or the
  /// English defaults when a block widget is used on its own.
  static EditorStrings stringsOf(BuildContext context) =>
      maybeOf(context)?.strings ?? const EditorStrings();

  @override
  bool updateShouldNotify(EditorConfigScope oldWidget) =>
      config != oldWidget.config;
}
