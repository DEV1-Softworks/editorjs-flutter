import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Called with the target of a link the reader tapped.
///
/// The URL is passed exactly as it appears in the document, so a handler that
/// opens it should decide which schemes it trusts.
typedef LinkTapCallback = void Function(String url);

/// Tells the block renderers below it what to do when a link is tapped.
///
/// `EditorJSView` inserts one from `EditorConfig.onLinkTap`. Custom renderers
/// should route their own links through [open] so they follow the same rule
/// as the built-in blocks:
///
/// ```dart
/// onTap: () => EditorLinkScope.open(context, block.url),
/// ```
class EditorLinkScope extends InheritedWidget {
  /// Handler for tapped links, or `null` to open them externally.
  final LinkTapCallback? onLinkTap;

  const EditorLinkScope({
    super.key,
    required this.onLinkTap,
    required super.child,
  });

  /// Schemes the default behaviour will hand to the operating system.
  /// Anything else (`javascript:`, `file:`, app-specific schemes) is ignored.
  static const Set<String> defaultSchemes = {'http', 'https', 'mailto', 'tel'};

  /// Opens [url] using the nearest scope's handler.
  ///
  /// Without a handler (or without a scope, as when a renderer is used on its
  /// own) the link is opened in the external application via
  /// [launchExternally]. Null and blank URLs are ignored.
  static void open(BuildContext context, String? url) {
    if (url == null || url.trim().isEmpty) return;

    final handler = context
        .getInheritedWidgetOfExactType<EditorLinkScope>()
        ?.onLinkTap;
    if (handler != null) {
      handler(url);
    } else {
      unawaited(launchExternally(url));
    }
  }

  /// Opens [url] in the external application if its scheme is one of
  /// [defaultSchemes]. Returns whether the link was opened.
  static Future<bool> launchExternally(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !defaultSchemes.contains(uri.scheme.toLowerCase())) {
      return false;
    }
    try {
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  bool updateShouldNotify(EditorLinkScope oldWidget) =>
      onLinkTap != oldWidget.onLinkTap;
}
