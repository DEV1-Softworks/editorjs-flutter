/// Every piece of text the editor and the viewer show on their own: button
/// labels, tooltips, field labels, hints and messages.
///
/// The defaults are English. To translate the package, or to reword a label,
/// pass an instance with the texts you want to `EditorConfig.strings`; anything
/// you leave out keeps its default:
///
/// ```dart
/// EditorConfig(
///   strings: EditorStrings(
///     paragraph: 'Párrafo',
///     addItem: 'Agregar elemento',
///     heading: (level) => 'Encabezado $level',
///   ),
/// )
/// ```
///
/// Texts that include a value (a heading level, a file size) are functions.
class EditorStrings {
  const EditorStrings({
    // Toolbar
    this.paragraph = 'Paragraph',
    this.paragraphLabel = 'T',
    this.heading = _heading,
    this.headingLabel = _headingLabel,
    this.quote = 'Quote',
    this.code = 'Code',
    this.unorderedList = 'Unordered list',
    this.orderedList = 'Ordered list',
    this.checklist = 'Checklist',
    this.legacyChecklist = 'Checklist (legacy)',
    this.table = 'Table',
    this.delimiter = 'Delimiter',
    this.warning = 'Warning',
    this.image = 'Image',
    this.embed = 'Embed',
    this.linkPreview = 'Link preview',
    this.attachment = 'Attachment',
    this.rawHtml = 'Raw HTML',
    this.hyperlink = 'Hyperlink',
    this.undo = 'Undo',
    this.redo = 'Redo',
    this.removeLastBlock = 'Remove last block',
    this.addHyperlinkTitle = 'Add hyperlink',
    this.hyperlinkTitleHint = 'Link title',
    // Shared actions and field labels
    this.add = 'Add',
    this.cancel = 'Cancel',
    this.save = 'Save',
    this.caption = 'Caption',
    this.title = 'Title',
    this.addItem = 'Add item',
    // Block controls
    this.moveUp = 'Move up',
    this.moveDown = 'Move down',
    this.deleteBlock = 'Delete block',
    this.unsupportedBlock = _unsupportedBlock,
    // Paragraph
    this.paragraphHint = 'Write something...',
    this.bold = 'Bold',
    this.boldLabel = 'B',
    this.italic = 'Italic',
    this.italicLabel = 'I',
    this.underline = 'Underline',
    this.underlineLabel = 'U',
    this.strikethrough = 'Strikethrough',
    this.strikethroughLabel = 'S',
    this.inlineCode = 'Inline code',
    this.highlight = 'Highlight',
    this.highlightLabel = 'mark',
    this.link = 'Link',
    this.linkLabel = 'link',
    this.addLinkTitle = 'Add link',
    this.editLinkTitle = 'Edit link',
    this.linkAddress = 'Link address',
    this.removeLink = 'Remove link',
    // Header
    this.headingLevel = 'Heading level',
    // List
    this.listUnordered = 'Unordered',
    this.listOrdered = 'Ordered',
    this.listChecklist = 'Checklist',
    this.startWith = 'Start with',
    this.counterNumeric = 'Numeric',
    this.counterLowerRoman = 'Lower Roman',
    this.counterUpperRoman = 'Upper Roman',
    this.counterLowerAlpha = 'Lower Alpha',
    this.counterUpperAlpha = 'Upper Alpha',
    this.outdent = 'Outdent',
    this.indent = 'Indent',
    this.removeItem = 'Remove item',
    this.checklistItemHint = 'List item...',
    // Quote
    this.quoteHint = 'Quote text...',
    this.quoteCaptionHint = 'Caption (optional)',
    this.align = 'Align:',
    this.alignLeft = 'left',
    this.alignCenter = 'center',
    this.alignRight = 'right',
    // Code
    this.codeHint = 'Enter code...',
    this.copy = 'Copy',
    // Warning
    this.warningTitleHint = 'Warning title',
    this.warningMessageHint = 'Warning message...',
    // Table
    this.firstRowIsHeader = 'First row is header',
    this.removeRow = 'Remove row',
    this.removeColumn = 'Remove column',
    this.addRow = 'Row',
    this.addColumn = 'Column',
    // Image
    this.camera = 'Camera',
    this.gallery = 'Gallery',
    this.imageUrl = 'Image URL',
    this.imageBorder = 'Border',
    this.imageStretch = 'Stretch',
    this.imageBackground = 'Background',
    this.imagePickFailed = 'Could not open the image.',
    this.imageUploadFailed = 'Upload failed. Try again.',
    // Embed
    this.embedLink = 'Embed link',
    this.embedService = _embedService,
    this.embedUnsupported = 'This link is not from a supported service.',
    this.embeddedContent = 'Embedded content',
    // Link preview
    this.linkUrl = 'Link',
    this.fetchPreview = 'Fetch preview',
    this.description = 'Description',
    this.previewImageUrl = 'Preview image URL',
    this.noPreview = 'No preview available for this link.',
    this.previewFailed = 'Could not fetch the preview.',
    // Attachment
    this.chooseFile = 'Choose file',
    this.fileUrl = 'File URL',
    this.fileSize = _fileSize,
    this.attachFailed = 'Could not attach the file.',
    this.downloadFile = 'Download file',
  });

