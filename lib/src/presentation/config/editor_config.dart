import '../../data/registry/block_type_registry.dart';
import '../../domain/entities/style_config.dart';
import '../registry/block_renderer_registry.dart';
import '../widgets/editor_link_scope.dart';

/// Configuration object shared by [EditorJSView] and [EditorJSEditor].
///
/// Provides optional customization of block registries and styling.
/// Defaults cover all built-in block types out of the box.
class EditorConfig {
  final BlockTypeRegistry typeRegistry;
  final BlockRendererRegistry rendererRegistry;
  final StyleConfig? styleConfig;

  /// Called when the reader taps a link in rendered content: an `<a>` inside
  /// any text, or a link, embed or attachment card.
  ///
  /// Leave it null to open links in the external application, limited to
  /// [allowedLinkSchemes]. A handler receives the URL unfiltered, so it can
  /// route app-specific links itself.
  final LinkTapCallback? onLinkTap;

  /// URL schemes the viewer may open externally when [onLinkTap] is null.
  ///
  /// Defaults to web links only (`http` and `https`). Add the schemes you
  /// want to allow, for example
  /// `{'http', 'https', 'mailto', 'tel'}` to also open e-mail and phone
  /// links. Links with any other scheme do nothing when tapped.
  final Set<String> allowedLinkSchemes;

  EditorConfig({
    BlockTypeRegistry? typeRegistry,
    BlockRendererRegistry? rendererRegistry,
    this.styleConfig,
    this.onLinkTap,
    this.allowedLinkSchemes = EditorLinkScope.defaultSchemes,
  })  : typeRegistry = typeRegistry ?? BlockTypeRegistry(),
        rendererRegistry = rendererRegistry ?? BlockRendererRegistry();
}
