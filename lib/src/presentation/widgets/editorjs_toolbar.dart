import 'package:flutter/material.dart';

import '../../domain/entities/blocks/attaches_block.dart';
import '../../domain/entities/blocks/checklist_block.dart';
import '../../domain/entities/blocks/code_block.dart';
import '../../domain/entities/blocks/delimiter_block.dart';
import '../../domain/entities/blocks/embed_block.dart';
import '../../domain/entities/blocks/header_block.dart';
import '../../domain/entities/blocks/image_block.dart';
import '../../domain/entities/blocks/link_tool_block.dart';
import '../../domain/entities/blocks/list_block.dart';
import '../../domain/entities/blocks/paragraph_block.dart';
import '../../domain/entities/blocks/quote_block.dart';
import '../../domain/entities/blocks/raw_block.dart';
import '../../domain/entities/blocks/table_block.dart';
import '../../domain/entities/blocks/warning_block.dart';
import '../config/editor_toolbar_item.dart';
import '../controller/editor_controller.dart';
import '../registry/block_renderer_registry.dart';

/// Toolbar for [EditorJSEditor].
///
/// Communicates exclusively via [EditorController] — holds no reference to
/// any parent widget. Each action appends a new [BlockEntity] to the controller.
class EditorJSToolbar extends StatelessWidget {
  final EditorController controller;
  final BlockRendererRegistry rendererRegistry;

  /// The buttons to show, in order. Defaults to every button.
  final List<EditorToolbarItem> items;

