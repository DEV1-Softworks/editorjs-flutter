import 'package:flutter/material.dart';

import '../config/editor_config.dart';
import '../controller/editor_controller.dart';
import 'editor_config_scope.dart';
import 'editorjs_toolbar.dart';

/// Interactive editor for EditorJS content.
///
/// Requires an [EditorController] which holds the document state and exposes
/// [EditorController.getContent] to export the result as EditorJS JSON.
///
/// Example:
/// ```dart
/// final controller = EditorController(serializer: serializeDocument);
///
/// EditorJSEditor(controller: controller)
///
/// // On save:
/// final json = controller.getContent();
/// ```
class EditorJSEditor extends StatefulWidget {
  final EditorController controller;
  final EditorConfig config;

  EditorJSEditor({
    super.key,
    required this.controller,
    EditorConfig? config,
  }) : config = config ?? EditorConfig();

  @override
  State<EditorJSEditor> createState() => _EditorJSEditorState();
}

class _EditorJSEditorState extends State<EditorJSEditor> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(EditorJSEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = widget.controller.blocks;

    final ids = widget.controller.blockIds;

    return EditorConfigScope(
      config: widget.config,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                final block = blocks[index];
                final editor = widget.config.rendererRegistry.buildEditor(
                      block,
                      (updated) => widget.controller.updateBlock(index, updated),
                    ) ??
                    _UnknownBlockWidget(type: block.type);

                return Padding(
                  key: ValueKey(ids[index]),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BlockWrap(
                    onMoveUp: index > 0
                        ? () => widget.controller.moveBlock(index, index - 1)
                        : null,
                    onMoveDown: index < blocks.length - 1
                        ? () => widget.controller.moveBlock(index, index + 1)
                        : null,
                    onDelete: () => widget.controller.removeBlock(index),
                    child: editor,
                  ),
                );
              },
            ),
          ),
          EditorJSToolbar(
            controller: widget.controller,
            rendererRegistry: widget.config.rendererRegistry,
            items: widget.config.toolbarItems,
          ),
        ],
      ),
    );
  }
}

class _BlockWrap extends StatelessWidget {
  final Widget child;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;

  const _BlockWrap({
    required this.child,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BlockControlButton(
              icon: Icons.arrow_upward,
              tooltip: 'Move up',
              onTap: onMoveUp,
            ),
            _BlockControlButton(
              icon: Icons.arrow_downward,
              tooltip: 'Move down',
              onTap: onMoveDown,
            ),
            _BlockControlButton(
              icon: Icons.close,
              tooltip: 'Delete block',
              onTap: onDelete,
              color: Colors.red.shade300,
            ),
          ],
        ),
      ],
    );
  }
}

class _BlockControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  const _BlockControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = onTap == null
        ? Colors.grey.shade300
        : (color ?? Colors.grey.shade500);

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 40,
        height: 40,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Center(
            child: Icon(icon, size: 14, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _UnknownBlockWidget extends StatelessWidget {
  final String type;

  const _UnknownBlockWidget({required this.type});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '[Unsupported block: $type]',
        style: TextStyle(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
          fontSize: 12,
        ),
      ),
    );
  }
}