  static String _heading(int level) => 'Heading $level';
  static String _headingLabel(int level) => 'H$level';
  static String _unsupportedBlock(String type) => '[Unsupported block: $type]';
  static String _embedService(String service) => 'Service: $service';
  static String _fileSize(int bytes) => '$bytes bytes';

  // --- Toolbar: tooltips of the buttons that add a block ---------------------

  final String paragraph;

  /// Text of the paragraph button, which has no icon.
  final String paragraphLabel;

  /// Tooltip of a heading button, and the hint of an empty heading.
  final String Function(int level) heading;

  /// Text of a heading button and of the entries of the level selector.
  final String Function(int level) headingLabel;
  final String quote;
  final String code;
  final String unorderedList;
  final String orderedList;

  /// The checklist stored as a list block (`@editorjs/list` 2.x).
  final String checklist;

  /// The checklist stored as the older `checklist` block.
  final String legacyChecklist;
  final String table;
  final String delimiter;
  final String warning;
  final String image;
  final String embed;
  final String linkPreview;
  final String attachment;

  /// Tooltip of the raw HTML button and label of the raw HTML field.
  final String rawHtml;
  final String hyperlink;
  final String undo;
  final String redo;
  final String removeLastBlock;

  /// Title of the dialog the hyperlink button opens.
  final String addHyperlinkTitle;
  final String hyperlinkTitleHint;

  // --- Shared actions and field labels ---------------------------------------

  final String add;
  final String cancel;
  final String save;

  /// Label of the caption field of image and embed blocks.
  final String caption;

  /// Label of the title field of link and attachment blocks.
  final String title;

  /// Button that appends an item to a list or a checklist.
  final String addItem;

  // --- Controls beside every block -------------------------------------------

  final String moveUp;
  final String moveDown;
  final String deleteBlock;

  /// Placeholder shown for a block the editor has no editor for.
  final String Function(String type) unsupportedBlock;

  // --- Paragraph --------------------------------------------------------------

  final String paragraphHint;

  /// Tooltips of the format buttons, each followed by the short text shown on
  /// the button itself.
  final String bold;
  final String boldLabel;
  final String italic;
  final String italicLabel;
  final String underline;
  final String underlineLabel;
  final String strikethrough;
  final String strikethroughLabel;
  final String inlineCode;
  final String highlight;
  final String highlightLabel;
  final String link;
  final String linkLabel;

  /// Titles of the link dialog, for a new and for an existing link.
  final String addLinkTitle;
  final String editLinkTitle;
  final String linkAddress;
  final String removeLink;

  // --- Header -----------------------------------------------------------------

  /// Tooltip of the level selector.
  final String headingLevel;

  // --- List -------------------------------------------------------------------

  /// Tooltips of the style selector.
  final String listUnordered;
  final String listOrdered;
  final String listChecklist;
  final String startWith;
  final String counterNumeric;
  final String counterLowerRoman;
  final String counterUpperRoman;
  final String counterLowerAlpha;
  final String counterUpperAlpha;
  final String outdent;
  final String indent;
  final String removeItem;

  /// Hint of an empty item of the older checklist block.
  final String checklistItemHint;

  // --- Quote ------------------------------------------------------------------

  final String quoteHint;
  final String quoteCaptionHint;
  final String align;
  final String alignLeft;
  final String alignCenter;
  final String alignRight;

  // --- Code -------------------------------------------------------------------

  final String codeHint;

  /// Tooltip of the copy button on a code block in the viewer.
  final String copy;

  // --- Warning ----------------------------------------------------------------

  final String warningTitleHint;
  final String warningMessageHint;

  // --- Table ------------------------------------------------------------------

  final String firstRowIsHeader;
  final String removeRow;
  final String removeColumn;

  /// Buttons that add a row and a column; shown next to a plus icon.
  final String addRow;
  final String addColumn;

  // --- Image ------------------------------------------------------------------

  final String camera;
  final String gallery;
  final String imageUrl;
  final String imageBorder;
  final String imageStretch;
  final String imageBackground;
  final String imagePickFailed;
  final String imageUploadFailed;

  // --- Embed ------------------------------------------------------------------

  final String embedLink;

  /// Line naming the service a link was recognized as.
  final String Function(String service) embedService;
  final String embedUnsupported;

  /// Heading of an embed card in the viewer when the service is unknown.
  final String embeddedContent;

  // --- Link preview -----------------------------------------------------------

  /// Label of the link field of a link block.
  final String linkUrl;
  final String fetchPreview;
  final String description;
  final String previewImageUrl;
  final String noPreview;
  final String previewFailed;

  // --- Attachment -------------------------------------------------------------

  final String chooseFile;
  final String fileUrl;
  final String Function(int bytes) fileSize;
  final String attachFailed;

  /// Text of an attachment card in the viewer when the file has no title or
  /// name.
  final String downloadFile;
}
