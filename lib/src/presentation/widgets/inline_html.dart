import 'package:flutter/widgets.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../data/utils/html_sanitizer.dart';
import '../../domain/entities/style_config.dart';
import '../utils/html_style_builder.dart';
import 'editor_link_scope.dart';

/// Renders a piece of EditorJS text.
///
/// Every editable field in EditorJS is `contenteditable`, so its saved value
/// is HTML: it can carry inline formatting (`<b>`, `<i>`, `<a>`, `<mark>`,
/// `<code>`) and always carries entities such as `&nbsp;` and `&amp;`. This
/// widget is the single place that turns such a string into widgets, so every
/// block sanitizes, styles and handles link taps the same way.
class InlineHtml extends StatelessWidget {
  final String html;
  final StyleConfig? styleConfig;

  /// Extra styling for the text as a whole (size, weight, colour, alignment),
  /// applied on top of [styleConfig].
  final Style? bodyStyle;

  /// Whether the text is a fragment inside another widget (a heading, a table
  /// cell, a caption) rather than a block of its own.
  ///
  /// A compact fragment has no outer margin and is only as wide as its
  /// content. A block keeps a vertical margin and spans the available width.
  /// Neither has a horizontal margin, so all blocks share one left edge.
  final bool compact;

  static const double _blockMargin = 8;

  const InlineHtml(
    this.html, {
    super.key,
    this.styleConfig,
    this.bodyStyle,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final styles = HtmlStyleBuilder.build(styleConfig);

    // flutter_html gives `<body>` an 8px margin on every side by default.
    var body = (styles['body'] ?? Style()).copyWith(
      margin: compact
          ? Margins.zero
          : Margins.symmetric(horizontal: 0, vertical: _blockMargin),
      padding: HtmlPaddings.zero,
    );
    if (bodyStyle != null) body = body.merge(bodyStyle!);

    return Html(
      data: HtmlSanitizer.sanitize(html),
      shrinkWrap: compact,
      style: {...styles, 'body': body},
      onLinkTap: (url, _, __) => EditorLinkScope.open(context, url),
    );
  }
}
