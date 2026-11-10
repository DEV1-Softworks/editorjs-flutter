import '../../domain/entities/blocks/attaches_block.dart';
import '../../domain/entities/blocks/link_tool_block.dart';

/// Fetches the preview data (title, description, image) of the page at [url]
/// for a link block, the way the backend endpoint of the EditorJS link tool
/// does.
///
/// Return `null` when the page has no usable preview. Throw to report a
/// failure; the editor keeps the fields as they were and shows an error.
typedef LinkPreviewFetcher = Future<LinkToolMeta?> Function(String url);

/// Lets the user choose a file, stores it where readers of the document can
/// reach it, and returns the attachment describing it.
///
/// This package does not bundle a file picker, so the app supplies both the
/// picking and the uploading. Return `null` if the user cancelled. Throw to
/// report a failure; the editor keeps the current attachment and shows an
/// error.
typedef AttachmentPicker = Future<AttachesBlock?> Function();
