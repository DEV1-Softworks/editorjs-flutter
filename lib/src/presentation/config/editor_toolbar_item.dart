/// The buttons the editor toolbar can show.
///
/// Pass a selection to `EditorConfig.toolbarItems` to choose which buttons
/// appear and in what order. The order of the values below is the default.
enum EditorToolbarItem {
  paragraph,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  quote,
  code,
  unorderedList,
  orderedList,

  /// A checklist stored the `@editorjs/list` 2.x way: a `list` block with the
  /// checklist style.
  checklist,

  /// A checklist stored as the older `@editorjs/checklist` block.
  legacyChecklist,
  table,
  delimiter,
  warning,
  image,
  hyperlink,
  undo,
  redo,
  removeLastBlock,
}
