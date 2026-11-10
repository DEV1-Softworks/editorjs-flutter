import '../../data/registry/block_type_registry.dart';
import '../../domain/entities/style_config.dart';
import '../registry/block_renderer_registry.dart';
import '../widgets/editor_link_scope.dart';
import 'block_editor_hooks.dart';
import 'editor_strings.dart';
import 'editor_toolbar_item.dart';
import 'image_uploader.dart';

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

  /// The buttons of the editor toolbar, in the order they are shown.
  ///
  /// Defaults to every button. Pass a shorter list to hide some, for example
  /// to offer only the kind of checklist your EditorJS setup can read:
  ///
  /// ```dart
  /// toolbarItems: EditorToolbarItem.values
  ///     .where((item) => item != EditorToolbarItem.legacyChecklist)
  ///     .toList(),
  /// ```
  final List<EditorToolbarItem> toolbarItems;

  /// Stores an image the user picks in the editor and returns its public URL.
  ///
  /// Without an uploader the image block keeps the path of the file on the
  /// device, which no other device can load. Set this for any document that
  /// is meant to be read elsewhere.
  final ImageUploader? imageUploader;

  /// Fetches title, description and image for the link of a link block.
  ///
  /// When set, the link editor offers a "Fetch preview" button. Without it
  /// the preview fields are filled in by hand.
  final LinkPreviewFetcher? linkPreviewFetcher;

  /// Lets the user choose and upload a file for an attachment block.
  ///
  /// When set, the attachment editor offers a "Choose file" button. Without
  /// it an attachment is given as a URL.
  final AttachmentPicker? attachmentPicker;

  /// The text of every label, tooltip, hint and message the editor and the
  /// viewer show. Defaults to English; pass your own [EditorStrings] to
  /// translate or reword them.
  final EditorStrings strings;

  EditorConfig({
    BlockTypeRegistry? typeRegistry,
    BlockRendererRegistry? rendererRegistry,
    this.styleConfig,
    this.onLinkTap,
    this.allowedLinkSchemes = EditorLinkScope.defaultSchemes,
    this.toolbarItems = EditorToolbarItem.values,
    this.imageUploader,
    this.linkPreviewFetcher,
    this.attachmentPicker,
    this.strings = const EditorStrings(),
  })  : typeRegistry = typeRegistry ?? BlockTypeRegistry(),
        rendererRegistry = rendererRegistry ?? BlockRendererRegistry();
}