  const EditorJSToolbar({
    super.key,
    required this.controller,
    required this.rendererRegistry,
    this.items = EditorToolbarItem.values,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in items) _buildButton(context, item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, EditorToolbarItem item) {
    return switch (item) {
      // --- Text blocks ---
      EditorToolbarItem.paragraph => _ToolbarButton(
          label: 'T',
          tooltip: 'Paragraph',
          onTap: () => controller.addBlock(const ParagraphBlock(html: '')),
        ),
      EditorToolbarItem.heading1 => _headingButton(1),
      EditorToolbarItem.heading2 => _headingButton(2),
      EditorToolbarItem.heading3 => _headingButton(3),
      EditorToolbarItem.heading4 => _headingButton(4),
      EditorToolbarItem.heading5 => _headingButton(5),
      EditorToolbarItem.heading6 => _headingButton(6),
      EditorToolbarItem.quote => _ToolbarButton(
          icon: Icons.format_quote,
          tooltip: 'Quote',
          onTap: () => controller.addBlock(const QuoteBlock(text: '')),
        ),
      EditorToolbarItem.code => _ToolbarButton(
          icon: Icons.code,
          tooltip: 'Code',
          onTap: () => controller.addBlock(const CodeBlock(code: '')),
        ),
      // --- Lists ---
      EditorToolbarItem.unorderedList => _ToolbarButton(
          icon: Icons.format_list_bulleted,
          tooltip: 'Unordered list',
          onTap: () => controller.addBlock(
            const ListBlock(
              style: ListStyle.unordered,
              items: [ListItem(content: '')],
            ),
          ),
        ),
      EditorToolbarItem.orderedList => _ToolbarButton(
          icon: Icons.format_list_numbered,
          tooltip: 'Ordered list',
          onTap: () => controller.addBlock(
            const ListBlock(
              style: ListStyle.ordered,
              items: [ListItem(content: '')],
            ),
          ),
        ),
      // Two checklists on purpose: which one a document can use depends on
      // the tools installed in the EditorJS instance that reads it.
      // `@editorjs/list` 2.x stores a checklist as a list block …
      EditorToolbarItem.checklist => _ToolbarButton(
          icon: Icons.checklist,
          tooltip: 'Checklist',
          onTap: () => controller.addBlock(
            const ListBlock(
              style: ListStyle.checklist,
              items: [ListItem(content: '')],
            ),
          ),
        ),
      // … while the older `@editorjs/checklist` tool has its own block.
      EditorToolbarItem.legacyChecklist => _ToolbarButton(
          icon: Icons.check_box_outlined,
          tooltip: 'Checklist (legacy)',
          onTap: () => controller.addBlock(
            const ChecklistBlock(
              items: [ChecklistItem(text: '')],
            ),
          ),
        ),
      // --- Structural ---
      EditorToolbarItem.table => _ToolbarButton(
          icon: Icons.table_chart_outlined,
          tooltip: 'Table',
          onTap: () => controller.addBlock(
            const TableBlock(
              content: [
                ['', ''],
                ['', ''],
              ],
            ),
          ),
        ),
      EditorToolbarItem.delimiter => _ToolbarButton(
          icon: Icons.horizontal_rule,
          tooltip: 'Delimiter',
          onTap: () => controller.addBlock(const DelimiterBlock()),
        ),
      EditorToolbarItem.warning => _ToolbarButton(
          icon: Icons.warning_amber_outlined,
          tooltip: 'Warning',
          onTap: () =>
              controller.addBlock(const WarningBlock(title: '', message: '')),
        ),
      // --- Media ---
      EditorToolbarItem.image => _ToolbarButton(
          icon: Icons.image_outlined,
          tooltip: 'Image',
          onTap: () => controller.addBlock(const ImageBlock(url: '')),
        ),
      EditorToolbarItem.embed => _ToolbarButton(
          icon: Icons.smart_display_outlined,
          tooltip: 'Embed',
          onTap: () => controller.addBlock(
            const EmbedBlock(service: '', source: '', embed: ''),
          ),
        ),
      EditorToolbarItem.linkPreview => _ToolbarButton(
          icon: Icons.add_link,
          tooltip: 'Link preview',
          onTap: () => controller.addBlock(const LinkToolBlock(link: '')),
        ),
      EditorToolbarItem.attachment => _ToolbarButton(
          icon: Icons.attach_file,
          tooltip: 'Attachment',
          onTap: () => controller.addBlock(const AttachesBlock(url: '')),
        ),
      EditorToolbarItem.rawHtml => _ToolbarButton(
          icon: Icons.html,
          tooltip: 'Raw HTML',
          onTap: () => controller.addBlock(const RawBlock(html: '')),
        ),
      EditorToolbarItem.hyperlink => _ToolbarButton(
          icon: Icons.link,
          tooltip: 'Hyperlink',
          onTap: () => _showHyperlinkDialog(context),
        ),
      // --- Actions ---
      EditorToolbarItem.undo => _ToolbarButton(
          icon: Icons.undo,
          tooltip: 'Undo',
          onTap: controller.canUndo ? controller.undo : null,
        ),
      EditorToolbarItem.redo => _ToolbarButton(
          icon: Icons.redo,
          tooltip: 'Redo',
          onTap: controller.canRedo ? controller.redo : null,
        ),
      EditorToolbarItem.removeLastBlock => _ToolbarButton(
          icon: Icons.delete_outline,
          tooltip: 'Remove last block',
          onTap: controller.blockCount > 0
              ? () => controller.removeBlock(controller.blockCount - 1)
              : null,
        ),
    };
  }

  Widget _headingButton(int level) => _ToolbarButton(
        label: 'H$level',
        tooltip: 'Heading $level',
        onTap: () => controller.addBlock(HeaderBlock(text: '', level: level)),
      );

  void _showHyperlinkDialog(BuildContext context) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add hyperlink'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: 'Link title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(hintText: 'https://...'),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              final title = titleController.text.trim();
              if (url.isNotEmpty) {
                controller.addBlock(ParagraphBlock(
                  html: '<a href="$url">${title.isNotEmpty ? title : url}</a>',
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ToolbarButton({
    this.label,
    this.icon,
    required this.tooltip,
    required this.onTap,
  }) : assert(label != null || icon != null);

  @override
  Widget build(BuildContext context) {
    final child = icon != null
        ? Icon(icon, size: 20, color: Colors.black54)
        : Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          );

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: child,
        ),
      ),
    );
  }
}
