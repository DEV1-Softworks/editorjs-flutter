import 'package:flutter/widgets.dart';

import '../config/editor_config.dart';

/// Makes the [EditorConfig] of the surrounding `EditorJSEditor` available to
/// the block editors below it.
///
/// Block editors are built by the registry from a block and a callback, so
/// they cannot receive configuration as arguments. They read it from here.
class EditorConfigScope extends InheritedWidget {
  final EditorConfig config;

  const EditorConfigScope({
    super.key,
    required this.config,
    required super.child,
  });

  /// The configuration of the surrounding editor, or `null` when a block
  /// editor is used on its own.
  static EditorConfig? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<EditorConfigScope>()?.config;

  @override
  bool updateShouldNotify(EditorConfigScope oldWidget) =>
      config != oldWidget.config;
}
