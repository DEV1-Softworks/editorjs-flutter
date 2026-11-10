import 'dart:convert';
import 'dart:developer' as dev;

import '../../domain/entities/block_document.dart';
import '../../domain/entities/block_entity.dart';
import '../../domain/entities/block_metadata.dart';
import '../../domain/entities/blocks/unknown_block.dart';
import '../../domain/repositories/document_repository.dart';
import '../registry/block_type_registry.dart';
import '../utils/json_reader.dart';

/// Implements [DocumentRepository] using EditorJS JSON as the serialization format.
///
/// Parsing is lossless for well-formed blocks: block ids and tunes are kept in
/// [BlockDocument.metadata], and a block that no mapper can read is kept
/// verbatim as an [UnknownBlock] instead of being discarded.
class JsonDocumentSource implements DocumentRepository {
  static const _logName = 'EditorJSFlutter';

  final BlockTypeRegistry registry;

  const JsonDocumentSource({required this.registry});

  @override
  BlockDocument parse(String jsonString) {
    late final Map<String, dynamic> root;
    try {
      root = jsonDecode(jsonString) as Map<String, dynamic>;
    } on FormatException catch (_) {
      return _emptyDocument();
    } on TypeError catch (_) {
      return _emptyDocument();
    }

    final blocks = <BlockEntity>[];
    final metadata = <BlockMetadata>[];

    for (final raw in JsonReader.list(root['blocks'])) {
      if (raw is! Map<String, dynamic>) continue;

      // A block without a type cannot be rendered or written back.
      final type = raw['type'];
      if (type is! String || type.isEmpty) continue;

      final id = raw['id'];
      final tunes = JsonReader.map(raw['tunes']);

      blocks.add(_parseBlock(type, JsonReader.map(raw['data']) ?? {}));
      metadata.add(BlockMetadata(
        id: id is String && id.isNotEmpty ? id : null,
        tunes: tunes != null && tunes.isNotEmpty ? tunes : null,
      ));
    }

    return BlockDocument(
      time: _readTime(root['time']),
      version: JsonReader.string(root['version']),
      blocks: blocks,
      metadata: metadata,
    );
  }

  BlockEntity _parseBlock(String type, Map<String, dynamic> data) {
    try {
      final entity = registry.parse(type, data);
      if (entity != null) return entity;
      dev.log(
        'Unknown block type "$type" kept as-is (not rendered)',
        name: _logName,
      );
    } catch (error, stackTrace) {
      // Mappers are an extension point, so anything can be thrown here.
      // One unreadable block must never take the whole document down.
      dev.log(
        'Block "$type" could not be parsed and was kept as-is (not rendered)',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return UnknownBlock(type: type, data: data);
  }

  static int _readTime(dynamic value) {
    final parsed = switch (value) {
      String v => int.tryParse(v),
      _ => JsonReader.integer(value),
    };
    return parsed ?? DateTime.now().millisecondsSinceEpoch;
  }

  static BlockDocument _emptyDocument() => BlockDocument(
        time: DateTime.now().millisecondsSinceEpoch,
        version: '',
        blocks: const [],
      );

  @override
  String serialize(BlockDocument document) => jsonEncode(document.toJson());
}
