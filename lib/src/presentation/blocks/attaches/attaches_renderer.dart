import 'package:flutter/material.dart';

import '../../../domain/entities/blocks/attaches_block.dart';
import '../../widgets/editor_link_scope.dart';
import '../base_block_renderer.dart';
import '../../widgets/editor_config_scope.dart';

class AttachesRenderer extends BlockRenderer<AttachesBlock> {
  const AttachesRenderer(
      {super.key, required super.block, super.styleConfig});

  @override
  Widget build(BuildContext context) {
    final strings = EditorConfigScope.stringsOf(context);
    final displayName =
        block.title ?? block.name ?? strings.downloadFile;
    final ext = block.extension?.toUpperCase();

    return InkWell(
      onTap: block.url.isNotEmpty
          ? () => EditorLinkScope.open(context, block.url)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _iconForExtension(block.extension),
                color: Colors.blue.shade700,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      fontFamily: styleConfig?.defaultFont,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ext != null || block.size != null)
                    Text(
                      [
                        if (ext != null) ext,
                        if (block.size != null) _formatSize(block.size!),
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontFamily: styleConfig?.defaultFont,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.download_outlined,
                color: Colors.blue.shade700, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _iconForExtension(String? ext) => switch (ext?.toLowerCase()) {
        'pdf' => Icons.picture_as_pdf_outlined,
        'doc' || 'docx' => Icons.description_outlined,
        'xls' || 'xlsx' => Icons.table_chart_outlined,
        'zip' || 'rar' || '7z' => Icons.folder_zip_outlined,
        'mp3' || 'wav' || 'ogg' => Icons.audio_file_outlined,
        'mp4' || 'mov' || 'avi' => Icons.video_file_outlined,
        _ => Icons.insert_drive_file_outlined,
      };

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
