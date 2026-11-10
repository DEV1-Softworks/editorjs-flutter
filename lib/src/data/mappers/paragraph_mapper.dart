import '../../domain/entities/blocks/paragraph_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

class ParagraphMapper implements BlockMapper<ParagraphBlock> {
  const ParagraphMapper();

  @override
  String get supportedType => 'paragraph';

  @override
  ParagraphBlock fromJson(Map<String, dynamic> data) => ParagraphBlock(
        html: JsonReader.string(data['text']),
      );
}
