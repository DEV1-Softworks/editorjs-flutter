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
  /// Leave it null to open `http`, `https`, `mailto` and `tel` links in the
  /// external application and ignore every other scheme. A handler receives
  /// the URL unfiltered, so it can route app-specific links itself.
  final LinkTapCallback? onLinkTap;

  EditorConfig({
    BlockTypeRegistry? typeRegistry,
    BlockRendererRegistry? rendererRegistry,
    this.styleConfig,
    this.onLinkTap,
  })  : typeRegistry = typeRegistry ?? BlockTypeRegistry(),
        rendererRegistry = rendererRegistry ?? BlockRendererRegistry();
}
