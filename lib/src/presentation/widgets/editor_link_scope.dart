import 'dart:async';

import 'package:flutter/foundation.dart';
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
/// `EditorJSView` inserts one from `EditorConfig.onLinkTap` and
/// `EditorConfig.allowedLinkSchemes`. Custom renderers
/// should route their own links through [open] so they follow the same rule
/// as the built-in blocks:
///
/// ```dart
/// onTap: () => EditorLinkScope.open(context, block.url),
/// ```
class EditorLinkScope extends InheritedWidget {
  /// Handler for tapped links, or `null` to open them externally.
  final LinkTapCallback? onLinkTap;

  /// URL schemes that may be opened externally when [onLinkTap] is null.
  final Set<String> allowedSchemes;

  const EditorLinkScope({
    super.key,
    required this.onLinkTap,
    this.allowedSchemes = defaultSchemes,
    required super.child,
  });

  /// Schemes opened externally unless configured otherwise: web links only.
  /// Anything else (`mailto:`, `tel:`, `javascript:`, `file:`, app-specific
  /// schemes) is ignored until it is added to the allowed schemes.
  static const Set<String> defaultSchemes = {'http', 'https'};

  /// Opens [url] using the nearest scope's handler.
  ///
  /// Without a handler (or without a scope, as when a renderer is used on its
  /// own) the link is opened in the external application via
  /// [launchExternally]. Null and blank URLs are ignored.
  static void open(BuildContext context, String? url) {
    if (url == null || url.trim().isEmpty) return;

    final scope = context.getInheritedWidgetOfExactType<EditorLinkScope>();
    final handler = scope?.onLinkTap;
    if (handler != null) {
      handler(url);
    } else {
      unawaited(launchExternally(
        url,
        allowedSchemes: scope?.allowedSchemes ?? defaultSchemes,
      ));
    }
  }

  /// Opens [url] in the external application if its scheme is one of
  /// [allowedSchemes] (compared case-insensitively). Returns whether the link
  /// was opened.
  static Future<bool> launchExternally(
    String url, {
    Set<String> allowedSchemes = defaultSchemes,
  }) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        !allowedSchemes.any((s) => s.toLowerCase() == uri.scheme)) {
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
      onLinkTap != oldWidget.onLinkTap ||
      !setEquals(allowedSchemes, oldWidget.allowedSchemes);
}
